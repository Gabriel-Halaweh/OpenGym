import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

/// Dummy widgets for the Guide Book to demonstrate features visually.
class GuideVisuals {
  /// A complete monthly calendar grid representation.
  static Widget dummyCalendar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.chevron_left_rounded, color: AppConstants.textPrimary),
              Text(
                'March 2026',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppConstants.textPrimary,
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppConstants.textPrimary),
            ],
          ),
          const SizedBox(height: 20),
          // Day names
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) {
                return SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      d,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Calendar Grid (5 weeks)
          _calendarWeek(['1', '2', '3', '4', '5', '6', '7']),
          _calendarWeek(['8', '9', '10', '11', '12', '13', '14'],
              dots: {
                '8': [AppConstants.completion],
                '10': [AppConstants.warning],
                '12': [AppConstants.accentGold],
              }),
          _calendarWeek(['15', '16', '17', '18', '19', '20', '21'],
              selectedDay: '17',
              today: '18',
              dots: {
                '15': [AppConstants.completion],
                '16': [AppConstants.completion],
                '17': [AppConstants.accentPrimary], // Planned
                '19': [AppConstants.error], // Missed
              }),
          _calendarWeek(['22', '23', '24', '25', '26', '27', '28'],
              dots: {
                '22': [AppConstants.accentPrimary],
                '24': [AppConstants.accentPrimary],
              }),
          _calendarWeek(['29', '30', '31', '', '', '', ''],
              dots: {
                '29': [AppConstants.accentPrimary],
              }),
        ],
      ),
    );
  }

  static Widget _calendarWeek(List<String> days,
      {String? selectedDay, String? today, Map<String, List<Color>>? dots}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((day) {
          if (day.isEmpty) return const SizedBox(width: 32, height: 40);
          final isSelected = day == selectedDay;
          final isToday = day == today;
          final dayDots = dots?[day];

          return SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.accentPrimary
                        : (isToday
                            ? AppConstants.accentPrimary.withValues(alpha: 0.15)
                            : Colors.transparent),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: (isSelected || isToday) ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? AppConstants.accentPrimary : AppConstants.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: (dayDots ?? []).map((c) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  )).toList(),
                ),
                if (dayDots == null || dayDots.isEmpty) const SizedBox(height: 6),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// A sample workout card as seen on the Home screen.
  static Widget workoutCard({
    required String title,
    String? programName,
    double? programProgress,
    String? weekName,
    double? weekProgress,
    required double dayProgress,
    required int completedSets,
    required int totalSets,
    bool isCompleted = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(
          color: isCompleted ? AppConstants.completion.withValues(alpha: 0.6) : AppConstants.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isCompleted ? AppConstants.completedGradient : AppConstants.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isCompleted ? Icons.check_rounded : Icons.fitness_center_rounded,
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
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (programName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        programName.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppConstants.accentTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: programProgress ?? 0,
                                backgroundColor: AppConstants.bgSurface,
                                valueColor: AlwaysStoppedAnimation(AppConstants.progressProgram),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${((programProgress ?? 0) * 100).toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.progressProgram),
                          ),
                        ],
                      ),
                    ],
                    if (weekName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        weekName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.accentPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: weekProgress ?? 0,
                                backgroundColor: AppConstants.bgSurface,
                                valueColor: AlwaysStoppedAnimation(AppConstants.progressWeek),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${((weekProgress ?? 0) * 100).toInt()}%',
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppConstants.progressWeek),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dayProgress,
              backgroundColor: AppConstants.bgSurface,
              valueColor: AlwaysStoppedAnimation(AppConstants.progressDay),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${completedSets}/${totalSets} sets',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500, color: AppConstants.textMuted),
              ),
              Text(
                '${(dayProgress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.progressDay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Sample dots indicators as seen in the calendar with functional labels.
  static Widget dotLegend(List<Map<String, dynamic>> items) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item['label'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.4,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// A premium-styled note or tip callout.
  static Widget callout({
    required String title,
    required String message,
    IconData icon = Icons.lightbulb_outline_rounded,
    Color? color,
  }) {
    final themeColor = color ?? AppConstants.accentSecondary;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: themeColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A sample template card accurate to the Workouts tab.
  static Widget templateItem({
    required String title,
    required String subtitle,
    String? note,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle_rounded, color: AppConstants.textMuted, size: 20),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                if (note != null) ...[
                   const SizedBox(height: 4),
                   Text(
                     note,
                     style: GoogleFonts.inter(
                       fontSize: 12,
                       color: AppConstants.textSecondary,
                       fontStyle: FontStyle.italic,
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppConstants.textMuted, size: 24),
        ],
      ),
    );
  }

  /// A sample exercise entry accurate to the routine editor.
  static Widget exerciseRow({
    required String name,
    required List<Map<String, String>> sets,
    bool isTemplate = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
            children: [
              Icon(Icons.drag_handle_rounded, color: AppConstants.textMuted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: AppConstants.progressDay, size: 20),
              const SizedBox(width: 8),
              Icon(Icons.percent_rounded, color: AppConstants.accentGold, size: 20),
              const SizedBox(width: 8),
              Icon(Icons.timer_off_rounded, color: AppConstants.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Field labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMD),
            child: Row(
              children: [
                const SizedBox(width: 28), // Spacer for set number
                Expanded(
                  child: Text(
                    'REPS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textMuted.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WEIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.textMuted.withValues(alpha: 0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (!isTemplate) const SizedBox(width: 44), // Spacer for checkmark
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...sets.asMap().entries.map((entry) {
            final idx = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppConstants.bgSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.border.withValues(alpha: 0.1)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(set['reps'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppConstants.bgSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.border.withValues(alpha: 0.1)),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(set['weight'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textPrimary)),
                    ),
                  ),
                  if (!isTemplate) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppConstants.bgSurface.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_rounded, color: AppConstants.textMuted.withValues(alpha: 0.3), size: 18),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Dummy widget for the Start Routine (Overview) screen.
  static Widget startRoutineDummy() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        children: [
          _startRoutineItem(1, 'Bench Press', '3 sets x 8 reps', useMax: true),
          _startRoutineItem(2, 'Incline DB Press', '3 sets x 10 reps', isDone: true),
          _startRoutineItem(3, 'Dips', '2 sets x AMRAP'),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                      border: Border.all(color: AppConstants.accentPrimary),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_note_rounded, color: AppConstants.accentPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text('Edit Routine', style: GoogleFonts.inter(color: AppConstants.accentPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppConstants.accentPrimary,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Start Routine', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static Widget _startRoutineItem(int index, String name, String summary, {bool useMax = false, bool isDone = false}) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? AppConstants.completion.withValues(alpha: 0.1) : AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: isDone ? AppConstants.completion.withValues(alpha: 0.5) : AppConstants.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDone ? AppConstants.completion.withValues(alpha: 0.2) : AppConstants.bgSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isDone 
                ? Icon(Icons.check_rounded, color: AppConstants.completion, size: 18)
                : Text('$index', style: GoogleFonts.jetBrainsMono(color: AppConstants.accentPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
                Text(summary, style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
              ],
            ),
          ),
          if (useMax)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.percent_rounded, size: 10, color: AppConstants.accentGold),
                  const SizedBox(width: 2),
                  Text('MAX', style: TextStyle(color: AppConstants.accentGold, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Dummy for the Active Workout Interface.
  static Widget activeWorkoutDummy() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Stack(
        children: [
          // 0. Background Depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppConstants.bgSurface, AppConstants.bgDark],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            ),
          ),
          
          // 1. Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.bgSurface.withValues(alpha: 0.8),
                border: Border(bottom: BorderSide(color: AppConstants.accentPrimary.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BENCH PRESS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5, color: AppConstants.accentPrimary)),
                        Text('Chest', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppConstants.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.bar_chart_rounded, color: AppConstants.accentSecondary.withValues(alpha: 0.6), size: 18),
                  const SizedBox(width: 8),
                  Icon(Icons.camera_alt_rounded, color: AppConstants.accentPrimary, size: 20),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_note_rounded, color: AppConstants.accentPrimary, size: 20),
                ],
              ),
            ),
          ),
          
          // 2. Set rows
          Positioned(
            top: 70, left: 16, right: 16,
            child: Column(
              children: [
                activeSetRow('1', '225', '8', true),
                activeSetRow('2', '225', '8', false, isCurrent: true),
                activeSetRow('3', '225', '8', false),
              ],
            ),
          ),
          
          // 3. Floating Nav
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navBtn(Icons.arrow_back_ios_new_rounded),
                const Spacer(),
                _navBtn(Icons.arrow_forward_ios_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _navBtn(IconData icon) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: AppConstants.accentPrimary, size: 18),
    );
  }

  static Widget _activeEntryDummy(String value, String hint) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppConstants.bgSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.1)),
      ),
      alignment: Alignment.center,
      child: Text(
        value.isEmpty ? hint : value,
        style: GoogleFonts.jetBrainsMono(
          color: value.isEmpty ? AppConstants.accentPrimary.withValues(alpha: 0.2) : AppConstants.accentPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget activeSetRow(String setNum, String weight, String reps, bool isChecked, {bool isCurrent = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isChecked 
            ? AppConstants.completion.withValues(alpha: 0.15) 
            : (isCurrent ? AppConstants.accentPrimary.withValues(alpha: 0.05) : AppConstants.bgCard.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked 
              ? AppConstants.completion.withValues(alpha: 0.8) 
              : (isCurrent ? AppConstants.accentPrimary.withValues(alpha: 0.6) : AppConstants.accentPrimary.withValues(alpha: 0.1)),
          width: isChecked || isCurrent ? 2 : 1.5,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: AppConstants.accentPrimary.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: isChecked ? AppConstants.completion.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1),
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
              setNum,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isChecked 
                  ? AppConstants.completion 
                  : (isCurrent ? AppConstants.accentPrimary : AppConstants.accentPrimary.withValues(alpha: 0.3)),
              ),
            ),
          ),
          
          Expanded(child: _activeEntryDummy(reps, '0')),
          const SizedBox(width: 8),
          Expanded(child: _activeEntryDummy(weight, '0')),
          
          const SizedBox(width: 12),
          
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: isChecked ? AppConstants.completedGradient : null,
              color: isChecked ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isChecked ? Colors.transparent : AppConstants.accentPrimary.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                if (isChecked)
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
              color: isChecked ? Colors.white : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  /// Dummy for finish stats card.
  static Widget statCardDummy(String title, String value, IconData icon) {
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
          Icon(icon, color: AppConstants.accentPrimary, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppConstants.textPrimary)),
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.textMuted, letterSpacing: 1)),
        ],
      ),
    );
  }

  /// Dummy element for Managing Exercises / Library to accurately mimic _ExerciseListTile.
  static Widget exerciseLibraryItem({required String name, required String tag}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppConstants.accentGradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.accentPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.accentPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.bar_chart_rounded, color: AppConstants.progressDay, size: 20),
          const SizedBox(width: 16),
          Icon(Icons.delete_outline_rounded, color: AppConstants.textMuted, size: 20),
        ],
      ),
    );
  }


  /// Dummy Gallery Album Folder.
  static Widget galleryAlbumItem({required String title, required String count}) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.bgSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusMD - 1)),
              ),
              child: Center(
                child: Icon(Icons.collections_rounded, size: 32, color: AppConstants.accentGold.withValues(alpha: 0.5)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  count,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Dummy for the Exercise Library.
  static Widget exerciseLibraryDummy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppConstants.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 14, color: AppConstants.textMuted),
                const SizedBox(width: 8),
                Text('Search exercises...', style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted)),
                const Spacer(),
                Icon(Icons.filter_list_rounded, size: 14, color: AppConstants.accentSecondary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tag Chips
          Row(
            children: [
              _tagChipDummy('Chest', true),
              const SizedBox(width: 6),
              _tagChipDummy('Compound', false),
              const SizedBox(width: 6),
              _tagChipDummy('Push', false),
            ],
          ),
          const SizedBox(height: 16),
          // List Item
          _exerciseTileDummy('BENCH PRESS', ['Chest', 'Compound'], true),
          const SizedBox(height: 8),
          _exerciseTileDummy('DUMBBELL FLYES', ['Chest', 'Isolation'], false),
        ],
      ),
    );
  }

  static Widget _tagChipDummy(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppConstants.accentPrimary.withValues(alpha: 0.1) : AppConstants.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppConstants.accentPrimary : AppConstants.border),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: active ? AppConstants.accentPrimary : AppConstants.textMuted,
        ),
      ),
    );
  }

  static Widget _exerciseTileDummy(String name, List<String> tags, bool hasStats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: AppConstants.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppConstants.textPrimary)),
                const SizedBox(height: 2),
                Text(tags.join(', ').toUpperCase(), style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: AppConstants.textMuted)),
              ],
            ),
          ),
          if (hasStats) 
            Icon(Icons.bar_chart_rounded, size: 18, color: AppConstants.progressDay),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, size: 18, color: AppConstants.textMuted.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  /// Dummy for the Exercise Blueprint (Settings).
  static Widget exerciseBlueprintDummy() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.accentSecondary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentSecondary.withValues(alpha: 0.05),
            blurRadius: 15,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppConstants.accentGold, size: 16),
              const SizedBox(width: 8),
              Text('INTELLIGENT BLUEPRINT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, color: AppConstants.accentGold, letterSpacing: 1)),
            ],
          ),
          const Divider(height: 24),
          _blueprintRow(Icons.percent_rounded, 'SMART WEIGHT (%)', 'Enabled', AppConstants.accentGold),
          _blueprintRow(Icons.timer_outlined, 'TIMER MODE', '1:00 (Countdown)', AppConstants.accentPrimary),
          _blueprintRow(Icons.auto_stories_rounded, 'ROUTINE ROUTING', 'Bench Progress', AppConstants.accentSecondary),
        ],
      ),
    );
  }

  static Widget _blueprintRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppConstants.textMuted)),
          const Spacer(),
          Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
  // --- CHARTS DUMMIES ---

  static Widget chartsTabsDummy() {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildChartTab('Exercises', true)),
              Expanded(child: _buildChartTab('Tags', false)),
              Expanded(child: _buildChartTab('Custom', false)),
            ],
          ),
          Container(height: 1, color: AppConstants.border),
        ],
      ),
    );
  }

  static Widget _buildChartTab(String text, bool isActive) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            text, 
            style: GoogleFonts.inter(
              fontSize: 14, 
              color: isActive ? AppConstants.accentPrimary : AppConstants.textMuted, 
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500
            )
          ),
        ),
        if (isActive) Container(height: 2, color: AppConstants.accentPrimary),
      ],
    );
  }

  static Widget chartsFiltersDummy() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(child: _buildVariantButton(Icons.fitness_center_rounded, 'Strength', true)),
                Expanded(child: _buildVariantButton(Icons.timer_outlined, 'Timed', false)),
                Expanded(child: _buildVariantButton(Icons.speed_rounded, 'Wt-Timed', false)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Exercise', style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textMuted)),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppConstants.textMuted, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Date Range:', style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
              Row(
                children: [
                  _buildQuickButton('1W'),
                  const SizedBox(width: 4),
                  _buildQuickButton('1M'),
                  const SizedBox(width: 4),
                  _buildQuickButton('1Y'),
                  const SizedBox(width: 4),
                  _buildQuickButton('All', active: true),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDateBox('Start', 'Feb 18')),
              const SizedBox(width: 12),
              Expanded(child: _buildDateBox('End', 'Mar 20')),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildVariantButton(IconData icon, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppConstants.bgSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: active ? Colors.white : AppConstants.textMuted),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.w500, color: active ? Colors.white : AppConstants.textMuted)),
        ],
      ),
    );
  }

  static Widget _buildQuickButton(String label, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppConstants.textMuted.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? Colors.transparent : AppConstants.textMuted.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: active ? AppConstants.textPrimary : AppConstants.textMuted),
      ),
    );
  }

  static Widget _buildDateBox(String label, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted)),
              Text(date, style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textPrimary, fontWeight: FontWeight.w500)),
            ],
          ),
          Icon(Icons.calendar_today_rounded, size: 16, color: AppConstants.textSecondary),
        ],
      ),
    );
  }

  static Widget chartsChartAreaDummy() {
    return const InteractiveChartDummy();
  }

  static Widget historicalLogDummy() {
    return Column(
      children: [
        _historyRowDummy('25 Oct, 2026', '5,200 KG', true),
        _historyRowDummy('18 Oct, 2026', '4,850 KG', false),
        _historyRowDummy('12 Oct, 2026', '4,600 KG', false),
      ],
    );
  }

  static Widget _historyRowDummy(String date, String value, bool isPr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.textPrimary)),
          Row(
            children: [
              if (isPr)
                Icon(Icons.emoji_events_rounded, size: 16, color: AppConstants.accentGold),
              if (isPr) const SizedBox(width: 8),
              Text(value, style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  /// A standalone row focusing on the stats/chart access.
  static Widget exerciseStatsRow() {
    return _exerciseTileDummy('BENCH PRESS', ['Chest', 'Compound'], true);
  }

  /// A sample of a Log Book history entry.
  static Widget logBookEntry({
    required String title,
    required String date,
    required String subtitle,
    required String type,
    bool isComplete = true,
  }) {
    IconData icon;
    LinearGradient gradient;

    switch (type) {
      case 'program':
        icon = Icons.calendar_month_rounded;
        gradient = AppConstants.purpleGradient;
        break;
      case 'week':
        icon = Icons.view_week_rounded;
        gradient = AppConstants.warmGradient;
        break;
      default:
        icon = Icons.today_rounded;
        gradient = AppConstants.completedGradient;
    }

    final statusColor = isComplete ? AppConstants.completion : AppConstants.warning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
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
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      date,
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
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
    );
  }

  /// Dummy for the high-level stats shown in the log detail view.
  static Widget logBookDetailsDummy() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push Day A',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.textPrimary,
            ),
          ),
          Text(
            'Completed March 20, 2026',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppConstants.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: statCardDummy('VOLUME', '12,450', Icons.fitness_center_rounded)),
              const SizedBox(width: 12),
              Expanded(child: statCardDummy('DURATION', '1h 05m', Icons.timer_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: statCardDummy('PEAK LIFT', '225 lb', Icons.emoji_events_rounded)),
              const SizedBox(width: 12),
              Expanded(child: statCardDummy('SETS', '8 / 8', Icons.layers_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  /// A swatch representing a theme preset, matching the production theme settings UI.
  static Widget themeColorDummy({
    required String name,
    required Color bgDark,
    required Color bgSurface,
    required Color primary,
    required Color secondary,
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // Standard card bg
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? primary : const Color(0xFF30363D),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Color Swatch Grid
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: bgDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  Expanded(flex: 2, child: Container(color: bgSurface)),
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Expanded(child: Container(color: primary)),
                        Expanded(child: Container(color: secondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isActive)
                  Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          if (isActive)
            Icon(Icons.check_circle_rounded, color: primary, size: 24),
        ],
      ),
    );
  }

  /// A vertical preview of multiple theme cards, matching the appearance settings list.
  static Widget themeStackDummy() {
    return Column(
      children: [
        themeColorDummy(
          name: 'Emerald (Active)',
          bgDark: const Color(0xFF0B1A14),
          bgSurface: const Color(0xFF203828),
          primary: const Color(0xFF10B981),
          secondary: const Color(0xFF3B82F6),
          isActive: true,
        ),
        const SizedBox(height: 12),
        themeColorDummy(
          name: 'Amethyst',
          bgDark: const Color(0xFF12091E),
          bgSurface: const Color(0xFF2A203C),
          primary: const Color(0xFFA855F7),
          secondary: const Color(0xFF7C3AED),
        ),
        const SizedBox(height: 12),
        themeColorDummy(
          name: 'Obsidian',
          bgDark: const Color(0xFF08080A),
          bgSurface: const Color(0xFF202028),
          primary: const Color(0xFF94A3B8),
          secondary: const Color(0xFF475569),
        ),
      ],
    );
  }

  /// A legend for mapping theme colors to UI elements.
  static Widget themeMapLegend(List<Map<String, dynamic>> mappings) {
    return Column(
      children: mappings.map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: m['color'] as Color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.border.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Icon(m['icon'] as IconData, size: 16, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    Text(
                      m['description'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// A studio-quality replica of the custom theme editor for the guide.
  static Widget themeEditorDummy() {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: AppConstants.bgDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Top Toolbar (Real layout: Back, Title, Undo/Redo, Save)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
                Expanded(
                  child: Text(
                    'Emerald',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                _ctrlBtn(Icons.undo_rounded),
                const SizedBox(width: 4),
                _ctrlBtn(Icons.redo_rounded),
                const SizedBox(width: 4),
                Text('Save', style: GoogleFonts.inter(color: AppConstants.accentPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
              ],
            ),
          ),
          
          // 2. Group Tabs (TabBar replica)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _miniTab('BG', true),
                const SizedBox(width: 16),
                _miniTab('Accent', false),
                const SizedBox(width: 16),
                _miniTab('Text', false),
              ],
            ),
          ),

          // 3. Selection Dots (The active color selector)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _miniDot(const Color(0xFF10B981), true), // Active
                    _miniDot(const Color(0xFF3B82F6), false),
                    _miniDot(const Color(0xFFF59E0B), false),
                    _miniDot(const Color(0xFFEF4444), false),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Accent Primary', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppConstants.textMuted)),
              ],
            ),
          ),

          // 4. Live Preview (Context-aware replica)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.border),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140, height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6))),
                          const SizedBox(width: 12),
                          Container(width: 60, height: 8, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Controls (HEX Row + RGB Sliders)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              border: Border(top: BorderSide(color: AppConstants.border)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(width: 10),
                    Text('#', style: GoogleFonts.inter(color: AppConstants.textSecondary, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    Text('10B981', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _ctrlBtn(Icons.copy_rounded),
                    const SizedBox(width: 6),
                    _ctrlBtn(Icons.paste_rounded),
                  ],
                ),
                const SizedBox(height: 10),
                _dummySlider('R', 16, Colors.red),
                _dummySlider('G', 185, Colors.green),
                _dummySlider('B', 129, Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dummySlider(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(label, style: GoogleFonts.robotoMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppConstants.textMuted))
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value / 255.0,
                child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text(value.toString(), style: GoogleFonts.robotoMono(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600))
          ),
        ],
      ),
    );
  }

  static Widget _miniTab(String label, bool active) {
    return Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: active ? AppConstants.accentPrimary : AppConstants.textMuted));
  }

  static Widget _miniDot(Color c, bool active) {
    return Container(
      width: 8, height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: active ? Border.all(color: Colors.white, width: 1.5) : null),
    );
  }

  static Widget _ctrlBtn(IconData icon) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: AppConstants.bgSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConstants.border)),
      child: Icon(icon, size: 16, color: AppConstants.textPrimary),
    );
  }

  /// Dummy for the Data Management screen showing export actions.
  static Widget dataManagementDummy() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.accentSecondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.upload_rounded, color: AppConstants.accentSecondary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save a Backup',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    Text(
                      'Export your logs to a file',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.accentSecondary,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Save Selection as File', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppConstants.border),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, color: AppConstants.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text('Copy JSON to Clipboard', style: GoogleFonts.inter(color: AppConstants.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class InteractiveChartDummy extends StatefulWidget {
  const InteractiveChartDummy({super.key});

  @override
  State<InteractiveChartDummy> createState() => _InteractiveChartDummyState();
}

