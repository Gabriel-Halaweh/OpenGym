import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../models/media_item.dart';
import '../utils/constants.dart';
import '../widgets/video_thumbnail_player.dart';
import '../widgets/video_view_item.dart';
import '../widgets/image_view_item.dart';
import 'camera_mockups.dart';
import '../services/media_storage_service.dart';
import 'package:provider/provider.dart';

class MediaViewPage extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;
  final Set<MediaItem>? selectedItems;
  final ValueChanged<MediaItem>? onToggleSelection;

  const MediaViewPage({
    super.key,
    required this.items,
    required this.initialIndex,
    this.selectedItems,
    this.onToggleSelection,
  });

  @override
  State<MediaViewPage> createState() => _MediaViewPageState();
}

class _MediaViewPageState extends State<MediaViewPage> {
  late PageController _pageController;
  late ScrollController _thumbnailController;
  late int _currentIndex;
  int _currentRotation = 0; // Steps of 90 degrees
  bool _uiVisible = true;
  bool _isLooping = false;
  double _currentScale = 1.0;
  int _pointerCount = 0;
  double? _startPointerY;
  bool _isDismissing = false;
  Timer? _hideTimer;

  // Drag Selection State
  int? _dragStartIndex;
  int? _lastDragIndex;
  bool _isDragging = false;
  bool _dragSelects = true;
  Set<MediaItem> _selectionAtStart = {};
  Timer? _autoScrollTimer;
  double _lastPointerX = 0;

  late Set<MediaItem> _internalSelectedItems;
  Set<MediaItem> get _selectedItems =>
      widget.selectedItems ?? _internalSelectedItems;
  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  void _onToggleSelection(MediaItem item) {
    if (widget.onToggleSelection != null) {
      widget.onToggleSelection!(item);
      setState(() {});
    } else {
      setState(() {
        if (_internalSelectedItems.contains(item)) {
          _internalSelectedItems.remove(item);
        } else {
          _internalSelectedItems.add(item);
        }
      });
    }
    if (_isSelectionMode) {
      _resetHideTimer(); // Keep UI visible in selection mode
    }
  }

  void _updateRangeSelection(int start, int end) {
    setState(() {
      _lastDragIndex = end;
    });
  }

  int? _calculateIndexAtPos(Offset localPos) {
    const double itemWidth = 60.0;
    const double spacing = 6.0;
    final double x = localPos.dx + _thumbnailController.offset - 16; // minus padding
    if (x < 0) return null;
    final int index = (x / (itemWidth + spacing)).floor();
    if (index >= 0 && index < widget.items.length) {
      // Double check if it's actually within an item vs in spacing
      final double itemStart = index * (itemWidth + spacing);
      if (x >= itemStart && x <= itemStart + itemWidth) {
        return index;
      }
    }
    return null;
  }

