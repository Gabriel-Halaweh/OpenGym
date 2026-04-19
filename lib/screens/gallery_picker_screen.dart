import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../utils/constants.dart';

class GalleryPickerScreen extends StatefulWidget {
  final String targetAlbumName;

  const GalleryPickerScreen({
    super.key,
    required this.targetAlbumName,
  });

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  AssetPathEntity? _selectedPath;
  List<AssetPathEntity> _paths = [];
  List<AssetEntity> _assets = [];
  Set<AssetEntity> _selectedAssets = {};
  bool _loading = true;
  PermissionState _ps = PermissionState.notDetermined;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // Check current state before calling requestPermissionExtend() which might trigger the systemic selector 
    final ps = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(),
    );
    if (!mounted) return;

    if (ps.isAuth || ps.hasAccess) {
      setState(() {
        _ps = ps;
        _loading = true; // Still show loading while fetching albums
      });
      _fetchPaths();
    } else {
      // If we don't have access, we request extension/authorization
      final newPs = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(),
      );
      if (!mounted) return;
      
      setState(() {
        _ps = newPs;
        if (newPs.isAuth || newPs.hasAccess) {
          _fetchPaths();
        } else {
          _loading = false;
        }
      });
    }
  }

  bool _isAscending = false; // Descending = Newest first
  int _columnCount = 3;
  double _baseScale = 1.0;
  final ScrollController _scrollController = ScrollController();

  // Drag select state
  int? _dragStartIndex;
  int? _lastDragIndex;
  bool _isDragging = false;
  Set<AssetEntity> _selectionAtStart = {};
  Timer? _autoScrollTimer;
  double _lastPointerY = 0;

  final int _pageSize = 60;
  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPaths() async {
    // Customize sorting for the entire library
    final filter = FilterOptionGroup()
      ..orders.add(OrderOption(
        type: OrderOptionType.updateDate, // Default sort by update date
        asc: _isAscending,
      ));

    // We only want images and videos
    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filter,
    );

    if (!mounted) return;
    setState(() {
      _paths = paths;
      _loading = false;
    });
  }

  void _toggleSort(bool ascending) async {
    if (_isAscending == ascending) return;
    setState(() {
      _isAscending = ascending;
      _loading = true;
    });
    
    final filter = FilterOptionGroup()
      ..orders.add(OrderOption(
        type: OrderOptionType.updateDate, 
        asc: _isAscending,
      ));

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: filter,
    );

    if (!mounted) return;
    
    AssetPathEntity? newSelectedPath;
    if (_selectedPath != null) {
      // Find the new version of the selected path to apply the new filter
      try {
        newSelectedPath = paths.firstWhere((p) => p.id == _selectedPath!.id);
      } catch (_) {
        newSelectedPath = paths.firstOrNull;
      }
    }

    setState(() {
      _paths = paths;
      _loading = false;
      if (newSelectedPath != null) {
        _selectedPath = newSelectedPath;
        _fetchAssets(newSelectedPath, clear: true);
      }
    });
  }

  Future<void> _fetchAssets(AssetPathEntity path, {bool clear = true}) async {
    if (clear) {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _assets = [];
        _page = 0;
        _hasMore = true;
        _selectedPath = path;
      });
    } else {
      _loadingMore = true;
    }

    final assets = await path.getAssetListPaged(page: _page, size: _pageSize);
    if (!mounted) return;

    setState(() {
      if (clear) {
        _assets = assets;
      } else {
        _assets.addAll(assets);
      }
      _hasMore = assets.length == _pageSize;
      _loading = false;
      _loadingMore = false;
      _page++;
    });
  }

  void _onAssetTap(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  // --- Pinch-to-zoom logic ---

  void _handleScaleUpdate(double scale) {
    const double threshold = 0.25;
    final double ratio = _baseScale / scale;

    if (ratio > 1.0 + threshold) {
      // Zoom out (More columns)
      if (_columnCount < 5) {
        setState(() => _columnCount = (_columnCount == 1) ? 3 : 5);
        _baseScale = scale;
      }
    } else if (ratio < 1.0 - threshold) {
      // Zoom in (Fewer columns)
      if (_columnCount > 1) {
        setState(() => _columnCount = (_columnCount == 5) ? 3 : 1);
        _baseScale = scale;
      }
    }
  }

  // --- Drag-to-select logic ---

  int? _calculateIndexAtPos(Offset localPos) {
    if (_assets.isEmpty) return null;
    final double scrollOffset = _scrollController.offset;
    final double rowHeight = (MediaQuery.of(context).size.width / _columnCount);
    final double itemHeight = rowHeight; // Assuming square items
    final double itemWidth = rowHeight;

    // Adjust for padding and spacing
    final double effectivePosY = localPos.dy + scrollOffset - 4.0; // Grid padding
    final double effectivePosX = localPos.dx - 4.0; // Grid padding

    if (effectivePosY < 0 || effectivePosX < 0) return null;

    final int row = (effectivePosY / (itemHeight + 4)).floor(); // itemHeight + mainAxisSpacing
    final int col = (effectivePosX / (itemWidth + 4)).floor(); // itemWidth + crossAxisSpacing
    
    final int index = (row * _columnCount) + col;
    if (index < 0) return 0;
    if (index >= _assets.length) return _assets.length - 1;
    return index;
  }

  void _updateRangeSelection(int start, int end) {
    final s = start < end ? start : end;
    final e = start < end ? end : start;
    
    final newSelection = Set<AssetEntity>.from(_selectionAtStart);
    for (int i = s; i <= e; i++) {
      if (i < _assets.length) { // Ensure index is within bounds
        newSelection.add(_assets[i]);
      }
    }
    
    setState(() {
      _selectedAssets = newSelection;
      _lastDragIndex = end;
    });
  }

  void _maybeStartAutoSelectionScroll(double viewportHeight) {
    _autoScrollTimer?.cancel();
    if (!_isDragging) return;

    const double edgeSize = 80.0;
    double scrollAmount = 0;

    if (_lastPointerY < edgeSize) {
      scrollAmount = -((edgeSize - _lastPointerY) / 1.0).clamp(2.0, 15.0);
    } else if (_lastPointerY > viewportHeight - edgeSize) {
      scrollAmount = ((_lastPointerY - (viewportHeight - edgeSize)) / 1.0).clamp(2.0, 15.0);
    }

    if (scrollAmount != 0) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_isDragging) {
          timer.cancel();
          return;
        }
        final double newOffset = (_scrollController.offset + scrollAmount).clamp(
          0.0, _scrollController.position.maxScrollExtent,
        );
        if (newOffset != _scrollController.offset) {
          _scrollController.jumpTo(newOffset);
          // Recalculate index based on new scroll position
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final Offset localPosition = renderBox.globalToLocal(Offset(MediaQuery.of(context).size.width / 2, _lastPointerY));
          final index = _calculateIndexAtPos(localPosition);
          if (index != null && index != _lastDragIndex) {
            _updateRangeSelection(_dragStartIndex!, index);
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
    setState(() {});
  }

  Future<void> _onImport() async {
    if (_selectedAssets.isEmpty) return;
    Navigator.pop(context, _selectedAssets.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      appBar: AppBar(
        backgroundColor: AppConstants.bgDark,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _selectedPath == null ? 'Device Gallery' : _selectedPath!.name,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        leading: IconButton(
          icon: Icon(
            _selectedPath == null
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
          ),
          onPressed: () {
            if (_selectedPath != null) {
              setState(() {
                _selectedPath = null;
                _assets = [];
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          // Button to expand the limited gallery selection
          if (_ps == PermissionState.limited || _ps == PermissionState.authorized)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              tooltip: 'Expand Gallery Access',
              onPressed: () async {
                await PhotoManager.presentLimited();
                // Re-fetch current state to refresh items
                _fetchPaths(); // Refresh album list in case of new albums
                if (_selectedPath != null) {
                  _fetchAssets(_selectedPath!, clear: true);
                }
              },
              color: AppConstants.accentGold,
            ),
          if (_selectedAssets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _onImport,
                child: Text(
                  'Import (${_selectedAssets.length})',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: AppConstants.accentPrimary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Sort Toggle Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  _sortTab('Newest', !_isAscending, () => _toggleSort(false)),
                  _sortTab('Oldest', _isAscending, () => _toggleSort(true)),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _sortTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppConstants.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD - 2),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppConstants.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_ps.isAuth && !_ps.hasAccess) { // Simplified condition
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 48, color: AppConstants.textMuted), // Changed size and color
            const SizedBox(height: 8), // Changed height
            Text(
              'Please enable gallery access in settings.',
              style: GoogleFonts.inter(color: AppConstants.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: PhotoManager.openSetting,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    }

    if (_selectedPath == null) {
      return _buildAlbumGrid();
    } else {
      return GestureDetector(
        onScaleStart: (_) => _baseScale = 1.0,
        onScaleUpdate: (details) {
          if (details.pointerCount < 2) return;
          _handleScaleUpdate(details.scale);
        },
        child: _buildAssetGrid(),
      );
    }
  }

  Widget _buildAlbumGrid() {
    if (_paths.isEmpty) {
      return const Center(child: Text('No galleries found.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _paths.length,
      itemBuilder: (context, index) {
        final path = _paths[index];
        return GestureDetector(
          onTap: () => _fetchAssets(path),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FutureBuilder<List<AssetEntity>>(
                  future: path.getAssetListRange(start: 0, end: 1),
                  builder: (context, snapshot) {
                    final asset = snapshot.data?.firstOrNull;
                    return Container(
                      decoration: BoxDecoration(
                        color: AppConstants.bgCard,
                        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                        border: Border.all(color: AppConstants.border),
                      ),
                      padding: const EdgeInsets.all(8), // Padding for thin images
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLG - 1),
                        child: asset != null
                            ? AssetEntityImage(
                                asset,
                                isOriginal: false,
                                thumbnailSize: const ThumbnailSize.square(300),
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                Icons.photo_library_outlined,
                                color: AppConstants.textMuted.withOpacity(0.3), // Changed withValues to withOpacity
                                size: 40,
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                path.name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              FutureBuilder<int>(
                future: path.assetCountAsync,
                builder: (context, snapshot) {
                  return Text(
                    '${snapshot.data ?? 0} items',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssetGrid() {
    if (_assets.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return const Center(child: Text('This gallery is empty.'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (_hasMore && !_loadingMore && scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
          _fetchAssets(_selectedPath!, clear: false);
        }
        return false;
      },
      child: GestureDetector(
        onLongPressStart: (details) {
          final index = _calculateIndexAtPos(details.localPosition);
          if (index != null) {
            HapticFeedback.heavyImpact();
            _isDragging = true;
            _dragStartIndex = index;
            _selectionAtStart = Set.from(_selectedAssets);
            _updateRangeSelection(index, index);
          }
        },
        onLongPressMoveUpdate: (details) {
          _lastPointerY = details.localPosition.dy;
          final index = _calculateIndexAtPos(details.localPosition);
          if (index != null && index != _lastDragIndex) {
            _updateRangeSelection(_dragStartIndex!, index);
          }
          _maybeStartAutoSelectionScroll(MediaQuery.of(context).size.height);
        },
        onLongPressEnd: (_) => _stopDragging(),
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: _assets.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _assets.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final asset = _assets[index];
            final isSelected = _selectedAssets.contains(asset);

            return GestureDetector(
              onTap: () => _onAssetTap(asset),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.bgCard,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AssetEntityImage(
                        asset,
                        isOriginal: false,
                        thumbnailSize: const ThumbnailSize.square(300), // Changed to 300
                        fit: BoxFit.cover,
                      ),
                      if (asset.type == AssetType.video)
                        const Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      if (isSelected)
                        Container(
                          color: AppConstants.accentPrimary.withOpacity(0.4), // Changed withValues to withOpacity
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppConstants.accentPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16, // Changed to 16
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