class _InteractiveChartDummyState extends State<InteractiveChartDummy> {
  bool isSessionMode = true;

  Widget _lbl(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted));
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('X-Axis: ', style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => isSessionMode = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSessionMode ? AppConstants.textPrimary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Session', style: GoogleFonts.inter(fontSize: 12, fontWeight: isSessionMode ? FontWeight.w600 : FontWeight.normal, color: isSessionMode ? AppConstants.textPrimary : AppConstants.textMuted)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => isSessionMode = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: !isSessionMode ? AppConstants.textPrimary.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Date', style: GoogleFonts.inter(fontSize: 12, fontWeight: !isSessionMode ? FontWeight.w600 : FontWeight.normal, color: !isSessionMode ? AppConstants.textPrimary : AppConstants.textMuted)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interactive Mock Chart
          Container(
            height: 200,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.border),
            ),
            child: Column(
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: _DummyInteractiveChartPainter(isSessionMode: isSessionMode),
                    ),
                  )
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: isSessionMode 
                     ? [_lbl('1'), _lbl('2'), _lbl('3'), _lbl('4'), _lbl('5')]
                     : [_lbl('Jan 5'), _lbl('Jan 18'), _lbl('Feb 3'), _lbl('Feb 9'), _lbl('Mar 2')],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}