  void _maybeStartAutoSelectionScroll(double maxWidth) {
    const double edgeThreshold = 100.0;
    const double scrollSpeed = 5.0;

    _autoScrollTimer?.cancel();

    if (_lastPointerX < edgeThreshold) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_thumbnailController.offset > 0) {
          _thumbnailController.jumpTo((_thumbnailController.offset - scrollSpeed).clamp(0, _thumbnailController.position.maxScrollExtent));
          final index = _calculateIndexAtPos(Offset(_lastPointerX, 0));
          if (index != null && index != _lastDragIndex) {
            _lastDragIndex = index;
            _updateRangeSelection(_dragStartIndex!, index);
            HapticFeedback.selectionClick();
          }
        }
      });
    } else if (_lastPointerX > maxWidth - edgeThreshold) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_thumbnailController.offset < _thumbnailController.position.maxScrollExtent) {
          _thumbnailController.jumpTo((_thumbnailController.offset + scrollSpeed).clamp(0, _thumbnailController.position.maxScrollExtent));
          final index = _calculateIndexAtPos(Offset(_lastPointerX, 0));
          if (index != null && index != _lastDragIndex) {
            _lastDragIndex = index;
            _updateRangeSelection(_dragStartIndex!, index);
            HapticFeedback.selectionClick();
          }
        }
      });
    }
  }

  void _stopDragging() {
    // Commit range selection
    if (_dragStartIndex != null && _lastDragIndex != null) {
      final start = _dragStartIndex!;
      final end = _lastDragIndex!;
      final range = [start, end]..sort();

      for (int i = range[0]; i <= range[1]; i++) {
        final item = widget.items[i];
        final wasSelected = _selectionAtStart.contains(item);
        if (_dragSelects != wasSelected) {
          _onToggleSelection(item);
        }
      }
    }

    setState(() {
      _isDragging = false;
      _dragStartIndex = null;
      _lastDragIndex = null;
      _autoScrollTimer?.cancel();
    });
  }

  void _clearSelection() {
    if (widget.onToggleSelection != null && widget.selectedItems != null) {
      final toRemove = List<MediaItem>.from(widget.selectedItems!);
      for (final item in toRemove) {
        widget.onToggleSelection!(item);
      }
      setState(() {});
    } else {
      setState(() {
        _internalSelectedItems.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _internalSelectedItems = {};
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _thumbnailController = ScrollController();
    
    // Scroll thumbnails to initial index after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToThumbnail(_currentIndex, animate: false);
        _startHideTimer();
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _uiVisible = false);
      }
    });
  }

  void _resetHideTimer() {
    setState(() => _uiVisible = true);
    _startHideTimer();
  }

  void _toggleUI() {
    setState(() {
      _uiVisible = !_uiVisible;
      if (_uiVisible) {
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
      }
    });
  }

  void _scrollToThumbnail(int index, {bool animate = true}) {
    if (!_thumbnailController.hasClients) return;
    
    const double itemWidth = 60.0;
    const double spacing = 8.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    final double offset = (index * (itemWidth + spacing)) - (screenWidth / 2) + (itemWidth / 2);
    
    if (animate) {
      _thumbnailController.animateTo(
        offset.clamp(0, _thumbnailController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _thumbnailController.jumpTo(
        offset.clamp(0, _thumbnailController.position.maxScrollExtent),
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _currentScale = 1.0;
    });
    _scrollToThumbnail(index);
  }

  void _rotateCurrent() {
    setState(() {
      // Sequence: 0 -> 1 (90) -> 3 (270) -> 0
      // Skip 2 (180 degrees upside down)
      if (_currentRotation == 0) {
        _currentRotation = 1;
      } else if (_currentRotation == 1) {
        _currentRotation = 3;
      } else {
        _currentRotation = 0;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbnailController.dispose();
    _hideTimer?.cancel();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          Listener(
            onPointerDown: (event) {
              _pointerCount++;
              _startPointerY = event.localPosition.dy;
              _isDismissing = false;
              
              if (_pointerCount >= 2) {
                // Instantly stop PageView from moving to prioritize pinch
                if (_pageController.hasClients) {
                  _pageController.position.hold(() {});
                }
              }
              setState(() {});
            },
            onPointerMove: (event) {
              if (_pointerCount == 1 && _currentScale <= 1.0 && _startPointerY != null && !_isDismissing) {
                final deltaY = event.localPosition.dy - _startPointerY!;
                final h = MediaQuery.of(context).size.height;
                final isEdge = _startPointerY! < 120 || _startPointerY! > h - 120;
                
                if (isEdge && deltaY > 100) {
                  _isDismissing = true;
                  Navigator.pop(context);
                }
              }
            },
            onPointerUp: (event) {
              _pointerCount = (_pointerCount - 1).clamp(0, 10);
              if (_pointerCount == 0) _startPointerY = null;
              setState(() {});
            },
            onPointerCancel: (event) {
              _pointerCount = (_pointerCount - 1).clamp(0, 10);
              if (_pointerCount == 0) _startPointerY = null;
              setState(() {});
            },
            child: PageView.builder(
                controller: _pageController,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  _onPageChanged(index);
                  _resetHideTimer();
                },
                physics: (_currentScale > 1.0 || _pointerCount >= 2) 
                    ? const NeverScrollableScrollPhysics() 
                    : const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final rotation = _currentRotation;
                
                return Hero(
                  tag: item.filePath,
                  child: item.mediaType == 'video'
                      ? VideoViewItem(
                          key: ValueKey('video_${item.filePath}_${index == _currentIndex}'),
                          filePath: item.filePath,
                          autoPlay: index == _currentIndex,
                          visible: _uiVisible,
                          rotation: rotation,
                          looping: _isLooping,
                          onInteraction: _resetHideTimer,
                          onToggleUI: _toggleUI,
                          onScaleChanged: (scale) {
                            if (mounted && _currentIndex == index) {
                              if (_currentScale != scale) {
                                setState(() => _currentScale = scale);
                              }
                            }
                          },
                          onComplete: () {},
                        )
                      : ImageViewItem(
                          key: ValueKey('image_${item.filePath}_${index == _currentIndex}'),
                          filePath: item.filePath,
                          rotation: rotation,
                          onToggleUI: _toggleUI,
                          onScaleChanged: (scale) {
                            if (mounted && _currentIndex == index) {
                              if (_currentScale != scale) {
                                setState(() => _currentScale = scale);
                              }
                            }
                          },
                        ),
                );
              },
            ),
          ),
        
        // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_uiVisible || _isSelectionMode) ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_uiVisible || _isSelectionMode),
                child: _isSelectionMode
                    ? AppBar(
                        backgroundColor: AppConstants.accentPrimary
                            .withValues(alpha: 0.9),
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: _clearSelection,
                        ),
                        title: Text(
                          '${_selectedItems.length} selected',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.ios_share_rounded,
                                color: Colors.white),
                            onPressed: _bulkExport,
                            tooltip: 'Export',
                          ),
                          IconButton(
                            icon: const Icon(Icons.drive_file_move_rounded,
                                color: Colors.white),
                            onPressed: _bulkMove,
                            tooltip: 'Move',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded,
                                color: Colors.white),
                            onPressed: _bulkDelete,
                            tooltip: 'Delete',
                          ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : AppBar(
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: Text(
                          widget.items[_currentIndex].fileName,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        actions: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _isLooping
                                  ? AppConstants.accentPrimary
                                      .withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.repeat_rounded,
                                color: _isLooping
                                    ? AppConstants.accentPrimary
                                    : Colors.white,
                              ),
                              onPressed: () {
                                _resetHideTimer();
                                setState(() => _isLooping = !_isLooping);
                              },
                              tooltip: 'Toggle Loop',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.ios_share_rounded,
                                color: Colors.white),
                            onPressed: () async {
                              final ms = context.read<MediaStorageService>();
                              _resetHideTimer();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Exporting to gallery...'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              await ms.exportToGallery([widget.items[_currentIndex]]);
                            },
                            tooltip: 'Export to gallery',
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_right_rounded,
                                color: Colors.white),
                            onPressed: () {
                              _resetHideTimer();
                              _rotateCurrent();
                            },
                            tooltip: 'Rotate',
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
              ),
            ),
          ),
          
          // Bottom Carousel Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: (_uiVisible || _isSelectionMode) ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: !(_uiVisible || _isSelectionMode),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 10), // Use padding to avoid overflow
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08), // 8% opacity glassy bar
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5)),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                             SizedBox(
                               height: 60, // Square thumbnails: 60x60
                               child: LayoutBuilder(
                                 builder: (context, constraints) => Listener(
                                   behavior: HitTestBehavior.translucent,
                                   onPointerDown: (event) {
                                     _pointerCount++;
                                   },
                                   onPointerMove: (event) {
                                     if (_isDragging) {
                                       _lastPointerX = event.localPosition.dx;
                                       final index = _calculateIndexAtPos(event.localPosition);
                                       if (index != null && index != _lastDragIndex) {
                                         _lastDragIndex = index;
                                         _updateRangeSelection(_dragStartIndex!, index);
                                         HapticFeedback.selectionClick();
                                       }
                                       _maybeStartAutoSelectionScroll(constraints.maxWidth);
                                     }
                                   },
                                   onPointerUp: (event) {
                                     _pointerCount = (_pointerCount - 1).clamp(0, 10);
                                     if (_isDragging) _stopDragging();
                                   },
                                   onPointerCancel: (event) {
                                     _pointerCount = (_pointerCount - 1).clamp(0, 10);
                                     if (_isDragging) _stopDragging();
                                   },
                                   child: ListView.separated(
                                     controller: _thumbnailController,
                                     scrollDirection: Axis.horizontal,
                                     padding: const EdgeInsets.symmetric(horizontal: 16),
                                     itemCount: widget.items.length,
                                     separatorBuilder: (context, index) =>
                                         const SizedBox(width: 6),
                                     itemBuilder: (context, index) {
                                       final item = widget.items[index];
                                       final isCurrent = index == _currentIndex;

                                       // Real-time selection calculation
                                       bool isSelected = _selectedItems.contains(item);
                                       if (_isDragging &&
                                           _dragStartIndex != null &&
                                           _lastDragIndex != null) {
                                         final range = [_dragStartIndex!, _lastDragIndex!]
                                           ..sort();
                                         if (index >= range[0] && index <= range[1]) {
                                           isSelected = _dragSelects;
                                         } else {
                                           isSelected = _selectionAtStart.contains(item);
                                         }
                                       }

                                       return GestureDetector(
                                         onTap: () {
                                           if (_isSelectionMode) {
                                             _onToggleSelection(item);
                                           } else {
                                             _resetHideTimer();
                                             _pageController.animateToPage(
                                               index,
                                               duration: const Duration(
                                                   milliseconds: 300),
                                               curve: Curves.easeInOut,
                                             );
                                           }
                                         },
                                         onLongPress: () {
                                           HapticFeedback.mediumImpact();
                                           setState(() {
                                             _isDragging = true;
                                             _dragStartIndex = index;
                                             _lastDragIndex = index;
                                             _selectionAtStart = Set.from(_selectedItems);
                                             _dragSelects = !_selectionAtStart.contains(item);
                                           });
                                         },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 60, // Make it square
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppConstants.accentPrimary
                                                    : (isCurrent
                                                        ? Colors.white
                                                        : Colors.transparent),
                                                width: isSelected || isCurrent ? 2.0 : 0,
                                              ),
                                            ),
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(2),
                                                  child: Opacity(
                                                    opacity: isSelected ? 0.6 : 1.0,
                                                    child: RotatedBox(
                                                      quarterTurns: _currentRotation,
                                                      child: item.mediaType == 'video'
                                                          ? VideoThumbnailPlayer(item: item)
                                                          : Image.file(
                                                              File(item.filePath),
                                                              fit: BoxFit.cover,
                                                              cacheWidth: 150, // Very small for carousel
                                                              errorBuilder: (context, error, stackTrace) =>
                                                                  Container(
                                                                color: Colors.white12,
                                                                child: const Icon(
                                                                  Icons.image_not_supported_rounded,
                                                                  color: Colors.white24,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Center(
                                                    child: Icon(
                                                      Icons.check_circle_rounded,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDelete() async {
    // We need to access MediaStorageService from context
    // Scaffold context is usually fine
    final ms = context.read<MediaStorageService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Delete ${_selectedItems.length} items?',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
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
      if (mounted) {
         // If current item was deleted, we might need to pop or refresh
         // But deleteMediaList handles reindexing, so maybe it's fine.
         // Let's just pop back to grid since the gallery view is now invalid.
         Navigator.pop(context);
      }
    }
  }

  Future<void> _bulkMove() async {
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
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _bulkExport() async {
    final ms = context.read<MediaStorageService>();
    final itemsToExport = _selectedItems.toList();
    
    _clearSelection();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting ${itemsToExport.length} items to gallery...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    final count = await ms.exportToGallery(itemsToExport);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully exported $count items.'),
          backgroundColor: AppConstants.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
