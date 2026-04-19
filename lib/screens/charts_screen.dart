import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/exercise_library_provider.dart';

import '../models/day_workout.dart';
import '../models/custom_measurement.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'log_book_screen.dart';
import 'theme_settings_screen.dart';
import 'delete_data_screen.dart';
import '../services/storage_service.dart';
import '../services/media_storage_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _exerciseVariant = 'strength'; // 'strength', 'timed', 'weighted-timed'
  String _tagVariant = 'strength';
  String _selectedExercise = '';
  String _selectedTag = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _xAxisMode = 'session'; // 'session' or 'date'
  String _metric = 'Volume'; // 'Volume', 'Avg Weight', 'Max Weight'
  int? _touchedIndex;

  // Custom measurement
  String _measurementType = 'weight';
  DateTime _measurementDate = DateTime.now();
  final _measurementValueCtrl = TextEditingController();
  final _measurementUnitCtrl = TextEditingController(text: 'lbs');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _measurementValueCtrl.dispose();
    _measurementUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Charts',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_rounded),
            tooltip: 'Log Book',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogBookScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _showSettings(context),
            tooltip: 'Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Exercises'),
            Tab(text: 'Tags'),
            Tab(text: 'Custom'),
          ],
          indicatorColor: AppConstants.accentPrimary,
          labelColor: AppConstants.accentPrimary,
          unselectedLabelColor: AppConstants.textMuted,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ExerciseChartTab(
            selectedExercise: _selectedExercise,
            onExerciseChanged: (v) => setState(() => _selectedExercise = v),
            variant: _exerciseVariant,
            onVariantChanged: (v) => setState(() {
              _exerciseVariant = v;
            }),
            startDate: _startDate,
            endDate: _endDate,
            onStartDateChanged: (v) => setState(() => _startDate = v),
            onEndDateChanged: (v) => setState(() => _endDate = v),
            xAxisMode: _xAxisMode,
            onXAxisModeChanged: (v) => setState(() => _xAxisMode = v),
            metric: _metric,
            onMetricChanged: (v) => setState(() => _metric = v),
            touchedIndex: _touchedIndex,
            onTouch: (i) => setState(() => _touchedIndex = i),
          ),
          _TagChartTab(
            selectedTag: _selectedTag,
            onTagChanged: (v) => setState(() => _selectedTag = v),
            variant: _tagVariant,
            onVariantChanged: (v) => setState(() {
              _tagVariant = v;
            }),
            startDate: _startDate,
            endDate: _endDate,
            onStartDateChanged: (v) => setState(() => _startDate = v),
            onEndDateChanged: (v) => setState(() => _endDate = v),
            xAxisMode: _xAxisMode,
            onXAxisModeChanged: (v) => setState(() => _xAxisMode = v),
          ),
          _CustomMeasurementsTab(
            measurementType: _measurementType,
            onTypeChanged: (v) => setState(() => _measurementType = v),
            startDate: _startDate,
            endDate: _endDate,
            onStartDateChanged: (v) => setState(() => _startDate = v),
            onEndDateChanged: (v) => setState(() => _endDate = v),
            measurementDate: _measurementDate,
            onDateChanged: (d) => setState(() => _measurementDate = d),
            valueController: _measurementValueCtrl,
            unitController: _measurementUnitCtrl,
            xAxisMode: _xAxisMode,
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) {
        // ignore: unused_local_variable
        final mediaStorage = context.read<MediaStorageService>();
        return Padding(
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
                'Settings',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.accentSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: AppConstants.accentSecondary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Appearance',
                  style: GoogleFonts.inter(
                    color: AppConstants.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Change the app color theme',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ThemeSettingsScreen(),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppConstants.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    color: AppConstants.error,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Manage Data',
                  style: GoogleFonts.inter(
                    color: AppConstants.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Delete exercises, templates, schedules & more',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final storage = context.read<StorageService>();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeleteDataScreen(storage: storage),
                    ),
                  );
                },
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Date Range Filter ──────────────────────────────────────────────

class _DateRangeFilter extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;

  const _DateRangeFilter({
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
          ),
          child: Row(
            children: [
              Text(
                'Date Range:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
              const Spacer(),
              _buildQuickButton('1W', const Duration(days: 7)),
              const SizedBox(width: 4),
              _buildQuickButton('1M', const Duration(days: 30)),
              const SizedBox(width: 4),
              _buildQuickButton('1Y', const Duration(days: 365)),
              const SizedBox(width: 4),
              _buildQuickButton('All', null),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildDateButton(context, 'Start', startDate, true),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildDateButton(context, 'End', endDate, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButton(String label, Duration? durationToSubtract) {
    return Material(
      color: AppConstants.bgSurface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          final now = DateTime.now();
          onEndDateChanged(now);
          if (durationToSubtract != null) {
            onStartDateChanged(now.subtract(durationToSubtract));
          } else {
            onStartDateChanged(DateTime(2000));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime date,
    bool isStart,
  ) {
    return Material(
      color: AppConstants.bgSurface,
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppConstants.accentPrimary,
                    surface: AppConstants.bgCard,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            if (isStart) {
              // Ensure start is before end
              if (picked.isAfter(endDate)) {
                onEndDateChanged(picked);
              }
              onStartDateChanged(picked);
            } else {
              // Ensure end is after start
              if (picked.isBefore(startDate)) {
                onStartDateChanged(picked);
              }
              onEndDateChanged(picked);
            }
          }
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppConstants.border),
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppConstants.textMuted,
                    ),
                  ),
                  Text(
                    date.year == 2000
                        ? 'All Time'
                        : Helpers.formatDateShort(date),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppConstants.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XAxisToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _XAxisToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      child: Row(
        children: [
          Text(
            'X-Axis: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppConstants.textMuted,
            ),
          ),
          _toggleChip('Session', 'session', mode, onChanged),
          const SizedBox(width: 6),
          _toggleChip('Date', 'date', mode, onChanged),
        ],
      ),
    );
  }

  Widget _toggleChip(
    String label,
    String value,
    String current,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = current == value;
    return Material(
      color: isSelected
          ? AppConstants.accentPrimary.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppConstants.accentPrimary
                  : AppConstants.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final ValueChanged<String> onChanged;

  const _MetricToggle({
    required this.label,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    return Material(
      color: isSelected ? AppConstants.bgCard : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppConstants.accentPrimary)
                : Border.all(color: Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppConstants.textPrimary
                  : AppConstants.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exercise Chart Tab ────────────────────────────────────────────

class _ExerciseChartTab extends StatelessWidget {
  final String selectedExercise;
  final ValueChanged<String> onExerciseChanged;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final String xAxisMode;
  final ValueChanged<String> onXAxisModeChanged;
  final String variant;
  final ValueChanged<String> onVariantChanged;
  final String metric;
  final ValueChanged<String> onMetricChanged;
  final int? touchedIndex;
  final ValueChanged<int?> onTouch;

  const _ExerciseChartTab({
    required this.selectedExercise,
    required this.onExerciseChanged,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.xAxisMode,
    required this.onXAxisModeChanged,
    required this.variant,
    required this.onVariantChanged,
    required this.metric,
    required this.onMetricChanged,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final libraryProvider = context.watch<ExerciseLibraryProvider>();

    // Collect exercises that have data for the CURRENT variant
    final exerciseMap = <String, String>{}; 
    final isTimed = variant == 'timed' || variant == 'weighted-timed';
    final isWeightedTimed = variant == 'weighted-timed';

    for (final log in provider.allCompletedItems) {
      if (log['type'] == 'day') {
        final day = log['item'] as DayWorkout;
        for (final ex in day.exercises) {
          if (ex.isTimed == isTimed && ex.isWeightedTimed == isWeightedTimed) {
            final id = ex.exerciseDefinitionId;
            if (!exerciseMap.containsKey(id)) {
              final def = libraryProvider.exercises
                  .where((d) => d.id == id)
                  .firstOrNull;
              exerciseMap[id] = def?.name ?? ex.exerciseName;
            }
          }
        }
      }
    }

    // Get data points
    final dataPoints = _getExerciseDataPoints(
      provider,
      selectedExercise,
      variant,
      startDate,
      endDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
            child: _VariantToggle(
              current: variant,
              onChanged: onVariantChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Exercise selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
            ),
            child: _SearchableSelector(
              value: exerciseMap.containsKey(selectedExercise)
                  ? selectedExercise
                  : null,
              hint: 'Select Exercise',
              options: exerciseMap,
              onChanged: onExerciseChanged,
            ),
          ),

          const SizedBox(height: 12),
          // Metric selector (hidden for timed/weighted-timed exercises)
          if (selectedExercise.isNotEmpty && variant == 'strength') ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
              ),
              child: Row(
                children: [
                  Text(
                    'Metric: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppConstants.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _MetricToggle(
                          label: 'Volume',
                          value: 'Volume',
                          current: metric,
                          onChanged: onMetricChanged,
                        ),
                        _MetricToggle(
                          label: 'Reps',
                          value: 'Reps',
                          current: metric,
                          onChanged: onMetricChanged,
                        ),
                        _MetricToggle(
                          label: 'Avg Wgt',
                          value: 'Avg Weight',
                          current: metric,
                          onChanged: onMetricChanged,
                        ),
                        _MetricToggle(
                          label: 'Max Wgt',
                          value: 'Max Weight',
                          current: metric,
                          onChanged: onMetricChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _DateRangeFilter(
            startDate: startDate,
            endDate: endDate,
            onStartDateChanged: onStartDateChanged,
            onEndDateChanged: onEndDateChanged,
          ),
          const SizedBox(height: 8),
          _XAxisToggle(mode: xAxisMode, onChanged: onXAxisModeChanged),
          const SizedBox(height: 16),

          // Chart
          if (dataPoints.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${variant == 'weighted-timed' ? 'Total Work' : (variant == 'timed' ? 'Total Time' : metric)} Over Selected Time',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (touchedIndex != null &&
                      touchedIndex! >= 0 &&
                      xAxisMode == 'session') ...[
                    Builder(
                      builder: (context) {
                        if (touchedIndex! < dataPoints.length) {
                          final p = dataPoints[touchedIndex!];
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatCompactNumber(p.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentPrimary,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ] else if (touchedIndex != null && xAxisMode == 'date') ...[
                    Builder(
                      builder: (context) {
                        try {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            touchedIndex!,
                          );
                          final p = dataPoints.firstWhere(
                            (element) => Helpers.isSameDay(element.date, date),
                          );
                          final (u, d) = Helpers.getMagnitudeInfo(dataPoints.map((x) => x.value).fold(0, (a, b) => a > b ? a : b));
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatWithMagnitude(p.value, d, u)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentPrimary,
                            ),
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildChart(context, dataPoints),
            const SizedBox(height: 12),
            _StatsWidget(values: dataPoints.map((p) => p.value).toList()),

            // History
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
              ),
              child: Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
                final prPoint = maxValue > 0 ? dataPoints.firstWhere((p) => p.value == maxValue) : null;
                final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
                return Column(
                  children: dataPoints.reversed.map((p) => _buildHistoryCard(p, divisor, unit, isPr: p == prPoint)).toList(),
                );
              },
            ),
          ] else
            _emptyChartState(),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<_ChartDataPoint> dataPoints) {
    final spots = dataPoints.asMap().entries.map((entry) {
      if (xAxisMode == 'date') {
        return FlSpot(
          entry.value.date.millisecondsSinceEpoch.toDouble(),
          entry.value.value,
        );
      }
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
    final (roundedMax, axisInterval) = Helpers.getAxisSpecs(maxValue, increments: 8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      height: 250,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: roundedMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisInterval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppConstants.border, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: axisInterval,
                getTitlesWidget: (value, meta) => Text(
                  Helpers.formatWithMagnitude(value, divisor, unit, precision: 3),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppConstants.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: xAxisMode == 'date' && spots.length > 1
                    ? ((spots.last.x - spots.first.x) / 5).clamp(
                        86400000.0 * 2,
                        double.infinity,
                      ) // min 2 days
                    : (spots.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  if (xAxisMode == 'date') {
                    // Prevent crowding near the last point
                    if (spots.length > 1 &&
                        value != spots.last.x &&
                        (spots.last.x - value) < (86400000.0 * 1.5)) {
                      return const SizedBox();
                    }
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        Helpers.formatDateShort(date),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dataPoints.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppConstants.accentPrimary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: touchedIndex == spot.x.toInt() ? 5 : 3,
                      color: touchedIndex == spot.x.toInt()
                          ? AppConstants.accentPrimary
                          : AppConstants.accentPrimary.withValues(alpha: 0.7),
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppConstants.accentPrimary.withValues(alpha: 0.2),
                    AppConstants.accentPrimary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchSpotThreshold: 99999,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
                final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    Helpers.formatWithMagnitude(spot.y, divisor, unit, precision: 3),
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty) {
                onTouch(response.lineBarSpots!.first.x.toInt());
              }
            },
          ),
        ),
      ),
    );
  }

  double _calculateInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    if (range == 0) return 1;
    // Scale interval dynamically to prevent grid line explosion (target ~5 lines)
    double interval = range / 5;
    if (interval < 1 && range > 0) interval = range / 2;
    return (interval == 0) ? 1 : interval;
  }

  Widget _buildHistoryCard(_ChartDataPoint point, double divisor, String unit, {bool isPr = false}) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
        left: AppConstants.paddingMD,
        right: AppConstants.paddingMD,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: isPr ? AppConstants.accentGold : AppConstants.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatDate(point.date),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.textMuted,
            ),
          ),
          Row(
            children: [
              if (isPr)
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppConstants.accentGold,
                ),
              if (isPr) const SizedBox(width: 8),
              Text(
                Helpers.formatWithMagnitude(point.value, divisor, unit, precision: 3),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartDataPoint> _getExerciseDataPoints(
    WorkoutProvider provider,
    String exerciseId,
    String variant,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (exerciseId.isEmpty) return [];

    final isWeightedTimed = variant == 'weighted-timed';
    final isTimed = variant == 'timed' || isWeightedTimed;

    final points = <_ChartDataPoint>[];

    for (final log in provider.allCompletedItems) {
      final logDate = log['date'] as DateTime;

      // Ensure we compare start of day to be inclusive
      final startBound = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      final nextDayAfterEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));
      if (logDate.isBefore(startBound) || !logDate.isBefore(nextDayAfterEnd)) {
        continue;
      }

      if (log['type'] == 'day') {
        final day = log['item'] as DayWorkout;
        for (final ex in day.exercises) {
          if (ex.exerciseDefinitionId == exerciseId &&
              ex.isTimed == isTimed &&
              ex.isWeightedTimed == isWeightedTimed) {
            double metricValue = 0;
            if (isWeightedTimed) {
              // Formula: Weight * Time * Reps
              double totalVolume = 0;
              for (final s in ex.sets) {
                if (s.isChecked) {
                  final w = s.weight ?? 0;
                  final t = s.value ?? 0;
                  final r = (s.reps ?? 1).toDouble();
                  totalVolume += w * t * r;
                }
              }
              metricValue = totalVolume;
            } else if (isTimed) {
              // Always total volume for timed exercises
              double totalVolume = 0;
              for (final set in ex.sets) {
                if (set.isChecked) {
                  totalVolume += (set.value ?? 0).toDouble();
                }
              }
              metricValue = totalVolume;
            } else {
              if (metric == 'Volume') {
                double totalVolume = 0;
                for (final set in ex.sets) {
                  if (set.isChecked && set.reps != null && set.reps! > 0) {
                    double setVal = (set.value == null || set.value == 0)
                        ? 1.0
                        : set.value!;
                    totalVolume += setVal * set.reps!;
                  }
                }
                metricValue = totalVolume;
              } else if (metric == 'Reps') {
                int totalReps = 0;
                for (final set in ex.sets) {
                  if (set.isChecked && set.reps != null && set.reps! > 0) {
                    totalReps += set.reps!;
                  }
                }
                metricValue = totalReps.toDouble();
              } else if (metric == 'Avg Weight') {
                double totalWeight = 0;
                int validSets = 0;
                for (final set in ex.sets) {
                  if (set.isChecked && (set.value ?? 0) > 0) {
                    totalWeight += set.value!;
                    validSets++;
                  }
                }
                metricValue = validSets > 0 ? totalWeight / validSets : 0;
              } else if (metric == 'Max Weight') {
                double maxWeight = 0;
                for (final set in ex.sets) {
                  if (set.isChecked && (set.value ?? 0) > maxWeight) {
                    maxWeight = set.value!;
                  }
                }
                metricValue = maxWeight;
              }
            }
            if (metricValue > 0) {
              points.add(_ChartDataPoint(date: logDate, value: metricValue));
            }
          }
        }
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  Widget _emptyChartState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: AppConstants.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              selectedExercise.isEmpty
                  ? 'Select an exercise to view chart'
                  : 'No data yet for this exercise',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tag Chart Tab ─────────────────────────────────────────────────

class _TagChartTab extends StatefulWidget {
  final String selectedTag;
  final ValueChanged<String> onTagChanged;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final String variant;
  final ValueChanged<String> onVariantChanged;
  final String xAxisMode;
  final ValueChanged<String> onXAxisModeChanged;

  const _TagChartTab({
    required this.selectedTag,
    required this.onTagChanged,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.variant,
    required this.onVariantChanged,
    required this.xAxisMode,
    required this.onXAxisModeChanged,
  });

  @override
  State<_TagChartTab> createState() => _TagChartTabState();
}

class _TagChartTabState extends State<_TagChartTab> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final libraryProvider = context.watch<ExerciseLibraryProvider>();

    // Collect all unique tags for the CURRENT variant
    final tagMap = <String, String>{}; 
    final isTimed = widget.variant == 'timed' || widget.variant == 'weighted-timed';
    final isWeightedTimed = widget.variant == 'weighted-timed';

    for (final log in provider.allCompletedItems) {
      if (log['type'] == 'day') {
        final day = log['item'] as DayWorkout;
        for (final ex in day.exercises) {
          if (ex.isTimed == isTimed && ex.isWeightedTimed == isWeightedTimed) {
            final def = libraryProvider.exercises
                .where((d) => d.id == ex.exerciseDefinitionId)
                .firstOrNull;
            final currentTags = def?.tags ?? ex.exerciseTags;

            for (final tag in currentTags) {
              tagMap[tag] = tag;
            }
          }
        }
      }
    }

    // Get data points for selected tag
    final dataPoints = _getTagDataPoints(
      provider,
      libraryProvider,
      widget.selectedTag,
      widget.variant,
      widget.startDate,
      widget.endDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
            child: _VariantToggle(
              current: widget.variant,
              onChanged: widget.onVariantChanged,
            ),
          ),
          const SizedBox(height: 12),

          // Tag selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
            ),
            child: _SearchableSelector(
              value: tagMap.containsKey(widget.selectedTag)
                  ? widget.selectedTag
                  : null,
              hint: 'Select Tag',
              options: tagMap,
              onChanged: widget.onTagChanged,
            ),
          ),

          const SizedBox(height: 12),
          _DateRangeFilter(
            startDate: widget.startDate,
            endDate: widget.endDate,
            onStartDateChanged: widget.onStartDateChanged,
            onEndDateChanged: widget.onEndDateChanged,
          ),
          const SizedBox(height: 8),
          _XAxisToggle(
            mode: widget.xAxisMode,
            onChanged: widget.onXAxisModeChanged,
          ),
          const SizedBox(height: 16),

          // Chart
          if (dataPoints.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${widget.variant == 'weighted-timed' ? 'Total Work' : (widget.variant == 'timed' ? 'Total Time' : 'Volume')} Over Selected Time',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (_touchedIndex != null &&
                      _touchedIndex! >= 0 &&
                      widget.xAxisMode == 'session') ...[
                    Builder(
                      builder: (context) {
                        if (_touchedIndex! < dataPoints.length) {
                          final p = dataPoints[_touchedIndex!];
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatCompactNumber(p.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentSecondary,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ] else if (_touchedIndex != null &&
                      widget.xAxisMode == 'date') ...[
                    Builder(
                      builder: (context) {
                        try {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            _touchedIndex!,
                          );
                          final p = dataPoints.firstWhere(
                            (element) => Helpers.isSameDay(element.date, date),
                          );
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatCompactNumber(p.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentSecondary,
                            ),
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildTagChart(dataPoints),
            const SizedBox(height: 12),
            _StatsWidget(values: dataPoints.map((p) => p.value).toList()),

            // History
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
              ),
              child: Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
                final prPoint = maxValue > 0 ? dataPoints.firstWhere((p) => p.value == maxValue) : null;
                final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
                return Column(
                  children: dataPoints.reversed.map((p) => _buildHistoryCard(p, divisor, unit, isPr: p == prPoint)).toList(),
                );
              },
            ),
          ] else
            _emptyTagChartState(),
        ],
      ),
    );
  }

  Widget _buildTagChart(List<_ChartDataPoint> dataPoints) {
    final spots = dataPoints.asMap().entries.map((entry) {
      if (widget.xAxisMode == 'date') {
        return FlSpot(
          entry.value.date.millisecondsSinceEpoch.toDouble(),
          entry.value.value,
        );
      }
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
    final (roundedMax, axisInterval) = Helpers.getAxisSpecs(maxValue, increments: 8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      height: 250,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: roundedMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: axisInterval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppConstants.border, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: axisInterval,
                getTitlesWidget: (value, meta) => Text(
                  Helpers.formatWithMagnitude(value, divisor, unit, precision: 3),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppConstants.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: widget.xAxisMode == 'date' && spots.length > 1
                    ? ((spots.last.x - spots.first.x) / 5).clamp(
                        86400000.0 * 2,
                        double.infinity,
                      )
                    : (spots.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  if (widget.xAxisMode == 'date') {
                    if (spots.length > 1 &&
                        value != spots.last.x &&
                        (spots.last.x - value) < (86400000.0 * 1.5)) {
                      return const SizedBox();
                    }
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        Helpers.formatDateShort(date),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dataPoints.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppConstants.accentSecondary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                      color: _touchedIndex == spot.x.toInt()
                          ? AppConstants.accentSecondary
                          : AppConstants.accentSecondary.withValues(alpha: 0.7),
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppConstants.accentSecondary.withValues(alpha: 0.2),
                    AppConstants.accentSecondary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchSpotThreshold: 99999,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                final maxValue = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
                final (unit, divisor) = Helpers.getMagnitudeInfo(maxValue);
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    Helpers.formatWithMagnitude(spot.y, divisor, unit, precision: 3),
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty) {
                setState(
                  () => _touchedIndex = response.lineBarSpots!.first.x.toInt(),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  double _calcInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    if (range == 0) return 1;
    // Scale interval dynamically to prevent grid line explosion
    double interval = range / 5;
    if (interval < 1 && range > 0) interval = range / 2;
    return (interval == 0) ? 1 : interval;
  }

  List<_ChartDataPoint> _getTagDataPoints(
    WorkoutProvider provider,
    ExerciseLibraryProvider libraryProvider,
    String tag,
    String variant,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (tag.isEmpty) return [];

    final isWeightedTimed = variant == 'weighted-timed';
    final isTimed = variant == 'timed' || isWeightedTimed;

    final points = <_ChartDataPoint>[];

    for (final log in provider.allCompletedItems) {
      final logDate = log['date'] as DateTime;

      // Ensure we compare start of day to be inclusive
      if (logDate.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          ) ||
          logDate.isAfter(
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          )) {
        continue;
      }

      if (log['type'] == 'day') {
        final day = log['item'] as DayWorkout;
        double sessionTagVolume = 0;
        for (final ex in day.exercises) {
          if (ex.isTimed != isTimed || ex.isWeightedTimed != isWeightedTimed) {
            continue;
          }

          // Resolve current tags from library, fallback to cached
          final def = libraryProvider.exercises
              .where((d) => d.id == ex.exerciseDefinitionId)
              .firstOrNull;
          final currentTags = def?.tags ?? ex.exerciseTags;
          if (currentTags.contains(tag)) {
            for (final s in ex.sets) {
              if (s.isChecked) {
                if (ex.isWeightedTimed) {
                  sessionTagVolume +=
                      (s.weight ?? 0) * (s.value ?? 0) * (s.reps ?? 1);
                } else if (ex.isTimed) {
                  sessionTagVolume += (s.value ?? 0).toDouble();
                } else {
                  if (s.reps != null && s.reps! > 0) {
                    double setVal = (s.value == null || s.value == 0)
                        ? 1.0
                        : s.value!;
                    sessionTagVolume += setVal * s.reps!;
                  }
                }
              }
            }
          }
        }
        if (sessionTagVolume > 0) {
          points.add(_ChartDataPoint(date: logDate, value: sessionTagVolume));
        }
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  Widget _buildHistoryCard(_ChartDataPoint point, double divisor, String unit, {bool isPr = false}) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
        left: AppConstants.paddingMD,
        right: AppConstants.paddingMD,
      ),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: isPr ? AppConstants.accentGold : AppConstants.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Helpers.formatDate(point.date),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.textMuted,
            ),
          ),
          Row(
            children: [
              if (isPr)
                Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppConstants.accentGold,
                ),
              if (isPr) const SizedBox(width: 8),
              Text(
                Helpers.formatWithMagnitude(point.value, divisor, unit, precision: 3),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyTagChartState() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 40,
              color: AppConstants.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              widget.selectedTag.isEmpty
                  ? 'Select a tag to view chart'
                  : 'No data yet for this tag',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppConstants.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Measurements Tab ───────────────────────────────────────

class _CustomMeasurementsTab extends StatefulWidget {
  final String measurementType;
  final ValueChanged<String> onTypeChanged;
  final DateTime startDate;
  final DateTime endDate;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final DateTime measurementDate;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController valueController;
  final TextEditingController unitController;
  final String xAxisMode;

  const _CustomMeasurementsTab({
    required this.measurementType,
    required this.onTypeChanged,
    required this.startDate,
    required this.endDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    required this.measurementDate,
    required this.onDateChanged,
    required this.valueController,
    required this.unitController,
    required this.xAxisMode,
  });

  @override
  State<_CustomMeasurementsTab> createState() => _CustomMeasurementsTabState();
}

class _CustomMeasurementsTabState extends State<_CustomMeasurementsTab> {
  int? _touchedIndex;
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<WorkoutProvider>();
        final goal = provider.getMeasurementGoal(widget.measurementType);
        if (goal != null) {
          _goalController.text = goal.toStringAsFixed(goal == goal.roundToDouble() ? 0 : 2);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _CustomMeasurementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.measurementType != widget.measurementType) {
      final goal = context.read<WorkoutProvider>().getMeasurementGoal(widget.measurementType);
      _goalController.text = goal != null 
          ? goal.toStringAsFixed(goal == goal.roundToDouble() ? 0 : 2) 
          : '';
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    // Collect all measurement types: defaults + any custom ones from data
    final defaultTypes = [
      'weight',
      'body_fat',
      'waist',
      'chest',
      'arms',
      'thighs',
    ];
    final allTypes = <String>{
      ...defaultTypes,
      ...provider.measurementTypes,
    }.toList()..sort();

    final typeLabels = <String, String>{
      'weight': 'Weight',
      'body_fat': 'Body Fat %',
      'waist': 'Waist',
      'chest': 'Chest',
      'arms': 'Arms',
      'thighs': 'Thighs',
    };

    // Get data for selected type
    final dataPoints = provider.getMeasurementsByType(
      widget.measurementType,
      widget.startDate,
      widget.endDate,
    );

    final goal = provider.getMeasurementGoal(widget.measurementType);
    String? prId;

    if (goal != null && dataPoints.isNotEmpty) {
      double minDiff = double.infinity;
      for (var p in dataPoints) {
        final diff = (p.value - goal).abs();
        if (diff < minDiff) {
           minDiff = diff;
           prId = p.id;
        }
      }
    } else if (dataPoints.isNotEmpty) {
      final maxValue = dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        for (var p in dataPoints) {
          if (p.value == maxValue) {
            prId = p.id;
            break;
          }
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header with delete button for custom types
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Measurement',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
              ),
              if (!defaultTypes.contains(widget.measurementType))
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppConstants.error,
                    size: 22,
                  ),
                  onPressed: () {
                    final label =
                        typeLabels[widget.measurementType] ??
                        widget.measurementType;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppConstants.bgCard,
                        title: Text(
                          'Delete all "$label" entries?',
                          style: GoogleFonts.inter(
                            color: AppConstants.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        content: Text(
                          'This will permanently delete every logged measurement for "$label", and remove it from the list if it was a custom type.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () {
                              provider.deleteMeasurementsByType(
                                widget.measurementType,
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('All "$label" entries deleted'),
                                ),
                              );
                              // Reset to a default type after deletion
                              widget.onTypeChanged('weight');
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppConstants.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Delete all entries of this type',
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Type selector dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppConstants.bgSurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(color: AppConstants.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: allTypes.contains(widget.measurementType)
                        ? widget.measurementType
                        : null,
                    hint: Text(
                      'Select Measurement Type',
                      style: GoogleFonts.inter(color: AppConstants.textMuted),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: AppConstants.bgCard,
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    items: allTypes
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(typeLabels[type] ?? type),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) widget.onTypeChanged(v);
                    },
                  ),
                ),
                // Add custom type
                IconButton(
                  icon: Icon(
                    Icons.add_rounded,
                    color: AppConstants.accentPrimary,
                    size: 22,
                  ),
                  onPressed: () => _showAddTypeDialog(context),
                  tooltip: 'Add custom type',
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Goal field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppConstants.bgSurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(color: AppConstants.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: AppConstants.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _goalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Goal (Optional)',
                      hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      final goal = double.tryParse(val.trim());
                      if (goal != null) {
                        provider.setMeasurementGoal(widget.measurementType, goal);
                      } else {
                        provider.clearMeasurementGoal(widget.measurementType);
                      }
                    },
                    onTapOutside: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final val = _goalController.text.trim();
                      final goal = double.tryParse(val);
                      if (goal != null) {
                        provider.setMeasurementGoal(widget.measurementType, goal);
                      } else {
                        provider.clearMeasurementGoal(widget.measurementType);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _DateRangeFilter(
            startDate: widget.startDate,
            endDate: widget.endDate,
            onStartDateChanged: widget.onStartDateChanged,
            onEndDateChanged: widget.onEndDateChanged,
          ),
          const SizedBox(height: 16),

          // Add new measurement
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppConstants.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Measurement',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: widget.measurementDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          widget.onDateChanged(date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        Helpers.formatDateShort(widget.measurementDate),
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        foregroundColor: AppConstants.accentSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: widget.valueController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: AppConstants.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Value',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: widget.unitController,
                        style: GoogleFonts.inter(
                          color: AppConstants.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Unit',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final val = double.tryParse(
                          widget.valueController.text.trim(),
                        );
                        if (val == null) return;
                        final unit = widget.unitController.text.trim();
                        
                        final now = DateTime.now();
                        final isToday = widget.measurementDate.year == now.year &&
                                        widget.measurementDate.month == now.month &&
                                        widget.measurementDate.day == now.day;
                        
                        final finalDate = isToday 
                            ? now 
                            : DateTime(
                                widget.measurementDate.year,
                                widget.measurementDate.month,
                                widget.measurementDate.day,
                                now.hour,
                                now.minute,
                                now.second,
                                now.millisecond,
                              );

                        final measurement = CustomMeasurement(
                          id: const Uuid().v4(),
                          date: finalDate,
                          type: widget.measurementType,
                          value: val,
                          unit: unit.isEmpty ? null : unit,
                        );
                        provider.saveMeasurement(measurement);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Logged $val ${unit.isEmpty ? widget.measurementType : unit} for ${Helpers.formatDateShort(widget.measurementDate)}',
                            ),
                          ),
                        );
                        widget.valueController.clear();
                      },
                      child: const Text('Log'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Chart
          if (dataPoints.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingMD,
                vertical: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Measurement Over Selected Time',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  if (_touchedIndex != null &&
                      _touchedIndex! >= 0 &&
                      widget.xAxisMode == 'session') ...[
                    Builder(
                      builder: (context) {
                        if (_touchedIndex! < dataPoints.length) {
                          final p = dataPoints[_touchedIndex!];
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatCompactNumber(p.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentTertiary,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ] else if (_touchedIndex != null &&
                      widget.xAxisMode == 'date') ...[
                    Builder(
                      builder: (context) {
                        try {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            _touchedIndex!,
                          );
                          final p = dataPoints.firstWhere(
                            (element) => Helpers.isSameDay(element.date, date),
                          );
                          return Text(
                            '${Helpers.formatDateShort(p.date)} - ${Helpers.formatCompactNumber(p.value)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppConstants.accentTertiary,
                            ),
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            _buildMeasurementChart(dataPoints, provider.getMeasurementGoal(widget.measurementType)),
            const SizedBox(height: 12),
            _StatsWidget(values: dataPoints.map((m) => m.value).toList()),
          ] else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 40,
                      color: AppConstants.textMuted.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log measurements to see trends',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // History
          if (dataPoints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'History',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...dataPoints.reversed
                .take(20)
                .map(
                  (m) => Dismissible(
                    key: Key(m.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: AppConstants.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete_rounded,
                        color: AppConstants.error,
                      ),
                    ),
                    onDismissed: (_) {
                      provider.deleteMeasurement(m.id);
                    },
                    child: GestureDetector(
                      onTap: () =>
                          _showEditMeasurementDialog(context, m, provider),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Builder(
                          builder: (context) {
                            final isPr = m.id == prId;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppConstants.bgCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isPr ? AppConstants.accentGold : AppConstants.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Helpers.formatDate(m.date),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppConstants.textMuted,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (isPr)
                                        Icon(
                                          Icons.emoji_events_rounded,
                                          size: 16,
                                          color: AppConstants.accentGold,
                                        ),
                                      if (isPr) const SizedBox(width: 8),
                                      Text(
                                        m.value.toStringAsFixed(
                                          m.value == m.value.roundToDouble() ? 0 : 1,
                                        ),
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textPrimary,
                                        ),
                                      ),
                                      if (m.unit != null) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          m.unit!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppConstants.textMuted,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 14,
                                        color: AppConstants.textMuted.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMeasurementChart(List<CustomMeasurement> data, double? goal) {
    final spots = data.asMap().entries.map((entry) {
      if (widget.xAxisMode == 'date') {
        return FlSpot(
          entry.value.date.millisecondsSinceEpoch.toDouble(),
          entry.value.value,
        );
      }
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      height: 250,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: AppConstants.border, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppConstants.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                interval: widget.xAxisMode == 'date' && spots.length > 1
                    ? ((spots.last.x - spots.first.x) / 5).clamp(
                        86400000.0 * 2,
                        double.infinity,
                      )
                    : (spots.length / 5).ceilToDouble().clamp(1, 100),
                getTitlesWidget: (value, meta) {
                  if (widget.xAxisMode == 'date') {
                    if (spots.length > 1 &&
                        value != spots.last.x &&
                        (spots.last.x - value) < (86400000.0 * 1.5)) {
                      return const SizedBox();
                    }
                    final date = DateTime.fromMillisecondsSinceEpoch(
                      value.toInt(),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        Helpers.formatDateShort(date),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  final idx = value.toInt();
                  if (idx >= 0 && idx < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${idx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (goal != null)
                HorizontalLine(
                  y: goal,
                  color: AppConstants.accentSecondary,
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    labelResolver: (_) => 'Goal',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.accentSecondary,
                    ),
                  ),
                ),
            ],
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppConstants.accentTertiary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: _touchedIndex == spot.x.toInt() ? 5 : 3,
                      color: _touchedIndex == spot.x.toInt()
                          ? AppConstants.accentTertiary
                          : AppConstants.accentTertiary.withValues(alpha: 0.7),
                      strokeWidth: 0,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppConstants.accentTertiary.withValues(alpha: 0.2),
                    AppConstants.accentTertiary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchSpotThreshold: 99999,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final unitStr = idx < data.length && data[idx].unit != null
                      ? ' ${data[idx].unit}'
                      : '';
                  return LineTooltipItem(
                    '${Helpers.formatCompactNumber(spot.y)}$unitStr',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTypeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Measurement Type'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g., calves, neck, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final type = controller.text.trim().toLowerCase();
              if (type.isNotEmpty) {
                context.read<WorkoutProvider>().addCustomMeasurementType(type);
                widget.onTypeChanged(type);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMeasurementDialog(
    BuildContext context,
    CustomMeasurement m,
    WorkoutProvider provider,
  ) {
    final ctrl = TextEditingController(
      text: m.value.toStringAsFixed(m.value == m.value.roundToDouble() ? 0 : 1),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Measurement'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
          decoration: InputDecoration(
            hintText: 'Value',
            suffixText: m.unit ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMeasurement(m.id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AppConstants.error),
            ),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null) {
                final updated = CustomMeasurement(
                  id: m.id,
                  type: m.type,
                  value: val,
                  unit: m.unit,
                  date: m.date,
                );
                provider.updateMeasurement(updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Stats Widget ──────────────────────────────────────────────────

class _StatsWidget extends StatelessWidget {
  final List<double> values;

  const _StatsWidget({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox();

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final latest = values.last;

    double median;
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length % 2 == 1) {
      median = sorted[mid];
    } else {
      median = (sorted[mid - 1] + sorted[mid]) / 2;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Min', min),
          _stat('Avg', avg),
          _stat('Median', median),
          _stat('Max', max),
          _stat('Latest', latest),
        ],
      ),
    );
  }

  Widget _stat(String label, double value) {
    return Column(
      children: [
        Text(
          Helpers.formatCompactNumber(value),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppConstants.accentPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted),
        ),
      ],
    );
  }
}

class _SearchableSelector extends StatelessWidget {
  final String? value;
  final String hint;
  final Map<String, String> options; // key -> label
  final ValueChanged<String> onChanged;

  const _SearchableSelector({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = value != null ? options[value] : null;

    return InkWell(
      onTap: () => _showSearch(context),
      borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.bgSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusSM),
          border: Border.all(color: AppConstants.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label ?? hint,
                style: GoogleFonts.inter(
                  color: label != null
                      ? AppConstants.textPrimary
                      : AppConstants.textMuted,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppConstants.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppConstants.bgDark,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusLG),
          ),
        ),
        child: _SearchDialog(
          hint: hint,
          options: options,
          onSelected: (v) {
            onChanged(v);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final String hint;
  final Map<String, String> options;
  final ValueChanged<String> onSelected;

  const _SearchDialog({
    required this.hint,
    required this.options,
    required this.onSelected,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final _controller = TextEditingController();
  late List<String> _filteredKeys;

  @override
  void initState() {
    super.initState();
    _filteredKeys = widget.options.keys.toList();
    _filteredKeys.sort(
      (a, b) => widget.options[a]!.compareTo(widget.options[b]!),
    );
    _controller.addListener(_filter);
  }

  void _filter() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredKeys = widget.options.keys.where((k) {
        return widget.options[k]!.toLowerCase().contains(query);
      }).toList();
      _filteredKeys.sort(
        (a, b) => widget.options[a]!.compareTo(widget.options[b]!),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      padding: EdgeInsets.only(
        top: 20,
        left: AppConstants.paddingMD,
        right: AppConstants.paddingMD,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppConstants.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search ${widget.hint.toLowerCase()}...',
              prefixIcon: const Icon(Icons.search_rounded),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            style: GoogleFonts.inter(color: AppConstants.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredKeys.length,
              separatorBuilder: (context, index) =>
                  Divider(color: AppConstants.border.withValues(alpha: 0.5)),
              itemBuilder: (ctx, i) {
                final k = _filteredKeys[i];
                return ListTile(
                  title: Text(
                    widget.options[k]!,
                    style: GoogleFonts.inter(
                      color: AppConstants.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppConstants.textMuted,
                  ),
                  onTap: () => widget.onSelected(k),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartDataPoint {
  final DateTime date;
  final double value;

  _ChartDataPoint({required this.date, required this.value});
}
class _VariantToggle extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _VariantToggle({
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          _buildItem('Strength', 'strength', Icons.fitness_center_rounded),
          _buildItem('Timed', 'timed', Icons.timer_rounded),
          _buildItem('Wt-Timed', 'weighted-timed', Icons.speed_rounded),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String value, IconData icon) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppConstants.bgCard : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? AppConstants.accentPrimary
                    : AppConstants.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppConstants.textPrimary
                      : AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
