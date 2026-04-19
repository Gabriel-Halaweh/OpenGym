import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:uuid/uuid.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/media_item.dart';

class MediaStorageService extends ChangeNotifier {
  static const String _rootFolderName = 'OpenGym';

  String? _rootPath;

  final _uuid = const Uuid();
  final Map<String, Future<String?>> _thumbnailTasks = {};
  
  // Concurrency control for thumbnail generation
  final List<Completer<void>> _thumbnailQueue = [];
  static const int _maxConcurrentThumbnails = 3;
  int _activeThumbnailCount = 0;
  
  // Per-album reindex queues to prevent global I/O contention while keeping updates local
  final Map<String, Future<void>> _reindexQueues = {};
  final Map<String, MediaItem?> _latestMediaCache = {};

  MediaItem? getLatestMediaForAlbum(String albumName) => _latestMediaCache[albumName];

  String? _extractUuid(String path) {
    try {
      final fileName = p.basenameWithoutExtension(path);
      final match = RegExp(r'_id_([a-fA-F0-9-]{36})').firstMatch(fileName);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  Future<String> _getThumbnailPath(String videoPath) async {
    // Optimization: Use UUID-based fingerprint instead of reading the whole video file.
    // This is much faster for listing large albums.
    final uuid = _extractUuid(videoPath) ?? p.basenameWithoutExtension(videoPath);
    return p.join(_rootPath!, '.thumbnails', '$uuid.jpg');
  }

  bool _initialized = false;
  String? _lastError;

  String? get rootPath => _rootPath;
  bool get isInitialized => _initialized;
  String? get lastError => _lastError;

  // ── Initialization ──────────────────────────────────────────────

  /// Initialize storage path to a private sandbox.
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _rootPath = p.join(appDir.path, _rootFolderName);

      final dir = Directory(_rootPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Ensure global thumbnail directory exists
      final thumbDir = Directory(p.join(_rootPath!, '.thumbnails'));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      _initialized = true;

      // Directory exists and initialization is complete
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Initialization error: $e');
    }
  }

  // ── Import / Export Logic ──────────────────────────────────────

  /// Import media from device assets (used by custom GalleryPickerScreen).
  Future<int> importFromAssets(String albumName, List<AssetEntity> assets) async {
    debugPrint('===========================================================');
    debugPrint('[IMPORT DIAGNOSIS] BEGINNING IMPORT OPERATION');
    debugPrint('[IMPORT DIAGNOSIS] Target Album: "$albumName"');
    debugPrint('[IMPORT DIAGNOSIS] Total Assets to Process: ${assets.length}');
    debugPrint('[IMPORT DIAGNOSIS] Service Initialized: $_initialized');
    debugPrint('[IMPORT DIAGNOSIS] Root Path: $_rootPath');

    if (!_initialized) {
      debugPrint('[IMPORT DIAGNOSIS] FAILED: MediaStorageService is not initialized.');
      return 0;
    }
    if (_rootPath == null) {
      debugPrint('[IMPORT DIAGNOSIS] FAILED: _rootPath is NULL. Directory initialization failed.');
      return 0;
    }
    if (assets.isEmpty) {
      debugPrint('[IMPORT DIAGNOSIS] ABORTED: The asset list passed to the service is empty.');
      return 0;
    }
    
    // 1. Prepare target directory
    try {
      await ensureAlbum(albumName);
      final albumDirPath = p.join(_rootPath!, albumName);
      final albumDir = Directory(albumDirPath);
      if (!await albumDir.exists()) {
        debugPrint('[IMPORT DIAGNOSIS] Creating missing album directory: $albumDirPath');
        await albumDir.create(recursive: true);
      }
      debugPrint('[IMPORT DIAGNOSIS] Destination folder ready: $albumDirPath');
    } catch (e) {
      debugPrint('[IMPORT DIAGNOSIS] CRITICAL: Failed to create or access album directory. Error: $e');
      return 0;
    }

    int importedCount = 0;
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      debugPrint('-----------------------------------------------------------');
      debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}/${assets.length}] ID: ${asset.id}');
      debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Type: ${asset.type}, Title: ${asset.title}');
      
