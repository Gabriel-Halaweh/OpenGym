import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/theme_provider.dart';
import 'package:flutter/services.dart';
import '../services/media_storage_service.dart';
import '../models/media_item.dart';
import '../utils/constants.dart';
import '../widgets/media_calendar_picker.dart';
import '../widgets/video_thumbnail_player.dart';
import 'camera_mockups.dart';
import 'camera_view_page.dart';
import 'media_view_page.dart';
import 'gallery_picker_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/storage_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isAlbumMode = false;
  DateTimeRange? _filterRange;
  int _columnCount = 3;

  final Set<MediaItem> _selectedItems = {};
  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadAlbumPrefs();
  }

  void _loadAlbumPrefs() {
    final storage = context.read<StorageService>();
    setState(() {
      _columnCount = storage.getAlbumColumns();
      _isAlbumMode = storage.getCameraIsAlbumMode();
    });
  }

  void _updateTab(bool isAlbumMode) {
    if (_isAlbumMode == isAlbumMode) return;
    setState(() => _isAlbumMode = isAlbumMode);
    context.read<StorageService>().saveCameraIsAlbumMode(isAlbumMode);
  }

  void _updateColumnCount(int count) {
    if (_columnCount == count) return;
    setState(() => _columnCount = count);
    context.read<StorageService>().saveAlbumColumns(count);
  }

  void _clearSelection() {
    setState(() {
      _selectedItems.clear();
    });
  }

  void _toggleSelection(MediaItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedItems.isEmpty) return;
    final ms = context.read<MediaStorageService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete ${_selectedItems.length} items?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final itemsToDelete = _selectedItems.toList();
      _clearSelection();
      await ms.deleteMediaList(itemsToDelete);
    }
  }

  Future<void> _bulkMove() async {
    if (_selectedItems.isEmpty) return;
    final ms = context.read<MediaStorageService>();
    final targetAlbum = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BulkMoveAlbumPicker(
        items: _selectedItems.toList(),
      ),
    );

    if (targetAlbum != null && mounted) {
      final itemsToMove = _selectedItems.toList();
      _clearSelection();
      await ms.moveMediaList(itemsToMove, targetAlbum);
    }
  }

  Future<void> _bulkExport() async {
    if (_selectedItems.isEmpty) return;
    final ms = context.read<MediaStorageService>();
    final itemsToExport = _selectedItems.toList();
    
    // Clear selection before process for cleaner UI
    _clearSelection();
    
    _toast(context, 'Exporting ${itemsToExport.length} items to gallery...');
    final count = await ms.exportToGallery(itemsToExport);
    
    if (mounted) {
      _toast(context, 'Successfully exported $count items.');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final mediaStorage = context.watch<MediaStorageService>();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor:
                    AppConstants.accentPrimary.withValues(alpha: 0.1),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSelection,
                ),
                title: Text(
                  '${_selectedItems.length} selected',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _bulkExport,
                    tooltip: 'Export to gallery',
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_rounded),
                    onPressed: _bulkMove,
                    tooltip: 'Move selected',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded),
                    onPressed: _bulkDelete,
                    color: Colors.redAccent,
                    tooltip: 'Delete selected',
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : AppBar(
                centerTitle: false,
                title: Text(
                  _isAlbumMode ? 'All albums' : 'Progress Tracker',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: _isAlbumMode ? 24 : 18,
                  ),
                ),
                actions: _buildAppBarActions(mediaStorage),
              ),

      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAlbumMode) ...[
            FloatingActionButton(
              heroTag: 'new_album_fab',
              backgroundColor: AppConstants.accentPrimary,
              onPressed: () =>
                  _AlbumModeView._showNewAlbumDialog(context, mediaStorage),
              child: const Icon(
                Icons.create_new_folder_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton(
            heroTag: 'camera_fab',
            backgroundColor: AppConstants.accentPrimary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraViewPage()),
              );
            },
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  _toggleTab(
                    'Photos',
                    Icons.photo_library_rounded,
                    !_isAlbumMode,
                    () => _updateTab(false),
                  ),
                  _toggleTab(
                    'Albums',
                    Icons.folder_rounded,
                    _isAlbumMode,
                    () => _updateTab(true),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isAlbumMode
                  ? _AlbumModeView(
                      key: const ValueKey('albums'),
                      filterRange: _filterRange,
                      columnCount: _columnCount,
                      onColumnCountChanged: _updateColumnCount,
                      selectedItems: _selectedItems,
                      onToggleSelection: _toggleSelection,
                    )
                  : _PhotoModeView(
                      key: const ValueKey('photos'),
                      filterRange: _filterRange,
                      selectedItems: _selectedItems,
                      onToggleSelection: _toggleSelection,
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _toggleTab(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppConstants.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD - 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppConstants.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(MediaStorageService mediaStorage) {
    return [
      IconButton(
        icon: const Icon(Icons.download_rounded),
        tooltip: 'Import',
        onPressed: () =>
            _AlbumModeView._showImportAction(context, mediaStorage),
      ),
      if (_filterRange != null)
        IconButton(
          icon: Icon(
            Icons.filter_alt_off_rounded,
            color: AppConstants.accentSecondary,
          ),
          tooltip: 'Clear Filter',
          onPressed: () => setState(() => _filterRange = null),
        )
      else
        IconButton(
          icon: const Icon(Icons.date_range_rounded),
          tooltip: 'Filter by Date',
          onPressed: () async {
            final allMedia = await mediaStorage.getAllMedia();
            if (!context.mounted) return;

            final range = await MediaCalendarPicker.showRangePicker(
              context,
              allMedia,
              initialRange: _filterRange,
            );

            // Note: MediaCalendarPicker returns null if cancelled,
            // but we can distinguish a manual clear if we wanted.
            // For now, only update if a range was selected.
            if (range != null) {
              setState(() => _filterRange = range);
            }
          },
        ),
      IconButton(
        icon: const Icon(Icons.compare_rounded),
        tooltip: 'Compare',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MockupFiveScreen()),
          );
        },
      ),
      const SizedBox(width: 8),
    ];
  }
}

