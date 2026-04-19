import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/day_workout.dart';
import '../models/exercise_instance.dart';
import '../models/exercise_definition.dart';
import '../models/exercise_set.dart';
import '../providers/exercise_library_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/tag_selection_sheet.dart';
import '../widgets/exercise_stats_dialog.dart';
import '../widgets/timer_picker_dialog.dart';

class DayEditorScreen extends StatefulWidget {
  final DayWorkout day;
  final String? parentType;
  final String? parentId;
  final bool isTemplate;
  final bool isDraft;
  final VoidCallback? onNestedSave;

  const DayEditorScreen({
    super.key,
    required this.day,
    this.parentType,
    this.parentId,
    this.isTemplate = false,
    this.isDraft = false,
    this.onNestedSave,
  });

  @override
  State<DayEditorScreen> createState() => _DayEditorScreenState();
}

class _DayEditorScreenState extends State<DayEditorScreen> {
  late DayWorkout _day;
  late bool _isDraft;

  @override
  void initState() {
    super.initState();
    _day = widget.day;
    _isDraft = widget.isDraft;
  }

  void _save() {
    if (_isDraft) return; // Do not auto-save if it's a draft

    if (widget.onNestedSave != null) {
      widget.onNestedSave!();
    } else if (widget.isTemplate) {
      context.read<WorkoutProvider>().saveDayTemplate(_day);
    } else {
      // Save as scheduled
      final provider = context.read<WorkoutProvider>();
      if (widget.parentType == 'week' && widget.parentId != null) {
        // Find the week and save it
        final week = provider.scheduledWeeks
            .where((w) => w.id == widget.parentId)
            .firstOrNull;
        if (week != null) {
          provider.saveScheduledWeek(week);
        }
      } else if (widget.parentType == 'program' && widget.parentId != null) {
        final program = provider.scheduledPrograms
            .where((p) => p.id == widget.parentId)
            .firstOrNull;
        if (program != null) {
          provider.saveScheduledProgram(program);
        }
      } else {
        provider.saveScheduledDay(_day);
      }
    }
  }

