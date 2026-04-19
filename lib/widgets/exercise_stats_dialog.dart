import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/workout_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/exercise_instance.dart';
import '../models/exercise_set.dart';

class ExerciseStatsDialog extends StatefulWidget {
  final String exerciseDefinitionId;
  final String exerciseName;
  final bool isTimed;
  final bool isWeightedTimed;

  const ExerciseStatsDialog({
    super.key,
    required this.exerciseDefinitionId,
    required this.exerciseName,
    required this.isTimed,
    this.isWeightedTimed = false,
  });

  @override
  State<ExerciseStatsDialog> createState() => _ExerciseStatsDialogState();
}

class _ExerciseStatsDialogState extends State<ExerciseStatsDialog> {
  late bool _isTimed;
  late bool _isWeightedTimed;

  @override
  void initState() {
    super.initState();
    _isTimed = widget.isTimed;
    _isWeightedTimed = widget.isWeightedTimed;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final stats = provider.getExerciseStats(
      widget.exerciseDefinitionId,
      isTimed: _isTimed,
      isWeightedTimed: _isWeightedTimed,
    );
    final history = provider.getExerciseFullHistory(
      widget.exerciseDefinitionId,
      isTimed: _isTimed,
      isWeightedTimed: _isWeightedTimed,
      limit: 7,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppConstants.bgElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exerciseName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppConstants.accentPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildModeChip('WEIGHT', Icons.fitness_center_rounded, !_isTimed, () {
                                setState(() {
                                  _isTimed = false;
                                  _isWeightedTimed = false;
                                });
                              }),
                              const SizedBox(width: 8),
                              _buildModeChip('TIME', Icons.timer_rounded, _isTimed && !_isWeightedTimed, () {
                                setState(() {
                                  _isTimed = true;
                                  _isWeightedTimed = false;
                                });
                              }),
                              const SizedBox(width: 8),
                              _buildModeChip('WEIGHT-TIME', Icons.speed_rounded, _isTimed && _isWeightedTimed, () {
                                setState(() {
                                  _isTimed = true;
                                  _isWeightedTimed = true;
                                });
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppConstants.bgSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                  children: [
                    if (stats.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            children: [
                              Icon(Icons.history_rounded, size: 48, color: AppConstants.textMuted.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'No session history found for this exercise.',
                                style: GoogleFonts.inter(color: AppConstants.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Stats Overview Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: stats.entries.map((e) {
                          IconData icon = Icons.analytics_rounded;
                          if (e.key.contains('Max')) icon = Icons.emoji_events_rounded;
                          if (e.key.contains('Volume')) icon = Icons.fitness_center_rounded;
                          if (e.key.contains('Time')) icon = Icons.timer_rounded;
                          if (e.key.contains('Sessions')) icon = Icons.calendar_today_rounded;
                          if (e.key.contains('Reps')) icon = Icons.repeat_rounded;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppConstants.accentPrimary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(icon, color: AppConstants.accentPrimary, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        e.key.toUpperCase(),
                                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppConstants.textMuted),
                                      ),
                                      Text(
                                        e.value,
                                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppConstants.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 32),
                      
                      // 1. Volume Chart
                      _buildHistorySection(
                        (_isTimed && !_isWeightedTimed) ? 'DURATION PROGRESS' : 'VOLUME PROGRESS',
                        'Historical trend across last 7 sessions',
                        (_isTimed && _isWeightedTimed) ? 'weight * time * reps' : (_isTimed ? 'duration' : 'weight * reps'),
                        _buildGroupedSetChart(
                          provider,
                          history,
                          (s) {
                            if (_isTimed && _isWeightedTimed) {
                              return ((s.weight ?? 0.0) * (s.timeSeconds ?? (s.value?.toInt() ?? 0)) * (s.reps ?? 1)).toDouble();
                            } else if (_isTimed) {
                              return (s.timeSeconds ?? (s.value?.toInt() ?? 0)).toDouble();
                            } else {
                              return ((s.value ?? 0.0) * (s.reps ?? 1)).toDouble();
                            }
                          },
                          (_isTimed && !_isWeightedTimed) ? 'sec' : 'vol',
                          AppConstants.accentPrimary,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. Weights Chart (if applicable)
                      if (!_isTimed || _isWeightedTimed)
                        _buildHistorySection(
                          'WEIGHT TRENDS',
                          'Target weights for last 7 sessions',
                          _isWeightedTimed ? 'weight' : 'value',
                          _buildGroupedSetChart(
                            provider,
                            history,
                            (s) => (_isWeightedTimed ? (s.weight ?? 0.0) : (s.value ?? 0.0)).toDouble(),
                            'kg',
                            AppConstants.accentSecondary,
                          ),
                        ),

                      if (!_isTimed || _isWeightedTimed) const SizedBox(height: 24),

                      // 3. Reps Chart (if applicable)
                      if (!_isTimed || _isWeightedTimed)
                        _buildHistorySection(
                          'REPETITIONS',
                          'Repetitions for last 7 sessions',
                          'reps',
                          _buildGroupedSetChart(
                            provider,
                            history,
                            (s) => (s.reps ?? 0).toDouble(),
                            'reps',
                            AppConstants.accentGold,
                          ),
                        ),


                      
                      const SizedBox(height: 24),
                      Text(
                        'HISTORICAL SESSIONS',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.textPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...history.reversed.map((instance) => _buildSessionLog(provider, instance as ExerciseInstance)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeChip(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.accentPrimary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppConstants.accentPrimary.withValues(alpha: 0.4) : AppConstants.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 10,
              color: isActive ? AppConstants.accentPrimary : AppConstants.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isActive ? AppConstants.accentPrimary : AppConstants.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(String title, String subtitle, String formula, Widget chart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w900, color: AppConstants.textPrimary),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.bgSurface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
              ),
              child: Text(
                formula.toUpperCase(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: AppConstants.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
          decoration: BoxDecoration(
            color: AppConstants.bgCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConstants.border.withValues(alpha: 0.3)),
          ),
          child: chart,
        ),
      ],
    );
  }

  Widget _buildGroupedSetChart(
    WorkoutProvider provider,
    List<ExerciseInstance> history,
    double Function(ExerciseSet) extractor,
    String unit,
    Color baseColor,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();

    // Find overall max for scaling
    double maxVal = 0;
    for (var ex in history) {
      for (var s in ex.sets.where((s) => s.isChecked)) {
        double v = extractor(s);
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal == 0) maxVal = 1;

    String dispUnit;
    double divisor;
    if (unit == 'sec') {
      dispUnit = '';
      divisor = 1.0;
    } else {
      final info = Helpers.getMagnitudeInfo(maxVal);
      dispUnit = info.$1;
      divisor = info.$2;
    }
    final (axisMax, axisInterval) = unit == 'sec' ? Helpers.getTimeAxisSpecs(maxVal) : Helpers.getAxisSpecs(maxVal);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: axisMax,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppConstants.bgSurface,
            tooltipBorder: BorderSide(color: baseColor.withValues(alpha: 0.2)),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                unit == 'sec' ? Helpers.formatDurationLong(rod.toY.toInt()) : Helpers.formatWithMagnitude(rod.toY, divisor, dispUnit),
                GoogleFonts.jetBrainsMono(
                  color: baseColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'S${idx + 1}',
                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppConstants.textMuted),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: unit == 'sec' ? 60 : 40,
              interval: axisInterval,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      unit == 'sec' ? Helpers.formatDurationLong(value.toInt()) : Helpers.formatWithMagnitude(value, divisor, dispUnit, precision: 1),
                      style: GoogleFonts.inter(fontSize: 8, color: AppConstants.textMuted, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: axisInterval,
          getDrawingHorizontalLine: (v) => FlLine(color: AppConstants.border.withValues(alpha: 0.05)),
          getDrawingVerticalLine: (v) => FlLine(color: AppConstants.border.withValues(alpha: 0.05)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: AppConstants.border.withValues(alpha: 0.2)),
            bottom: BorderSide(color: AppConstants.border.withValues(alpha: 0.2)),
          ),
        ),
        barGroups: List.generate(history.length, (i) {
          final ex = history[i];
          final completedSets = ex.sets
              .where((s) => provider.isSetApplicable(ex, s, _isTimed, _isWeightedTimed))
              .where((s) => extractor(s) > 0)
              .toList();
          return BarChartGroupData(
            x: i,
            barRods: List.generate(completedSets.length, (sIdx) {
              final val = extractor(completedSets[sIdx]);
              // Slightly alternate color or darken for sets
              final setOpacity = 1.0 - (sIdx * 0.15).clamp(0.0, 0.4);
              return BarChartRodData(
                toY: val,
                color: baseColor.withValues(alpha: setOpacity),
                width: history.length > 5 ? 4 : 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              );
            }),
            barsSpace: 2,
          );
        }),
      ),
    );
  }

  Widget _buildSessionLog(WorkoutProvider provider, ExerciseInstance ex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LOGGED SESSION',
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppConstants.accentPrimary, letterSpacing: 0.5),
              ),
              // We don't easily have the date here since it's on the DayWorkout, 
              // but we can assume it's part of the history retrieved which was filtered by date.
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ex.sets.where((s) => provider.isSetApplicable(ex, s, _isTimed, _isWeightedTimed)).toList().asMap().entries.map((entry) {
              final s = entry.value;
              String label = '';
              if (_isWeightedTimed) {
                label = '${s.weight ?? 0}kg x ${s.reps ?? 0} (${Helpers.formatDurationLong(s.timeSeconds ?? s.value?.toInt() ?? 0)})';
              } else if (_isTimed) {
                label = Helpers.formatDurationLong(s.timeSeconds ?? s.value?.toInt() ?? 0);
              } else {
                label = '${Helpers.formatCompactNumber((s.value ?? 0.0).toDouble())}kg x ${s.reps ?? 0}';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppConstants.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'SET ${entry.key + 1}: $label',
                  style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.textSecondary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

void showExerciseStatsDialog(
  BuildContext context,
  String definitionId,
  String name,
  bool isTimed, {
  bool isWeightedTimed = false,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent, // Background handled by sheet
    isScrollControlled: true,
    enableDrag: true,
    builder: (_) => ExerciseStatsDialog(
      exerciseDefinitionId: definitionId,
      exerciseName: name,
      isTimed: isTimed,
      isWeightedTimed: isWeightedTimed,
    ),
  );
}