// ============================================================
// PHOTO MODE — Netflix-style rows using real file system data
// ============================================================

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppConstants.bgElevated,
    ),
  );
}

class _PhotoModeView extends StatelessWidget {
  final DateTimeRange? filterRange;
  final Set<MediaItem> selectedItems;
  final ValueChanged<MediaItem> onToggleSelection;

  const _PhotoModeView({
    super.key,
    this.filterRange,
    required this.selectedItems,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.watch<MediaStorageService>();

    return FutureBuilder<List<AlbumInfo>>(
      future: mediaStorage.getAlbums(filter: filterRange),
      builder: (context, snapshot) {
        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return Center(
            child: Text(
              'No albums yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppConstants.textMuted,
              ),
            ),
          );
        }

        return ListView(
          children: [
            const SizedBox(height: 4),
            ...albums.map(
              (album) => _AlbumRow(
                albumInfo: album,
                filterRange: filterRange,
                selectedItems: selectedItems,
                onToggleSelection: onToggleSelection,
              ),
            ),
            const SizedBox(height: 130),
          ],
        );
      },
    );
  }
}

class _AlbumRow extends StatefulWidget {
  final AlbumInfo albumInfo;
  final DateTimeRange? filterRange;
  final Set<MediaItem> selectedItems;
  final ValueChanged<MediaItem> onToggleSelection;

  const _AlbumRow({
    required this.albumInfo,
    this.filterRange,
    required this.selectedItems,
    required this.onToggleSelection,
  });

  @override
  State<_AlbumRow> createState() => _AlbumRowState();
}

class _AlbumRowState extends State<_AlbumRow> {
  late Future<List<MediaItem>> _mediaFuture;
  late MediaStorageService _ms;
  final ScrollController _scrollController = ScrollController();

  // Drag Selection State
  int? _dragStartIndex;
  int? _lastDragIndex;
  bool _isDragging = false;
  bool _dragSelects = true; 
  Set<MediaItem> _selectionAtStart = {};
  Timer? _autoScrollTimer;
  double _lastPointerX = 0;

  @override
  void initState() {
    super.initState();
    _ms = context.read<MediaStorageService>();
    _refreshMedia();
    _ms.addListener(_refreshMedia);
  }

