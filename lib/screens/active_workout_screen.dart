import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/day_workout.dart';
import '../models/exercise_instance.dart';
import '../models/exercise_set.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'day_editor_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../widgets/exercise_stats_dialog.dart';
import '../providers/exercise_library_provider.dart';
import '../services/media_storage_service.dart';
import 'camera_view_page.dart';
import '../widgets/timer_picker_dialog.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final DayWorkout day;
  final String? parentType;
  final String? parentId;

  const ActiveWorkoutScreen({
    super.key, 
    required this.day,
    this.parentType,
    this.parentId,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 1;
  final ValueNotifier<int> _restSeconds = ValueNotifier(0);
  final ValueNotifier<int> _activeTimerSeconds = ValueNotifier(0);
  final ValueNotifier<bool> _isActiveTimerRunning = ValueNotifier(false);
  bool _showActiveTimerOverlay = false;
  Timer? _timer;
  String _autoRestMode = 'off'; // 'off', '30s', '1m'
  bool _autoPlay = false;
  bool _isAutoEngaged = false;
  late List<ExerciseInstance> _exercises;
  late final PageController _pageController;
  final GlobalKey<_ActiveTimerWidgetState> _timerKey = GlobalKey<_ActiveTimerWidgetState>();

  @override
  void initState() {
    super.initState();
    _exercises = widget.day.exercises;
    _pageController = PageController(initialPage: _currentExerciseIndex);
    
    if (widget.day.startedDate == null || widget.day.completedSets == 0) {
      widget.day.startedDate = DateTime.now();
      // Recalculate percentages when starting a new routine
      context.read<WorkoutProvider>().recalculateIncompletePercentages(widget.day);
      Future.microtask(() => _saveProgress());
    } else {
      // Also recalculate when entering an ongoing routine to pick up any new maxes
      context.read<WorkoutProvider>().recalculateIncompletePercentages(widget.day);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _restSeconds.dispose();
    _activeTimerSeconds.dispose();
    _isActiveTimerRunning.dispose();
    super.dispose();
  }

  void _cycleAutoRest() {
    setState(() {
      if (_autoRestMode == 'off') {
        _autoRestMode = '30s';
      } else if (_autoRestMode == '30s') _autoRestMode = '1m';
      else _autoRestMode = 'off';
    });
    HapticFeedback.selectionClick();
  }

  void _startRest(int seconds) {
    _timer?.cancel();
    _restSeconds.value = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSeconds.value > 0) {
        _restSeconds.value--;
      } else {
        timer.cancel();
        // Auto-play next set if enabled and engaged
        if (_autoPlay && _isAutoEngaged && mounted) {
          // Use a small delay to ensure the UI has settled if we just transitioned exercises
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _timerKey.currentState?.autoStart();
          });
        }
      }
    });
  }

  void _cancelRest() {
    _timer?.cancel();
    _restSeconds.value = 0;
  }

  void _handleSetCheck(ExerciseSet set) {
    setState(() {
      set.isChecked = !set.isChecked;
    });

    if (set.isChecked) {
      HapticFeedback.mediumImpact();
      if (_autoRestMode == '30s') {
        _startRest(30);
      } else if (_autoRestMode == '1m') {
        _startRest(60);
      }
      
      // Auto-set completion date if finished
      if (_exercises.every((e) => e.isCompleted)) {
        widget.day.completedDate = DateTime.now();
      }
    }
    _saveProgress();
  }

  void _saveProgress() {
    final provider = context.read<WorkoutProvider>();
    if (widget.parentType == 'week' && widget.parentId != null) {
      final week = provider.scheduledWeeks.where((w) => w.id == widget.parentId).firstOrNull;
      if (week != null) provider.saveScheduledWeek(week);
    } else if (widget.parentType == 'program' && widget.parentId != null) {
      final program = provider.scheduledPrograms.where((p) => p.id == widget.parentId).firstOrNull;
      if (program != null) provider.saveScheduledProgram(program);
    } else {
      provider.saveScheduledDay(widget.day);
    }
  }

  void _nextExercise({bool isAuto = false}) {
    if (!isAuto) _cancelRest();
    if (_currentExerciseIndex < _exercises.length) {
      setState(() {
        _currentExerciseIndex++;
        if (!isAuto) _isAutoEngaged = false;
      });
      _pageController.jumpToPage(_currentExerciseIndex);
    }
  }

  void _prevExercise() {
    _cancelRest();
    if (_currentExerciseIndex > 0) {
      _cancelRest();
      setState(() {
        _currentExerciseIndex--;
        _isAutoEngaged = false;
      });
      _pageController.jumpToPage(_currentExerciseIndex);
    }
  }

  Future<bool> _onWillPop() async {
    if (_restSeconds.value > 0) {
      _cancelRest();
      return false;
    }
    _saveProgress();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final allCompleted = _exercises.every((e) => e.isCompleted);
    final canShowFinish = true;
    
    final currentEx = (_currentExerciseIndex > 0 && _currentExerciseIndex <= _exercises.length) 
        ? _exercises[_currentExerciseIndex - 1] 
        : null;

    final completedCount = _exercises.where((e) => e.isCompleted).length;
    final progress = _exercises.isEmpty ? 0.0 : completedCount / _exercises.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgSurface,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            widget.day.displayTitle.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.5,
              color: AppConstants.textMuted.withValues(alpha: 0.7),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.edit_note_rounded, color: AppConstants.accentPrimary, size: 24),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayEditorScreen(
                      day: widget.day,
                      parentType: widget.parentType,
                      parentId: widget.parentId,
                      isTemplate: false,
                    ),
                  ),
                );
                if (mounted) {
                  setState(() {
                    if (_currentExerciseIndex > _exercises.length) {
                      _currentExerciseIndex = _exercises.length;
                    }
                  });
                  _saveProgress();
                }
              },
              tooltip: 'Edit Workout Layout',
            ),
            IconButton(
              icon: Icon(Icons.camera_alt_rounded, color: AppConstants.accentPrimary, size: 24),
              onPressed: _openCamera,
              tooltip: 'Exercise Camera',
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          behavior: HitTestBehavior.opaque, // Full screen tap detection
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 0. Background Depth Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConstants.bgSurface,
                      AppConstants.bgDark,
                    ],
                  ),
                ),
              ),
              
              // 1. Content Area (Scrollable horizontal page view behind header)
              RepaintBoundary(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    _cancelRest();
                    setState(() {
                      _currentExerciseIndex = index;
                      _isAutoEngaged = false;
                    });
                    HapticFeedback.selectionClick();
                  },
                  itemCount: _exercises.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildWorkoutOverview();
                    if (index == _exercises.length + 1) return _buildFinishPage();
                    return _buildExerciseView(_exercises[index - 1]);
                  },
                ),
              ),

              // 2. Glass Header Overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _buildGlassHeader(currentEx, progress),
                ),
              ),

              // 3. Navigation Controls (Floating Bottom)
              _buildFloatingNav(currentEx),

              // 4. Rest Timer Overlay
              ValueListenableBuilder<int>(
                valueListenable: _restSeconds,
                builder: (context, restSecs, child) {
                  if (restSecs > 0) return _buildTimerOverlay(restSecs);
                  return const SizedBox.shrink();
                },
              ),

            // 5. Active Exercise Timer Overlay
            if (_showActiveTimerOverlay) // Use overlay state instead of running state
              _buildActiveTimerOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  void _editExercise(ExerciseInstance ex) {
    final nameController = TextEditingController(text: ex.exerciseName);
    final durationController = TextEditingController(text: ex.timerDurationSeconds.toString());
    TimerMode tempMode = ex.timerMode;
    bool tempWeighted = ex.isWeightedTimed;
    bool tempPercent = ex.usePercentage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: AppConstants.bgElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('EDIT EXERCISE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text('TIMER SETTINGS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppConstants.textMuted)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _modeBtn('NONE', tempMode == TimerMode.none, () => setSheetState(() => tempMode = TimerMode.none)),
                  const SizedBox(width: 8),
                  _modeBtn('STOPWATCH', tempMode == TimerMode.stopwatch, () => setSheetState(() => tempMode = TimerMode.stopwatch)),
                  const SizedBox(width: 8),
                  _modeBtn('COUNTDOWN', tempMode == TimerMode.countdown, () => setSheetState(() => tempMode = TimerMode.countdown)),
                ],
              ),
              if (tempMode == TimerMode.countdown) ...[
                const SizedBox(height: 37), // Increased spacing between timer and cards
                GestureDetector(
                  onTap: () async {
                    int initial = int.tryParse(durationController.text) ?? 60;
                    int? res = await TimerPickerDialog.show(ctx, initialSeconds: initial);
                    if (res != null) {
                      durationController.text = res.toString();
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Default Seconds', border: OutlineInputBorder()),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SwitchListTile(
               title: const Text('Weighted Timed'),
               value: tempWeighted,
               onChanged: (v) => setSheetState(() => tempWeighted = v),
               contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
               title: const Text('Use Percentage (%)'),
               value: tempPercent,
               onChanged: (v) => setSheetState(() => tempPercent = v),
               contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      ex.exerciseName = nameController.text.trim();
                      ex.timerMode = tempMode;
                      ex.timerDurationSeconds = int.tryParse(durationController.text) ?? 60;
                      ex.isWeightedTimed = tempWeighted;
                      ex.usePercentage = tempPercent;
                    });
                    _saveProgress();
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SAVE CHANGES'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppConstants.accentPrimary : AppConstants.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? AppConstants.accentPrimary : AppConstants.border),
          ),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: active ? Colors.white : AppConstants.textMuted)),
        ),
      ),
    );
  }

  void _openCamera() async {
    try {
      debugPrint('Camera Button: Pressed');
      final currentEx = (_currentExerciseIndex > 0 && _currentExerciseIndex <= _exercises.length) 
          ? _exercises[_currentExerciseIndex - 1] 
          : null;

      if (currentEx == null) {
        debugPrint('Camera Button: No specific exercise, defaulting to Camera');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraViewPage(initialAlbum: 'Camera')),
        );
        return;
      }

      final library = context.read<ExerciseLibraryProvider>();
      final def = library.getExerciseById(currentEx.exerciseDefinitionId);
      String targetAlbum = (def?.defaultAlbum.isNotEmpty == true) ? def!.defaultAlbum : 'Camera';
      debugPrint('Camera Button: Target Album is "$targetAlbum"');

      if (targetAlbum == 'Camera') {
        debugPrint('Camera Button: Using Camera folder directly');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraViewPage(initialAlbum: 'Camera')),
        );
        return;
      }

      final mediaStorage = context.read<MediaStorageService>();
      final albums = await mediaStorage.getAlbums();
      final exists = albums.any((a) => MediaStorageService.namesMatch(a.name, targetAlbum));
      debugPrint('Camera Button: Album exists on disk: $exists');

      if (!exists) {
        debugPrint('Camera Button: Showing Album Not Found dialog');
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppConstants.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Album Not Found', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppConstants.textPrimary)),
            content: Text('The designated album "$targetAlbum" does not exist. Would you like to create it now or save photos to the default "Camera" album?', style: GoogleFonts.inter(color: AppConstants.textMuted)),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text('CANCEL', style: GoogleFonts.inter(color: AppConstants.textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'default'),
                child: Text('USE DEFAULT', style: GoogleFonts.inter(color: AppConstants.accentPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.accentPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, 'create'),
                child: Text('CREATE', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        );

        debugPrint('Camera Button: User chose "$choice"');
        if (choice == 'create') {
          await mediaStorage.ensureAlbum(targetAlbum);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CameraViewPage(initialAlbum: targetAlbum)),
            );
          }
        } else if (choice == 'default') {
          if (def != null) {
            final updatedDef = def.copyWith(defaultAlbum: 'Camera');
            await library.updateExercise(updatedDef);
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraViewPage(initialAlbum: 'Camera')),
            );
          }
        }
        return;
      }

      // Album exists
      debugPrint('Camera Button: Navigating to CameraViewPage with "$targetAlbum"');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CameraViewPage(initialAlbum: targetAlbum)),
        );
      }
    } catch (e, stack) {
      debugPrint('Camera Button Error: $e');
      debugPrint(stack.toString());
    }
  }

  Widget _buildGlassHeader(ExerciseInstance? currentEx, double progress) {
    final topPadding = MediaQuery.of(context).padding.top + 56; // Status bar + AppBar height

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgSurface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: AppConstants.accentPrimary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Title & Tags Container
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.15)),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.accentPrimary.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_currentExerciseIndex == _exercises.length + 1) const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _currentExerciseIndex == 0 
                                            ? 'WORKOUT OVERVIEW' 
                                            : (_currentExerciseIndex == _exercises.length + 1 
                                                ? 'FINISH ROUTINE' 
                                                : (currentEx?.exerciseName.toUpperCase() ?? '')),
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                          color: (() {
                                            if (_currentExerciseIndex == 0) return AppConstants.progressProgram;
                                            if (_currentExerciseIndex == _exercises.length + 1) {
                                              return _exercises.every((e) => e.isCompleted) ? AppConstants.success : AppConstants.warning;
                                            }
                                            return AppConstants.accentPrimary;
                                          })(),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (currentEx != null && _currentExerciseIndex > 0 && _currentExerciseIndex <= _exercises.length) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.bar_chart_rounded, 
                                          size: 20, 
                                          color: (() {
                                            final level = context.watch<WorkoutProvider>().getExerciseDataLevel(currentEx.exerciseDefinitionId, currentEx.isTimed, currentEx.isWeightedTimed);
                                            if (level == 2) return AppConstants.progressDay;
                                            if (level == 1) return AppConstants.progressWeek;
                                            return AppConstants.textMuted.withValues(alpha: 0.3);
                                          })(),
                                        ),
                                        onPressed: () => showExerciseStatsDialog(
                                          context, 
                                          currentEx.exerciseDefinitionId, 
                                          currentEx.exerciseName, 
                                          currentEx.isTimed, 
                                          isWeightedTimed: currentEx.isWeightedTimed
                                        ),
                                        tooltip: 'Exercise Stats',
                                      ),
                                    ],
                                   ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          if (_currentExerciseIndex == 0) ...[
                            Text(
                              '${_exercises.length} EXERCISES • ${_exercises.fold(0, (sum, ex) => sum + ex.sets.length)} TOTAL SETS',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppConstants.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 24,
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                                    stops: const [0.0, 0.08, 0.92, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _exercises.expand((ex) => ex.exerciseTags).toSet().length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                                  itemBuilder: (context, index) {
                                    final tag = _exercises.expand((ex) => ex.exerciseTags).toSet().toList()[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.progressProgram.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppConstants.progressProgram.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        tag.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: AppConstants.progressProgram,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ]
                          else if (_currentExerciseIndex == _exercises.length + 1) ...[
                             SizedBox(
                               height: 38,
                               child: ShaderMask(
                                 shaderCallback: (Rect bounds) {
                                   return LinearGradient(
                                     begin: Alignment.centerLeft,
                                     end: Alignment.centerRight,
                                     colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                                     stops: const [0.0, 0.08, 0.92, 1.0],
                                   ).createShader(bounds);
                                 },
                                 blendMode: BlendMode.dstIn,
                                 child: ListView(
                                   scrollDirection: Axis.horizontal,
                                   physics: const BouncingScrollPhysics(),
                                   padding: const EdgeInsets.symmetric(horizontal: 12),
                                   children: [
                                     _buildHeaderInfoCard('START', widget.day.startedDate != null ? DateFormat('h:mm a').format(widget.day.startedDate!) : '--:--'),
                                     const SizedBox(width: 8),
                                     _buildHeaderInfoCard('END', DateFormat('h:mm a').format(DateTime.now())),
                                     const SizedBox(width: 8),
                                     _buildHeaderInfoCard('ELAPSED', Helpers.formatDurationLong(DateTime.now().difference(widget.day.startedDate ?? DateTime.now()).inSeconds)),
                                   ],
                                 ),
                               ),
                             ),
                          ]
                          else if (currentEx?.exerciseTags.isNotEmpty ?? false)
                            SizedBox(
                              height: 24,
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                                    stops: const [0.0, 0.08, 0.92, 1.0],
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.dstIn,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  itemCount: currentEx!.exerciseTags.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                                  itemBuilder: (context, index) {
                                    final tag = currentEx.exerciseTags[index];
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppConstants.accentPrimary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        tag.toUpperCase(),
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                          color: AppConstants.accentPrimary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Card Area: Timer Tools OR Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
                      child: Container(
                        height: 44, // Match Timer Tools height
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppConstants.bgCard.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _currentExerciseIndex == 0 || _currentExerciseIndex == _exercises.length + 1
                          ? Row(
                              children: [
                                Icon(Icons.analytics_outlined, size: 14, color: AppConstants.accentPrimary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor: AppConstants.accentPrimary.withValues(alpha: 0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accentPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppConstants.accentPrimary,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                // Autoplay Toggle
                                _buildHeaderTool(
                                  icon: _autoPlay ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
                                  label: 'AUTO-PLAY',
                                  isActive: _autoPlay,
                                  activeColor: AppConstants.accentSecondary,
                                  onTap: () => setState(() => _autoPlay = !_autoPlay),
                                ),
                                
                                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 12), color: AppConstants.border),

                                // Auto-Rest Mode Cycles
                                Expanded(
                                  child: _buildHeaderTool(
                                    icon: Icons.timer_outlined,
                                    label: 'REST: $_autoRestMode',
                                    isActive: _autoRestMode != 'off',
                                    activeColor: AppConstants.accentWarm,
                                    onTap: () {
                                      setState(() {
                                        if (_autoRestMode == 'off') {
                                          _autoRestMode = '30s';
                                        } else if (_autoRestMode == '30s') _autoRestMode = '1m';
                                        else _autoRestMode = 'off';
                                      });
                                    },
                                  ),
                                ),

                                Container(width: 1, height: 16, margin: const EdgeInsets.symmetric(horizontal: 12), color: AppConstants.border),

                                // Manual Timer Tools
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildHeaderTool(icon: Icons.history_rounded, label: '30s', isActive: false, onTap: () => _startRest(30)),
                                    const SizedBox(width: 8),
                                    _buildHeaderTool(icon: Icons.update_rounded, label: '1m', isActive: false, onTap: () => _startRest(60)),
                                  ],
                                ),
                              ],
                            ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // 3. Carousel Progress
                  _ExerciseCarousel(
                    exercises: _exercises,
                    currentIndex: _currentExerciseIndex,
                    onIndexChanged: (index) {
                      _cancelRest();
                      setState(() {
                        _currentExerciseIndex = index;
                        _isAutoEngaged = false;
                      });
                      if (_pageController.hasClients) {
                        _pageController.jumpToPage(index);
                      }
                      HapticFeedback.selectionClick();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderTool({required IconData icon, required String label, required bool isActive, required VoidCallback onTap, Color? activeColor}) {
    final finalActiveColor = activeColor ?? AppConstants.accentPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container( // Wrap in container to increase hit area
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? finalActiveColor : AppConstants.textMuted),
            const SizedBox(width: 4),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isActive ? finalActiveColor : AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExerciseView(ExerciseInstance ex) {
    final headerHeight = MediaQuery.of(context).padding.top + 280; // Added 25px extra spacing

    return SingleChildScrollView(
      key: ValueKey('exercise_view_$_currentExerciseIndex'),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppConstants.paddingMD, headerHeight, AppConstants.paddingMD, 100),
      child: Column(
        children: [
          if (ex.isTimed)
            _ActiveTimerWidget(
              key: _timerKey,
              exercise: ex,
              onChanged: () {
                if (mounted) setState(() {});
                _saveProgress();
              },
              autoPlay: _autoPlay,
              onManualStart: () => setState(() => _isAutoEngaged = true),
              onTick: (secs, running) {
                if (_activeTimerSeconds.value != secs) {
                  _activeTimerSeconds.value = secs;
                }
                if (_isActiveTimerRunning.value != running) {
                  _isActiveTimerRunning.value = running;
                }
                if (running && !_showActiveTimerOverlay) {
                  setState(() {
                    _showActiveTimerOverlay = true;
                  });
                }
              },
              onSetChecked: () {
                // Ensure the overlay closes so the rest timer can be seen
                if (mounted) {
                  setState(() => _showActiveTimerOverlay = false);
                }

                if (_autoPlay && _isAutoEngaged) {
                  if (ex.isCompleted) {
                    // Exercise completed, check for next exercise
                    if (_currentExerciseIndex < _exercises.length) {
                      _nextExercise(isAuto: true);
                      
                      // Start rest if mode is active
                      if (_autoRestMode == '30s') {
                        _startRest(30);
                      } else if (_autoRestMode == '1m') {
                        _startRest(60);
                      } else {
                        // No rest, start next exercise timer immediately (with small buffer)
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted && _isAutoEngaged) _timerKey.currentState?.autoStart();
                        });
                      }
                    } else {
                      // Last exercise completed, move to finish page
                      setState(() { _currentExerciseIndex++; });
                      _pageController.jumpToPage(_currentExerciseIndex);
                    }
                  } else {
                    // Not completed, just start rest for next set
                    if (_autoRestMode == '30s') {
                      _startRest(30);
                    } else if (_autoRestMode == '1m') {
                      _startRest(60);
                    } else {
                      // No rest, start next set immediately (with small buffer)
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && _isAutoEngaged) _timerKey.currentState?.autoStart();
                      });
                    }
                  }
                }
                _saveProgress();
              },
            ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1))),
                if (!ex.isTimed || ex.isWeightedTimed)
                  Expanded(child: Center(child: Text('REPS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 1)))),
                if (!ex.isTimed || ex.isWeightedTimed)
                  Expanded(child: Center(child: Text(ex.isWeightedTimed ? 'KG' : 'VALUE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 1)))),
                if (ex.isTimed)
                  Expanded(child: Center(child: Text('TIME', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 1)))),
                const SizedBox(width: 40),
              ],
            ),
          ),

          ...ex.sets.asMap().entries.map((entry) {
            final idx = entry.key;
            final set = entry.value;
            final isFirstUncompleted = !set.isChecked && (idx == 0 || ex.sets[idx - 1].isChecked);
            
            return _ActiveSetRow(
              setNumber: idx + 1,
              set: set,
              exercise: ex,
              isCurrent: isFirstUncompleted,
              onCheck: () => _handleSetCheck(set),
              onChanged: () {
                if (mounted) setState(() {});
                _saveProgress();
              },
              onRemove: () {
                setState(() {
                  ex.sets.removeAt(idx);
                });
                _saveProgress();
              },
            );
          }),

          TextButton(
            onPressed: () {
              setState(() {
                if (ex.sets.isNotEmpty) {
                  final newSet = ex.sets.last.deepCopy();
                  newSet.isChecked = false;
                  // Clear time if it's a stopwatch
                  if (ex.isTimed && ex.timerMode == TimerMode.stopwatch) {
                    newSet.timeSeconds = null;
                    newSet.value = null;
                  }
                  ex.sets.add(newSet);
                } else {
                  ex.sets.add(ExerciseSet());
                }
              });
              _saveProgress();
              HapticFeedback.lightImpact();
            },
            child: Text(
              '+ ADD SET',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, color: AppConstants.accentPrimary, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNav(ExerciseInstance? currentEx) {
    if (currentEx == null) return const SizedBox.shrink();
    final showNextBtn = currentEx.isCompleted && _currentExerciseIndex < _exercises.length - 1;

    return Positioned(
      bottom: 53, // Raised 25px + 8px from absolute bottom for optimal reach
      left: AppConstants.paddingMD,
      right: AppConstants.paddingMD,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Arrow
          _navBtnCompact(Icons.arrow_back_ios_new_rounded, _currentExerciseIndex > 0 ? _prevExercise : null),
          
          // Next Exercise Button (Center)
          if (showNextBtn)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _nextExercise,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppConstants.bgCard.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppConstants.accentPrimary.withValues(alpha: 0.5), 
                            width: 1.5
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'NEXT EXERCISE',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: AppConstants.accentPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_double_arrow_right_rounded, color: AppConstants.accentPrimary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const Spacer(),

          // Forward Arrow
          _navBtnCompact(
              Icons.arrow_forward_ios_rounded, 
              _currentExerciseIndex < (_exercises.length + 1)
                  ? () {
                      if (_currentExerciseIndex < _exercises.length) {
                        _nextExercise();
                      } else {
                        setState(() { _currentExerciseIndex++; });
                        _pageController.jumpToPage(_currentExerciseIndex);
                      }
                    } 
                  : null),
        ],
      ),
    );
  }

  Widget _buildWorkoutOverview() {
    final headerHeight = MediaQuery.of(context).padding.top + 280; // Added 25px extra spacing

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(AppConstants.paddingMD, headerHeight, AppConstants.paddingMD, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25),
          // Checklist Items (Spacing removed for seamless transition)
          ..._exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final ex = entry.value;
            final isDone = ex.isCompleted;
            final isPartial = ex.progress > 0 && !isDone;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDone 
                  ? AppConstants.completion.withValues(alpha: 0.15) 
                  : (isPartial ? AppConstants.warning.withValues(alpha: 0.15) : AppConstants.bgCard.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: isDone 
                    ? AppConstants.completion.withValues(alpha: 0.8) 
                    : (isPartial ? AppConstants.warning.withValues(alpha: 0.6) : AppConstants.border.withValues(alpha: 0.2)),
                  width: (isDone || isPartial) ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                dense: true,
                onTap: () {
                  setState(() {
                    _currentExerciseIndex = idx + 1;
                  });
                  _pageController.jumpToPage(_currentExerciseIndex);
                },
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone 
                        ? AppConstants.completion 
                        : (isPartial ? AppConstants.warning : AppConstants.textMuted.withValues(alpha: 0.3)),
                      width: 2,
                    ),
                    color: isDone 
                      ? AppConstants.completion.withValues(alpha: 0.1) 
                      : (isPartial ? AppConstants.warning.withValues(alpha: 0.1) : Colors.transparent),
                  ),
                  child: isDone 
                    ? Icon(Icons.check, size: 14, color: AppConstants.completion) 
                    : (isPartial ? Icon(Icons.adjust_rounded, size: 14, color: AppConstants.warning) : null),
                ),
                title: Text(
                  ex.exerciseName.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.w500 : FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                subtitle: Text(
                  Helpers.getExerciseSummary(
                    ex, 
                    showReps: false,
                    refWeight: ex.usePercentage 
                      ? context.read<WorkoutProvider>().getExerciseReferenceWeight(ex.exerciseDefinitionId) 
                      : null
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textMuted.withValues(alpha: 0.5),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => showExerciseStatsDialog(
                        context, 
                        ex.exerciseDefinitionId, 
                        ex.exerciseName, 
                        ex.isTimed, 
                        isWeightedTimed: ex.isWeightedTimed
                      ),
                      icon: Icon(
                        Icons.bar_chart_rounded, 
                        size: 18, 
                        color: context.watch<WorkoutProvider>().getExerciseStats(ex.exerciseDefinitionId).isNotEmpty
                            ? AppConstants.accentSecondary.withValues(alpha: 0.6)
                            : AppConstants.textMuted.withValues(alpha: 0.3),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.textMuted.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppConstants.accentPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 0.5)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionMsg(bool isLogged, bool allCompleted) {
    if (isLogged) return const SizedBox.shrink();
    if (allCompleted) {
      return Text(
        'Great job completing all exercises. Ready to log your hard work?',
        style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textMuted, height: 1.5),
        textAlign: TextAlign.center,
      );
    } else {
      return Text(
        'You still have some unfinished exercises! Finishing all exercises will automatically mark this routine as complete.',
        style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textMuted.withValues(alpha: 0.8), height: 1.5),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppConstants.accentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppConstants.textMuted)),
              ),
            ]
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.w900, color: AppConstants.textPrimary)),
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted)),
        ]
      )
    );
  }

  Widget _buildBarChart(String title, List<ExerciseInstance> exercises, double Function(ExerciseInstance) extractor, String unit, {Color? barColor}) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    final maxValue = exercises.map(extractor).fold(0.0, (m, v) => v > m ? v : m);
    if (maxValue == 0) return const SizedBox.shrink();

    String dispUnit;
    double magDivisor;
    if (unit == 'sec') {
      dispUnit = '';
      magDivisor = 1.0;
    } else {
      final info = Helpers.getMagnitudeInfo(maxValue);
      dispUnit = info.$1;
      magDivisor = info.$2;
    }
    final (roundedMax, axisInterval) = unit == 'sec' ? Helpers.getTimeAxisSpecs(maxValue, increments: 8) : Helpers.getAxisSpecs(maxValue, increments: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
          decoration: BoxDecoration(
            color: AppConstants.bgCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(color: AppConstants.border.withValues(alpha: 0.3)),
          ),
          child: SizedBox(
            height: 180, 
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                maxY: roundedMax, 
                barTouchData: BarTouchData(
                  enabled: false,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 0,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        unit == 'sec' ? Helpers.formatDurationLong(rod.toY.toInt()) : Helpers.formatWithMagnitude(rod.toY, magDivisor, dispUnit, precision: 1),
                        GoogleFonts.jetBrainsMono(color: AppConstants.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= exercises.length) return const SizedBox();
                        final name = exercises[value.toInt()].exerciseName;
                        final shortName = name.length > 5 ? name.substring(0, 5) : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(shortName.toUpperCase(), style: GoogleFonts.inter(color: AppConstants.textMuted, fontSize: 8, fontWeight: FontWeight.w900)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: unit == 'sec' ? 65 : 45,
                      interval: axisInterval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            unit == 'sec' ? Helpers.formatDurationLong(value.toInt()) : Helpers.formatWithMagnitude(value, magDivisor, dispUnit, precision: 1),
                            style: GoogleFonts.inter(fontSize: 9, color: AppConstants.textMuted, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: true,
                  horizontalInterval: axisInterval,
                  getDrawingHorizontalLine: (val) => FlLine(color: AppConstants.border.withValues(alpha: 0.05), strokeWidth: 1),
                  getDrawingVerticalLine: (val) => FlLine(color: AppConstants.border.withValues(alpha: 0.05), strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: AppConstants.border.withValues(alpha: 0.2)),
                    bottom: BorderSide(color: AppConstants.border.withValues(alpha: 0.2)),
                  ),
                ),
                barGroups: List.generate(exercises.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: [0],
                    barRods: [
                      BarChartRodData(
                        toY: extractor(exercises[i]),
                        color: barColor ?? AppConstants.accentSecondary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishPage() {
    final headerHeight = MediaQuery.of(context).padding.top + 280;
    final allCompleted = _exercises.every((e) => e.isCompleted);
    final isLogged = widget.day.isCompleted && widget.day.completedDate != null;

    if (!isLogged) {
      return Container(
        padding: EdgeInsets.fromLTRB(AppConstants.paddingMD, headerHeight, AppConstants.paddingMD, 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(
              allCompleted ? Icons.emoji_events_rounded : Icons.checklist_rounded,
              size: 100,
              color: allCompleted ? AppConstants.completion : AppConstants.accentPrimary,
            ),
            const SizedBox(height: 32),
            Text(
              allCompleted ? 'ROUTINE COMPLETE!' : 'FINISH ROUTINE?',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: allCompleted ? AppConstants.completion : AppConstants.accentPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              allCompleted 
                  ? 'Incredible work! Ready to log your hard work and see your stats?' 
                  : 'You still have some unfinished exercises! Finishing all exercises will automatically mark this routine as complete.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppConstants.textMuted.withValues(alpha: 0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: () {
                  if (allCompleted) {
                    setState(() {
                      widget.day.isCompleted = true;
                      widget.day.completedDate = DateTime.now();
                    });
                    _saveProgress();
                    HapticFeedback.heavyImpact();
                  } else {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppConstants.bgCard,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Finish Incomplete Routine?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppConstants.textPrimary)),
                        content: Text('Are you sure you want to finish this routine early? Incomplete sets and exercises will be saved, but won\'t contribute to your recorded volume.', style: GoogleFonts.inter(color: AppConstants.textMuted)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: TextStyle(color: AppConstants.textMuted))),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              setState(() {
                                widget.day.isCompleted = true;
                                widget.day.completedDate = DateTime.now();
                              });
                              _saveProgress();
                              HapticFeedback.heavyImpact();
                            },
                            style: FilledButton.styleFrom(backgroundColor: AppConstants.warning),
                            child: const Text('FINISH NOW'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: Icon(Icons.bolt_rounded, color: AppConstants.bgDark, size: 28),
                label: Text(
                  'FINISH ROUTINE',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppConstants.bgDark,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: allCompleted ? AppConstants.completion : AppConstants.warning,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 8,
                  shadowColor: (allCompleted ? AppConstants.completion : AppConstants.warning).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      );
    }

    // Calculated Stats
    int totalSets = 0;
    int completedSets = 0;
    double totalVolume = 0;
    double maxWeight = 0;

    for (var ex in _exercises) {
      totalSets += ex.sets.length;
      for (var set in ex.sets) {
        if (set.isChecked) {
          completedSets++;
          if (ex.isTimed) {
            if (ex.isWeightedTimed) {
              totalVolume += (set.weight ?? 0) * (set.timeSeconds ?? set.value ?? 0) * (set.reps ?? 1);
              if ((set.weight ?? 0) > maxWeight) maxWeight = set.weight!;
            }
          } else {
            totalVolume += (set.value ?? 0) * (set.reps ?? 1);
            if ((set.value ?? 0) > maxWeight) maxWeight = set.value!;
          }
        }
      }
    }

    int routineDurationSeconds = 0;
    if (widget.day.startedDate != null && widget.day.completedDate != null) {
      routineDurationSeconds = widget.day.completedDate!.difference(widget.day.startedDate!).inSeconds;
    }

    final weightExercises = _exercises.where((ex) => !ex.isTimed && ex.progress > 0).toList();
    final timeExercises = _exercises.where((ex) => ex.isTimed && !ex.isWeightedTimed && ex.progress > 0).toList();
    final weightTimeExercises = _exercises.where((ex) => ex.isWeightedTimed && ex.progress > 0).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(AppConstants.paddingMD, headerHeight, AppConstants.paddingMD, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary
          Center(
            child: Column(
              children: [
                const SizedBox(height: 23),
                _buildTypeTag(widget.parentType ?? 'day', allCompleted, showPartialLabel: true),
                const SizedBox(height: 16),
                Icon(
                  allCompleted ? Icons.check_circle_rounded : Icons.warning_rounded, 
                  size: 64, 
                  color: allCompleted ? AppConstants.completion : AppConstants.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  allCompleted ? 'WORKOUT LOGGED' : 'LOGGED INCOMPLETE', 
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: allCompleted ? AppConstants.completion : AppConstants.warning)
                ),
                const SizedBox(height: 8),
                Text(Helpers.formatDate(widget.day.completedDate!), style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
              ],
            )
          ),
          const SizedBox(height: 32),
          
          // Stat Grid
          Row(
            children: [
              Expanded(child: _buildStatCard('VOLUME', Helpers.formatCompactNumber(totalVolume), 'work output', Icons.fitness_center_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('SETS', '$completedSets / $totalSets', 'completed', Icons.layers_rounded)),
            ]
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatCard('MAX LIFT', Helpers.formatCompactNumber(maxWeight), 'heaviest set', Icons.emoji_events_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('DURATION', Helpers.formatDurationLong(routineDurationSeconds), 'total time', Icons.timer_rounded)),
            ]
          ),

          _buildBarChart('WEIGHT DISTRIBUTION', weightExercises, (ex) {
            double vol = 0;
            for (var s in ex.sets.where((s) => s.isChecked)) {
              vol += (s.value ?? 0) * (s.reps ?? 1);
            }
            return vol;
          }, 'vol', barColor: allCompleted ? null : AppConstants.warning),

          _buildBarChart('TIME DISTRIBUTION', timeExercises, (ex) {
            double time = 0;
            for (var s in ex.sets.where((s) => s.isChecked)) {
              time += (s.timeSeconds ?? s.value ?? 0);
            }
            return time;
          }, 'sec', barColor: allCompleted ? null : AppConstants.warning),

          _buildBarChart('WEIGHTED-TIME DISTRIBUTION', weightTimeExercises, (ex) {
            double wVol = 0;
            for (var s in ex.sets.where((s) => s.isChecked)) {
              wVol += (s.weight ?? 0) * (s.timeSeconds ?? s.value ?? 0) * (s.reps ?? 1);
            }
            return wVol;
          }, 'vol', barColor: allCompleted ? null : AppConstants.warning),

          const SizedBox(height: 32),
          Text('EXERCISE BREAKDOWN', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppConstants.textPrimary)),
          const SizedBox(height: 16),
          
          // Breakdown list
          ..._exercises.where((e) => e.progress > 0).map((ex) {
            double exVol = 0;
            int exTime = 0;
            for (var s in ex.sets.where((s) => s.isChecked)) {
              if (ex.isWeightedTimed) {
                exVol += (s.weight ?? 0) * (s.timeSeconds ?? s.value ?? 0) * (s.reps ?? 1);
                exTime += (s.timeSeconds ?? s.value?.toInt() ?? 0);
              } else if (ex.isTimed) {
                exTime += (s.timeSeconds ?? s.value?.toInt() ?? 0);
              } else {
                exVol += (s.value ?? 0) * (s.reps ?? 1);
              }
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.bgCard.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.border.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.exerciseName.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppConstants.textPrimary)),
                        const SizedBox(height: 4),
                        Text('${ex.sets.where((s) => s.isChecked).length} sets', style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted)),
                      ]
                    )
                  ),
                  if (exVol > 0)
                    FittedBox(fit: BoxFit.scaleDown, child: Text('${Helpers.formatCompactNumber(exVol)} vol', style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)))
                  else if (exTime > 0)
                    FittedBox(fit: BoxFit.scaleDown, child: Text(Helpers.formatDurationLong(exTime), style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w800, color: AppConstants.accentPrimary))),
                ]
              )
            );
          }),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppConstants.accentPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('RETURN TO HOME', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1, color: AppConstants.accentPrimary)),
            ),
          )
        ]
      )
    );
  }

  Widget _buildTypeTag(String type, bool isComplete, {bool showPartialLabel = false}) {
    final color = isComplete ? AppConstants.completion : AppConstants.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            type.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (!isComplete && showPartialLabel) ...[
          const SizedBox(width: 8),
          Text(
            'PARTIALLY COMPLETE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppConstants.warning,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _navBtnCompact(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: AppConstants.animFast,
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: enabled 
                  ? AppConstants.bgCard.withValues(alpha: 0.5) 
                  : AppConstants.bgSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: enabled 
                    ? AppConstants.accentPrimary.withValues(alpha: 0.3) 
                    : AppConstants.border.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                if (enabled)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
              ],
            ),
            child: Icon(
              icon, 
              size: 20, 
              color: enabled ? AppConstants.accentPrimary : AppConstants.textMuted.withValues(alpha: 0.2)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTimerOverlay() {
    // Adjust index because _currentExerciseIndex 0 is the Overview page
    final currentEx = _exercises[_currentExerciseIndex - 1];
    final isCountdown = currentEx.timerMode == TimerMode.countdown;

    return Stack(
      children: [
        // Outer layer: Tap to pause/close
        GestureDetector(
          onTap: () {
            _timerKey.currentState?.onExit();
            setState(() => _showActiveTimerOverlay = false);
          },
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppConstants.bgElevated,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.accentPrimary.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentEx.exerciseName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppConstants.accentPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCountdown ? 'TIME REMAINING' : 'ELAPSED TIME',
                  style: GoogleFonts.inter(
                    color: AppConstants.textMuted,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<int>(
                  valueListenable: _activeTimerSeconds,
                  builder: (context, secs, _) {
                    return Text(
                      Helpers.formatDuration(secs),
                      style: GoogleFonts.jetBrainsMono(
                        color: AppConstants.accentPrimary, // Changed from warm as requested
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<bool>(
                  valueListenable: _isActiveTimerRunning,
                  builder: (context, isRunning, _) {
                    return GestureDetector(
                      onTap: () {
                        // Tapping the button now toggles without closing
                        _timerKey.currentState?._toggleTimer();
                      },
                      child: Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: (isRunning ? AppConstants.accentSecondary : AppConstants.accentPrimary).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: (isRunning ? AppConstants.accentSecondary : AppConstants.accentPrimary).withValues(alpha: 0.5)),
                        ),
                        child: Icon(
                          isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, 
                          color: isRunning ? AppConstants.accentSecondary : AppConstants.accentPrimary, 
                          size: 28
                        ),
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerOverlay(int restSecs) {
    return GestureDetector(
      onTap: _cancelRest,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          color: Colors.black.withValues(alpha: 0.8),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RESTING',
                style: GoogleFonts.inter(
                  color: AppConstants.accentPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 10,
                ),
              ),
              Text(
                '${restSecs}s',
                style: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.w200,
                ),
              ),
              const SizedBox(height: 24),
              const Text('TAP TO SKIP REST', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Active Set Row ───────────────────────────────────────────────────

class _ActiveSetRow extends StatelessWidget {
  final int setNumber;
  final ExerciseSet set;
  final ExerciseInstance exercise;
  final bool isCurrent;
  final VoidCallback onCheck;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ActiveSetRow({
    required this.setNumber,
    required this.set,
    required this.exercise,
    this.isCurrent = false,
    required this.onCheck,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isTimed = exercise.isTimed;
    final isWeightedTimed = exercise.isWeightedTimed;

    return GestureDetector(
      onLongPressStart: (details) async {
        final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromRect(
            details.globalPosition & const Size(1, 1),
            Offset.zero & overlay.size,
          ),
          color: AppConstants.bgElevated,
          items: [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: AppConstants.error, size: 16),
                  const SizedBox(width: 8),
                  Text('Delete Set', style: GoogleFonts.inter(fontSize: 13, color: AppConstants.error)),
                ],
              ),
            ),
          ],
        );
        if (result == 'delete') {
          onRemove();
        }
      },
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: set.isChecked 
              ? AppConstants.completion.withValues(alpha: 0.15) 
              : (isCurrent ? AppConstants.accentPrimary.withValues(alpha: 0.05) : AppConstants.bgCard.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: set.isChecked 
                ? AppConstants.completion.withValues(alpha: 0.8) 
                : (isCurrent ? AppConstants.accentPrimary.withValues(alpha: 0.6) : AppConstants.accentPrimary.withValues(alpha: 0.1)),
            width: isCurrent || set.isChecked ? 2 : 1.5,
          ),
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: AppConstants.accentPrimary.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: set.isChecked 
                  ? AppConstants.completion.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$setNumber',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: set.isChecked 
                    ? AppConstants.completion 
                    : (isCurrent ? AppConstants.accentPrimary : AppConstants.accentPrimary.withValues(alpha: 0.3)),
                ),
              ),
            ),
            
            if (!isTimed || isWeightedTimed)
              Expanded(
                child: _ActiveEntryCompact(
                  value: set.reps?.toString() ?? '',
                  hint: '0',
                  onChanged: (v) {
                    set.reps = int.tryParse(v);
                    onChanged();
                  },
                ),
              ),
            
            if (!isTimed || isWeightedTimed) const SizedBox(width: 8),

            if (!isTimed || isWeightedTimed)
              Expanded(
                child: _ActiveEntryCompact(
                  value: isWeightedTimed 
                      ? (set.weight?.toInt().toString() ?? '')
                      : (set.value?.toInt().toString() ?? ''),
                  hint: '0',
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    final provider = context.read<WorkoutProvider>();
                    final refWeight = provider.getExerciseReferenceWeight(exercise.exerciseDefinitionId);

                    if (isWeightedTimed) {
                      set.weight = val;
                    } else {
                      set.value = val;
                    }

                    // Sync percentage if reference weight is known
                    if (val != null && refWeight != null && refWeight > 0) {
                      set.percent = (val / refWeight * 100);
                    }

                    onChanged();
                  },
                ),
              ),
            
            if (!isTimed || isWeightedTimed) const SizedBox(width: 8),

            if (isTimed)
              Expanded(
                child: _ActiveEntryCompact(
                  value: set.timeSeconds?.toString() ?? (set.value?.toInt().toString() ?? ''),
                  hint: '0',
                  isTimeField: true,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    set.timeSeconds = val;
                    if (val != null) set.value = val.toDouble();
                    onChanged();
                  },
                ),
              ),
            
            const SizedBox(width: 12),

            GestureDetector(
              onTap: onCheck,
              child: AnimatedContainer(
                duration: AppConstants.animMedium,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: set.isChecked ? AppConstants.completedGradient : null,
                  color: set.isChecked ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: set.isChecked ? Colors.transparent : AppConstants.accentPrimary.withValues(alpha: 0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    if (set.isChecked)
                      BoxShadow(
                        color: AppConstants.completion.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: set.isChecked ? Colors.white : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveEntryCompact extends StatefulWidget {
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool isTimeField;

  const _ActiveEntryCompact({
    required this.value,
    required this.hint,
    required this.onChanged,
    this.isTimeField = false,
  });

  @override
  State<_ActiveEntryCompact> createState() => _ActiveEntryCompactState();
}

class _ActiveEntryCompactState extends State<_ActiveEntryCompact> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _ActiveEntryCompact oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (mounted) setState(() {});
      },
      child: Builder(
        builder: (ctx) {
          final hasFocus = Focus.of(ctx).hasFocus;
          return AnimatedContainer(
            duration: AppConstants.animFast,
            height: 36,
            decoration: BoxDecoration(
              color: hasFocus 
                  ? AppConstants.accentPrimary.withValues(alpha: 0.15) 
                  : AppConstants.bgSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFocus 
                    ? AppConstants.accentPrimary 
                    : AppConstants.accentPrimary.withValues(alpha: 0.1),
                width: hasFocus ? 1.5 : 1,
              ),
              boxShadow: [
                if (hasFocus)
                  BoxShadow(
                    color: AppConstants.accentPrimary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
              ],
            ),
            child: TextField(
              controller: _controller,
              readOnly: widget.isTimeField,
              onTap: widget.isTimeField ? () async {
                final int initial = int.tryParse(_controller.text) ?? 0;
                final result = await TimerPickerDialog.show(context, initialSeconds: initial);
                if (result != null) {
                  _controller.text = result.toString();
                  widget.onChanged(result.toString());
                }
              } : null,
              onChanged: widget.isTimeField ? null : widget.onChanged,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.jetBrainsMono(
                color: hasFocus ? AppConstants.textPrimary : AppConstants.accentPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(color: AppConstants.accentPrimary.withValues(alpha: 0.2)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActiveTimerWidget extends StatefulWidget {
  final ExerciseInstance exercise;
  final VoidCallback onChanged;
  final bool autoPlay;
  final VoidCallback? onManualStart;
  final Function(int, bool)? onTick;
  final VoidCallback? onSetChecked;

  const _ActiveTimerWidget({
    super.key,
    required this.exercise,
    required this.onChanged,
    this.autoPlay = false,
    this.onManualStart,
    this.onTick,
    this.onSetChecked,
  });

  @override
  State<_ActiveTimerWidget> createState() => _ActiveTimerWidgetState();
}

class _ActiveTimerWidgetState extends State<_ActiveTimerWidget> {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isRunning = false;
  late int _originalSeconds;

  void autoStart() {
    if (!_isRunning) {
      _start();
    }
  }

  @override
  void initState() {
    super.initState();
    _syncDuration();
  }

  @override
  void didUpdateWidget(_ActiveTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 1. Sync if exercise changed
    // 2. Sync if the next uncompleted time changed and we aren't running (this handles external set edits)
    // Use _originalSeconds as the comparison because the exercise object is mutated in-place
    final nextTime = widget.exercise.nextUncompletedTime;
    
    if (oldWidget.exercise.id != widget.exercise.id || (nextTime != _originalSeconds && !_isRunning)) {
      _syncDuration();
      // Notify parent/overlays of the change immediately
      widget.onTick?.call(_currentSeconds, _isRunning);
    }
  }

  void _syncDuration() {
    if (widget.exercise.timerMode == TimerMode.countdown) {
      _originalSeconds = widget.exercise.nextUncompletedTime;
      _currentSeconds = _originalSeconds;
    } else {
      // Stopwatch always starts at 0 and doesn't "preload"
      _originalSeconds = 0;
      _currentSeconds = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pause();
    } else {
      widget.onManualStart?.call();
      _start();
    }
  }

  void _showDurationPicker() async {
    int? newSeconds = await TimerPickerDialog.show(context, initialSeconds: _originalSeconds);

    if (newSeconds != null && mounted) {
      if (_isRunning) _pause();
      setState(() {
        _originalSeconds = newSeconds;
        _currentSeconds = newSeconds;
        // Bi-directional sync: Update the next uncompleted set's data
        for (var set in widget.exercise.sets) {
          if (!set.isChecked) {
            set.timeSeconds = newSeconds;
            // Repurpose 'value' as time for timed exercises
            set.value = newSeconds.toDouble();
            break;
          }
        }
        widget.exercise.timerDurationSeconds = newSeconds;
      });
      widget.onChanged();
      widget.onTick?.call(_currentSeconds, _isRunning);
    }
  }

  void _start() {
    setState(() => _isRunning = true);
    widget.onTick?.call(_currentSeconds, _isRunning);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (widget.exercise.timerMode == TimerMode.countdown) {
          if (_currentSeconds > 0) _currentSeconds--;
          if (_currentSeconds == 0) {
            _pause();
            _autoCheckSet();
          }
        } else {
          _currentSeconds++;
        }
      });
      widget.onTick?.call(_currentSeconds, _isRunning);
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
    widget.onTick?.call(_currentSeconds, _isRunning);
    // Removed autoCheckSet from here to allow resuming
  }

  void onExit() {
    // If it's a stopwatch and it was running or had progress, we finish the set when closing the popup
    if (widget.exercise.timerMode == TimerMode.stopwatch && _currentSeconds > 0) {
      _autoCheckSet();
    }
    _pause();
  }

  void _autoCheckSet() {
    int finalTime = _currentSeconds;
    // For countdown, if it finished at 0, we log the target duration
    if (widget.exercise.timerMode == TimerMode.countdown && _currentSeconds == 0) {
      finalTime = _originalSeconds;
    }

    for (final set in widget.exercise.sets) {
      if (!set.isChecked) {
        set.isChecked = true;
        set.value = finalTime.toDouble();
        set.timeSeconds = finalTime;
        HapticFeedback.heavyImpact();
        break;
      }
    }
    if (widget.exercise.timerMode == TimerMode.stopwatch) {
      _currentSeconds = 0;
    } else {
      _syncDuration(); // Autoset for next set only for countdowns
    }
    
    widget.onChanged();
    widget.onTick?.call(_currentSeconds, _isRunning);
    widget.onSetChecked?.call();
  }

  @override
  Widget build(BuildContext context) {
    final timerColor = AppConstants.accentPrimary; // Always primary as requested
    final isCountdown = widget.exercise.timerMode == TimerMode.countdown;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: timerColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: timerColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _showDurationPicker,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  isCountdown ? Icons.hourglass_bottom_rounded : Icons.timer_rounded, 
                  size: 18, 
                  color: timerColor.withValues(alpha: 0.6)
                ),
                const SizedBox(width: 12),
                Text(
                  Helpers.formatDuration(_currentSeconds),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                    color: _isRunning ? timerColor : AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleTimer,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_isRunning ? AppConstants.accentSecondary : AppConstants.accentPrimary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _isRunning ? AppConstants.accentSecondary : AppConstants.accentPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCarousel extends StatefulWidget {
  final List<ExerciseInstance> exercises;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const _ExerciseCarousel({
    required this.exercises,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  State<_ExerciseCarousel> createState() => _ExerciseCarouselState();
}

class _ExerciseCarouselState extends State<_ExerciseCarousel> {
  late ScrollController _scrollController;
  final double itemWidth = 45.0;
  final double margin = 8.0;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(widget.currentIndex, animate: false, triggerCallback: false);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_ExerciseCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && 
        !_isAutoScrolling && 
        !_scrollController.position.isScrollingNotifier.value) {
      _scrollToIndex(widget.currentIndex, animate: true, triggerCallback: false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isAutoScrolling) return;

    final centerOffset = _scrollController.offset;
    final newIndex = (centerOffset / (itemWidth + margin)).round();
    
    final maxIndex = widget.exercises.length + 1;
    final clampedIndex = newIndex.clamp(0, maxIndex);
    
    if (clampedIndex != widget.currentIndex) {
      widget.onIndexChanged(clampedIndex);
    }
  }

  void _scrollToIndex(int index, {bool animate = false, bool triggerCallback = true}) {
    if (!_scrollController.hasClients) return;
    final target = index * (itemWidth + margin);
    _isAutoScrolling = true;
    
    if (animate) {
      _scrollController.animateTo(
        target.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: AppConstants.animFast,
        curve: Curves.easeOutCubic,
      ).then((_) {
        _isAutoScrolling = false;
        if (triggerCallback && index != widget.currentIndex) {
          widget.onIndexChanged(index);
        }
      });
    } else {
      _scrollController.jumpTo(target.clamp(0.0, _scrollController.position.maxScrollExtent));
      _isAutoScrolling = false;
      if (triggerCallback && index != widget.currentIndex) {
        widget.onIndexChanged(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // Increased for scaling safety
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            if (!_isAutoScrolling) {
              _scrollToIndex(widget.currentIndex, animate: true, triggerCallback: false);
            }
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 2 - 22.5),
          itemCount: widget.exercises.length + 2,
          itemBuilder: (context, index) {
            return _CarouselItem(
              index: index,
              scrollController: _scrollController,
              isCurrent: index == widget.currentIndex,
              ex: (index == 0 || index == widget.exercises.length + 1) ? null : widget.exercises[index - 1],
              isFinish: index == widget.exercises.length + 1,
              allDone: widget.exercises.every((e) => e.isCompleted),
              anyDone: widget.exercises.any((e) => e.progress > 0),
              itemWidth: itemWidth,
              margin: margin,
              onTap: () => _scrollToIndex(index),
            );
          },
        ),
      ),
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final int index;
  final ScrollController scrollController;
  final bool isCurrent;
  final ExerciseInstance? ex; // Null for index 0 (Overview) and N+1 (Finish)
  final bool isFinish;
  final bool allDone;
  final bool anyDone;
  final double itemWidth;
  final double margin;
  final VoidCallback onTap;

  const _CarouselItem({
    required this.index,
    required this.scrollController,
    required this.isCurrent,
    required this.ex,
    this.isFinish = false,
    this.allDone = false,
    this.anyDone = false,
    required this.itemWidth,
    required this.margin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final scrollOffset = scrollController.hasClients ? scrollController.offset : 0.0;
        final itemCenter = index * (itemWidth + margin);
        final distance = (itemCenter - scrollOffset).abs();
        final scale = (1.2 - (distance / 180)).clamp(0.85, 1.2);

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Transform.scale(
            scale: scale,
            child: RepaintBoundary(
              child: Container(
                width: itemWidth,
                margin: EdgeInsets.only(right: margin),
                decoration: BoxDecoration(
                  gradient: isCurrent 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: index == 0 
                              ? [AppConstants.progressProgram, AppConstants.progressProgram.withValues(alpha: 0.7)]
                              : (isFinish 
                                  ? (allDone 
                                      ? [AppConstants.success, AppConstants.success.withValues(alpha: 0.7)]
                                      : (anyDone 
                                          ? [AppConstants.warning, AppConstants.warning.withValues(alpha: 0.7)]
                                          : [AppConstants.accentPrimary, AppConstants.accentPrimary.withValues(alpha: 0.7)]))
                                  : [AppConstants.accentPrimary, AppConstants.accentPrimary.withValues(alpha: 0.7)]),
                        )
                      : null,
                  color: isCurrent 
                      ? null 
                      : (index == 0 
                          ? AppConstants.progressProgram.withValues(alpha: 0.1)
                          : (isFinish 
                              ? (allDone 
                                  ? AppConstants.success.withValues(alpha: 0.1) 
                                  : (anyDone 
                                      ? AppConstants.warning.withValues(alpha: 0.1) 
                                      : AppConstants.bgSurface.withValues(alpha: 0.3)))
                              : (ex?.isCompleted ?? false 
                                  ? AppConstants.completion.withValues(alpha: 0.1) 
                                  : ((ex?.progress ?? 0) > 0 
                                      ? AppConstants.warning.withValues(alpha: 0.1) 
                                      : AppConstants.bgSurface.withValues(alpha: 0.3))))),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent 
                        ? (index == 0 
                            ? AppConstants.progressProgram 
                            : (isFinish 
                                ? (allDone 
                                    ? AppConstants.success 
                                    : (anyDone ? AppConstants.warning : AppConstants.accentPrimary))
                                : AppConstants.accentPrimary))
                        : (index == 0 
                            ? AppConstants.progressProgram.withValues(alpha: 0.4)
                            : (isFinish 
                                ? (allDone 
                                    ? AppConstants.success.withValues(alpha: 0.4) 
                                    : (anyDone 
                                        ? AppConstants.warning.withValues(alpha: 0.4) 
                                        : AppConstants.accentPrimary.withValues(alpha: 0.1)))
                                : (ex?.isCompleted ?? false 
                                    ? AppConstants.completion.withValues(alpha: 0.4) 
                                    : ((ex?.progress ?? 0) > 0
                                        ? AppConstants.warning.withValues(alpha: 0.4) 
                                        : AppConstants.accentPrimary.withValues(alpha: 0.1))))),
                    width: isCurrent ? 2.0 : 1,
                  ),
                  boxShadow: [
                    if (isCurrent)
                      BoxShadow(
                        color: (index == 0 
                            ? AppConstants.progressProgram 
                            : (isFinish 
                                ? (allDone 
                                    ? AppConstants.success 
                                    : (anyDone ? AppConstants.warning : AppConstants.accentPrimary))
                                : AppConstants.accentPrimary)).withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                  ],
                ),
                child: Center(
                  child: index == 0 
                  ? Icon(
                      Icons.menu_rounded, 
                      size: 18, 
                      color: isCurrent ? Colors.white : AppConstants.textMuted
                    )
                  : (isFinish 
                      ? Icon(
                          Icons.flag_rounded,
                          size: 18,
                          color: isCurrent 
                              ? Colors.white 
                              : AppConstants.textMuted
                        )
                      : Text(
                          '$index',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isCurrent 
                                ? Colors.white 
                                : (ex?.isCompleted ?? false 
                                    ? AppConstants.completion 
                                    : ((ex?.progress ?? 0) > 0 
                                        ? AppConstants.warning 
                                        : AppConstants.textMuted)),
                          ),
                        )),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
