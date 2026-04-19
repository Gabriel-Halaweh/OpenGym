import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/media_item.dart';
import '../services/media_storage_service.dart';
import '../utils/constants.dart';

class VideoThumbnailPlayer extends StatefulWidget {
  final String? filePath;
  final MediaItem? item;

  const VideoThumbnailPlayer({super.key, this.filePath, this.item});

  @override
  State<VideoThumbnailPlayer> createState() => _VideoThumbnailPlayerState();
}

class _VideoThumbnailPlayerState extends State<VideoThumbnailPlayer> {
  String? _cachedPath;
  bool _isInit = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Fast path: if the item already has a verified thumbnail path, use it immediately
    if (widget.item?.thumbnailPath != null) {
      final file = File(widget.item!.thumbnailPath!);
      if (file.existsSync()) {
        _cachedPath = widget.item!.thumbnailPath;
        _isInit = true;
      }
    }
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoThumbnailPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.item != widget.item) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    final storage = context.read<MediaStorageService>();

    MediaItem? targetItem = widget.item;

    if (targetItem == null && widget.filePath != null) {
      targetItem = MediaItem(
        filePath: widget.filePath!,
        albumName: '', 
        dateTaken: DateTime.now(),
        mediaType: 'video',
      );
    }

    if (targetItem == null) return;

    try {
      final path = await storage.getOrGenerateThumbnail(targetItem);
      if (mounted) {
        setState(() {
          _cachedPath = path;
          _isInit = true;
          _error = path == null;
        });
      }
    } catch (e) {
      debugPrint('Error loading video thumbnail: $e');
      if (mounted) {
        setState(() {
          _error = true;
          _isInit = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return Container(
        color: AppConstants.bgElevated,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1,
              color: Colors.white24,
            ),
          ),
        ),
      );
    }

    if (_error || _cachedPath == null) {
      return Container(
        color: AppConstants.bgElevated,
        child: Center(
          child: Icon(
            Icons.videocam_off_rounded,
            color: AppConstants.textMuted.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      );
    }

    return Image.file(
      File(_cachedPath!),
      fit: BoxFit.cover,
      cacheWidth: 250, // Optimize memory for thumbnails
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppConstants.bgElevated,
          child: const Icon(Icons.broken_image_rounded, size: 24),
        );
      },
    );
  }
}