  @override
  void didUpdateWidget(covariant _AlbumRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterRange != widget.filterRange) {
      _refreshMedia();
    }
  }

  void _refreshMedia() {
    if (!mounted) return;
    setState(() {
      _mediaFuture = _ms.getMediaForAlbum(
        widget.albumInfo.name,
        filter: widget.filterRange,
      );
    });
  }

  @override
  void dispose() {
    _ms.removeListener(_refreshMedia);
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }
  void _updateRangeSelection(int start, int end, List<MediaItem> allItems) {
    setState(() {
      _lastDragIndex = end;
    });
  }


  int? _calculateIndexAtPos(Offset localPos, double rowHeight, int itemCount) {
    if (itemCount == 0) return null;
    const double padding = 16.0;
    const double spacing = 10.0;
    const double itemWidth = 90.0;
    
    final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final double relativeX = localPos.dx + scrollOffset - padding;

    if (relativeX < 0) return 0;
    
    final int index = (relativeX / (itemWidth + spacing)).floor();
    
    if (index < 0) return 0;
    if (index >= itemCount) return itemCount - 1;
    return index;
  }

  void _maybeStartAutoSelectionScroll(double viewportWidth, List<MediaItem> allItems) {
    _autoScrollTimer?.cancel();
    if (!_isDragging) return;

    const double edgeSize = 100.0;
    double scrollAmount = 0;

    if (_lastPointerX < edgeSize) {
      scrollAmount = -((edgeSize - _lastPointerX) / 1.0).clamp(2.0, 15.0);
    } else if (_lastPointerX > viewportWidth - edgeSize) {
      scrollAmount = ((_lastPointerX - (viewportWidth - edgeSize)) / 1.0).clamp(2.0, 15.0);
    }

    if (scrollAmount != 0) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_isDragging || !_scrollController.hasClients) {
          timer.cancel();
          return;
        }

        final double newOffset = (_scrollController.offset + scrollAmount).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        
        if (newOffset != _scrollController.offset) {
          _scrollController.jumpTo(newOffset);
          final index = _calculateIndexAtPos(Offset(_lastPointerX, 0), 120, allItems.length);
          if (index != null && index != _lastDragIndex) {
            _lastDragIndex = index;
            _updateRangeSelection(_dragStartIndex!, index, allItems);
          }
        }
      });
    }
  }

  void _stopDragging() {
    _isDragging = false;
    _dragStartIndex = null;
    _lastDragIndex = null;
    _autoScrollTimer?.cancel();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: _mediaFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    widget.albumInfo.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlbumDetailScreen(
                          albumName: widget.albumInfo.name,
                          filterRange: widget.filterRange,
                          selectedItems: widget.selectedItems,
                          onToggleSelection: widget.onToggleSelection,
                        ),
                      ),
                    ),
                    child: Text(
                      'See all',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppConstants.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: LayoutBuilder(
                builder: (context, constraints) => Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerMove: (event) {
                    if (_isDragging) {
                      _lastPointerX = event.localPosition.dx;
                      final index = _calculateIndexAtPos(
                        event.localPosition,
                        constraints.maxHeight,
                        items.length,
                      );
                      if (index != null && index != _lastDragIndex) {
                        _lastDragIndex = index;
                        _updateRangeSelection(_dragStartIndex!, index, items);
                        HapticFeedback.selectionClick();
                      }
                      _maybeStartAutoSelectionScroll(
                        constraints.maxWidth,
                        items,
                      );
                    }
                  },
                  onPointerUp: (event) {
                    if (_isDragging) {
                      // Commit changes
                      final range = [_dragStartIndex!, _lastDragIndex!]..sort();
                      for (int i = range[0]; i <= range[1]; i++) {
                        final item = items[i];
                        final wasSelected = _selectionAtStart.contains(item);
                        if (_dragSelects != wasSelected) {
                          widget.onToggleSelection(item);
                        }
                      }
                      _stopDragging();
                    }
                  },
                  onPointerCancel: (event) {
                    if (_isDragging) _stopDragging();
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: _isDragging 
                        ? const NeverScrollableScrollPhysics() 
                        : const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final dateStr = DateFormat('MMM d, yyyy').format(item.dateTaken);

                      // Real-time selection calc
                      bool isSelected = widget.selectedItems.contains(item);
                      if (_isDragging && _dragStartIndex != null && _lastDragIndex != null) {
                        final range = [_dragStartIndex!, _lastDragIndex!]..sort();
                        if (index >= range[0] && index <= range[1]) {
                          isSelected = _dragSelects;
                        } else {
                          isSelected = _selectionAtStart.contains(item);
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          if (widget.selectedItems.isNotEmpty) {
                            widget.onToggleSelection(item);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MediaViewPage(
                                  items: items,
                                  initialIndex: index,
                                  selectedItems: widget.selectedItems,
                                  onToggleSelection: widget.onToggleSelection,
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _isDragging = true;
                            _dragStartIndex = index;
                            _lastDragIndex = index;
                            _selectionAtStart = Set.from(widget.selectedItems);
                            _dragSelects = !widget.selectedItems.contains(item);
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppConstants.accentPrimary
                                  : AppConstants.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD - (isSelected ? 2 : 1),
                            ),
                            child: Hero(
                              tag: item.filePath,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Opacity(
                                    opacity: isSelected ? 0.7 : 1.0,
                                    child: item.mediaType == 'video'
                                        ? VideoThumbnailPlayer(item: item)
                                        : Image.file(
                                            File(item.filePath),
                                            fit: BoxFit.cover,
                                            cacheWidth: 250,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: AppConstants.bgElevated,
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: AppConstants.textMuted
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          ),
                                  ),
                                  if (isSelected)
                                    Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppConstants.accentPrimary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  if (item.mediaType == 'video')
                                    const Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.7),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ============================================================
// ALBUM MODE — Grid of album folders from real file system
// ============================================================

class _AlbumModeView extends StatefulWidget {
  final DateTimeRange? filterRange;
  final int columnCount;
  final ValueChanged<int> onColumnCountChanged;
  final Set<MediaItem> selectedItems;
  final ValueChanged<MediaItem> onToggleSelection;

  const _AlbumModeView({
    super.key,
    this.filterRange,
    required this.columnCount,
    required this.onColumnCountChanged,
    required this.selectedItems,
    required this.onToggleSelection,
  });

  @override
  State<_AlbumModeView> createState() => _AlbumModeViewState();

  static void _showNewAlbumDialog(
    BuildContext context,
    MediaStorageService mediaStorage,
  ) {
    final controller = TextEditingController();
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: Text(
            'New Album',
            style: GoogleFonts.inter(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Album name',
              hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                if (!MediaStorageService.isValidAlbumName(raw)) {
                  setDialogState(
                    () => errorText =
                        'Only letters, numbers, and spaces allowed.',
                  );
                  return;
                }
                final formatted = MediaStorageService.capitalizeAlbumName(raw);
                final exists = await mediaStorage.albumExists(formatted);
                if (exists) {
                  setDialogState(
                    () => errorText = 'An album with that name already exists.',
                  );
                  return;
                }
                await mediaStorage.ensureAlbum(formatted);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showImportAction(
    BuildContext context,
    MediaStorageService ms,
  ) async {
    final albums = await ms.getAlbums();
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppConstants.bgCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Import Media into...',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (albums.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Create an album first to import.'),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: albums.length,
                      itemBuilder: (itemCtx, i) {
                        final folderName = albums[i].name;
                        return ListTile(
                          leading: const Icon(Icons.folder_rounded),
                          title: Text(folderName),
                          onTap: () async {
                            // 1. Pop the BottomSheet first
                            Navigator.pop(ctx);
                            
                            // 2. Open the Gallery Picker from the PARENT context
                            final List<AssetEntity>? assets =
                                await Navigator.push<List<AssetEntity>>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GalleryPickerScreen(
                                  targetAlbumName: folderName,
                                ),
                              ),
                            );

                            debugPrint('[CAMERA_SCREEN] Navigator.push returned with assets: ${assets?.length ?? "NULL"}');

                            // 3. Use the PARENT context for the mounted check to ensure it stays active
                            if (assets != null &&
                                assets.isNotEmpty &&
                                context.mounted) {
                              debugPrint('[CAMERA_SCREEN] Triggering importFromAssets for album: $folderName');
                              final count = await ms.importFromAssets(
                                folderName,
                                assets,
                              );
                              if (context.mounted) {
                                if (count > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Imported $count files to $folderName'),
                                      backgroundColor: AppConstants.success,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Import failed or empty. Check terminal for [IMPORT DIAGNOSIS].'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    }
  }
}

class _AlbumModeViewState extends State<_AlbumModeView> {
  int _pointerCount = 0;
  double _baseScale = 1.0;
  ScrollPhysics _gridPhysics = const BouncingScrollPhysics();

  void _updateGridPhysics() {
    setState(() {
      _gridPhysics = _pointerCount >= 2
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics();
    });
  }

  void _handleScaleUpdate(double scale) {
    // We use a ratio-based approach for more consistent detection
    const double threshold = 0.25;
    final double ratio = _baseScale / scale;

    if (ratio > 1.0 + threshold) {
      // Pinching IN
      if (widget.columnCount == 3) {
        widget.onColumnCountChanged(1);
        _baseScale = scale;
      }
    } else if (ratio < 1.0 - threshold) {
      // Pinching OUT (Zooming)
      if (widget.columnCount == 1) {
        widget.onColumnCountChanged(3);
        _baseScale = scale;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.watch<MediaStorageService>();

    return FutureBuilder<List<AlbumInfo>>(
      future: mediaStorage.getAlbums(filter: widget.filterRange),
      builder: (context, snapshot) {
        final albums = snapshot.data ?? [];

        if (albums.isEmpty) {
          return Center(
            child: Text(
              'No albums',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppConstants.textMuted,
              ),
            ),
          );
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _pointerCount++;
            _updateGridPhysics();
          },
          onPointerUp: (event) {
            _pointerCount = (_pointerCount - 1).clamp(0, 10);
            _updateGridPhysics();
          },
          onPointerCancel: (event) {
            _pointerCount = (_pointerCount - 1).clamp(0, 10);
            _updateGridPhysics();
          },
          child: GestureDetector(
            onScaleStart: (_) => _baseScale = 1.0,
            onScaleUpdate: (details) {
              if (details.pointerCount < 2) return;
              _handleScaleUpdate(details.scale);
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: GridView.builder(
                key: ValueKey('grid_${widget.columnCount}'),
                physics: _gridPhysics,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.columnCount,
                  crossAxisSpacing: widget.columnCount == 1 ? 0 : 12,
                  mainAxisSpacing: widget.columnCount == 1 ? 16 : 12,
                  childAspectRatio: widget.columnCount == 1 ? 3.5 : 0.82,
                ),
                itemCount: albums.length,
                itemBuilder: (context, i) {
                  final album = albums[i];
                  return _AlbumCard(
                    album: album,
                    filterRange: widget.filterRange,
                    isListLayout: widget.columnCount == 1,
                    selectedItems: widget.selectedItems,
                    onToggleSelection: widget.onToggleSelection,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatefulWidget {
  final AlbumInfo album;
  final DateTimeRange? filterRange;
  final bool isListLayout;
  final Set<MediaItem> selectedItems;
  final ValueChanged<MediaItem> onToggleSelection;

  const _AlbumCard({
    required this.album,
    this.filterRange,
    this.isListLayout = false,
    required this.selectedItems,
    required this.onToggleSelection,
  });

  @override
  State<_AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<_AlbumCard> {
  late Future<List<MediaItem>> _mediaFuture;
  late MediaStorageService _ms;

  @override
  void initState() {
    super.initState();
    _ms = context.read<MediaStorageService>();
    _refreshMedia();
    _ms.addListener(_refreshMedia);
  }

  @override
  void didUpdateWidget(covariant _AlbumCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterRange != widget.filterRange) {
      _refreshMedia();
    }
  }

  void _refreshMedia() {
    if (!mounted) return;
    setState(() {
      _mediaFuture = _ms.getMediaForAlbum(
        widget.album.name,
        filter: widget.filterRange,
      );
    });
  }

  @override
  void dispose() {
    _ms.removeListener(_refreshMedia);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.read<MediaStorageService>();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumDetailScreen(
            albumName: widget.album.name,
            filterRange: widget.filterRange,
            selectedItems: widget.selectedItems,
            onToggleSelection: widget.onToggleSelection,
          ),
        ),
      ),
      onLongPress: () => _showAlbumOptions(context, widget.album, mediaStorage),
      child: widget.isListLayout ? _buildListLayout() : _buildGridLayout(),
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildThumbnail(borderRadius: 24)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.album.name,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.album.itemCount} items',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppConstants.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: _buildThumbnail(borderRadius: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.album.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.album.itemCount} items',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppConstants.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppConstants.textMuted),
        ],
      ),
    );
  }

  Widget _buildThumbnail({required double borderRadius}) {
    return FutureBuilder<List<MediaItem>>(
      future: _mediaFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final firstItem = items.isNotEmpty ? items.first : null;

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppConstants.bgElevated,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: firstItem != null
                ? (firstItem.mediaType == 'video'
                      ? VideoThumbnailPlayer(item: firstItem)
                      : Image.file(
                          File(firstItem.filePath),
                          fit: BoxFit.cover,
                          cacheWidth: 250,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.image_rounded,
                            size: 32,
                            color: AppConstants.textMuted.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ))
                : Icon(
                    Icons.folder_rounded,
                    size: 32,
                    color: AppConstants.textMuted.withValues(alpha: 0.3),
                  ),
          ),
        );
      },
    );
  }

  static void _showAlbumOptions(
    BuildContext context,
    AlbumInfo album,
    MediaStorageService mediaStorage,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                album.name,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: AppConstants.accentPrimary,
              ),
              title: Text(
                'Rename',
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameAlbumDialog(context, album, mediaStorage);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteAlbumConfirm(context, album, mediaStorage);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static void _showDeleteAlbumConfirm(
    BuildContext context,
    AlbumInfo album,
    MediaStorageService mediaStorage,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete Album?',
          style: GoogleFonts.inter(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${album.name}" and all ${album.itemCount} items inside it? This cannot be undone.',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await mediaStorage.deleteAlbum(album.name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void _showRenameAlbumDialog(
    BuildContext context,
    AlbumInfo album,
    MediaStorageService mediaStorage,
  ) {
    final controller = TextEditingController(text: album.name);
    String? errorText;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: Text(
            'Rename Album',
            style: GoogleFonts.inter(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.inter(color: AppConstants.textPrimary),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'New name',
              hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                if (!MediaStorageService.isValidAlbumName(raw)) {
                  setDialogState(
                    () => errorText =
                        'Only letters, numbers, and spaces allowed.',
                  );
                  return;
                }
                final formatted = MediaStorageService.capitalizeAlbumName(raw);
                if (MediaStorageService.namesMatch(formatted, album.name)) {
                  // Same name effectively, just update casing
                  await mediaStorage.renameAlbum(album.name, formatted);
                  if (ctx.mounted) Navigator.pop(ctx);
                  return;
                }
                final exists = await mediaStorage.albumExists(formatted);
                if (exists) {
                  // Close rename dialog, ask to merge
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    _showMergeAlbumDialog(
                      context,
                      album.name,
                      formatted,
                      mediaStorage,
                    );
                  }
                  return;
                }
                await mediaStorage.renameAlbum(album.name, formatted);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Rename'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showMergeAlbumDialog(
    BuildContext context,
    String source,
    String target,
    MediaStorageService mediaStorage,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Album Exists',
          style: GoogleFonts.inter(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '"$target" already exists. Would you like to merge "$source" into "$target"?',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await mediaStorage.mergeAlbums(source, target);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }
}

void _showMediaOptions(BuildContext context, MediaItem item) {
  final mediaStorage = context.read<MediaStorageService>();
  final label = item.mediaType == 'video' ? 'Video' : 'Photo';
  showModalBottomSheet(
    context: context,
    backgroundColor: AppConstants.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              item.fileName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.ios_share_rounded,
              color: AppConstants.accentPrimary,
            ),
            title: Text(
              'Export to Gallery',
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
            ),
            onTap: () async {
              Navigator.pop(ctx);
              final success = await mediaStorage.exportMedia(item);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Exported to Public Gallery' : 'Export failed',
                    ),
                    backgroundColor: success
                        ? AppConstants.success
                        : AppConstants.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.drive_file_move_rounded,
              color: AppConstants.accentPrimary,
            ),
            title: Text(
              'Move to Album',
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
            ),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _MoveToAlbumScreen(item: item),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: Text(
              'Delete $label',
              style: GoogleFonts.inter(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  backgroundColor: AppConstants.bgCard,
                  title: Text(
                    'Delete $label?',
                    style: GoogleFonts.inter(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    'Delete "${item.fileName}"? This cannot be undone.',
                    style: GoogleFonts.inter(color: AppConstants.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dCtx),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () async {
                        await mediaStorage.deleteMedia(item.filePath);
                        if (dCtx.mounted) Navigator.pop(dCtx);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ============================================================
// Move To Album Screen
// ============================================================

class _MoveToAlbumScreen extends StatelessWidget {
  final MediaItem item;
  const _MoveToAlbumScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.watch<MediaStorageService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Move to Album',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: FutureBuilder<List<AlbumInfo>>(
        future: mediaStorage.getAlbums(),
        builder: (context, snapshot) {
          final albums = snapshot.data ?? [];
          // Filter out the current album
          final targets = albums
              .where((a) => a.name != item.albumName)
              .toList();

          if (targets.isEmpty) {
            return Center(
              child: Text(
                'No other albums to move to.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppConstants.textMuted,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: targets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final album = targets[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppConstants.bgCard,
                leading: Icon(
                  Icons.folder_rounded,
                  color: AppConstants.accentPrimary,
                ),
                title: Text(
                  album.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${album.itemCount} items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppConstants.textMuted,
                ),
                onTap: () async {
                  await mediaStorage.moveMedia(item.filePath, album.name);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Moved to ${album.name}',
                          style: GoogleFonts.inter(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppConstants.bgElevated,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