class _DummyInteractiveChartPainter extends CustomPainter {
  final bool isSessionMode;
  _DummyInteractiveChartPainter({required this.isSessionMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = AppConstants.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
       final y = size.height * (i / 3);
       canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paint = Paint()
      ..color = AppConstants.accentSecondary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // In session mode, spacing is perfectly even.
    // In date mode, they are spaced more erratically based on 'real' time gaps.
    final List<double> xRatios = isSessionMode 
        ? [0.0, 0.25, 0.50, 0.75, 1.0]
        : [0.0, 0.22, 0.52, 0.63, 1.0];
        
    final List<double> yRatios = [0.8, 0.6, 0.7, 0.4, 0.2];

    for (int i = 0; i < xRatios.length; i++) {
      final x = size.width * xRatios[i];
      final y = size.height * yRatios[i];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw shadow/fill
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppConstants.accentSecondary.withValues(alpha: 0.2),
          AppConstants.accentSecondary.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));
      
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw interaction dots
    final dotOuter = Paint()..color = AppConstants.bgCard;
    final dotInner = Paint()..color = AppConstants.accentSecondary;
    
    for (int i = 0; i < xRatios.length; i++) {
        final center = Offset(size.width * xRatios[i], size.height * yRatios[i]);
        canvas.drawCircle(center, 5, dotOuter);
        canvas.drawCircle(center, 3, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _DummyInteractiveChartPainter oldDelegate) {
    return oldDelegate.isSessionMode != isSessionMode;
  }
}

class CameraInterfaceDummy extends StatelessWidget {
  const CameraInterfaceDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border, width: 2),
      ),
      child: Stack(
        children: [
          // Simulated Camera Preview
          Center(
            child: Icon(
              Icons.person_outline_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // Top controls
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bubbleIcon(Icons.folder_rounded, "Album"),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      const Icon(Icons.flash_on_rounded, size: 16, color: Colors.yellow),
                      const SizedBox(width: 8),
                      Icon(Icons.accessibility_new_rounded,
                          size: 16, color: AppConstants.accentPrimary),
                    ],
                  ),
                ),
                _bubbleIcon(Icons.aspect_ratio_rounded, "3:4"),
              ],
            ),
          ),


          // Bottom Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: Colors.white70, size: 20),
                ),
                // Shutter
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Flip
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flip_camera_android_rounded,
                      color: Colors.white, size: 22),
                ),
              ],
            ),
          ),

          // Mode toggle
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("VIDEO",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white38,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 16),
                Text("PHOTO",
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.yellow,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubbleIcon(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class PoseEngineDummy extends StatelessWidget {
  const PoseEngineDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          
          // Ghost Skeleton (Reference)
          Center(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                size: const Size(120, 160),
                painter: _SkeletonPainter(color: Colors.white),
              ),
            ),
          ),

          // User Skeleton (Live)
          Center(
            child: CustomPaint(
              size: const Size(120, 160),
              painter: _SkeletonPainter(color: AppConstants.accentPrimary),
            ),
          ),

          // Match Indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 14),
                  const SizedBox(width: 6),
                  Text("MATCH 98%",
                      style: GoogleFonts.inter(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),

          // Status label
          Positioned(
            bottom: 12,
            left: 12,
            child: Text(
              "POSE ENGINE ACTIVE",
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppConstants.textMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SkeletonPainter extends CustomPainter {
  final Color color;
  _SkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()..color = color;

    // Head
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 8, jointPaint);
    
    // Spine
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      paint,
    );

    // Shoulders
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.25),
      Offset(size.width * 0.65, size.height * 0.25),
      paint,
    );

    // Hips
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.6, size.height * 0.5),
      paint,
    );

    // Left Arm
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.25),
      Offset(size.width * 0.25, size.height * 0.45),
      paint,
    );

    // Right Arm
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.25),
      Offset(size.width * 0.75, size.height * 0.45),
      paint,
    );

    // Left Leg
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.5),
      Offset(size.width * 0.35, size.height * 0.8),
      paint,
    );

    // Right Leg
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.5),
      Offset(size.width * 0.65, size.height * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.border.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
