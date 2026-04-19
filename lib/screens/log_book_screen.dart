import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'day_overview_screen.dart';
import 'logged_item_stats_screen.dart';

class LogBookScreen extends StatelessWidget {
  const LogBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final logs = provider.allCompletedItems;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log Book',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_rounded,
                    size: 56,
                    color: AppConstants.textMuted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No completed workouts yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed workouts will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppConstants.textMuted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                return _LogEntryCard(logData: logs[index]);
              },
            ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final Map<String, dynamic> logData;

  const _LogEntryCard({required this.logData});

  String get _type => logData['type'] as String;
  dynamic get _item => logData['item'];
  DateTime get _date => logData['date'] as DateTime;
  String? get _parentType => logData['parentType'] as String?;
  String? get _parentId => logData['parentId'] as String?;
  String? get _parentName => logData['parentName'] as String?;

  String get _title {
    if (_type == 'day') {
      return (_item as DayWorkout).displayTitle;
    } else if (_type == 'week') {
      return (_item as WeekWorkout).displayTitle;
    } else {
      return (_item as ProgramWorkout).displayTitle;
    }
  }

  IconData get _icon {
    switch (_type) {
      case 'program':
        return Icons.calendar_month_rounded;
      case 'week':
        return Icons.view_week_rounded;
      default:
        return Icons.today_rounded;
    }
  }

  LinearGradient get _gradient {
    switch (_type) {
      case 'program':
        return AppConstants.purpleGradient;
      case 'week':
        return AppConstants.warmGradient;
      default:
        return AppConstants.completedGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Material(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LoggedItemStatsScreen(
                  item: _item,
                  type: _type,
                  parentId: _parentId,
                  parentType: _parentType,
                ),
              ),
            );
          },
          onLongPress: () => _showLongPressOptions(context),
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: _gradient,
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                  child: Icon(_icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                        children: [
                          _buildTypeTag(),
                          const Spacer(),
                          Text(
                            Helpers.formatDate(_date),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppConstants.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_parentName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _parentName!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppConstants.textSecondary,
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
    );
  }

  bool get _isFullyCompleted {
    final item = _item;
    if (_type == 'day') return (item as DayWorkout).isFullyCompleted;
    if (_type == 'week') return (item as WeekWorkout).isCompleted;
    return (item as ProgramWorkout).isCompleted;
  }

  Widget _buildTypeTag() {
    final isComplete = _isFullyCompleted;
    final color = isComplete ? AppConstants.completion : AppConstants.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _type.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        if (!isComplete) ...[
          const SizedBox(width: 8),
          Text(
            'PARTIALLY COMPLETE',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppConstants.warning,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }

  String _buildSubtitle() {
    int totalSets = 0;
    int totalReps = 0;
    double volume = 0;
    int timedVol = 0;
    double weightedTimedWork = 0;

    void processDay(DayWorkout day) {
      for (final ex in day.exercises) {
        for (final s in ex.sets) {
          if (s.isChecked) {
            totalSets++;
            if (ex.isTimed) {
              if (ex.isWeightedTimed) {
                weightedTimedWork += (s.weight ?? 0) * (s.value ?? 0) * (s.reps ?? 1);
              } else {
                timedVol += (s.value ?? 0).toInt();
              }
            } else {
              totalReps += (s.reps ?? 0);
              volume += ((s.reps ?? 0) * (s.value ?? 0));
            }
          }
        }
      }
    }

    if (_type == 'day') {
      processDay(_item as DayWorkout);
    } else if (_type == 'week') {
      for (final d in (_item as WeekWorkout).days) {
        processDay(d);
      }
    } else {
      for (final w in (_item as ProgramWorkout).weeks) {
        for (final d in w.days) {
          processDay(d);
        }
      }
    }

    final List<String> parts = [];
    if (volume > 0) parts.add('Vol: ${volume.toInt()}');
    if (totalReps > 0) parts.add('Reps: $totalReps');
    if (totalSets > 0) parts.add('Sets: $totalSets');
    if (timedVol > 0) parts.add('Time: ${Helpers.formatDurationLong(timedVol)}');
    if (weightedTimedWork > 0) parts.add('W-Timed: ${weightedTimedWork.toInt()}');

    return parts.join('  •  ');
  }

  void _showLongPressOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (_type == 'day')
              ListTile(
                leading: Icon(
                  Icons.fitness_center_rounded,
                  color: AppConstants.accentPrimary,
                ),
                title: Text(
                  'View Workout',
                  style: GoogleFonts.inter(color: AppConstants.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToDay(context);
                },
              ),
            ListTile(
              leading: Icon(Icons.edit_off_rounded, color: AppConstants.error),
              title: Text(
                'Remove from Log',
                style: GoogleFonts.inter(color: AppConstants.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteConfirm(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToDay(BuildContext context) {
    if (_type != 'day') return;
    final day = _item as DayWorkout;
    final provider = context.read<WorkoutProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayOverviewScreen(
          day: day,
          parentType: _parentType,
          parentId: _parentId,
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    final provider = context.read<WorkoutProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Log?'),
        content: Text(
          'Un-complete "$_title"? This will not delete it from your schedule, but it will be marked as incomplete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_type == 'day') {
                final day = _item as DayWorkout;
                for (final ex in day.exercises) {
                  for (final s in ex.sets) {
                    s.isChecked = false;
                  }
                }
                day.isCompleted = false; // Add this
                day.completedDate = null;
                if (_parentType == null) {
                  provider.saveScheduledDay(day);
                } else if (_parentType == 'week') {
                  final w = provider.scheduledWeeks.firstWhere(
                    (w) => w.id == _parentId,
                  );
                  final dIdx = w.days.indexWhere((d) => d.id == day.id);
                  if (dIdx != -1) w.days[dIdx] = day;
                  provider.saveScheduledWeek(w);
                } else if (_parentType == 'program') {
                  final p = provider.scheduledPrograms.firstWhere(
                    (p) => p.id == _parentId,
                  );
                  for (final w in p.weeks) {
                    final dIdx = w.days.indexWhere((d) => d.id == day.id);
                    if (dIdx != -1) w.days[dIdx] = day;
                  }
                  provider.saveScheduledProgram(p);
                }
              } else if (_type == 'week') {
                final w = _item as WeekWorkout;
                for (final d in w.days) {
                  for (final ex in d.exercises) {
                    for (final s in ex.sets) {
                      s.isChecked = false;
                    }
                  }
                  d.isCompleted = false; // Add this
                  d.completedDate = null;
                }
                w.completedDate = null;
                provider.saveScheduledWeek(w);
              } else if (_type == 'program') {
                final p = _item as ProgramWorkout;
                for (final w in p.weeks) {
                  for (final d in w.days) {
                    for (final ex in d.exercises) {
                      for (final s in ex.sets) {
                        s.isChecked = false;
                      }
                    }
                    d.isCompleted = false; // Add this
                    d.completedDate = null;
                  }
                  w.completedDate = null;
                }
                p.completedDate = null;
                provider.saveScheduledProgram(p);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Un-complete'),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
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
              _title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completed ${Helpers.formatDate(_date)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppConstants.textMuted,
              ),
            ),
            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                color: AppConstants.bgSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                children: [
                  Text(
                    'Workout Stats',
                    style: GoogleFonts.inter(
                      color: AppConstants.completion,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSubtitle(),
                    style: GoogleFonts.inter(
                      color: AppConstants.textPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                if (_type == 'day')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _navigateToDay(context);
                      },
                      icon: const Icon(Icons.fitness_center_rounded, size: 18),
                      label: const Text('View Workout'),
                    ),
                  ),
                if (_type == 'day') const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showDeleteConfirm(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppConstants.error,
                      side: BorderSide(color: AppConstants.error),
                    ),
                    icon: const Icon(Icons.edit_off_rounded, size: 18),
                    label: const Text('Remove from Log'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom),
          ],
        ),
      ),
    );
  }
}
