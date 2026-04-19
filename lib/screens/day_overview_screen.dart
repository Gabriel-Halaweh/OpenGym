import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/day_workout.dart';
import '../models/exercise_instance.dart';
import '../providers/workout_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'day_editor_screen.dart';
import 'active_workout_screen.dart';
import '../widgets/exercise_stats_dialog.dart';

class DayOverviewScreen extends StatefulWidget {
  final DayWorkout day;
  final String? parentType;
  final String? parentId;
  final bool isDraft;

  const DayOverviewScreen({
    super.key,
    required this.day,
    this.parentType,
    this.parentId,
    this.isDraft = false,
  });

  @override
  State<DayOverviewScreen> createState() => _DayOverviewScreenState();
}

class _DayOverviewScreenState extends State<DayOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.day.displayTitle,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // Basic info
          if (widget.day.description != null && widget.day.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingMD),
                decoration: BoxDecoration(
                  color: AppConstants.bgSurface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Text(
                  widget.day.description!,
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          
          Expanded(
            child: widget.day.exercises.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMD),
                  itemCount: widget.day.exercises.length,
                  itemBuilder: (context, index) {
                    final ex = widget.day.exercises[index];
                    final isDone = ex.isCompleted;
                    final isPartial = ex.progress > 0 && !isDone;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMD),
                        decoration: BoxDecoration(
                          color: isDone 
                              ? AppConstants.completion.withValues(alpha: 0.15) 
                              : (isPartial ? AppConstants.warning.withValues(alpha: 0.15) : AppConstants.bgCard),
                          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                          border: Border.all(
                            color: isDone 
                                ? AppConstants.completion.withValues(alpha: 0.8) 
                                : (isPartial ? AppConstants.warning.withValues(alpha: 0.8) : AppConstants.border),
                            width: (isDone || isPartial) ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDone 
                                    ? AppConstants.completion.withValues(alpha: 0.25) 
                                    : (isPartial ? AppConstants.warning.withValues(alpha: 0.25) : AppConstants.bgSurface),
                                borderRadius: BorderRadius.circular(8),
                                border: isDone 
                                  ? Border.all(color: AppConstants.completion.withValues(alpha: 0.5)) 
                                  : (isPartial ? Border.all(color: AppConstants.warning.withValues(alpha: 0.5)) : null),
                              ),
                              alignment: Alignment.center,
                              child: isDone
                                ? Icon(Icons.check_rounded, color: AppConstants.completion, size: 18)
                                : isPartial
                                ? Icon(Icons.adjust_rounded, color: AppConstants.warning, size: 18)
                                : Text(
                                    '${index + 1}',
                                    style: GoogleFonts.jetBrainsMono(
                                      color: AppConstants.accentPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          ex.exerciseName,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.bar_chart_rounded, 
                                          size: 20, 
                                          color: (() {
                                            final level = provider.getExerciseDataLevel(ex.exerciseDefinitionId, ex.isTimed, ex.isWeightedTimed);
                                            if (level == 2) return AppConstants.progressDay;
                                            if (level == 1) return AppConstants.progressWeek;
                                            return AppConstants.textMuted.withValues(alpha: 0.3);
                                          })(),
                                        ),
                                        onPressed: () => showExerciseStatsDialog(
                                          context, 
                                          ex.exerciseDefinitionId, 
                                          ex.exerciseName, 
                                          ex.isTimed, 
                                          isWeightedTimed: ex.isWeightedTimed
                                        ),
                                        tooltip: 'Exercise Stats',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _buildExerciseSummary(context, ex),
                                    style: GoogleFonts.inter(
                                      color: AppConstants.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ex.usePercentage)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppConstants.accentGold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.percent_rounded, size: 12, color: AppConstants.accentGold),
                                    const SizedBox(width: 2),
                                    Text(
                                      'MAX',
                                      style: TextStyle(
                                        color: AppConstants.accentGold,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.fromLTRB(
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              AppConstants.paddingMD,
              MediaQuery.of(context).padding.bottom + AppConstants.paddingMD,
            ),
            decoration: BoxDecoration(
              color: AppConstants.bgSurface,
              border: Border(top: BorderSide(color: AppConstants.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DayEditorScreen(
                            day: widget.day,
                            parentType: widget.parentType,
                            parentId: widget.parentId,
                            isDraft: widget.isDraft,
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Edit Routine'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiveWorkoutScreen(
                            day: widget.day,
                            parentType: widget.parentType,
                            parentId: widget.parentId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start Routine'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppConstants.accentPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppConstants.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises in this routine',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Edit Routine to add some',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _buildExerciseSummary(BuildContext context, ExerciseInstance ex) {
    final refWeight = ex.usePercentage 
      ? context.read<WorkoutProvider>().getExerciseReferenceWeight(ex.exerciseDefinitionId)
      : null;
    return Helpers.getExerciseSummary(ex, refWeight: refWeight);
  }
}
