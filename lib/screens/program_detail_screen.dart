import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/program_workout.dart';
import '../models/week_workout.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'week_detail_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final ProgramWorkout program;
  final bool isTemplate;
  final bool isDraft;

  const ProgramDetailScreen({
    super.key,
    required this.program,
    this.isTemplate = false,
    this.isDraft = false,
  });

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  late ProgramWorkout _program;
  late bool _isDraft;

  bool _isSelectionMode = false;
  final Set<String> _selectedWeekIds = {};

  @override
  void initState() {
    super.initState();
    _program = widget.program;
    _isDraft = widget.isDraft;
  }

  void _save() {
    if (_isDraft) return;
    if (widget.isTemplate) {
      context.read<WorkoutProvider>().saveProgramTemplate(_program);
    } else {
      context.read<WorkoutProvider>().saveScheduledProgram(_program);
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
            _selectedWeekIds.clear();
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
                ? '${_selectedWeekIds.length} Selected'
                : _program.displayTitle,
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
                    _selectedWeekIds.clear();
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
            if (!_isDraft && !_isSelectionMode && _program.weeks.isNotEmpty)
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
            if (_program.description != null &&
                _program.description!.isNotEmpty)
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
                  _program.description!,
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),

            // Progress
            if (!widget.isTemplate && _program.weeks.isNotEmpty)
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
                          tween: Tween(begin: 0, end: _program.progress),
                          duration: AppConstants.animMedium,
                          builder: (_, value, child) => LinearProgressIndicator(
                            value: value,
                            backgroundColor: AppConstants.bgSurface,
                            valueColor: AlwaysStoppedAnimation(
                              _program.isCompleted
                                  ? AppConstants.completion
                                  : AppConstants.progressProgram,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Helpers.progressPercent(_program.progress),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _program.isCompleted
                            ? AppConstants.completion
                            : AppConstants.progressProgram,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Weeks list
            Expanded(
              child: _program.weeks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_week_rounded,
                            size: 48,
                            color: AppConstants.textMuted.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No weeks yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add a week',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppConstants.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _program.weeks.length,
                      buildDefaultDragHandles: !_isSelectionMode,
                      onReorder: (oldIndex, newIndex) {
                        if (!_isSelectionMode) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _program.weeks.removeAt(oldIndex);
                            _program.weeks.insert(newIndex, item);
                          });
                          _save();
                        }
                      },
                      itemBuilder: (context, index) {
                        final week = _program.weeks[index];
                        final isComplete =
                            week.isCompleted && !widget.isTemplate;
                        final isSelected = _selectedWeekIds.contains(week.id);

                        return Padding(
                          key: ValueKey(week.id),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMD,
                            vertical: AppConstants.paddingXS,
                          ),
                          child: Material(
                            color: isSelected
                                ? AppConstants.accentSecondary.withValues(
                                    alpha: 0.1,
                                  )
                                : AppConstants.bgCard,
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusMD,
                            ),
                            child: InkWell(
                              onTap: () async {
                                if (_isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedWeekIds.remove(week.id);
                                    } else {
                                      _selectedWeekIds.add(week.id);
                                    }
                                  });
                                } else {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WeekDetailScreen(
                                        week: week,
                                        isTemplate: widget.isTemplate,
                                        parentProgramId: widget.isTemplate
                                            ? null
                                            : _program.id,
                                        onNestedSave: () => _save(),
                                        isDraft: _isDraft,
                                      ),
                                    ),
                                  );
                                  setState(() {});
                                  _save();
                                }
                              },
                              borderRadius: BorderRadius.circular(
                                AppConstants.radiusMD,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppConstants.paddingMD,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.radiusMD,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppConstants.accentSecondary
                                        : (isComplete
                                              ? AppConstants.completion
                                                    .withValues(alpha: 0.5)
                                              : AppConstants.border),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (!_isSelectionMode)
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Icon(
                                                Icons.drag_handle_rounded,
                                                color: AppConstants.textMuted,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            gradient: isComplete
                                                ? AppConstants.completedGradient
                                                : AppConstants.warmGradient,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Week ${index + 1}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppConstants.textMuted,
                                                ),
                                              ),
                                              Text(
                                                week.title ?? 'Untitled',
                                                style: GoogleFonts.inter(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppConstants.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!widget.isTemplate &&
                                            !_isSelectionMode) ...[
                                          Text(
                                            Helpers.progressPercent(
                                              week.progress,
                                            ),
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isComplete
                                                  ? AppConstants.completion
                                                  : AppConstants.progressWeek,
                                            ),
                                          ),
                                        ],
                                        if (_isSelectionMode) ...[
                                          const SizedBox(width: 8),
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                      .radio_button_unchecked_rounded,
                                            color: isSelected
                                                ? AppConstants.accentSecondary
                                                : AppConstants.textMuted,
                                          ),
                                        ] else if (!widget.isTemplate) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy_rounded,
                                              color: AppConstants.textMuted,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () =>
                                                _showSaveAsTemplateDialog(
                                                  context,
                                                  week,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (!widget.isTemplate &&
                                        week.days.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: week.progress,
                                          backgroundColor: AppConstants.bgSurface,
                                          valueColor: AlwaysStoppedAnimation(
                                            isComplete
                                                ? AppConstants.completion
                                                : AppConstants.progressWeek,
                                          ),
                                          minHeight: 3,
                                        ),
                                      ),
                                    ],
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '${week.days.length} day${week.days.length != 1 ? 's' : ''}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppConstants.textMuted,
                                        ),
                                      ),
                                    ),
                                    if (week.note != null &&
                                        week.note!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          week.note!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppConstants.textSecondary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton.extended(
                heroTag: 'program_selection_fab',
                onPressed: _selectedWeekIds.isNotEmpty
                    ? () => _deleteSelectedWeeks(context)
                    : null,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                backgroundColor: _selectedWeekIds.isNotEmpty
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
            : FloatingActionButton.extended(
                heroTag: 'program_add_week_fab',
                onPressed: _showAddWeekDialog,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  'Add Week',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
      ),
    );
  }

  void _deleteSelectedWeeks(BuildContext context) {
    if (_selectedWeekIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete ${_selectedWeekIds.length} Weeks?',
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
        ),
        content: Text(
          'Are you sure you want to permanently remove these weeks?',
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
                _program.weeks.removeWhere(
                  (week) => _selectedWeekIds.contains(week.id),
                );
                _isSelectionMode = false;
                _selectedWeekIds.clear();
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

  void _showAddWeekDialog() {
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
              'Add Week',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Create new
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppConstants.warmGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                'Create New Week',
                style: GoogleFonts.inter(
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _createNewWeek();
              },
            ),
            const Divider(),
            // Import templates
            if (context.read<WorkoutProvider>().weekTemplates.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Import from Template',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textMuted,
                  ),
                ),
              ),
              ...context.read<WorkoutProvider>().weekTemplates.map(
                (t) => ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppConstants.accentGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.file_download_outlined,
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
                    '${t.days.length} days',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    final copy = t.deepCopy(asTemplate: false);
                    setState(() => _program.weeks.add(copy));
                    _save();
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _createNewWeek() {
    final titleController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Week'),
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
                controller: noteController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(labelText: 'Note (optional)'),
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
              final week = WeekWorkout(
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                isTemplate: false,
              );
              setState(() => _program.weeks.add(week));
              _save();
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _scheduleDraft() async {
    setState(() {
      _isDraft = false;
    });
    context.read<WorkoutProvider>().saveScheduledProgram(_program);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program Scheduled successfully!')),
    );
    if (context.mounted) Navigator.pop(context);
  }

  void _showSaveAsTemplateDialog(BuildContext context, WeekWorkout week) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Template?'),
        content: const Text(
          'Would you like to extract this week and save it as a standalone Week Template?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newTemplate = week.deepCopy(asTemplate: true);
              if (newTemplate.title == null || newTemplate.title!.isEmpty) {
                newTemplate.title = 'Saved Week Template';
              }
              context.read<WorkoutProvider>().saveWeekTemplate(newTemplate);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Week saved as template')),
              );
            },
            child: const Text('Save Template'),
          ),
        ],
      ),
    );
  }
}
