import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/week_workout.dart';
import '../models/day_workout.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'day_editor_screen.dart';
import 'day_overview_screen.dart';

class WeekDetailScreen extends StatefulWidget {
  final WeekWorkout week;
  final bool isTemplate;
  final String? parentProgramId;
  final VoidCallback? onNestedSave;
  final bool isDraft;

  const WeekDetailScreen({
    super.key,
    required this.week,
    this.isTemplate = false,
    this.parentProgramId,
    this.onNestedSave,
    this.isDraft = false,
  });

  @override
  State<WeekDetailScreen> createState() => _WeekDetailScreenState();
}

class _WeekDetailScreenState extends State<WeekDetailScreen> {
  late WeekWorkout _week;
  late bool _isDraft;

  bool _isSelectionMode = false;
  final Set<String> _selectedDayIds = {};

  @override
  void initState() {
    super.initState();
    _week = widget.week;
    _isDraft = widget.isDraft;
  }

  void _save() {
    if (_isDraft) return;

    if (widget.onNestedSave != null) {
      widget.onNestedSave!();
    } else if (widget.isTemplate) {
      context.read<WorkoutProvider>().saveWeekTemplate(_week);
    } else if (widget.parentProgramId != null) {
      final provider = context.read<WorkoutProvider>();
      final program = provider.scheduledPrograms
          .where((p) => p.id == widget.parentProgramId)
          .firstOrNull;
      if (program != null) {
        provider.saveScheduledProgram(program);
      }
    } else {
      context.read<WorkoutProvider>().saveScheduledWeek(_week);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return PopScope(
      canPop: !_isDraft && !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedDayIds.clear();
          });
          return;
        }
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
            _isSelectionMode
                ? '${_selectedDayIds.length} Selected'
                : _week.displayTitle,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedDayIds.clear();
                  });
                },
              ),
            if (_isDraft && !_isSelectionMode)
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
            if (!_isDraft && !_isSelectionMode && _week.days.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Bulk Delete',
                onPressed: () {
                  setState(() {
                    _isSelectionMode = true;
                  });
                },
              ),
          ],
        ),
        body: Column(
          children: [
            // Description
            if (_week.description != null && _week.description!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                margin: const EdgeInsets.all(AppConstants.paddingMD),
                decoration: BoxDecoration(
                  color: AppConstants.bgSurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Text(
                  _week.description!,
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

            // Progress
            if (!widget.isTemplate && _week.days.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _week.progress),
                          duration: AppConstants.animMedium,
                          builder: (_, value, child) => LinearProgressIndicator(
                            value: value,
                            backgroundColor: AppConstants.bgSurface,
                            valueColor: AlwaysStoppedAnimation(
                              _week.isCompleted
                                  ? AppConstants.completion
                                  : AppConstants.progressWeek,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Helpers.progressPercent(_week.progress),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _week.isCompleted
                            ? AppConstants.completion
                            : AppConstants.progressWeek,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Days list (Sun-Sat)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final day = _week.getDayForWeekday(index);
                  final dayName = DayWorkout.dayNames[index];

                  if (day != null) {
                    return DragTarget<DayWorkout>(
                      onWillAcceptWithDetails: (details) => details.data != day,
                      onAcceptWithDetails: (details) {
                        _handleDayDrop(details.data, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return Container(
                          margin: isHovered
                              ? const EdgeInsets.only(top: 8, bottom: 8)
                              : null,
                          decoration: isHovered
                              ? BoxDecoration(
                                  color: AppConstants.accentSecondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD,
                                  ),
                                  border: Border.all(
                                    color: AppConstants.accentSecondary,
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                )
                              : null,
                          child: LongPressDraggable<DayWorkout>(
                            data: day,
                            maxSimultaneousDrags: _isSelectionMode ? 0 : 1,
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.8,
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  child: _DayCard(
                                    day: day,
                                    dayName: dayName,
                                    isTemplate: widget.isTemplate,
                                    isSelectionMode: false,
                                    isSelected: false,
                                    onTap: () {},
                                    onSaveAsTemplate: () {},
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _DayCard(
                                day: day,
                                dayName: dayName,
                                isTemplate: widget.isTemplate,
                                isSelectionMode: false,
                                isSelected: false,
                                onTap: () {},
                                onSaveAsTemplate: () {},
                              ),
                            ),
                            child: _DayCard(
                              day: day,
                              dayName: dayName,
                              isTemplate: widget.isTemplate,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedDayIds.contains(day.id),
                              onSaveAsTemplate: () =>
                                  _showSaveAsTemplateDialog(context, day),
                              onTap: () async {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (_selectedDayIds.contains(day.id)) {
                                      _selectedDayIds.remove(day.id);
                                    } else {
                                      _selectedDayIds.add(day.id);
                                    }
                                  });
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => widget.isTemplate
                                          ? DayEditorScreen(
                                              day: day,
                                              isTemplate: true,
                                              onNestedSave: () => _save(),
                                            )
                                          : DayOverviewScreen(
                                              day: day,
                                              parentType: 'week',
                                              parentId: _week.id,
                                              isDraft: _isDraft,
                                            ),
                                    ),
                                  );
                                  setState(() {});
                                  _save();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return DragTarget<DayWorkout>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        _handleDayDrop(details.data, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return Container(
                          margin: isHovered
                              ? const EdgeInsets.only(top: 8, bottom: 8)
                              : null,
                          decoration: isHovered
                              ? BoxDecoration(
                                  color: AppConstants.accentSecondary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD,
                                  ),
                                )
                              : null,
                          child: _EmptyDaySlot(
                            dayName: dayName,
                            dayIndex: index,
                            onAddDay: () => _addDayToSlot(index),
                            onImportDay: () => _importDayToSlot(index),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton.extended(
                heroTag: 'week_selection_fab',
                onPressed: _selectedDayIds.isNotEmpty
                    ? () => _deleteSelectedDays(context)
                    : null,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                backgroundColor: _selectedDayIds.isNotEmpty
                    ? AppConstants.error
                    : AppConstants.textMuted,
                label: Text(
                  'Delete',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  void _deleteSelectedDays(BuildContext context) {
    if (_selectedDayIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete ${_selectedDayIds.length} Days?',
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
        ),
        content: Text(
          'Are you sure you want to permanently empty these days?',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'No',
              style: GoogleFonts.inter(color: AppConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _week.days.removeWhere(
                  (day) => _selectedDayIds.contains(day.id),
                );
                _isSelectionMode = false;
                _selectedDayIds.clear();
              });
              _save();
              Navigator.pop(ctx);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.inter(color: AppConstants.error),
            ),
          ),
        ],
      ),
    );
  }

  void _addDayToSlot(int dayOfWeek) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add ${DayWorkout.dayNames[dayOfWeek]}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final day = DayWorkout(
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                dayOfWeek: dayOfWeek,
                isTemplate: false,
              );
              setState(() => _week.days.add(day));
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _importDayToSlot(int dayOfWeek) {
    final provider = context.read<WorkoutProvider>();
    final templates = provider.dayTemplates;

    if (templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No day templates to import from')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLG),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Import Day Template',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'For ${DayWorkout.dayNames[dayOfWeek]}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ...templates.map(
              (t) => ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppConstants.accentGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.today_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                title: Text(
                  t.displayTitle,
                  style: GoogleFonts.inter(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  '${t.exercises.length} exercises',
                  style: GoogleFonts.inter(
                    color: AppConstants.textMuted,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  final copy = t.deepCopy(asTemplate: false);
                  copy.dayOfWeek = dayOfWeek;
                  setState(() => _week.days.add(copy));
                  _save();
                  Navigator.pop(ctx);
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _scheduleDraft() async {
    setState(() {
      _isDraft = false;
    });
    if (widget.onNestedSave != null) {
      widget.onNestedSave!();
    } else {
      context.read<WorkoutProvider>().saveScheduledWeek(_week);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Week Scheduled successfully!')),
    );
    if (context.mounted) Navigator.pop(context);
  }

  void _showSaveAsTemplateDialog(BuildContext context, DayWorkout day) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Save as Template?',
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
        ),
        content: Text(
          'Would you like to extract this day and save it as a standalone Day Template?',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppConstants.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              final newTemplate = day.deepCopy(asTemplate: true);
              if (newTemplate.title == null || newTemplate.title!.isEmpty) {
                newTemplate.title = 'Saved Day Template';
              }
              context.read<WorkoutProvider>().saveDayTemplate(newTemplate);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Day saved as template')),
              );
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }

  void _handleDayDrop(DayWorkout draggedDay, int newSlotIndex) {
    final originalSlotIndex = draggedDay.dayOfWeek;
    if (originalSlotIndex == newSlotIndex) return;

    setState(() {
      final existingDayInSlot = _week.getDayForWeekday(newSlotIndex);
      if (existingDayInSlot != null) {
        // Swap their slots
        existingDayInSlot.dayOfWeek = originalSlotIndex;
      }
      draggedDay.dayOfWeek = newSlotIndex;
    });
    _save();
  }
}

class _DayCard extends StatelessWidget {
  final DayWorkout day;
  final String dayName;
  final bool isTemplate;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSaveAsTemplate;

  const _DayCard({
    required this.day,
    required this.dayName,
    required this.isTemplate,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onSaveAsTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = day.isCompleted && !isTemplate;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Material(
        color: isSelected
            ? AppConstants.accentSecondary.withValues(alpha: 0.1)
            : AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: isSelected
                    ? AppConstants.accentSecondary
                    : (isComplete
                          ? AppConstants.completion.withValues(alpha: 0.5)
                          : AppConstants.border),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: isComplete
                            ? AppConstants.completedGradient
                            : AppConstants.accentGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isComplete ? Icons.check_rounded : Icons.today_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textMuted,
                            ),
                          ),
                          Text(
                            day.title ?? 'Workout',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isTemplate && !isSelectionMode)
                      Text(
                        Helpers.progressPercent(day.progress),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isComplete
                              ? AppConstants.completion
                              : AppConstants.progressDay,
                        ),
                      ),
                    if (isSelectionMode) ...[
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected
                            ? AppConstants.accentSecondary
                            : AppConstants.textMuted,
                      ),
                    ] else if (!isTemplate) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.copy_rounded,
                          color: AppConstants.textMuted,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onSaveAsTemplate,
                      ),
                    ],
                  ],
                ),
                if (!isTemplate && day.exercises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: day.progress,
                      backgroundColor: AppConstants.bgSurface,
                      valueColor: AlwaysStoppedAnimation(
                        isComplete
                            ? AppConstants.completion
                            : AppConstants.progressDay,
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${day.exercises.length} exercise${day.exercises.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyDaySlot extends StatelessWidget {
  final String dayName;
  final int dayIndex;
  final VoidCallback onAddDay;
  final VoidCallback onImportDay;

  const _EmptyDaySlot({
    required this.dayName,
    required this.dayIndex,
    required this.onAddDay,
    required this.onImportDay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppConstants.bgCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: AppConstants.border.withValues(alpha: 0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Text(
              dayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppConstants.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              'Rest',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppConstants.textMuted.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.add_rounded,
                color: AppConstants.accentPrimary,
                size: 20,
              ),
              onPressed: onAddDay,
              splashRadius: 18,
              tooltip: 'Create new',
            ),
            IconButton(
              icon: Icon(
                Icons.file_download_outlined,
                color: AppConstants.accentSecondary,
                size: 20,
              ),
              onPressed: onImportDay,
              splashRadius: 18,
              tooltip: 'Import template',
            ),
          ],
        ),
      ),
    );
  }
}
