import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import '../models/exercise_instance.dart';
import '../providers/workout_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/exercise_stats_dialog.dart';
import 'day_overview_screen.dart';

class LoggedItemStatsScreen extends StatelessWidget {
  final dynamic item; // DayWorkout, WeekWorkout, or ProgramWorkout
  final String type; // 'day', 'week', 'program'
  final String? parentType;
  final String? parentId;

  const LoggedItemStatsScreen({
    super.key,
    required this.item,
    required this.type,
    this.parentType,
    this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    final List<DayWorkout> allDays = [];
    String title = '';
    DateTime? date;
    bool isFullyCompleted = false;

    if (type == 'day') {
      final day = item as DayWorkout;
      allDays.add(day);
      title = day.displayTitle;
      date = day.completedDate;
      isFullyCompleted = day.isFullyCompleted;
    } else if (type == 'week') {
      final week = item as WeekWorkout;
      allDays.addAll(week.days.where((d) => d.isCompleted));
      title = week.displayTitle;
      date = week.completedDate;
      isFullyCompleted = week.isCompleted;
    } else {
      final program = item as ProgramWorkout;
      for (final week in program.weeks) {
        allDays.addAll(week.days.where((d) => d.isCompleted));
      }
      title = program.displayTitle;
      date = program.completedDate;
      isFullyCompleted = program.isCompleted;
    }

    // Aggregating Stats
    int totalSets = 0;
    int completedSets = 0;
    double totalVolume = 0;
    double maxWeight = 0;
    int totalDurationSeconds = 0;

    final Map<String, _ExerciseStats> exerciseMap = {};

    for (var day in allDays) {
      if (day.startedDate != null && day.completedDate != null) {
        totalDurationSeconds +=
            day.completedDate!.difference(day.startedDate!).inSeconds;
      }

      for (var ex in day.exercises) {
        final stats = exerciseMap.putIfAbsent(
          ex.exerciseDefinitionId,
          () => _ExerciseStats(
            id: ex.exerciseDefinitionId,
            name: ex.exerciseName,
            isTimed: ex.isTimed,
            isWeightedTimed: ex.isWeightedTimed,
          ),
        );
        
        totalSets += ex.sets.length;
        for (var set in ex.sets) {
          if (set.isChecked) {
            completedSets++;
            double vol = 0;
            if (ex.isTimed) {
              if (ex.isWeightedTimed) {
                vol = ((set.weight ?? 0) *
                        (set.timeSeconds ?? set.value ?? 0) *
                        (set.reps ?? 1))
                    .toDouble();
                if ((set.weight ?? 0) > maxWeight) maxWeight = set.weight!;
                stats.volume += vol;
                stats.timeSeconds += (set.timeSeconds ?? set.value?.toInt() ?? 0);
              } else {
                vol = (set.timeSeconds?.toDouble() ??
                    set.value?.toDouble() ??
                    0.0);
                stats.timeSeconds += vol.toInt();
              }
            } else {
              vol = ((set.value ?? 0) * (set.reps ?? 1)).toDouble();
              if ((set.value ?? 0) > maxWeight) maxWeight = set.value!;
              stats.volume += vol;
            }
          }
        }
      }
    }
    totalVolume = exerciseMap.values.fold(0, (sum, s) => sum + s.volume);

    return Scaffold(
      backgroundColor: AppConstants.bgSurface,
      appBar: AppBar(
        title: Text(
          'WORKOUT STATS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        child: Column(
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 23),
                  _buildTypeTag(type, isFullyCompleted),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (date != null)
                    Text(
                      Helpers.formatDate(date),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppConstants.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Stat Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'VOLUME',
                    Helpers.formatCompactNumber(totalVolume),
                    'total work',
                    Icons.fitness_center_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'SETS',
                    '$completedSets / $totalSets',
                    'completed',
                    Icons.layers_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'MAX LIFT',
                  Helpers.formatCompactNumber(maxWeight),
                  'heaviest set',
                  Icons.emoji_events_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: type == 'day' 
                  ? _buildStatCard(
                      'DURATION',
                      Helpers.formatDurationLong(totalDurationSeconds),
                      'total time',
                      Icons.timer_rounded,
                    )
                  : (type == 'week' 
                      ? _buildStatCard(
                          'WORKOUTS',
                          '${allDays.length}',
                          'sessions done',
                          Icons.event_available_rounded,
                        )
                      : _buildStatCard(
                          'SESSION AVG',
                          Helpers.formatCompactNumber(allDays.isEmpty ? 0 : totalVolume / allDays.length),
                          'vol per session',
                          Icons.calculate_rounded,
                        )
                    ),
              ),
            ],
          ),

            const SizedBox(height: 40),
            
            // Charts
            if (type == 'day') ...[
               _buildDayCharts(allDays.first),
            ] else ...[
               _buildHistoryChart(allDays, type),
            ],

            const SizedBox(height: 40),
            
            // Exercise Breakdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'EXERCISE BREAKDOWN',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...exerciseMap.values.map((s) => _buildExerciseBreakdownRow(context, s)),

            const SizedBox(height: 40),

            // Navigation Button (Only for days)
            if (type == 'day')
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DayOverviewScreen(
                          day: item as DayWorkout,
                          parentType: parentType,
                          parentId: parentId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    'GO TO ROUTINE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                  ),
                ),
              ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTag(String type, bool isComplete) {
    final color = isComplete ? AppConstants.completion : AppConstants.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${type.toUpperCase()} ${isComplete ? 'COMPLETE' : 'INCOMPLETE'}',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppConstants.accentPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppConstants.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppConstants.textPrimary,
              ),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCharts(DayWorkout day) {
    final weightExercises = day.exercises.where((ex) => !ex.isTimed && ex.progress > 0).toList();
    final timeExercises = day.exercises.where((ex) => ex.isTimed && !ex.isWeightedTimed && ex.progress > 0).toList();
    final weightTimeExercises = day.exercises.where((ex) => ex.isWeightedTimed && ex.progress > 0).toList();

    return Column(
      children: [
        if (weightExercises.isNotEmpty)
          _buildDistributionChart(
            'WEIGHT DISTRIBUTION',
            weightExercises,
            (ex) => ex.sets.where((s) => s.isChecked).fold(0.0, (sum, s) => sum + ((s.value ?? 0) * (s.reps ?? 1)).toDouble()),
          ),
        if (timeExercises.isNotEmpty)
          _buildDistributionChart(
            'TIME DISTRIBUTION',
            timeExercises,
            (ex) => ex.sets.where((s) => s.isChecked).fold(0.0, (sum, s) => sum + (s.timeSeconds?.toDouble() ?? s.value?.toDouble() ?? 0.0)),
            isTime: true,
          ),
        if (weightTimeExercises.isNotEmpty)
          _buildDistributionChart(
            'WEIGHTED-TIME DISTRIBUTION',
            weightTimeExercises,
            (ex) => ex.sets.where((s) => s.isChecked).fold(0.0, (sum, s) => sum + ((s.weight ?? 0) * (s.timeSeconds ?? s.value ?? 0) * (s.reps ?? 1)).toDouble()),
          ),
      ],
    );
  }

  Widget _buildDistributionChart(String title, List<ExerciseInstance> exercises, double Function(ExerciseInstance) extractor, {bool isTime = false}) {
     final maxValue = exercises.map(extractor).fold(0.0, (m, v) => v > m ? v : m);
     if (maxValue == 0) return const SizedBox.shrink();

     String dispUnit;
     double magDivisor;
     if (isTime) {
       dispUnit = '';
       magDivisor = 1.0;
     } else {
       final info = Helpers.getMagnitudeInfo(maxValue);
       dispUnit = info.$1;
       magDivisor = info.$2;
     }
     final (roundedMax, axisInterval) = isTime ? Helpers.getTimeAxisSpecs(maxValue, increments: 8) : Helpers.getAxisSpecs(maxValue, increments: 8);

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const SizedBox(height: 32),
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
                         isTime ? Helpers.formatDurationLong(rod.toY.toInt()) : Helpers.formatWithMagnitude(rod.toY, magDivisor, dispUnit, precision: 1),
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
                       getTitlesWidget: (val, meta) {
                         if (val.toInt() < 0 || val.toInt() >= exercises.length) return const SizedBox();
                          final name = exercises[val.toInt()].exerciseName;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(name.length > 4 ? name.substring(0, 4).toUpperCase() : name.toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppConstants.textMuted)),
                          );
                       }
                     )
                   ),
                   leftTitles: AxisTitles(
                     sideTitles: SideTitles(
                       showTitles: true,
                       reservedSize: isTime ? 65 : 45,
                       interval: axisInterval,
                       getTitlesWidget: (value, meta) => Padding(
                         padding: const EdgeInsets.only(right: 6),
                         child: FittedBox(
                           fit: BoxFit.scaleDown,
                           alignment: Alignment.centerRight,
                           child: Text(
                             isTime ? Helpers.formatDurationLong(value.toInt()) : Helpers.formatWithMagnitude(value, magDivisor, dispUnit, precision: 1),
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
                 barGroups: List.generate(exercises.length, (i) => BarChartGroupData(
                   x: i,
                   showingTooltipIndicators: [0],
                   barRods: [BarChartRodData(toY: extractor(exercises[i]), color: AppConstants.accentPrimary, width: 16, borderRadius: BorderRadius.circular(4))]
                 ))
               )
             ),
           ),
         ),
       ],
     );
  }

   Widget _buildHistoryChart(List<DayWorkout> days, String type) {
    if (days.isEmpty) return const SizedBox.shrink();
    
    // Process days into volumes
    double getDayVol(DayWorkout day) {
      double vol = 0;
      for (var ex in day.exercises) {
        for (var s in ex.sets.where((s) => s.isChecked)) {
           if (ex.isTimed) {
             vol += (ex.isWeightedTimed ? (s.weight ?? 0) * (s.timeSeconds ?? s.value ?? 0) * (s.reps ?? 1) : (s.timeSeconds ?? s.value ?? 0)).toDouble();
           } else {
             vol += ((s.value ?? 0) * (s.reps ?? 1)).toDouble();
           }
        }
      }
      return vol;
    }

    final List<MapEntry<String, double>> chartData = [];
    if (type == 'week') {
      // 7 Slots logic
      final slots = List.generate(7, (i) => 0.0);
      for (var d in days) {
        if (d.dayOfWeek != null) slots[d.dayOfWeek!] += getDayVol(d);
      }
      final labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
      for (int i = 0; i < 7; i++) {
        chartData.add(MapEntry(labels[i], slots[i]));
      }
    } else {
      // Program logic: Keep historical list
      final sortedDays = [...days]..sort((a,b) => (a.scheduledDate ?? DateTime.now()).compareTo(b.scheduledDate ?? DateTime.now()));
      for (var d in sortedDays) {
        final date = d.scheduledDate ?? d.completedDate ?? DateTime.now();
        chartData.add(MapEntry('${date.day}/${date.month}', getDayVol(d)));
      }
    }

    final maxValue = chartData.map((e) => e.value).fold(0.0, (m, v) => v > m ? v : m);
    if (maxValue == 0 && type != 'week') return const SizedBox.shrink();
    
    final (magUnit, magDivisor) = Helpers.getMagnitudeInfo(maxValue);
    final (roundedMax, axisInterval) = Helpers.getAxisSpecs(maxValue, increments: 8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          (type == 'week' ? 'DAILY VOLUME PROGRESSION' : 'WEEKLY PROGRESSION').toUpperCase(),
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppConstants.textMuted, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 24, 16, 12),
          decoration: BoxDecoration(
            color: AppConstants.bgCard.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(color: AppConstants.border.withValues(alpha: 0.3)),
          ),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                minY: 0,
                maxY: roundedMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.transparent,
                    tooltipPadding: EdgeInsets.zero,
                    tooltipMargin: 0,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        Helpers.formatWithMagnitude(rod.toY, magDivisor, magUnit, precision: 1),
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
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() < 0 || val.toInt() >= chartData.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(chartData[val.toInt()].key, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppConstants.textMuted)),
                        );
                      }
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: axisInterval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          Helpers.formatWithMagnitude(value, magDivisor, magUnit, precision: 1),
                          style: GoogleFonts.inter(fontSize: 9, color: AppConstants.textMuted, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.right,
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
                barGroups: List.generate(chartData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: [0],
                    barRods: [BarChartRodData(toY: chartData[i].value, color: AppConstants.accentSecondary, width: type == 'week' ? 24 : 16, borderRadius: BorderRadius.circular(4))]
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseBreakdownRow(BuildContext context, _ExerciseStats stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Helpers.formatCompactNumber(stats.volume)} vol • ${Helpers.formatDurationLong(stats.timeSeconds)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => showExerciseStatsDialog(
              context, 
              stats.id, 
              stats.name, 
              stats.isTimed, 
              isWeightedTimed: stats.isWeightedTimed
            ),
            icon: Icon(Icons.bar_chart_rounded, size: 20, color: AppConstants.accentPrimary.withValues(alpha: 0.6)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Exercise Stats',
          ),
        ],
      ),
    );
  }
}

class _ExerciseStats {
  final String id;
  final String name;
  final bool isTimed;
  final bool isWeightedTimed;
  double volume = 0;
  int timeSeconds = 0;

  _ExerciseStats({
    required this.id, 
    required this.name, 
    required this.isTimed, 
    required this.isWeightedTimed
  });
}
