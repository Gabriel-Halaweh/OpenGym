import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class VideoViewItem extends StatefulWidget {
  final String filePath;
  final bool autoPlay;
  final bool visible;
  final int rotation;
  final VoidCallback? onInteraction;
  final VoidCallback? onToggleUI;
  final bool looping;
  final VoidCallback? onComplete;
  final Function(double)? onScaleChanged;

  const VideoViewItem({
    super.key,
    required this.filePath,
    this.visible = true,
    this.rotation = 0,
    this.onInteraction,
    this.onToggleUI,
    this.autoPlay = true,
    this.looping = false,
    this.onComplete,
    this.onScaleChanged,
  });

  @override
  State<VideoViewItem> createState() => _VideoViewItemState();
}

class _VideoViewItemState extends State<VideoViewItem> {
  late VideoPlayerController _controller;
  late TransformationController _transformationController;
  bool _wasPlayingBeforeScrub = false;
  double? _scrubbingValue;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (mounted) {
          _controller.setLooping(widget.looping);
          setState(() {});
          if (widget.autoPlay) {
            _controller.play();
          }
        }
      });
    
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _controller.addListener(_videoListener);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (widget.onScaleChanged != null) {
      widget.onScaleChanged!(scale);
    }
  }

  void _videoListener() {
    if (!mounted) return;
    
    if (_controller.value.position >= _controller.value.duration &&
        _controller.value.isPlaying && !widget.looping) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
      _controller.pause();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(VideoViewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.looping != widget.looping) {
      _controller.setLooping(widget.looping);
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final double safeBottom = MediaQuery.of(context).padding.bottom;
    // Base distance to clear the carousel: 10 (pad) + 12 (gap) + 60 (thumb) + 12 (gap) + 16 (extra gap) = 110
    final double controlBottomPosition = safeBottom + 110;

    return GestureDetector(
      onTap: () {
        if (widget.onToggleUI != null) widget.onToggleUI!();
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Player - rotated
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 10.0,
              clipBehavior: Clip.none,
              onInteractionStart: (_) {
                if (widget.onInteraction != null) widget.onInteraction!();
              },
              child: RotatedBox(
                quarterTurns: widget.rotation,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. Controls - NOT rotated
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: widget.visible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !widget.visible,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fade backdrop
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(color: Colors.black.withValues(alpha: 0.2)),
                    ),
                  ),
                  
                  // Play/Pause button in center
                  Center(
                    child: RotatedBox(
                      quarterTurns: widget.rotation,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onInteraction != null) widget.onInteraction!();
                          setState(() {
                            _controller.value.isPlaying ? _controller.pause() : _controller.play();
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          padding: const EdgeInsets.all(16),
                          child: Icon(
                            _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Controls Section - rotates with video
                  Positioned(
                    bottom: controlBottomPosition, // Clear the carousel
                    top: (widget.rotation != 0) ? 100 : null, // Lowered from 40 for better reach
                    left: (widget.rotation == 1) ? 10 : ((widget.rotation == 0) ? 20 : null), // User: 90 -> Left
                    right: (widget.rotation == 3) ? 10 : ((widget.rotation == 0) ? 20 : null), // User: 270 -> Right
                    width: (widget.rotation != 0) ? 80 : null, // Sufficient width for the vertical bar
                    child: RotatedBox(
                      quarterTurns: widget.rotation,
                      child: GestureDetector(
                        onTap: () {}, // Consume taps
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the bar in the vertical space
                          mainAxisSize: (widget.rotation != 0) ? MainAxisSize.max : MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 60,
                              child: Row(
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                        activeTrackColor: AppConstants.accentPrimary,
                                        inactiveTrackColor: Colors.white12,
                                        thumbColor: Colors.white,
                                      ),
                                      child: Slider(
                                        value: _scrubbingValue ?? _controller.value.position.inMilliseconds.toDouble(),
                                        min: 0.0,
                                        max: _controller.value.duration.inMilliseconds.toDouble(),
                                        onChangeStart: (value) {
                                          if (widget.onInteraction != null) widget.onInteraction!();
                                          _wasPlayingBeforeScrub = _controller.value.isPlaying;
                                          _controller.pause();
                                          setState(() {
                                            _scrubbingValue = value;
                                          });
                                        },
                                        onChanged: (value) {
                                          setState(() {
                                            _scrubbingValue = value;
                                          });
                                          // High-precision seeking
                                          _controller.seekTo(Duration(milliseconds: value.toInt()));
                                        },
                                        onChangeEnd: (_) {
                                          setState(() {
                                            _scrubbingValue = null;
                                          });
                                          if (_wasPlayingBeforeScrub) {
                                            _controller.play();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