  void _autoComplete() {
    _save();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return PopScope(
      canPop: !_isDraft,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Discard Unsaved Workout?'),
            content: const Text(
              'You have not scheduled this one-shot workout yet. If you go back, your progress will be lost.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppConstants.error,
                ),
                child: const Text('Discard'),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _day.displayTitle,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_isDraft)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  onPressed: _scheduleDraft,
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: const Text('Schedule'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            // Description
            if (_day.description != null && _day.description!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.bgSurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Text(
                  _day.description!,
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

            // Progress bar
            if (_day.exercises.isNotEmpty && !widget.isTemplate) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.paddingMD,
                  AppConstants.paddingSM,
                  AppConstants.paddingMD,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _day.progress),
                          duration: AppConstants.animMedium,
                          builder: (_, value, child) => LinearProgressIndicator(
                            value: value,
                            backgroundColor: AppConstants.bgSurface,
                            valueColor: AlwaysStoppedAnimation(
                              _day.isCompleted
                                  ? AppConstants.completion
                                  : AppConstants.progressDay,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Helpers.progressPercent(_day.progress),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _day.isCompleted
                            ? AppConstants.completion
                            : AppConstants.progressDay,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Exercise list
            Expanded(
              child: _day.exercises.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 140),
                      itemCount: _day.exercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _day.exercises.removeAt(oldIndex);
                          _day.exercises.insert(newIndex, item);
                        });
                        _save();
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, _) {
                            return Material(
                              color: Colors.transparent,
                              elevation: 6,
                              shadowColor: AppConstants.accentPrimary
                                  .withValues(alpha: 0.3),
                              child: child,
                            );
                          },
                        );
                      },
                      itemBuilder: (context, index) {
                        return _ExerciseCard(
                          key: ValueKey(_day.exercises[index].id),
                          exercise: _day.exercises[index],
                          onChanged: () {
                            setState(() {});
                            _autoComplete();
                          },
                          onRemove: () {
                            setState(() {
                              _day.exercises.removeAt(index);
                            });
                            _save();
                          },
                          isTemplate: widget.isTemplate,
                          isDraft: _isDraft,
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0 
            ? null 
            : FloatingActionButton.extended(
          heroTag: 'day_editor_add_exercise_fab',
          onPressed: _showAddExerciseDialog,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Add Exercise',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            size: 56,
            color: AppConstants.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No exercises yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add exercises from your library',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog() {
    final library = context.read<ExerciseLibraryProvider>();
    String search = '';
    final Set<String> newlyAdded = _day.exercises.map((e) => e.exerciseDefinitionId).toSet();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final filtered = library.exercises.where((e) {
            final q = Helpers.toUniquenessKey(search);
            if (q.isEmpty) return true;
            return Helpers.toUniquenessKey(e.name).contains(q) ||
                e.tags.any((tag) => Helpers.toUniquenessKey(tag).contains(q));
          }).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppConstants.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMD),
                  child: Text(
                    'Add Exercise',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMD,
                  ),
                  child: TextField(
                    onChanged: (v) => setSheetState(() => search = v),
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppConstants.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSM,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Create new exercise button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMD,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCreateExerciseDialog();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Create New Exercise',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No exercises found.\nTry creating one above.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppConstants.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final ex = filtered[i];
                            return ListTile(
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: AppConstants.accentGradient,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.fitness_center_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                ex.name,
                                style: GoogleFonts.inter(
                                  color: AppConstants.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: ex.tags.isNotEmpty
                                  ? Text(
                                      ex.tags.join(', '),
                                      style: GoogleFonts.inter(
                                        color: AppConstants.textMuted,
                                        fontSize: 12,
                                      ),
                                    )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.bar_chart_rounded,
                                      size: 20,
                                      color: (() {
                                        final level = context.watch<WorkoutProvider>().getExerciseDataLevel(ex.id, false, false);
                                        if (level == 2) return AppConstants.progressDay;
                                        if (level == 1) return AppConstants.progressWeek;
                                        return AppConstants.textMuted.withValues(alpha: 0.3);
                                      })(),
                                    ),
                                    onPressed: () {
                                      showExerciseStatsDialog(
                                        context,
                                        ex.id,
                                        ex.name,
                                        false,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _ShakeIconButton(
                                    key: ValueKey('add_btn_${ex.id}'),
                                    icon: newlyAdded.contains(ex.id) 
                                        ? Icons.check_circle_rounded 
                                        : Icons.add_circle_rounded,
                                    color: newlyAdded.contains(ex.id) 
                                        ? AppConstants.completion 
                                        : AppConstants.accentPrimary,
                                    onTap: () {
                                      setState(() {
                                        _day.exercises.add(
                                          ExerciseInstance(
                                            exerciseDefinitionId: ex.id,
                                            exerciseName: ex.name,
                                            exerciseTags: List.from(ex.tags),
                                            timerMode: TimerMode.values[max(0, min(ex.timerMode, TimerMode.values.length - 1))],
                                            timerDurationSeconds: ex.timerDurationSeconds,
                                            usePercentage: ex.usePercentage,
                                            isWeightedTimed: ex.isWeightedTimed,
                                          ),
                                        );
                                      });
                                      setSheetState(() {
                                        newlyAdded.add(ex.id);
                                      });
                                      _save();
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _day.exercises.add(
                                    ExerciseInstance(
                                      exerciseDefinitionId: ex.id,
                                      exerciseName: ex.name,
                                      exerciseTags: List.from(ex.tags),
                                      timerMode: TimerMode.values[max(0, min(ex.timerMode, TimerMode.values.length - 1))],
                                      timerDurationSeconds: ex.timerDurationSeconds,
                                      usePercentage: ex.usePercentage,
                                      isWeightedTimed: ex.isWeightedTimed,
                                    ),
                                  );
                                });
                                setSheetState(() {
                                  newlyAdded.add(ex.id);
                                });
                                _save();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateExerciseDialog() {
    final nameController = TextEditingController();
    final library = context.read<ExerciseLibraryProvider>();
    List<String> selectedTags = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: GoogleFonts.inter(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(hintText: 'Exercise name'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tags',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text(
                        'Select Tags',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final tags = await TagSelectionSheet.show(
                          context,
                          allTags: library.tags,
                          initialSelectedTags: selectedTags,
                          tagParents: library.tagParents,
                          onCreateTag: (newTag) async {
                            await library.addTag(newTag);
                          },
                        );
                        if (tags != null) {
                          setDialogState(() {
                            selectedTags = tags;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (selectedTags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: selectedTags.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setDialogState(() {
                              selectedTags.remove(tag);
                            });
                          },
                          backgroundColor: AppConstants.accentPrimary
                              .withValues(alpha: 0.2),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = Helpers.formatExerciseName(nameController.text);
                if (name.isEmpty) return;
                final def = ExerciseDefinition(name: name, tags: selectedTags);
                final success = await library.addExercise(def);
                
                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('An exercise with this name already exists.'),
                      backgroundColor: AppConstants.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                setState(() {
                  _day.exercises.add(
                    ExerciseInstance(
                      exerciseDefinitionId: def.id,
                      exerciseName: def.name,
                      exerciseTags: List.from(def.tags),
                    ),
                  );
                });
                _save();
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create & Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleDraft() async {
    // If it's a completely standalone drafted day, we prompt for date or auto-save.
    // Assuming the user already picked a date when they clicked "Create One-Shot" from the Calendar.
    // If widget.day.scheduledDate is null, we should pick a date. But Home Screen sets it initially.
    setState(() {
      _isDraft = false;
    });
    // Now it behaves as a normal scheduled event, save it!
    context.read<WorkoutProvider>().saveScheduledDay(_day);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout Scheduled successfully!')),
    );
    if (context.mounted) Navigator.pop(context);
  }
}

class _ShakeIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShakeIconButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ShakeIconButton> createState() => _ShakeIconButtonState();
}

class _ShakeIconButtonState extends State<_ShakeIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.2, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _ShakeIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.icon != oldWidget.icon) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Visual pulse: scale up slightly when added
        final double scale = 1.0 + (sin(_controller.value * pi) * 0.2);
        
        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: _animation.value,
            child: IconButton(
              onPressed: () {
                widget.onTap();
                _controller.forward(from: 0);
              },
              icon: Icon(widget.icon, color: widget.color, size: 28),
            ),
          ),
        );
      },
    );
  }
}

// ── Exercise Card ──────────────────────────────────────────────────

class _ExerciseCard extends StatefulWidget {
  final ExerciseInstance exercise;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool isTemplate;
  final bool isDraft;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onRemove,
    this.isTemplate = false,
    this.isDraft = false,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ExerciseLibraryProvider>();
    final ex = widget.exercise;
    final isComplete = ex.isCompleted && !widget.isTemplate && !widget.isDraft;

    // Resolve current name from library
    final def = library.exercises
        .where((d) => d.id == ex.exerciseDefinitionId)
        .firstOrNull;
    final currentName = def?.name ?? ex.exerciseName;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: AppConstants.animMedium,
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: isComplete
                    ? AppConstants.completion.withValues(alpha: 0.5)
                    : AppConstants.border,
              ),
            ),
            child: Column(
              children: [
                // Header
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppConstants.radiusMD),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppConstants.paddingMD,
                      26, // Increased top padding to clear the small top buttons
                      AppConstants.paddingMD,
                      AppConstants.paddingMD,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.drag_handle_rounded,
                          color: AppConstants.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentName,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              if (!widget.isTemplate)
                                Text(
                                  '${ex.completedSets}/${ex.totalSets} sets',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppConstants.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Stats button
                        IconButton(
                            icon: Icon(
                              Icons.bar_chart_rounded,
                              color: (() {
                                final level = context.watch<WorkoutProvider>().getExerciseDataLevel(ex.exerciseDefinitionId, ex.isTimed, ex.isWeightedTimed);
                                if (level == 2) return AppConstants.progressDay;
                                if (level == 1) return AppConstants.progressWeek;
                                return AppConstants.textMuted.withValues(alpha: 0.3);
                              })(),
                              size: 20,
                            ),
                            onPressed: () {
                              showExerciseStatsDialog(
                                context,
                                ex.exerciseDefinitionId,
                                currentName,
                                ex.isTimed,
                                isWeightedTimed: ex.isWeightedTimed,
                              );
                            },
                          ),
                        // Percentage toggle
                        if (!ex.isTimed || ex.isWeightedTimed)
                          IconButton(
                            icon: Icon(
                              Icons.percent_rounded,
                              color: ex.usePercentage
                                  ? AppConstants.accentGold
                                  : AppConstants.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => ex.usePercentage = !ex.usePercentage);
                              widget.onChanged();
                            },
                          ),
                        // Weighted toggle for timed
                        if (ex.isTimed)
                          IconButton(
                            icon: Icon(
                              Icons.fitness_center_rounded,
                              color: ex.isWeightedTimed
                                  ? AppConstants.accentSecondary
                                  : AppConstants.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => ex.isWeightedTimed = !ex.isWeightedTimed);
                              widget.onChanged();
                            },
                          ),
                        // Timer toggle
                        PopupMenuButton<TimerMode>(
                          icon: Icon(
                            ex.timerMode == TimerMode.stopwatch
                                ? Icons.timer_rounded
                                : ex.timerMode == TimerMode.countdown
                                    ? Icons.hourglass_bottom_rounded
                                    : Icons.timer_off_rounded,
                            color: ex.isTimed
                                ? AppConstants.accentPrimary
                                : AppConstants.textMuted,
                            size: 20,
                          ),
                          onSelected: (mode) {
                            setState(() => ex.timerMode = mode);
                            widget.onChanged();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: TimerMode.none, child: Text('No Timer')),
                            const PopupMenuItem(value: TimerMode.stopwatch, child: Text('Stopwatch')),
                            const PopupMenuItem(value: TimerMode.countdown, child: Text('Countdown')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Sets Area
                AnimatedCrossFade(
              firstChild: Column(
                children: [
                  const Divider(height: 1),
                  // Sets list
                  ...ex.sets.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final set = entry.value;
                    return _SetRow(
                      setNumber: idx + 1,
                      set: set,
                      isTimed: ex.isTimed,
                      timerMode: ex.timerMode,
                      onChanged: () {
                        setState(() {});
                        widget.onChanged();
                      },
                      onRemove: () {
                        setState(() {
                          ex.sets.removeAt(idx);
                        });
                        widget.onChanged();
                      },
                      isTemplate: widget.isTemplate,
                      isDraft: widget.isDraft,
                      usePercentage: ex.usePercentage,
                      isWeightedTimed: ex.isWeightedTimed,
                      refWeight: context
                          .read<WorkoutProvider>()
                          .getExerciseReferenceWeight(ex.exerciseDefinitionId),
                    );
                  }),
                  // Add set button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingSM,
                      vertical: 2,
                    ),
                    child: SizedBox(
                      height: 28,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          setState(() {
                            if (ex.sets.isNotEmpty) {
                              final newSet = ex.sets.last.deepCopy();
                              if (ex.isTimed && ex.timerMode == TimerMode.stopwatch) {
                                newSet.timeSeconds = null;
                                newSet.value = null;
                              }
                              ex.sets.add(newSet);
                            } else {
                              ex.sets.add(
                                ExerciseSet(
                                  timeSeconds: (ex.isTimed && ex.timerMode == TimerMode.countdown)
                                      ? ex.timerDurationSeconds
                                      : null,
                                ),
                              );
                            }
                          });
                          widget.onChanged();
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          'Add Set',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: AppConstants.animMedium,
            ),
          ],
        ),
      ),

