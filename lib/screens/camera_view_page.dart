import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
// Note: We are phasing out the pure-Dart 'image' package for performance.
// import 'package:image/image.dart' as img;
import '../utils/constants.dart';
import '../services/media_storage_service.dart';
import '../utils/helpers.dart';
import '../widgets/video_thumbnail_player.dart';
import 'dart:ui' as ui;
import 'package:image_editor/image_editor.dart';
import 'media_view_page.dart';
import '../models/media_item.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:native_device_orientation/native_device_orientation.dart';

class CameraViewPage extends StatefulWidget {
  final String? initialAlbum;
  const CameraViewPage({super.key, this.initialAlbum});

  @override
  State<CameraViewPage> createState() => _CameraViewPageState();
}

class _CameraViewPageState extends State<CameraViewPage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _selectedCameraIndex = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // States
  String _activeMode = 'PHOTO'; // 'PHOTO' or 'VIDEO'
  bool _isRecording = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  FlashMode _flashMode = FlashMode.off;
  int _timerSeconds = 0; // 0, 2, 5, 10
  String _aspectRatioMode = '3:4'; // '3:4', '9:16', '1:1'
  late String _targetAlbum;
  bool _showTimerOptions = false;
  bool _showZoomOptions = false;
  double _baseZoom = 1.0;

  // Capture states
  Timer? _countdownTimer;
  int _countdownRemaining = 0;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _isSaving = false;
  Offset? _focusPoint;
  bool _isFocusLocked = false;
  Timer? _focusTimer;

  // Pose Detection State
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );
  bool _isPoseEnabled = false;
  List<Pose> _detectedPoses = [];
  bool _isProcessingPose = false;
  Size? _lastImageSize;
  InputImageRotation? _lastInputImageRotation;

  // Smoothing states
  final Map<PoseLandmarkType, Offset> _smoothedPositions = {};
  final Map<PoseLandmarkType, double> _smoothedLikelihoods = {};
  static const double _smoothingAlpha = 0.35; 

  // Ghost Pose States
  Map<PoseLandmarkType, Offset>? _averageGhostPose;
  double _ghostFacingConsensus = 0; // Negative = Facing Left, Positive = Facing Right
  bool _isGhostSymmetric = true; // Default to true until calculated
  Map<String, double>? _ghostAngles; // Cached ghost angles
  Map<String, double>? _flippedGhostAngles; // Cached flipped angles
  
  double _smoothedFacingDir = 0; 
  bool _currentGhostFlipped = false;

  DateTime? _lastPoseUpdateTime;
  Timer? _poseStalenessTimer;

  // Auto-Capture States
  int _poseMatchCountdown = 0;
  Timer? _poseMatchTimer;
  Map<String, double> _lastAngles = {};
  Offset? _lastHeadCenter;
  bool _isPoseMatching = false;

  // Device Orientation Tracking
  NativeDeviceOrientation _deviceOrientation = NativeDeviceOrientation.portraitUp;
  StreamSubscription<NativeDeviceOrientation>? _orientationSubscription;
  late AnimationController _iconRotationController;
  double _currentIconAngle = 0;
  double _targetIconAngle = 0;

  double get _aspectRatio {
    switch (_aspectRatioMode) {
      case '9:16':
        return 9 / 16;
      case '1:1':
        return 1 / 1;
      case '3:4':
      default:
        return 3 / 4;
    }
  }

  @override
  void initState() {
    super.initState();
    _targetAlbum = widget.initialAlbum ?? 'Camera';
    WidgetsBinding.instance.addObserver(this);
    
    // Warm up the latest media cache for this album
    context.read<MediaStorageService>().reindexAlbum(_targetAlbum);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iconRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _iconRotationController.addListener(() {
      setState(() {
        _currentIconAngle = _currentIconAngle + (_targetIconAngle - _currentIconAngle) * _iconRotationController.value;
      });
    });

    // Subscribe to device orientation changes
    _orientationSubscription = NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((orientation) {
      if (orientation != _deviceOrientation && mounted) {
        setState(() => _deviceOrientation = orientation);
        _animateIconRotation(orientation);
      }
    });

    _initializeCamera();
    // No need to manually load, the Selector will handle it.
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.max,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    try {
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _isInitialized = true;
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _animateIconRotation(NativeDeviceOrientation orientation) {
    double target;
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft:
        target = math.pi / 2;   // 90° clockwise
        break;
      case NativeDeviceOrientation.landscapeRight:
        target = -math.pi / 2;  // 90° counter-clockwise
        break;
      case NativeDeviceOrientation.portraitDown:
        target = math.pi;       // 180°
        break;
      case NativeDeviceOrientation.portraitUp:
      default:
        target = 0;
        break;
    }
    _targetIconAngle = target;
    _currentIconAngle = _currentIconAngle; // keep current as start
    _iconRotationController.forward(from: 0);
  }

  /// Returns the rotation in quarter-turns needed to correct a photo taken at the current device orientation.
  int _getOrientationRotationDegrees() {
    switch (_deviceOrientation) {
      case NativeDeviceOrientation.landscapeLeft:
        return 90;
      case NativeDeviceOrientation.landscapeRight:
        return 270;
      case NativeDeviceOrientation.portraitDown:
        return 180;
      case NativeDeviceOrientation.portraitUp:
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _recordingTimer?.cancel();
    _focusTimer?.cancel();
    _pulseController.dispose();
    _iconRotationController.dispose();
    _orientationSubscription?.cancel();
    _poseDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _countdownRemaining > 0) {
      return;
    }

    if (_timerSeconds > 0) {
      setState(() => _countdownRemaining = _timerSeconds);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_countdownRemaining > 1) {
            _countdownRemaining--;
          } else {
            _countdownRemaining = 0;
            timer.cancel();
            _executeCapture();
          }
        });
      });
    } else {
      _executeCapture();
    }
  }

  Future<void> _executeCapture() async {
    if (_isSaving) return;
    _pulseController.forward().then((_) => _pulseController.reverse());
    setState(() => _isSaving = true);

    try {
      final XFile rawFile = await _controller!.takePicture();
      if (!mounted) return;

      // 1. Get image dimensions natively (very fast)
      final Uint8List rawBytes = await File(rawFile.path).readAsBytes();
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
        rawBytes,
      );
      final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
        buffer,
      );
      final int imgWidth = descriptor.width;
      final int imgHeight = descriptor.height;

      // 2. Calculate crop coordinates
      final sensorRatio = 1 / _controller!.value.aspectRatio;
      int cropX = 0, cropY = 0, cropW = 0, cropH = 0;

      if (sensorRatio > _aspectRatio) {
        cropH = imgHeight;
        cropW = (imgHeight * _aspectRatio).toInt();
        cropX = (imgWidth - cropW) ~/ 2;
        cropY = 0;
      } else {
        cropW = imgWidth;
        cropH = (imgWidth / _aspectRatio).toInt();
        cropX = 0;
        cropY = (imgHeight - cropH) ~/ 2;
      }

      // 3. Perform Native Cropping, Orientation Correction, and Compression
      final option = ImageEditorOption();
      option.addOption(
        ClipOption(x: cropX, y: cropY, width: cropW, height: cropH),
      );

      // 3.5 Correct for device orientation so photos are always right-side up
      final int rotationDeg = _getOrientationRotationDegrees();
      if (rotationDeg != 0) {
        option.addOption(RotateOption(rotationDeg));
      }

      option.outputFormat = const OutputFormat.jpeg(90);

      // Using editFile might be missing in some versions or renamed, try editImage as it's more universal
      final processedBytes = await ImageEditor.editImage(
        image: rawBytes,
        imageEditorOption: option,
      );

      if (processedBytes == null || !mounted) return;

      final mediaStorage = context.read<MediaStorageService>();
      await mediaStorage.savePhoto(_targetAlbum, processedBytes, ext: 'jpg');
      
      // Auto-refresh ghost if pose is active to include the new photo
      if (_isPoseEnabled) _refreshPoseEngine();
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      setState(() => _isSaving = true);
      final XFile videoFile = await _controller!.stopVideoRecording();
      _recordingTimer?.cancel();
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
      });

      final bytes = await File(videoFile.path).readAsBytes();
      if (!mounted) {
        _isSaving = false;
        return;
      }
      await context.read<MediaStorageService>().saveVideo(_targetAlbum, bytes);
      setState(() => _isSaving = false);
    } else {
      await _controller!.startVideoRecording();
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordingSeconds++);
      });
      setState(() => _isRecording = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _togglePoseDetection() async {
    if (_controller == null || !_isInitialized) return;

    setState(() {
      _isPoseEnabled = !_isPoseEnabled;
      if (!_isPoseEnabled) {
        _detectedPoses = [];
      }
    });

    if (_isPoseEnabled) {
      _loadGhostPoses(); // Initial load
      // Start Image Stream
      try {
        await _controller!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint('Error starting image stream: $e');
        setState(() => _isPoseEnabled = false);
      }
    } else {
      // Stop Image Stream
      setState(() => _averageGhostPose = null);
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping image stream: $e');
      }
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (!_isPoseEnabled || _isProcessingPose || _isSaving) return;

    // Log the first frame to confirm stream is running
    if (_lastImageSize == null) {
      debugPrint('Pose Stream Started: ${image.width}x${image.height}, Format: ${image.format.raw}');
    }

    _isProcessingPose = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        // Log failure once
        if (_lastImageSize == null) debugPrint('Failed to convert CameraImage to InputImage');
        _isProcessingPose = false;
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);
      
      if (mounted && _isPoseEnabled) {
        if (poses.isNotEmpty) {
          final firstPose = poses.first;
          
          // Apply EMA Smoothing to landmarks
          firstPose.landmarks.forEach((type, landmark) {
            final double currX = landmark.x;
            final double currY = landmark.y;
            final double currL = landmark.likelihood;

            if (_smoothedPositions.containsKey(type)) {
              final prevPos = _smoothedPositions[type]!;
              final prevLik = _smoothedLikelihoods[type]!;
              
              _smoothedPositions[type] = Offset(
                prevPos.dx + _smoothingAlpha * (currX - prevPos.dx),
                prevPos.dy + _smoothingAlpha * (currY - prevPos.dy),
              );
              _smoothedLikelihoods[type] = prevLik + _smoothingAlpha * (currL - prevLik);
            } else {
              _smoothedPositions[type] = Offset(currX, currY);
              _smoothedLikelihoods[type] = currL;
            }
          });
        } else {
          // Decay likelihoods if no one is detected to fade out the skeleton
          _smoothedLikelihoods.updateAll((type, value) => value * 0.5);
        }

        // Update activity timer
        _lastPoseUpdateTime = DateTime.now();

        // --- POSE MATCHING LOGIC ---
        if (_averageGhostPose != null) {
          final currentAngles = _calculatePoseAngles(_smoothedPositions);
          
          double rawFacing = 0;
          if (poses.isNotEmpty) {
            final p = poses.first;
            final ls = p.landmarks[PoseLandmarkType.leftShoulder];
            final rs = p.landmarks[PoseLandmarkType.rightShoulder];
            final lh = p.landmarks[PoseLandmarkType.leftHip];
            final rh = p.landmarks[PoseLandmarkType.rightHip];
            
            // Average shoulder and hip Z-delta for a more robust facing signal
            double sZ = (ls != null && rs != null) ? (ls.z - rs.z) : 0;
            double hZ = (lh != null && rh != null) ? (lh.z - rh.z) : 0;
            rawFacing = (sZ + hZ) / 2;
          }
          
          // Smooth the facing direction to prevent jittery flipping
          _smoothedFacingDir = _smoothedFacingDir + 0.15 * (rawFacing - _smoothedFacingDir);

          // Mirror logic with Hysteresis and Symmetry Check
          if (!_isGhostSymmetric && _ghostFacingConsensus != 0) {
             // Normalize current facing signal (-1 to 1)
             double currentSign = _smoothedFacingDir.sign;
             if (_smoothedFacingDir.abs() < 1.0) currentSign = 0; // Dead zone

             // Flip if we are posing in the OPPOSITE direction of the consensus
             // Note: Consensus of 1 means Anchor was 'Positive Z Delta' (Left side away)
             if (currentSign != 0 && currentSign * _ghostFacingConsensus < 0) {
               _currentGhostFlipped = true;
             } else if (currentSign != 0 && currentSign * _ghostFacingConsensus > 0) {
               _currentGhostFlipped = false;
             }
          } else {
             _currentGhostFlipped = false;
          }
          
          Map<String, double> targetAngles;
          if (_currentGhostFlipped) {
            _flippedGhostAngles ??= _calculatePoseAngles(_mirrorPose(_averageGhostPose!));
            targetAngles = _flippedGhostAngles!;
          } else {
            _ghostAngles ??= _calculatePoseAngles(_averageGhostPose!);
            targetAngles = _ghostAngles!;
          }

          if (currentAngles.isNotEmpty && targetAngles.isNotEmpty) {
            double weightedDiff = 0;
            double totalWeight = 0;
            double maxStabilityChange = 0;

            // 1. Calculate Head Movement for stability (pos-based)
            Offset? headPos;
            int headCount = 0;
            _smoothedPositions.forEach((type, pos) {
               if (type.index <= 10 && (_smoothedLikelihoods[type] ?? 0) > 0.3) {
                  headPos = (headPos == null) ? pos : headPos! + pos;
                  headCount++;
               }
            });
            final currentHeadCenter = (headCount > 0 && headPos != null) ? Offset(headPos!.dx / headCount, headPos!.dy / headCount) : null;
            double headMovement = 1000.0;
            if (currentHeadCenter != null && _lastHeadCenter != null) {
               headMovement = (currentHeadCenter - _lastHeadCenter!).distance;
            }

            currentAngles.forEach((key, angle) {
              if (targetAngles.containsKey(key)) {
                double diff = (angle - targetAngles[key]!).abs();
                if (diff > 180) diff = 360 - diff;
                
                double weight = (key.contains('Elbow') || key.contains('Shoulder') || key.contains('Wrist')) ? 3.0 : 1.0;
                weightedDiff += (diff * weight);
                totalWeight += weight;
              }
              // Stability check restricted to less jittery segments: Chest/Shoulder and Elbows
              if (_lastAngles.containsKey(key) && (key.contains('Shoulder') || key.contains('Elbow') || key.contains('Hip'))) {
                double change = (angle - _lastAngles[key]!).abs();
                if (change > 180) change = 360 - change;
                if (change > maxStabilityChange) maxStabilityChange = change;
              }
            });

            final avgDiff = totalWeight > 0 ? (weightedDiff / totalWeight) : 1000.0;
            final isMatching = avgDiff < 20.0; 
            
            // Combined stability check: Reliable angles remain still AND head center doesn't shift more than ~1.5% of height
            final double imgH = (_lastImageSize?.height ?? 1000.0);
            final bool headStable = headMovement < (imgH * 0.015);
            final bool anglesStable = maxStabilityChange < 8.5;
            final isStable = totalWeight > 0 && anglesStable && headStable;

            if (isMatching && isStable) {
              if (!_isPoseMatching) {
                _isPoseMatching = true;
                _startPoseMatchCountdown();
              }
            } else {
              if (_isPoseMatching) {
                _isPoseMatching = false;
                _cancelPoseMatchCountdown();
              }
            }
            _lastAngles = currentAngles;
            _lastHeadCenter = currentHeadCenter;
          }
        }
        // ---------------------------

        setState(() {
          _detectedPoses = poses;
          _lastImageSize = inputImage.metadata?.size;
          _lastInputImageRotation = inputImage.metadata?.rotation;
        });
      }
    } catch (e) {
      debugPrint('Pose detection error: $e');
    } finally {
      if (mounted) {
        _isProcessingPose = false;
        _checkPoseStaleness();
      }
    }
  }

  Map<String, double> _calculatePoseAngles(Map<PoseLandmarkType, Offset> positions) {
    final Map<String, double> angles = {};
    
    double getA(PoseLandmarkType t1, PoseLandmarkType tCenter, PoseLandmarkType t2) {
      final p1 = positions[t1];
      final center = positions[tCenter];
      final p2 = positions[t2];
      if (p1 == null || center == null || p2 == null) return -1;
      
      final double ang1 = math.atan2(p1.dy - center.dy, p1.dx - center.dx);
      final double ang2 = math.atan2(p2.dy - center.dy, p2.dx - center.dx);
      double diff = (ang1 - ang2) * 180 / math.pi;
      diff = diff.abs();
      if (diff > 180) diff = 360 - diff;
      return diff;
    }

    void addAngle(String name, PoseLandmarkType t1, PoseLandmarkType tc, PoseLandmarkType t2) {
      final a = getA(t1, tc, t2);
      if (a != -1) angles[name] = a;
    }

    addAngle('L_Elbow', PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    addAngle('R_Elbow', PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
    addAngle('L_Shoulder', PoseLandmarkType.leftHip, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    addAngle('R_Shoulder', PoseLandmarkType.rightHip, PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    addAngle('L_Hip', PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    addAngle('R_Hip', PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    addAngle('L_Knee', PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    addAngle('R_Knee', PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    addAngle('L_Wrist', PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex);
    addAngle('R_Wrist', PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex);

    return angles;
  }

  Map<PoseLandmarkType, Offset> _mirrorPose(Map<PoseLandmarkType, Offset> pose) {
    final Map<PoseLandmarkType, Offset> mirrored = {};
    pose.forEach((type, pos) {
      mirrored[type] = Offset(1.0 - pos.dx, pos.dy);
    });

    final Map<PoseLandmarkType, Offset> swapped = Map.from(mirrored);
    
    // Bilateral Mapping Table
    final pairs = {
      PoseLandmarkType.nose: PoseLandmarkType.nose, // Nose is its own pair for categorical swapping
      PoseLandmarkType.leftEyeInner: PoseLandmarkType.rightEyeInner,
      PoseLandmarkType.leftEye: PoseLandmarkType.rightEye,
      PoseLandmarkType.leftEyeOuter: PoseLandmarkType.rightEyeOuter,
      PoseLandmarkType.leftEar: PoseLandmarkType.rightEar,
      PoseLandmarkType.leftMouth: PoseLandmarkType.rightMouth,
      PoseLandmarkType.leftShoulder: PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow: PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist: PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftPinky: PoseLandmarkType.rightPinky,
      PoseLandmarkType.leftIndex: PoseLandmarkType.rightIndex,
      PoseLandmarkType.leftThumb: PoseLandmarkType.rightThumb,
      PoseLandmarkType.leftHip: PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee: PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle: PoseLandmarkType.rightAnkle,
      PoseLandmarkType.leftHeel: PoseLandmarkType.rightHeel,
      PoseLandmarkType.leftFootIndex: PoseLandmarkType.rightFootIndex,
    };

    pairs.forEach((left, right) {
      final pL = mirrored[left];
      final pR = mirrored[right];
      if (pL != null) swapped[right] = pL;
      if (pR != null) swapped[left] = pR;
    });

    return swapped;
  }

  void _startPoseMatchCountdown() {
    _poseMatchTimer?.cancel();
    setState(() => _poseMatchCountdown = 3);
    _poseMatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_poseMatchCountdown > 1) {
            _poseMatchCountdown--;
          } else {
            _poseMatchCountdown = 0;
            _poseMatchTimer?.cancel();
            _executeCapture();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelPoseMatchCountdown() {
    _poseMatchTimer?.cancel();
    _poseMatchTimer = null;
    if (mounted) {
      setState(() => _poseMatchCountdown = 0);
    }
  }

  void _checkPoseStaleness() {
    if (!_isPoseEnabled || _lastPoseUpdateTime == null) return;
    
    // Check if pose has been static or missing for 5 seconds
    final now = DateTime.now();
    if (now.difference(_lastPoseUpdateTime!).inSeconds >= 5) {
      _resetPoseState();
    }
  }

  void _resetPoseState() {
    if (mounted) {
      setState(() {
        _smoothedPositions.clear();
        _smoothedLikelihoods.clear();
        _detectedPoses = [];
        _lastPoseUpdateTime = null;
      });
      debugPrint("Pose Engine: Stale state reset performed.");
    }
  }

  Future<void> _loadGhostPoses() async {
    if (!_isPoseEnabled || !mounted) return;
    
    debugPrint("Ghost Engine: Loading reference poses...");
    final ms = context.read<MediaStorageService>();
    final items = await ms.getMediaForAlbum(_targetAlbum);
    if (items.isEmpty) return;

    // List all candidates by searching backwards until we find at least 2 valid poses
    final allPhotoPaths = items
        .where((i) => !i.filePath.endsWith('.mp4'))
        .map((i) => i.filePath)
        .toList();

    if (allPhotoPaths.isEmpty) return;

    final Map<PoseLandmarkType, List<Offset>> relativeCollection = {};
    double totalFacing = 0;
    int facingCount = 0;
    
    double totalEnvScale = 0;
    Offset totalEnvCenter = Offset.zero;
    int envCount = 0;
    
    // Polarity Tracking: We keep the angles of the first valid pose found as our "Anatomical Anchor".
    Map<String, double>? anchorAngles;

    // We use a dedicated detector in SINGLE mode for static images to get the 
    // absolute highest landmark precision possible (ignoring temporal smoothing).
    final highPrecisionDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.accurate,
      ),
    );

    // Iterate through photos backwards until we find up to 3 valid ones
    for (final path in allPhotoPaths) {
      if (envCount >= 3) break; 
      
      try {
        final inputImage = InputImage.fromFilePath(path);
        final bytes = await File(path).readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image image = frameInfo.image;
        final double w = image.width.toDouble();
        final double h = image.height.toDouble();

        final poses = await highPrecisionDetector.processImage(inputImage);
        if (poses.isNotEmpty) {
          final p = poses.first;
          
          final ls = p.landmarks[PoseLandmarkType.leftShoulder];
          final rs = p.landmarks[PoseLandmarkType.rightShoulder];
          final lh = p.landmarks[PoseLandmarkType.leftHip];
          final rh = p.landmarks[PoseLandmarkType.rightHip];

          if (ls != null && rs != null && lh != null && rh != null) {
            // 1. Calculate the pose's "Canonical Form"
            final Offset shoulderMid = Offset((ls.x + rs.x) / 2, (ls.y + rs.y) / 2);
            final Offset hipMid = Offset((lh.x + rh.x) / 2, (lh.y + rh.y) / 2);
            final double torsoHeight = math.sqrt(math.pow(shoulderMid.dx - hipMid.dx, 2) + math.pow(shoulderMid.dy - hipMid.dy, 2));
            
            if (torsoHeight > 0.01) {
              // Extract current normalized landmarks
              final Map<PoseLandmarkType, Offset> currentNormalized = {};
              p.landmarks.forEach((type, landmark) {
                if (landmark.likelihood > 0.5) {
                   currentNormalized[type] = Offset((landmark.x - hipMid.dx) / torsoHeight, (landmark.y - hipMid.dy) / torsoHeight);
                }
              });

              // 2. Anatomical Alignment (Polarity Check)
              bool shouldMirrorThisOne = false;
              final currentAngles = _calculatePoseAngles(currentNormalized);
              
              if (anchorAngles == null) {
                // This is our first valid pose; it becomes the Anchor for everyone else.
                anchorAngles = currentAngles;
              } else {
                // Compare current pose vs Anchor, and Mirrored pose vs Anchor.
                final mirroredPose = _mirrorPose(currentNormalized);
                final mirroredAngles = _calculatePoseAngles(mirroredPose);
                
                double normalDiff = 0;
                double mirroredDiff = 0;
                int count = 0;
                
                anchorAngles.forEach((k, v) {
                   if (currentAngles.containsKey(k) && mirroredAngles.containsKey(k)) {
                      double dN = (v - currentAngles[k]!).abs();
                      if (dN > 180) dN = 360 - dN;
                      double dM = (v - mirroredAngles[k]!).abs();
                      if (dM > 180) dM = 360 - dM;
                      
                      normalDiff += dN;
                      mirroredDiff += dM;
                      count++;
                   }
                });
                
                // If it matches the mirror better, it's an "anatomically flipped" version of the same pose.
                // We flip it back to align it with the average.
                if (count > 0 && mirroredDiff < normalDiff) {
                   shouldMirrorThisOne = true;
                   debugPrint("Ghost Engine: Detected flipped polarity for $path. Aligning to anchor.");
                }
              }

              // 3. Accumulate data based on alignment
              final finalToProcess = shouldMirrorThisOne ? _mirrorPose(currentNormalized) : currentNormalized;
              
              // Robust facing consensus (Normalized Sign)
              double sZ = (ls.z - rs.z);
              double hZ = (lh.z - rh.z);
              double facingVal = (sZ + hZ) / 2;
              
              // If we mirrored the pose, we flip the facing value to stay in sync with the anatomy
              double alignedFacing = facingVal * (shouldMirrorThisOne ? -1 : 1);
              
              totalFacing += alignedFacing.sign;
              facingCount++;
              
              totalEnvCenter += Offset(hipMid.dx / w, hipMid.dy / h);
              totalEnvScale += (torsoHeight / math.max(w, h));
              envCount++;

              finalToProcess.forEach((type, rel) {
                relativeCollection.putIfAbsent(type, () => []);
                relativeCollection[type]!.add(rel);
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Ghost Engine: Error processing $path - $e");
      }
    }

    // Disposal
    highPrecisionDetector.close();

    if (relativeCollection.isEmpty || envCount == 0 || facingCount == 0) return;

    // 4. Calculate the "Canonical Average Pose" (The perfect proportions)
    final Map<PoseLandmarkType, Offset> canonicalAverage = {};
    relativeCollection.forEach((type, offsets) {
      if (offsets.isNotEmpty) {
        double sumX = 0, sumY = 0;
        for (var o in offsets) {sumX += o.dx; sumY += o.dy;}
        canonicalAverage[type] = Offset(sumX / offsets.length, sumY / offsets.length);
      }
    });

    // 5. Re-project the Canonical Shape into the "Average Environment" (0..1 space)
    final avgEnvScale = totalEnvScale / envCount;
    final avgEnvCenter = Offset(totalEnvCenter.dx / envCount, totalEnvCenter.dy / envCount);
    
    final Map<PoseLandmarkType, Offset> averageAsNormalized = {};
    canonicalAverage.forEach((type, relPos) {
      averageAsNormalized[type] = Offset(
        avgEnvCenter.dx + (relPos.dx * avgEnvScale),
        avgEnvCenter.dy + (relPos.dy * avgEnvScale)
      );
    });

    // 6. Universal Alignment (Center Width, 1/3 Height)
    Offset? currentHeadSum;
    int headPointCount = 0;
    averageAsNormalized.forEach((type, pos) {
      if (type.index <= 10) { // Facial landmarks 0-10
        currentHeadSum = (currentHeadSum == null) ? pos : currentHeadSum! + pos;
        headPointCount++;
      }
    });

    if (headPointCount > 0 && currentHeadSum != null) {
      final currentHeadCenter = Offset(currentHeadSum!.dx / headPointCount, currentHeadSum!.dy / headPointCount);
      final deltaX = 0.5 - currentHeadCenter.dx;
      final deltaY = 0.333 - currentHeadCenter.dy;
      
      // Shift the entire skeleton
      averageAsNormalized.updateAll((type, pos) => Offset(pos.dx + deltaX, pos.dy + deltaY));
    }

    // Check for Symmetry
    final baseAng = _calculatePoseAngles(averageAsNormalized);
    final flipAng = _calculatePoseAngles(_mirrorPose(averageAsNormalized));
    double symDiff = 0;
    int symCount = 0;
    baseAng.forEach((k, v) {
      if (flipAng.containsKey(k)) {
        double d = (v - flipAng[k]!).abs();
        if (d > 180) d = 360 - d;
        symDiff += d;
        symCount++;
      }
    });

    if (mounted) {
      setState(() {
        _averageGhostPose = averageAsNormalized;
        // The consensus is now a clean Sign (-1 or 1) representing the dominant orientation
        _ghostFacingConsensus = (totalFacing / facingCount).sign;
        _isGhostSymmetric = symCount > 0 && (symDiff / symCount) < 15.0;
        _ghostAngles = null;
        _flippedGhostAngles = null;
        _smoothedFacingDir = 0;
        _currentGhostFlipped = false;
      });
      debugPrint("Ghost Engine: Proportional Averaging Complete (Photos: $envCount, Consensus: $_ghostFacingConsensus).");
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _cameras[_selectedCameraIndex].sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isIOS) {
      // Simplified mapping for common camera orientations
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    var format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    // Extensive fallback for Android formats
    if (format == null && Platform.isAndroid) {
      if (image.format.raw == 17) {
        format = InputImageFormat.nv21;
      } else if (image.format.raw == 35) format = InputImageFormat.yuv420;
    }

    // Defensive fallback - if we still don't have a format, guess based on OS
    format ??= Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    
    // Stop image stream if active before switching hardware
    if (_isPoseEnabled && _controller != null) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _resetPoseState(); 
    await _initializeCamera();

    // Restart image stream if it was active
    if (_isPoseEnabled && _controller != null && _controller!.value.isInitialized) {
      _loadGhostPoses();
      try {
        await _controller!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint("Error restarting pose engine after camera switch: $e");
      }
    }
  }

  void _refreshPoseEngine() async {
    if (!_isPoseEnabled || !mounted) return;
    
    // Stop current stream
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }

    // Reset and reload
    _resetPoseState();
    await _loadGhostPoses();

    // Restart
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint("Error refreshing pose engine: $e");
      }
    }
  }

  Future<void> _setZoom(double zoom) async {
    final targetZoom = zoom.clamp(_minZoom, _maxZoom);
    await _controller?.setZoomLevel(targetZoom);
    if (mounted) setState(() => _currentZoom = targetZoom);
  }

  void _cycleZoom() {
    final List<double> steps = _getZoomSteps();
    int nextIndex = 0;
    for (int i = 0; i < steps.length; i++) {
      if (_currentZoom < steps[i] - 0.05) {
        nextIndex = i;
        break;
      }
      if (i == steps.length - 1) nextIndex = 0;
    }
    _setZoom(steps[nextIndex]);
  }

  List<double> _getZoomSteps() {
    final List<double> steps = [];
    if (_minZoom < 1.0) steps.add(_minZoom);
    steps.addAll([1.0, 2.0, 5.0]);
    if (_maxZoom > 5.1 && !steps.contains(_maxZoom)) steps.add(_maxZoom);
    return steps.where((s) => s >= _minZoom && s <= _maxZoom).toList();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseZoom = _currentZoom;
    if (_showZoomOptions || _showTimerOptions) {
      setState(() {
        _showZoomOptions = false;
        _showTimerOptions = false;
      });
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_controller == null || !_isInitialized) return;
    final double newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
    _setZoom(newZoom);
  }

  void _onPreviewTap() {
    if (_showZoomOptions || _showTimerOptions) {
      setState(() {
        _showZoomOptions = false;
        _showTimerOptions = false;
      });
    }
  }

  Offset _convertViewToSensor(Offset localPoint, double boxWidth, double boxHeight) {
    if (_controller == null) return const Offset(0.5, 0.5);
    final double rawSensorRatio = _controller!.value.aspectRatio;
    final double visualRatio = rawSensorRatio < 1 ? rawSensorRatio : 1 / rawSensorRatio;

    double fullWidth, fullHeight;
    if (visualRatio > _aspectRatio) {
      fullHeight = boxHeight;
      fullWidth = boxHeight / visualRatio;
    } else {
      fullWidth = boxWidth;
      fullHeight = boxWidth / visualRatio;
    }

    double offsetX = (fullWidth - boxWidth) / 2;
    double offsetY = (fullHeight - boxHeight) / 2;
    double sensorX = (localPoint.dx + offsetX) / fullWidth;
    double sensorY = (localPoint.dy + offsetY) / fullHeight;
    return Offset(sensorX.clamp(0.0, 1.0), sensorY.clamp(0.0, 1.0));
  }

  void _handleFocusTap(TapDownDetails details, double boxWidth, double boxHeight) {
    if (_controller == null || !_isInitialized) return;
    final Offset localOffset = details.localPosition;

    if (_isFocusLocked) {
      setState(() {
        _isFocusLocked = false;
        _focusPoint = null;
      });
      _controller!.setFocusMode(FocusMode.auto);
      _controller!.setExposureMode(ExposureMode.auto);
      return;
    }

    _focusTimer?.cancel();
    setState(() {
      _focusPoint = localOffset;
      _isFocusLocked = false;
    });

    final Offset focusPoint = _convertViewToSensor(localOffset, boxWidth, boxHeight);
    () async {
      try {
        if (_controller!.value.isInitialized) {
          await Future.wait([
            _controller!.setFocusPoint(focusPoint),
            _controller!.setExposurePoint(focusPoint),
          ]);
        }
      } catch (e) {
        debugPrint('Focus hardware error: $e');
      }
    }();

    _focusTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isFocusLocked) setState(() => _focusPoint = null);
    });
    _onPreviewTap();
  }

  void _handleFocusLongPress(LongPressStartDetails details, double boxWidth, double boxHeight) {
    if (_controller == null || !_isInitialized) return;
    final Offset localOffset = details.localPosition;
    _focusTimer?.cancel();
    setState(() {
      _focusPoint = localOffset;
      _isFocusLocked = true;
    });

    final Offset focusPoint = _convertViewToSensor(localOffset, boxWidth, boxHeight);
    () async {
      try {
        if (_controller!.value.isInitialized) {
          await Future.wait([
            _controller!.setFocusPoint(focusPoint),
            _controller!.setExposurePoint(focusPoint),
          ]);
          await Future.delayed(const Duration(milliseconds: 1200));
          if (mounted && _isFocusLocked) {
            await Future.wait([
              _controller!.setFocusMode(FocusMode.locked),
              _controller!.setExposureMode(ExposureMode.locked),
            ]);
          }
        }
      } catch (e) {
        debugPrint('Focus lock hardware error: $e');
      }
    }();
  }

  Future<void> _toggleFlash() async {
    FlashMode next;
    switch (_flashMode) {
      case FlashMode.off: next = FlashMode.auto; break;
      case FlashMode.auto: next = FlashMode.always; break;
      case FlashMode.always: next = FlashMode.off; break;
      default: next = FlashMode.off;
    }
    await _controller?.setFlashMode(next);
    setState(() => _flashMode = next);
  }

  Future<void> _toggleTorch() async {
    if (_flashMode == FlashMode.torch) {
      await _controller?.setFlashMode(FlashMode.off);
      setState(() => _flashMode = FlashMode.off);
    } else {
      await _controller?.setFlashMode(FlashMode.torch);
      setState(() => _flashMode = FlashMode.torch);
    }
  }

  void _cycleAspectRatio() {
    setState(() {
      if (_aspectRatioMode == '3:4') {
        _aspectRatioMode = '9:16';
      } else if (_aspectRatioMode == '9:16') _aspectRatioMode = '1:1';
      else _aspectRatioMode = '3:4';
    });
  }

  String _getRatioLabel() => _aspectRatioMode;

  void _openAlbumPicker() async {
    final ms = context.read<MediaStorageService>();
    final albums = await ms.getAlbums();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AlbumPickerSheet(
        currentAlbum: _targetAlbum,
        albums: albums,
        onSelected: (name) {
          setState(() => _targetAlbum = name);
          _refreshPoseEngine(); // Reload ghost for new album
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isPoseEnabled) {
      debugPrint('BUILD: Pose Overlay logic active. Has frame: ${_lastImageSize != null}');
    }
    
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;
                double boxWidth = availableWidth;
                double boxHeight = availableWidth / _aspectRatio;
                if (boxHeight > availableHeight) {
                  boxHeight = availableHeight;
                  boxWidth = availableHeight * _aspectRatio;
                }

                final rawSensorRatio = _controller!.value.aspectRatio;
                final visualRatio = rawSensorRatio < 1 ? rawSensorRatio : 1 / rawSensorRatio;

                double scale;
                if (visualRatio > _aspectRatio) {
                  scale = visualRatio / _aspectRatio;
                } else {
                  scale = _aspectRatio / visualRatio;
                }

                return Center(
                  child: Container(
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRect(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTapDown: (details) => _handleFocusTap(details, boxWidth, boxHeight),
                            onLongPressStart: (details) => _handleFocusLongPress(details, boxWidth, boxHeight),
                            onScaleStart: _handleScaleStart,
                            onScaleUpdate: _handleScaleUpdate,
                            child: Transform.scale(
                              scale: scale,
                              child: Center(child: CameraPreview(_controller!)),
                            ),
                          ),
                          if (_focusPoint != null)
                            Positioned(
                              left: _focusPoint!.dx - 35,
                              top: _focusPoint!.dy - 35,
                              child: Container(
                                width: 70, height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _isFocusLocked ? Colors.amber : Colors.white,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: _isFocusLocked ? const Center(child: Icon(Icons.lock_rounded, color: Colors.amber, size: 20)) : null,
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

          // 1.5 Pose Detection Layer (Calculated on top of everything)
          if (_isPoseEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Logic to find the camera box coordinate space
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;
                    double boxWidth = availableWidth;
                    double boxHeight = availableWidth / _aspectRatio;
                    if (boxHeight > availableHeight) {
                      boxHeight = availableHeight;
                      boxWidth = availableHeight * _aspectRatio;
                    }
                    
                    final rawSensorRatio = _controller?.value.aspectRatio ?? 1.0;
                    final visualRatio = rawSensorRatio < 1 ? rawSensorRatio : 1 / rawSensorRatio;

                    // Unified mirroring logic
                    final effectiveGhost = _currentGhostFlipped ? _mirrorPose(_averageGhostPose!) : _averageGhostPose;

                    return Center(
                      child: SizedBox(
                        width: boxWidth,
                        height: boxHeight,
                        child: CustomPaint(
                          painter: PosePainter(
                            poses: _detectedPoses,
                            smoothedPositions: _smoothedPositions,
                            smoothedLikelihoods: _smoothedLikelihoods,
                            averageGhostPose: effectiveGhost,
                            imageSize: _lastImageSize ?? const Size(720, 1280),
                            rotation: _lastInputImageRotation ?? InputImageRotation.rotation90deg,
                            boxWidth: boxWidth,
                            boxHeight: boxHeight,
                            previewRatio: _aspectRatio,
                            cameraRatio: visualRatio,
                            isFrontCamera: _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 1.6 Pose Engine Indicator (Top level)
          if (_isPoseEnabled)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: (_lastImageSize != null) ? Colors.greenAccent : Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (_lastImageSize != null)
                            BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "POSE ENGINE ACTIVE",
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // 1.7 Pose Match Countdown Overlay
          if (_poseMatchCountdown > 0)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "MATCH DETECTED!",
                        style: GoogleFonts.inter(
                          color: Colors.greenAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "$_poseMatchCountdown",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 160,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            const Shadow(
                              color: Colors.black54,
                              blurRadius: 30,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "HOLD STILL...",
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. Top Controls
          SafeArea(
            child: Stack(
              children: [
                // Folder / Album Picker (Top Left)
                Positioned(
                  top: 10,
                  left: 16,
                  child: GestureDetector(
                    onTap: _openAlbumPicker,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: _orientedIcon(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.folder_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _targetAlbum,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Aspect Ratio Toggle (Top Right)
                Positioned(
                  top: 10,
                  right: 16,
                  child: _circleIconButton(
                    _orientedIcon(
                      Text(
                        _getRatioLabel(),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    _cycleAspectRatio,
                    size: 48,
                  ),
                ),

                // Centered Tool Bubble
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _topBubbleItem(
                                Icon(
                                  _timerSeconds == 0
                                      ? Icons.timer_off_rounded
                                      : Icons.timer_rounded,
                                  color: _timerSeconds > 0
                                      ? Colors.yellow
                                      : Colors.white,
                                  size: 22,
                                ),
                                () => setState(
                                  () => _showTimerOptions = !_showTimerOptions,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              _topBubbleItem(
                                GestureDetector(
                                  onLongPress: _toggleTorch,
                                  child: Icon(
                                    _flashMode == FlashMode.off
                                        ? Icons.flash_off_rounded
                                        : _flashMode == FlashMode.auto
                                        ? Icons.flash_auto_rounded
                                        : _flashMode == FlashMode.torch
                                        ? Icons.flashlight_on_rounded
                                        : Icons.flash_on_rounded,
                                    color: _flashMode == FlashMode.torch
                                        ? Colors.yellow
                                        : Colors.white,
                                    size: 22,
                                  ),
                                ),
                                _toggleFlash,
                              ),
                              Container(
                                width: 1,
                                height: 16,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              _topBubbleItem(
                                Icon(
                                  Icons.accessibility_new_rounded,
                                  color: _isPoseEnabled
                                      ? AppConstants.accentPrimary
                                      : Colors.white.withOpacity(0.6),
                                  size: 22,
                                ),
                                _togglePoseDetection,
                              ),
                            ],
                          ),
                        ),

                        // Timer Options Dropdown (Inline underneath bubble)
                        if (_showTimerOptions)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              onTap: () {},
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [0, 2, 5, 10]
                                      .map(
                                        (s) => GestureDetector(
                                          onTap: () => setState(() {
                                            _timerSeconds = s;
                                          }),
                                          behavior: HitTestBehavior.opaque,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _timerSeconds == s
                                                  ? AppConstants.accentPrimary
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: _orientedIcon(
                                              Text(
                                                s == 0 ? 'Off' : '${s}s',
                                                style: GoogleFonts.inter(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
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
          ),

          // 3. Bottom Controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 40 + MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Bubble Options
                if (_showZoomOptions)
                  Builder(
                    builder: (context) {
                      final steps = _getZoomSteps();
                      // Identify the "active" step: the largest step <= current zoom
                      final activeStep = steps.lastWhere(
                        (s) => _currentZoom >= (s - 0.05),
                        orElse: () => steps.first,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {},
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: steps
                                  .map(
                                    (z) => GestureDetector(
                                      onTap: () => setState(() {
                                        _setZoom(z);
                                      }),
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: z == activeStep
                                              ? AppConstants.accentPrimary
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: _orientedIcon(
                                          Text(
                                            '${z % 1 == 0 ? z.toInt() : z.toStringAsFixed(1)}x',
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // Main Zoom Indicator/Button
                GestureDetector(
                  onTap: () =>
                      setState(() => _showZoomOptions = !_showZoomOptions),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _showZoomOptions
                            ? AppConstants.accentPrimary
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: _orientedIcon(
                      Text(
                        '${_currentZoom % 1 == 0 ? _currentZoom.toInt() : _currentZoom.toStringAsFixed(1)}x',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Main Controls Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery button
                      _circleIconButton(
                        Selector<MediaStorageService, MediaItem?>(
                          selector: (_, ms) =>
                              ms.getLatestMediaForAlbum(_targetAlbum),
                          builder: (context, latestItem, _) {
                            final path = latestItem?.filePath;
                            return Opacity(
                              opacity: _isSaving ? 0.6 : 1.0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: ScaleTransition(
                                          scale: animation,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: path != null
                                        ? Container(
                                            key: ValueKey(path),
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white24,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: Stack(
                                                alignment: Alignment.center,
                                                fit: StackFit.expand,
                                                children: [
                                                  path.endsWith('.mp4')
                                                      ? VideoThumbnailPlayer(
                                                          filePath: path,
                                                        )
                                                      : Image.file(
                                                          File(path),
                                                          fit: BoxFit.cover,
                                                          cacheWidth: 100,
                                                          errorBuilder: (ctx, err, st) => Container(
                                                            color: Colors.white10,
                                                            child: const Icon(
                                                              Icons.photo_library_rounded,
                                                              color: Colors.white24,
                                                              size: 18,
                                                            ),
                                                          ),
                                                        ),
                                                  if (path.endsWith('.mp4'))
                                                    Container(
                                                      decoration:
                                                          const BoxDecoration(
                                                            color:
                                                                Colors.black26,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            2,
                                                          ),
                                                      child: const Icon(
                                                        Icons
                                                            .play_arrow_rounded,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : Container(
                                            key: const ValueKey('empty'),
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white10,
                                              ),
                                              color: Colors.white10,
                                            ),
                                            child: const Icon(
                                              Icons.photo_library_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                  ),
                                  if (_isSaving)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                        _isSaving
                            ? null
                            : () async {
                                final ms = context.read<MediaStorageService>();
                                final items = await ms.getMediaForAlbum(
                                  _targetAlbum,
                                );
                                if (items.isNotEmpty && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MediaViewPage(
                                        items: items,
                                        initialIndex: 0,
                                      ),
                                    ),
                                  );
                                } else {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No items in $_targetAlbum',
                                          style: GoogleFonts.inter(),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            AppConstants.bgElevated,
                                      ),
                                    );
                                  }
                                }
                              },
                      ),
                      // Capture Button & Mode Toggle
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_activeMode == 'VIDEO') {
                                _toggleRecording();
                              } else {
                                _takePicture();
                              }
                            },
                            child: Container(
                              width: 84,
                              height: 84,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      margin: EdgeInsets.all(_isRecording ? 18 : 0),
                                      decoration: BoxDecoration(
                                        color: _activeMode == 'VIDEO'
                                            ? Colors.red
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          _isRecording ? 8 : 40,
                                        ),
                                        boxShadow: [
                                          if (_pulseAnimation.value > 1.0)
                                            BoxShadow(
                                              color:
                                                  (_activeMode == 'VIDEO'
                                                          ? Colors.red
                                                          : Colors.white)
                                                      .withOpacity(0.6),
                                              blurRadius:
                                                  15 *
                                                  (_pulseAnimation.value - 1) *
                                                  6,
                                              spreadRadius:
                                                  2 *
                                                  (_pulseAnimation.value - 1) *
                                                  6,
                                            ),
                                        ],
                                      ),
                                      child: _countdownRemaining > 0
                                          ? Center(
                                              child: _orientedIcon(
                                                Text(
                                                  '$_countdownRemaining',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 32,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Mode Slide Toggle
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _modeText('VIDEO'),
                              const SizedBox(width: 20),
                              _modeText('PHOTO'),
                            ],
                          ),
                        ],
                      ),
                      // Flip Camera
                      _circleIconButton(
                        const Icon(
                          Icons.flip_camera_android_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        _toggleCamera,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Recording Indicator
          if (_isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 0,
              right: 0,
              child: Center(
                child: _orientedIcon(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.white, size: 10),
                        const SizedBox(width: 10),
                        Text(
                          Helpers.formatDuration(_recordingSeconds),
                          style: GoogleFonts.robotoMono(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Wraps a widget with an animated rotation that matches device orientation.
  Widget _orientedIcon(Widget child) {
    return AnimatedRotation(
      turns: _targetIconAngle / (2 * math.pi),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }

  Widget _topBubbleItem(Widget child, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: _orientedIcon(child),
      ),
    );
  }

  Widget _modeText(String mode) {
    final isActive = _activeMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _activeMode = mode),
      child: _orientedIcon(
        Text(
          mode,
          style: GoogleFonts.inter(
            color: isActive ? Colors.yellow : Colors.white.withOpacity(0.4),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton(
    Widget child,
    VoidCallback? onTap, {
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: _orientedIcon(child),
      ),
    );
  }
}

class _AlbumPickerSheet extends StatelessWidget {
  final String currentAlbum;
  final List<AlbumInfo> albums;
  final Function(String) onSelected;

  const _AlbumPickerSheet({
    required this.currentAlbum,
    required this.albums,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                Text(
                  'Select Album',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showNewAlbumDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: albums.length,
              itemBuilder: (context, i) {
                final album = albums[i];
                final isSelected = album.name == currentAlbum;
                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.folder_rounded
                        : Icons.folder_open_rounded,
                    color: isSelected
                        ? AppConstants.accentPrimary
                        : AppConstants.textMuted,
                  ),
                  title: Text(
                    album.name,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppConstants.accentPrimary
                          : AppConstants.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: AppConstants.accentPrimary,
                        )
                      : null,
                  onTap: () => onSelected(album.name),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showNewAlbumDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'New Album',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
          decoration: InputDecoration(
            hintText: 'Album name',
            hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final formatted = MediaStorageService.capitalizeAlbumName(name);
                onSelected(formatted);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Map<PoseLandmarkType, Offset> smoothedPositions;
  final Map<PoseLandmarkType, double> smoothedLikelihoods;
  final Map<PoseLandmarkType, Offset>? averageGhostPose;
  final Size imageSize;
  final InputImageRotation rotation;
  final double boxWidth;
  final double boxHeight;
  final double previewRatio;
  final double cameraRatio;
  final bool isFrontCamera;

  PosePainter({
    required this.poses,
    required this.smoothedPositions,
    required this.smoothedLikelihoods,
    this.averageGhostPose,
    required this.imageSize,
    required this.rotation,
    required this.boxWidth,
    required this.boxHeight,
    required this.previewRatio,
    required this.cameraRatio,
    required this.isFrontCamera,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    if (poses.isEmpty && smoothedPositions.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    // 0. Draw GHOST Average Pose
    if (averageGhostPose != null && averageGhostPose!.isNotEmpty) {
      final ghostPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = Colors.white.withOpacity(0.75);
        
      final ghostJointPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.orange.withOpacity(0.75);

      void drawGhostLine(PoseLandmarkType t1, PoseLandmarkType t2) {
        final p1 = averageGhostPose![t1];
        final p2 = averageGhostPose![t2];
        if (p1 != null && p2 != null) {
          canvas.drawLine(_translateNormalized(p1), _translateNormalized(p2), ghostPaint);
        }
      }

      // Draw ghost connections (Standard limbs)
      drawGhostLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawGhostLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawGhostLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawGhostLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawGhostLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);
      drawGhostLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawGhostLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawGhostLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
      drawGhostLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawGhostLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
      drawGhostLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
      drawGhostLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

      // Draw ghost joints (Aggregating Head)
      Offset? ghostHead;
      int ghostHeadCount = 0;

      averageGhostPose!.forEach((type, pos) {
        if (type.index <= 10) {
           ghostHead = (ghostHead == null) ? pos : ghostHead! + pos;
           ghostHeadCount++;
        } else {
           canvas.drawCircle(_translateNormalized(pos), 4, ghostJointPaint);
        }
      });

      if (ghostHeadCount > 0 && ghostHead != null) {
        final avgGhostHead = Offset(ghostHead!.dx / ghostHeadCount, ghostHead!.dy / ghostHeadCount);
        canvas.drawCircle(_translateNormalized(avgGhostHead), 5, ghostJointPaint);
      }
    }

    // 1. Draw Skeleton Lines (Using smoothed data if available)
    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = smoothedPositions[type1];
      final p2 = smoothedPositions[type2];
      final l1 = smoothedLikelihoods[type1] ?? 0;
      final l2 = smoothedLikelihoods[type2] ?? 0;

      if (p1 != null && l1 > 0.3 && p2 != null && l2 > 0.3) {
        canvas.drawLine(
          _translateRaw(p1, canvasSize),
          _translateRaw(p2, canvasSize),
          paint,
        );
      }
    }

    // Arms
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Torso
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

    // Legs
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // 2. Draw Joints (Excluding granular facial points, using a single Head point)
    Offset? headPos;
    double headLikelihood = 0;
    int headCount = 0;

    smoothedPositions.forEach((type, pos) {
      final l = smoothedLikelihoods[type] ?? 0;
      if (l < 0.3) return;

      // Group facial points (Nose to Mouth)
      if (type.index <= 10) {
        headPos = (headPos == null) ? pos : headPos! + pos;
        headLikelihood += l;
        headCount++;
      } else {
        canvas.drawCircle(_translateRaw(pos, canvasSize), 4, jointPaint);
      }
    });

    if (headCount > 0 && headPos != null) {
      final avgHead = Offset(headPos!.dx / headCount, headPos!.dy / headCount);
      canvas.drawCircle(_translateRaw(avgHead, canvasSize), 5, jointPaint);
    }
  }

  Offset _translateRaw(Offset rawPos, Size canvasSize) {
    // Current width and height based on rotation
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;

    final double imgW = isRotated ? imageSize.height : imageSize.width;
    final double imgH = isRotated ? imageSize.width : imageSize.height;

    // 1. Normalize image coordinates (0..1)
    double normX = rawPos.dx / imgW;
    double normY = rawPos.dy / imgH;

    if (isFrontCamera) {
      normX = 1.0 - normX;
    }

    double fullWidth, fullHeight;
    if (cameraRatio > previewRatio) {
      fullHeight = boxHeight;
      fullWidth = boxHeight / cameraRatio;
    } else {
      fullWidth = boxWidth;
      fullHeight = boxWidth / cameraRatio;
    }

    double offsetX = (fullWidth - boxWidth) / 2;
    double offsetY = (fullHeight - boxHeight) / 2;

    double finalX = (normX * fullWidth) - offsetX;
    double finalY = (normY * fullHeight) - offsetY;

    return Offset(finalX, finalY);
  }

  Offset _translateNormalized(Offset norm) {
    // 1. Normalize mapping
    double normX = norm.dx;
    double normY = norm.dy;

    // ML Kit results for reference photos are fixed usually.
    // If we are currently using the FRONT camera, we need to flip the ghost
    // to match the mirrored preview.
    if (isFrontCamera) {
      normX = 1.0 - normX;
    }

    // Normalized (0..1) directly to our local sensor space
    double fullWidth, fullHeight;
    if (cameraRatio > previewRatio) {
      fullHeight = boxHeight;
      fullWidth = boxHeight / cameraRatio;
    } else {
      fullWidth = boxWidth;
      fullHeight = boxWidth / cameraRatio;
    }

    double offsetX = (fullWidth - boxWidth) / 2;
    double offsetY = (fullHeight - boxHeight) / 2;

    double finalX = (normX * fullWidth) - offsetX;
    double finalY = (normY * fullHeight) - offsetY;

    return Offset(finalX, finalY);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) => true;
}
