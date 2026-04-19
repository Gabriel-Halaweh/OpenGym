import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImageViewItem extends StatefulWidget {
  final String filePath;
  final int rotation;
  final VoidCallback? onToggleUI;
  final Function(double)? onScaleChanged;

  const ImageViewItem({
    super.key,
    required this.filePath,
    this.rotation = 0,
    this.onToggleUI,
    this.onScaleChanged,
  });

  @override
  State<ImageViewItem> createState() => _ImageViewItemState();
}

class _ImageViewItemState extends State<ImageViewItem> {
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (widget.onScaleChanged != null) {
      widget.onScaleChanged!(scale);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 1.0,
      maxScale: 10.0,
      clipBehavior: Clip.none,
      child: GestureDetector(
        onTap: widget.onToggleUI,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: RotatedBox(
            quarterTurns: widget.rotation,
            child: Image.file(
              File(widget.filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_rounded, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text('Failed to load image', style: GoogleFonts.inter(color: Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