      try {
        // 2. Fetch the file source (Scoped Storage Safe)
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Requesting standard file handle (asset.file)...');
        File? sourceFile = await asset.file;
        
        if (sourceFile == null) {
          debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] asset.file returned NULL. Trying originFile fallback...');
          sourceFile = await asset.originFile;
        }
        
        if (sourceFile == null) {
          debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] CRITICAL FAILURE: Could not get ANY file handle from photo_manager.');
          continue;
        }

        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Source Path: ${sourceFile.path}');
        if (!await sourceFile.exists()) {
          debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] ERROR: Source file path reported, but file.exists() is FALSE.');
          continue;
        }

        // 3. Extension extraction
        String ext;
        if (asset.title != null && asset.title!.contains('.')) {
          ext = asset.title!.split('.').last.toLowerCase();
        } else {
          ext = (asset.type == AssetType.video) ? 'mp4' : 'jpg';
        }
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Resolved Extension: $ext');

        // 4. Filename & Destination
        final typeLabel = (asset.type == AssetType.video) ? 'Vid' : 'Photo';
        final normalizedAlbum = albumName.replaceAll(RegExp(r'\s+'), '');
        final d = asset.createDateTime ?? DateTime.now();
        final filename = '${typeLabel}_${normalizedAlbum}_${d.year}${_pad(d.month)}${_pad(d.day)}_${_pad(d.hour)}${_pad(d.minute)}${_pad(d.second)}_id_${_uuid.v4()}.$ext';
        final fullPath = p.join(_rootPath!, albumName, filename);
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Target Path: $fullPath');
        
        // 5. Stream Copy
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Starting Stream Pipe...');
        final destinationFile = File(fullPath);
        final sink = destinationFile.openWrite();
        await sourceFile.openRead().pipe(sink);
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] Stream Pipe Complete.');
        
        // 6. Verification
        if (await destinationFile.exists()) {
          final stats = await destinationFile.stat();
          debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] SUCCESS: File verified on disk. Size: ${stats.size} bytes.');
          importedCount++;
        } else {
          debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] FAILURE: Destination file does not exist after pipe.');
        }
      } catch (e) {
        debugPrint('[IMPORT DIAGNOSIS] [Item ${i + 1}] EXCEPTION: $e');
      }
    }

    // 7. Finish
    debugPrint('===========================================================');
    if (importedCount > 0) {
      debugPrint('[IMPORT DIAGNOSIS] Operation finished with $importedCount successes.');
      debugPrint('[IMPORT DIAGNOSIS] Triggering album reindex for "$albumName"');
      await reindexAlbum(albumName); 
      notifyListeners();
    } else {
      debugPrint('[IMPORT DIAGNOSIS] Operation finished with ZERO items imported.');
    }
    debugPrint('===========================================================');

    return importedCount;
  }

  /// Export selected media items to the system gallery.
  Future<int> exportToGallery(List<MediaItem> items) async {
    int exportedCount = 0;
    
    // Check permission state first with required requestOption
    final ps = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    if (!ps.isAuth && !ps.hasAccess) {
      debugPrint('[EXPORT] FAILED: No gallery write permission.');
      return 0;
    }

    debugPrint('[EXPORT] Starting bulk export of ${items.length} items to system gallery...');
    
    // On Android, using 'DCIM/OpenGym' ensures that both photos and videos 
    // are placed in a single shared folder instead of being split into 
    // 'Pictures' and 'Movies' by the system.
    const String relativePath = 'DCIM/OpenGym';

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final file = File(item.filePath);
      if (!await file.exists()) {
        debugPrint('[EXPORT] Skipping missing file: ${item.filePath}');
        continue;
      }

      try {
        AssetEntity? result;
        final String title = p.basenameWithoutExtension(item.filePath);

        if (item.mediaType == 'video') {
          debugPrint('[EXPORT] Video item ${i + 1}/${items.length}: $title');
          // Videos must be passed as File objects directly to the editor
          result = await PhotoManager.editor.saveVideo(
            file,
            title: title,
            desc: 'Exported from Workout App',
            relativePath: relativePath,
          );
        } else {
          debugPrint('[EXPORT] Photo item ${i + 1}/${items.length}: $title');
          // Photos are best passed as Uint8List for cross-platform stability
          final Uint8List bytes = await file.readAsBytes();
          result = await PhotoManager.editor.saveImage(
            bytes,
            title: title,
            filename: '$title.jpg',
            desc: 'Exported from Workout App',
            relativePath: relativePath,
          );
        }

        if (result != null) {
          debugPrint('[EXPORT] SUCCESS: $title was saved to system gallery.');
          exportedCount++;
        } else {
          debugPrint('[EXPORT] FAILED: $title - system editor returned null.');
        }
      } catch (e) {
        debugPrint('[EXPORT] EXCEPTION for ${item.filePath}: $e');
      }
    }

    return exportedCount;
  }

  /// Import images or videos from the system gallery into a specific album.
  /// Deprecated: Prefer using custom GalleryPickerScreen and [importFromAssets].
  Future<int> importMedia(String albumName) async {
    // This method is now officially DISABLED in favor of importFromAssets + GalleryPickerScreen.
    // We are printing a stack trace here so we can find any accidental callers in the logs.
    debugPrint('*** WARNING: OLD ImagePicker TRIGGERED for album: $albumName ***');
    debugPrint(StackTrace.current.toString());
    return 0;
  }


  /// Exports a media item back to the public system gallery.
  Future<bool> exportMedia(MediaItem item) async {
    if (!_initialized) return false;
    
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Request appropriate permissions for Android
        if (sdkInt >= 33) {
          final photos = await Permission.photos.request();
          final videos = await Permission.videos.request();
          if (photos.isDenied && videos.isDenied) return false;
        } else {
          final storage = await Permission.storage.request();
          if (storage.isDenied) return false;
        }

        const platform = MethodChannel('com.opengym.app/media_scanner');
        await platform.invokeMethod('saveToGallery', {
          'filePath': item.filePath,
          'albumName': 'OpenGym Exported',
        });
        return true;
      } else if (Platform.isIOS) {
        // iOS implementation would go here if needed
        return false;
      }
      return false;
    } catch (e) {
      _lastError = 'Export failed: $e';
      debugPrint(_lastError);
      return false;
    }
  }

  /// Tells the Android MediaScanner to check a specific path.
  Future<void> triggerMediaScanForPath(String path) async {
    if (!Platform.isAndroid) return;
    try {
      const platform = MethodChannel('com.opengym.app/media_scanner');
      await platform.invokeMethod('scanFolder', {'path': path});
    } catch (e) {
      debugPrint('Failed to trigger scan for $path: $e');
    }
  }

  // ── Album Management ────────────────────────────────────────────

  Future<bool> ensureAlbum(String albumName) async {
    if (_rootPath == null) return false;
    final dir = Directory(p.join(_rootPath!, albumName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    notifyListeners();
    return true;
  }

  Future<void> deleteAlbum(String albumName) async {
    if (_rootPath == null) return;
    final dir = Directory(p.join(_rootPath!, albumName));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    notifyListeners();
  }

  /// Normalizes album name: Title Case, trimmed. Strips non-alphanumeric chars.
  static String capitalizeAlbumName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').trim();
    return cleaned.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Returns true if name contains only alphanumeric characters and spaces.
  static bool isValidAlbumName(String name) {
    return RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(name.trim()) && name.trim().isNotEmpty;
  }

  /// Check if normalized names match (ignoring spaces and case).
  static bool namesMatch(String a, String b) {
    return a.replaceAll(RegExp(r'\s+'), '').toLowerCase() ==
        b.replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }

  /// Returns true if an album with the same normalized name exists.
  Future<bool> albumExists(String name) async {
    if (_rootPath == null) return false;
    final albums = await getAlbums();
    return albums.any((a) => namesMatch(a.name, name));
  }

  /// Delete a single media file and its associated thumbnail.
  Future<void> deleteMedia(String filePath) async {
    if (_rootPath == null) return;
    
    // Find the item to get its album name for reindexing
    final file = File(filePath);
    if (!await file.exists()) return;
    
    final parts = filePath.split(Platform.isWindows ? '\\' : '/');
    if (parts.length < 2) return;
    final albumName = parts[parts.length - 2];
    
    // We can just construct a temporary MediaItem or call a more granular delete
    // For simplicity, let's just delete and reindex
    await file.delete();
    
    // Try delete thumbnail if it's a video
    try {
      final thumbPath = await _getThumbnailPath(filePath);
      final thumbFile = File(thumbPath);
      if (await thumbFile.exists()) await thumbFile.delete();
    } catch (_) {}

    await reindexAlbum(albumName);
    notifyListeners();
  }

  /// Bulk delete media files and their associated thumbnails.
  Future<void> deleteMediaList(List<MediaItem> items) async {
    if (_rootPath == null || items.isEmpty) return;

    final albumsToReindex = <String>{};

    for (final item in items) {
      final file = File(item.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
          albumsToReindex.add(item.albumName);
        } catch (e) {
          debugPrint('Failed to delete file ${item.filePath}: $e');
        }
      }

      // Delete thumbnail if it exists
      if (item.mediaType == 'video') {
        try {
          final thumbnailPath = await _getThumbnailPath(item.filePath);
          final thumbnailFile = File(thumbnailPath);
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete thumbnail for ${item.filePath}: $e');
        }
      }
    }

    for (final album in albumsToReindex) {
      await reindexAlbum(album);
    }
    notifyListeners();
  }

  /// Permanently delete ALL media files, albums, and thumbnails.
  Future<void> clearAllMedia() async {
    if (_rootPath == null) return;
    try {
      final dir = Directory(_rootPath!);
      if (await dir.exists()) {
        // Delete everything inside OpenGym root
        final contents = dir.listSync();
        for (final entity in contents) {
          if (entity is Directory) {
            await entity.delete(recursive: true);
          } else if (entity is File) {
            await entity.delete();
          }
        }
        
        // Ensure .thumbnails directory is recreated
        final thumbDir = Directory(p.join(_rootPath!, '.thumbnails'));
        if (!await thumbDir.exists()) {
          await thumbDir.create(recursive: true);
        }
      }
      _latestMediaCache.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all media: $e');
    }
  }

  /// Bulk move media files from their current albums to a target album.
  Future<void> moveMediaList(List<MediaItem> items, String targetAlbum) async {
    if (_rootPath == null || items.isEmpty) return;
    await ensureAlbum(targetAlbum);
    
    final albumsToReindex = <String>{targetAlbum};
    
    for (final item in items) {
      final file = File(item.filePath);
      if (!await file.exists()) continue;
      
      final fileName = p.basename(item.filePath);
      final newPath = p.join(_rootPath!, targetAlbum, fileName);
      
      if (item.filePath == newPath) continue;
      
      await file.rename(newPath);
      albumsToReindex.add(item.albumName);
    }
    
    for (final album in albumsToReindex) {
      await reindexAlbum(album);
    }
    
    notifyListeners();
  }

  /// Move a single media file from its current album to a target album.
  Future<void> moveMedia(String filePath, String targetAlbum) async {
    if (_rootPath == null) return;
    await ensureAlbum(targetAlbum);
    final file = File(filePath);
    if (!await file.exists()) return;
    final fileName = p.basename(filePath);
    final newPath = p.join(_rootPath!, targetAlbum, fileName);
    await file.rename(newPath);
    await reindexAlbum(targetAlbum);
    // If it was moved from another valid album, reindex that too
    final parts = filePath.split(Platform.isWindows ? '\\' : '/');
    if (parts.length >= 2) {
      final oldAlbum = parts[parts.length - 2];
      if (oldAlbum != _rootFolderName) {
        await reindexAlbum(oldAlbum);
      }
    }
    notifyListeners();
  }

  /// Rename an album directory. Returns the new name.
  Future<String> renameAlbum(String oldName, String newName) async {
    if (_rootPath == null) return oldName;
    final oldDir = Directory(p.join(_rootPath!, oldName));
    if (!await oldDir.exists()) return oldName;
    final formatted = capitalizeAlbumName(newName);
    final newPath = p.join(_rootPath!, formatted);
    await oldDir.rename(newPath);
    notifyListeners();
    return formatted;
  }

  /// Merge source album into target: move all files, then delete source folder.
  Future<void> mergeAlbums(String source, String target) async {
    if (_rootPath == null) return;
    final sourceDir = Directory(p.join(_rootPath!, source));
    if (!await sourceDir.exists()) return;
    await ensureAlbum(target);
    await for (final entity in sourceDir.list()) {
      if (entity is File) {
        final fileName = p.basename(entity.path);
        final newPath = p.join(_rootPath!, target, fileName);
        await entity.rename(newPath);
      }
    }
    await sourceDir.delete(recursive: true);
    await reindexAlbum(target);
    notifyListeners();
  }

  /// Renames all files in an album to YYYYMMDD_HHMMSS_AlbumName_Type_Count_id_UUID.ext
  Future<void> reindexAlbum(String albumName) async {
    final completer = Completer<void>();
    final previousTask = _reindexQueues[albumName] ?? Future.value();
    _reindexQueues[albumName] = completer.future;

    await previousTask;
    try {
      await _executeReindex(albumName);
      // After reindexing, refresh the cache for this specific album rigorously.
      // This ensures that importing historical photos correctly updates the "latest" cover if needed.
      final items = await getMediaForAlbum(albumName, newestFirst: true);
      if (items.isNotEmpty) {
        _latestMediaCache[albumName] = items.first;
      } else {
        _latestMediaCache[albumName] = null;
      }
    } finally {
      completer.complete();
    }
  }

  Future<void> _executeReindex(String albumName) async {
    if (_rootPath == null) return;
    final dir = Directory(p.join(_rootPath!, albumName));
    if (!await dir.exists()) return;

    final allMedia = <MediaItem>[];
    await for (final entity in dir.list()) {
      if (entity is File && _isMediaFile(entity.path)) {
        final date = _parseDateFromFilename(entity.path) ??
            (await entity.stat()).modified;
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        // Updated to include modern video containers: mkv, webm
        final type = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext) ? 'video' : 'photo';
        allMedia.add(MediaItem(
          filePath: entity.path,
          albumName: albumName,
          dateTaken: date,
          mediaType: type,
          id: _extractUuid(entity.path),
        ));
      }
    }

    final normalizedAlbum = albumName.replaceAll(RegExp(r'\s+'), '');

    // TO PREVENT DATA LOSS: We never use sequential numbers (Photo_1, Photo_2)
    // as the ONLY uniqueness constraint. Every file MUST retain its UUID.
    for (final item in allMedia) {
      final uuid = item.id ?? _uuid.v4();
      final d = item.dateTaken;
      final datePrefix = '${d.year}${_pad(d.month)}${_pad(d.day)}_${_pad(d.hour)}${_pad(d.minute)}${_pad(d.second)}';
      final ext = p.extension(item.filePath).toLowerCase().replaceAll('.', '');
      final finalType = item.mediaType == 'video' ? 'Vid' : 'Photo';
      final newName = '${finalType}_${normalizedAlbum}_${datePrefix}_id_$uuid.$ext';
      final newPath = p.join(_rootPath!, albumName, newName);
      
      if (item.filePath != newPath) {
        await _safeRename(item.filePath, newPath);
      }
    }
  }

  /// Optional background cleanup of orphaned thumbnails. 
  /// Should be called rarely (e.g., app start or manual cleanup), not on every capture.
  Future<void> cleanupOrphanedThumbnails() async {
    if (_rootPath == null) return;
    final globalThumbDir = Directory(p.join(_rootPath!, '.thumbnails'));
    if (!await globalThumbDir.exists()) return;

    final List<String> allVideoUuids = [];
    final root = Directory(_rootPath!);
    await for (final album in root.list()) {
      if (album is Directory && !p.basename(album.path).startsWith('.')) {
        await for (final file in album.list()) {
          if (file is File && _isMediaFile(file.path)) {
            final ext = p.extension(file.path).toLowerCase();
            // Expanded video list for cleanup logic
            if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(ext)) {
              final uuid = _extractUuid(file.path);
              if (uuid != null) allVideoUuids.add(uuid);
            }
          }
        }
      }
    }
    
    final Set<String> activeFingerprints = allVideoUuids.toSet();
    await for (final entity in globalThumbDir.list()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        final fileName = p.basenameWithoutExtension(entity.path);
        if (!activeFingerprints.contains(fileName)) {
          await entity.delete();
        }
      }
    }
  }

  Future<void> _safeRename(String oldPath, String newPath) async {
    try {
      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);
      }
    } catch (e) {
      debugPrint('Rename failure: $e');
    }
  }

  Future<List<AlbumInfo>> getAlbums({DateTimeRange? filter}) async {
    if (_rootPath == null) return [];
    final root = Directory(_rootPath!);
    if (!await root.exists()) return [];

    final albums = <AlbumInfo>[];
    await for (final entity in root.list()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.startsWith('.')) continue;
        final counts = await _getDetailedCounts(entity, filter: filter);
        if (counts['total']! > 0 || filter == null) {
          albums.add(AlbumInfo(
            name: name, 
            itemCount: counts['total']!, 
            photoCount: counts['photos']!,
            videoCount: counts['videos']!,
            path: entity.path
          ));
        }
      }
    }
    albums.sort((a, b) => a.name.compareTo(b.name));
    return albums;
  }

  Future<Map<String, int>> _getDetailedCounts(Directory dir, {DateTimeRange? filter}) async {
    int photos = 0;
    int videos = 0;
    await for (final entity in dir.list()) {
      if (entity is File && _isMediaFile(entity.path)) {
        if (filter != null) {
          final date = _parseDateFromFilename(entity.path) ?? (await entity.stat()).modified;
          final startBound = DateTime(filter.start.year, filter.start.month, filter.start.day);
          final nextDayAfterEnd = DateTime(filter.end.year, filter.end.month, filter.end.day).add(const Duration(days: 1));
          if (date.isBefore(startBound) || !date.isBefore(nextDayAfterEnd)) {
            continue;
          }
        }
        final ext = entity.path.split('.').last.toLowerCase();
        if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
          videos++;
        } else {
          photos++;
        }
      }
    }
    return {'total': photos + videos, 'photos': photos, 'videos': videos};
  }

  bool _isMediaFile(String path) {
    final ext = p.extension(path).toLowerCase().replaceAll('.', '');
    // Added standard modern formats: heic, heif, mkv, webm
    return ['png', 'jpg', 'jpeg', 'webp', 'heic', 'heif', 'mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  // ── Media Access ────────────────────────────────────────────────

  Future<List<MediaItem>> getMediaForAlbum(String albumName,
      {bool newestFirst = true, DateTimeRange? filter}) async {
    if (_rootPath == null) return [];
    final dirPath = p.join(_rootPath!, albumName);
    final dir = Directory(dirPath);
    if (!await dir.exists()) return [];

    final items = <MediaItem>[];
    // Use sync listing for metadata parsing to avoid context switching
    final entities = dir.listSync();
    
    for (final entity in entities) {
      if (entity is File && _isMediaFile(entity.path)) {
        // High performance: Parse everything from filename if possible
        final date = _parseDateFromFilename(entity.path) ?? 
                    entity.lastModifiedSync();
                    
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        // Synchronized video detection: ensures MKV/WebM are not forced into Photo mode
        final type = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext) ? 'video' : 'photo';
        if (filter != null) {
          final startBound = DateTime(filter.start.year, filter.start.month, filter.start.day);
          final nextDayAfterEnd = DateTime(filter.end.year, filter.end.month, filter.end.day).add(const Duration(days: 1));
          if (date.isBefore(startBound) || !date.isBefore(nextDayAfterEnd)) {
            continue;
          }
        }

        String? thumb;
        if (type == 'video') {
          final potential = await _getThumbnailPath(entity.path);
          if (await File(potential).exists()) {
            thumb = potential;
          }
        }
        
        final item = MediaItem(
          filePath: entity.path,
          albumName: albumName,
          dateTaken: date,
          mediaType: type,
          thumbnailPath: thumb,
          id: type == 'video' ? _extractUuid(entity.path) : null,
        );
        items.add(item);
      }
    }

    items.sort((a, b) => newestFirst
        ? b.dateTaken.compareTo(a.dateTaken)
        : a.dateTaken.compareTo(b.dateTaken));
    
    // Update cache with the most recent item
    if (items.isNotEmpty) {
      _latestMediaCache[albumName] = newestFirst ? items.first : items.last;
    } else {
      _latestMediaCache[albumName] = null;
    }

    return items;
  }

  /// Get all media across all albums, sorted by date.
  Future<List<MediaItem>> getAllMedia({bool newestFirst = true, DateTimeRange? filter}) async {
    final albums = await getAlbums(filter: filter);
    final all = <MediaItem>[];
    for (final album in albums) {
      all.addAll(await getMediaForAlbum(album.name, newestFirst: false, filter: filter));
    }
    all.sort((a, b) => newestFirst
        ? b.dateTaken.compareTo(a.dateTaken)
        : a.dateTaken.compareTo(b.dateTaken));
    return all;
  }

  DateTime? _parseDateFromFilename(String path) {
    final filename = p.basenameWithoutExtension(path);
    
    // Use regex to find the YYYYMMDD_HHMMSS pattern anywhere in the filename
    final dateRegex = RegExp(r'(\d{8})_(\d{6})');
    final match = dateRegex.firstMatch(filename);
    
    if (match == null) return null;
    
    try {
      final datePart = match.group(1)!;
      final timePart = match.group(2)!;
      
      final y = int.parse(datePart.substring(0, 4));
      final m = int.parse(datePart.substring(4, 6));
      final d = int.parse(datePart.substring(6, 8));
      final h = int.parse(timePart.substring(0, 2));
      final min = int.parse(timePart.substring(2, 4));
      final s = int.parse(timePart.substring(4, 6));
      
      return DateTime(y, m, d, h, min, s);
    } catch (_) {
      return null;
    }
  }

  Future<String?> savePhoto(String albumName, Uint8List bytes,
      {DateTime? date, String ext = 'jpg'}) async {
    if (_rootPath == null) return null;
    await ensureAlbum(albumName);

    final d = date ?? DateTime.now();
    // Unique name without CAP_ prefix
    final normalizedAlbum = albumName.replaceAll(RegExp(r'\s+'), '');
    final filename =
        'Photo_${normalizedAlbum}_${d.year}${_pad(d.month)}${_pad(d.day)}_${_pad(d.hour)}${_pad(d.minute)}${_pad(d.second)}_id_${_uuid.v4()}.$ext';
    final fullPath = p.join(_rootPath!, albumName, filename);
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    
    // Optimistically update cache immediately so UI feels instant
    _latestMediaCache[albumName] = MediaItem(
      filePath: file.path,
      albumName: albumName,
      dateTaken: d,
      mediaType: 'photo',
    );
    notifyListeners();

    // Trigger reindexing in the background
    reindexAlbum(albumName).then((_) => notifyListeners());

    return file.path;
  }

  Future<String?> saveVideo(String albumName, Uint8List bytes,
      {DateTime? date}) async {
    if (_rootPath == null) return null;
    await ensureAlbum(albumName);

    final d = date ?? DateTime.now();
    // Use VID_ prefix for clear identification, but remove CAP_
    final normalizedAlbum = albumName.replaceAll(RegExp(r'\s+'), '');
    final filename =
        'Vid_${normalizedAlbum}_${d.year}${_pad(d.month)}${_pad(d.day)}_${_pad(d.hour)}${_pad(d.minute)}${_pad(d.second)}_id_${_uuid.v4()}.mp4';
    final fullPath = p.join(_rootPath!, albumName, filename);
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    
    // Optimistically update cache
    final mediaItem = MediaItem(
      filePath: file.path, 
      albumName: albumName, 
      dateTaken: d, 
      mediaType: 'video',
    );
    _latestMediaCache[albumName] = mediaItem;
    notifyListeners();

    // For videos, we must ensure reindexing and thumbnail generation happen BEFORE 
    // we return and release the camera UI's saving state.
    await reindexAlbum(albumName);
    await getOrGenerateThumbnail(mediaItem);

    notifyListeners();
    return file.path;
  }

  Future<String?> getOrGenerateThumbnail(MediaItem item) async {
    if (item.mediaType != 'video') return null;
    
    final targetPath = await _getThumbnailPath(item.filePath);
    if (await File(targetPath).exists()) return targetPath;

    // Prevent multiple concurrent tasks for the same exact thumbnail
    if (_thumbnailTasks.containsKey(targetPath)) {
      return _thumbnailTasks[targetPath];
    }

    final task = _queuedThumbnailGeneration(item, targetPath);
    _thumbnailTasks[targetPath] = task;
    
    try {
      final result = await task;
      if (result != null) {
        notifyListeners();
      }
      return result;
    } finally {
      _thumbnailTasks.remove(targetPath);
    }
  }

  Future<String?> _queuedThumbnailGeneration(MediaItem item, String targetPath) async {
    // Throttling logic: wait if too many tasks are active
    if (_activeThumbnailCount >= _maxConcurrentThumbnails) {
      final completer = Completer<void>();
      _thumbnailQueue.add(completer);
      await completer.future;
    }

    _activeThumbnailCount++;
    try {
      return await _executeThumbnailGeneration(item, targetPath);
    } finally {
      _activeThumbnailCount--;
      // Run the next task in queue
      if (_thumbnailQueue.isNotEmpty) {
        _thumbnailQueue.removeAt(0).complete();
      }
    }
  }

  Future<String?> _executeThumbnailGeneration(MediaItem item, String targetPath) async {
    final thumbDir = Directory(p.dirname(targetPath));
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }

    try {
      // Use timeMs: 0 for extreme speed and low memory impact.
      // Initializing VideoPlayerControllers in a loop is what causes the OOM crash.
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: item.filePath,
        thumbnailPath: thumbDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 250, // Reduced from 400 for even lighter memory usage
        quality: 60,   // Reduced from 75
        timeMs: 0,
      );
      
      if (thumbPath != null && thumbPath != targetPath) {
        final generatedFile = File(thumbPath);
        if (await generatedFile.exists()) {
          // Rename to the fingerprint-stable path
          await generatedFile.rename(targetPath);
        }
      }
      
      return targetPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');


}

class AlbumInfo {
  final String name;
  final int itemCount;
  final int photoCount;
  final int videoCount;
  final String path;

  const AlbumInfo({
    required this.name,
    required this.itemCount,
    this.photoCount = 0,
    this.videoCount = 0,
    required this.path,
  });
}