      // 1. Collapse Button (Top Middle)
      Positioned(
        top: 6,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              HapticFeedback.lightImpact();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Icon(
                _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                size: 16,
                color: AppConstants.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),

      // 2. Delete Button (Top Right)
      Positioned(
        top: 6,
        right: 6,
        child: GestureDetector(
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppConstants.bgElevated,
                title: Text(
                  'Remove Exercise',
                  style: GoogleFonts.inter(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                content: Text(
                  'Are you sure you want to remove this exercise?',
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppConstants.textMuted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('Remove', style: GoogleFonts.inter(color: AppConstants.error)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              widget.onRemove();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: AppConstants.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      ],
    ),
  );
}
}

// _TimerWidget removed as requested.

// ── Set Row ────────────────────────────────────────────────────────

class _SetRow extends StatelessWidget {
  final int setNumber;
  final ExerciseSet set;
  final bool isTimed;
  final TimerMode timerMode;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool isTemplate;
  final bool isDraft;
  final bool usePercentage;
  final bool isWeightedTimed;
  final double? refWeight;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.isTimed,
    required this.timerMode,
    required this.onChanged,
    required this.onRemove,
    this.isTemplate = false,
    this.isDraft = false,
    this.usePercentage = false,
    this.isWeightedTimed = false,
    this.refWeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) async {
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox;
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
                  Icon(
                    Icons.delete_outline_rounded,
                    color: AppConstants.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Set',
                    style: GoogleFonts.inter(color: AppConstants.error),
                  ),
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
        color: set.isChecked
            ? AppConstants.completion.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMD,
          vertical: AppConstants.paddingXS + 2,
        ),
        child: Row(
          children: [
            // Set number
            SizedBox(
              width: 28,
              child: Text(
                '$setNumber',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textMuted,
                ),
              ),
            ),
            // Reps (shown for strength OR weighted-timed)
            if (!isTimed || isWeightedTimed)
              Expanded(
                child: _CompactField(
                  value: set.reps?.toString() ?? '',
                  hint: 'Reps',
                  onChanged: (v) {
                    set.reps = int.tryParse(v);
                    onChanged();
                  },
                ),
              ),
            if (!isTimed || isWeightedTimed) const SizedBox(width: 8),

            // Weight Field (shown for strength OR weighted-timed)
            // For Weighted-Timed, we use 'set.weight'
            // For Strength, we use 'set.value'
            if (!isTimed || isWeightedTimed)
              Expanded(
                child: _CompactField(
                  // When using percentage, we display and edit 'set.percent' specifically
                  value: usePercentage
                      ? (set.percent?.toInt().toString() ?? '')
                      : (isWeightedTimed
                          ? (set.weight?.toInt().toString() ?? '')
                          : (set.value?.toInt().toString() ?? '')),
                  hint: usePercentage ? '%' : 'Weight',
                  suffix: usePercentage ? '%' : null,
                  onChanged: (v) {
                    final double? val = double.tryParse(v);
                    if (usePercentage) {
                      set.percent = val;
                      // Instantly calculate the flat weight if we have a max reference
                      if (val != null && refWeight != null && refWeight! > 0) {
                        final flat = (val / 100) * refWeight!;
                        if (isWeightedTimed) {
                          set.weight = flat.roundToDouble();
                        } else {
                          set.value = flat.roundToDouble();
                        }
                      }
                    } else {
                      if (isWeightedTimed) {
                        set.weight = val;
                      } else {
                        set.value = val;
                      }
                    }
                    onChanged();
                  },
                ),
              ),
            if (!isTimed || isWeightedTimed) const SizedBox(width: 8),

            // Time Field Placeholder for Stopwatch
            if (isTimed && timerMode == TimerMode.stopwatch)
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppConstants.bgSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.border.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: AppConstants.textMuted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'STOPWATCH',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppConstants.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Time Field (shown for countdown timed exercises)
            if (isTimed && timerMode == TimerMode.countdown)
              Expanded(
                child: _CompactField(
                  value: set.timeSeconds?.toString() ??
                      (set.value?.toInt().toString() ?? ''),
                  hint: 'Time',
                  suffix: 's',
                  isTimeField: true,
                  onChanged: (v) {
                    final val = int.tryParse(v);
                    set.timeSeconds = val;
                    if (val != null) set.value = val.toDouble();
                    onChanged();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactField extends StatefulWidget {
  final String value;
  final String hint;
  final String? suffix;
  final ValueChanged<String> onChanged;
  final bool isTimeField;

  const _CompactField({
    required this.value,
    required this.hint,
    this.suffix,
    required this.onChanged,
    this.isTimeField = false,
  });

  @override
  State<_CompactField> createState() => _CompactFieldState();
}

class _CompactFieldState extends State<_CompactField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _CompactField oldWidget) {
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
    return TextField(
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
      keyboardType: TextInputType.number,
      style: GoogleFonts.inter(color: AppConstants.textPrimary, fontSize: 13),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: AppConstants.bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        isDense: true,
        suffixText: widget.suffix,
        suffixStyle: GoogleFonts.inter(
          color: AppConstants.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }
}
