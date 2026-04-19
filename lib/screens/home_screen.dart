import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../services/media_storage_service.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import 'day_editor_screen.dart';
import 'day_overview_screen.dart';
import 'week_detail_screen.dart';
import 'program_detail_screen.dart';
import 'theme_settings_screen.dart';
import 'delete_data_screen.dart';
import 'import_export_screen.dart';
import '../services/storage_service.dart';
import 'log_book_screen.dart';
import 'guide_book_screen.dart';
import '../services/seed_data.dart';
import '../providers/exercise_library_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // PageView for animated day swiping
  static const int _initialPage = 100000;
  late final PageController _dayPageController;
  // Anchor date: the date at the _initialPage index. Only updated on calendar taps.
  late DateTime _anchorDate;

  @override
  void initState() {
    super.initState();
    _anchorDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    _dayPageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _dayPageController.dispose();
    super.dispose();
  }

  /// Derive the date for a given page index relative to the anchor.
  DateTime _dateForPage(int pageIndex) {
    final offset = pageIndex - _initialPage;
    return _anchorDate.add(Duration(days: offset));
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<WorkoutProvider>();
    final selectedItems = provider.getItemsForDate(_selectedDay);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Guide Book',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GuideBookScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.today_rounded),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
                _anchorDate = DateTime(
                  _selectedDay.year,
                  _selectedDay.month,
                  _selectedDay.day,
                );
              });
              _dayPageController.jumpToPage(_initialPage);
            },
            tooltip: 'Today',
          ),
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
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSM,
            ),
            decoration: BoxDecoration(
              color: AppConstants.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              border: Border.all(color: AppConstants.border),
            ),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  Helpers.isSameDay(day, _selectedDay),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                  _anchorDate = DateTime(
                    selected.year,
                    selected.month,
                    selected.day,
                  );
                });
                _dayPageController.jumpToPage(_initialPage);
              },
              onDayLongPressed: (selected, focused) {
                _showScheduleDialog(selected);
              },
              onHeaderTapped: (_) => _showMonthYearPicker(),
              eventLoader: (day) {
                final items = provider.getItemsForDate(day);
                return items;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: GoogleFonts.inter(
                  color: AppConstants.textPrimary,
                ),
                weekendTextStyle: GoogleFonts.inter(
                  color: AppConstants.textSecondary,
                ),
                todayDecoration: BoxDecoration(
                  color: AppConstants.accentPrimary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.inter(
                  color: AppConstants.accentPrimary,
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppConstants.accentPrimary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                markersMaxCount: 0, // We use custom markers
                cellMargin: const EdgeInsets.all(4),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return null;
                  final today = DateTime.now();
                  final yesterday = today.subtract(const Duration(days: 1));
                  final isDatePast = date.isBefore(
                    DateTime(today.year, today.month, today.day),
                  );
                  final isYesterday = Helpers.isSameDay(date, yesterday);

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: events.take(3).map((e) {
                      final item = e as Map<String, dynamic>;
                      final day = item['item'] as DayWorkout;
                      Color dotColor;
                      if (day.isHidden) {
                        dotColor = AppConstants.textMuted;
                      } else if (day.isCompleted) {
                        dotColor = day.isFullyCompleted ? AppConstants.completion : AppConstants.warning;
                      } else if (day.completedSets > 0) {
                        dotColor = AppConstants.accentGold; 
                      } else if (isDatePast) {
                        dotColor = isYesterday
                            ? AppConstants.error
                            : AppConstants.textMuted; 
                      } else {
                        dotColor = AppConstants.accentPrimary; 
                      }
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppConstants.textPrimary,
                ),
                formatButtonTextStyle: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.accentPrimary,
                ),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(color: AppConstants.accentPrimary),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: AppConstants.textPrimary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textPrimary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.inter(
                  color: AppConstants.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: GoogleFonts.inter(
                  color: AppConstants.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              startingDayOfWeek: StartingDayOfWeek.sunday,
            ),
          ),

          const SizedBox(height: 12),

          // Selected day header + scheduled items (swipeable with animation)
          Expanded(
            child: PageView.builder(
              controller: _dayPageController,
              onPageChanged: (page) {
                final newDate = _dateForPage(page);
                setState(() {
                  _selectedDay = newDate;
                  _focusedDay = newDate;
                });
              },
              itemBuilder: (context, page) {
                final pageDate = _dateForPage(page);
                final pageItems = provider.getItemsForDate(pageDate);
                return Column(
                  children: [
                    // Selected day header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMD,
                      ),
                      child: Row(
                        children: [
                          Text(
                            Helpers.isSameDay(pageDate, now)
                                ? 'Today'
                                : Helpers.formatDate(pageDate),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (pageItems.isNotEmpty)
                            Text(
                              '${pageItems.length} ${pageItems.length == 1 ? 'workout' : 'workouts'}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppConstants.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Scheduled items
                    Expanded(
                      child: pageItems.isEmpty
                          ? _buildEmptyDayState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: pageItems.length,
                              itemBuilder: (context, index) {
                                final itemData = pageItems[index];
                                final day = itemData['item'] as DayWorkout;
                                return _ScheduledDayCard(
                                  day: day,
                                  parentType: itemData['parentType'] as String?,
                                  parentName: itemData['parentName'] as String?,
                                  parentProgress:
                                      itemData['parentProgress'] as double?,
                                  weekName: itemData['weekName'] as String?,
                                  weekProgress:
                                      itemData['weekProgress'] as double?,
                                  onTap: () => _navigateToDay(day, itemData),
                                  onLongPress: () =>
                                      _showItemOptions(day, itemData),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDayState() {
    final isPast = _selectedDay.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPast ? Icons.event_busy_rounded : Icons.self_improvement_rounded,
            size: 48,
            color: AppConstants.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            isPast ? 'Rest day' : 'No workouts scheduled',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press a date to schedule a workout',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDay(DayWorkout day, Map<String, dynamic> itemData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayOverviewScreen(
          day: day,
          parentType: itemData['parentType'] as String?,
          parentId: itemData['parentId'] as String?,
        ),
      ),
    );
  }

  void _showItemOptions(DayWorkout day, Map<String, dynamic> itemData) {
    final provider = context.read<WorkoutProvider>();
    final parentType = itemData['parentType'] as String?;
    final parentId = itemData['parentId'] as String?;

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
              day.displayTitle,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Hide / Unhide
            ListTile(
              leading: Icon(
                day.isHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: AppConstants.textPrimary,
              ),
              title: Text(
                day.isHidden ? 'Unhide' : 'Hide',
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
              ),
              subtitle: Text(
                day.isHidden
                    ? 'Show on calendar and include in progress'
                    : 'Grey out calendar dot and exclude from progress',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
              onTap: () {
                day.isHidden = !day.isHidden;
                if (parentType == null) {
                  provider.saveScheduledDay(day);
                } else {
                  // just saveData on the whole list is needed, since the parent is mutated
                  // actually, just calling saveScheduledDay(day) might not save the parent.
                  // Since we are referencing the object in memory, we should persist its parent.
                  if (parentType == 'week') {
                    final w = context
                        .read<WorkoutProvider>()
                        .scheduledWeeks
                        .firstWhere((w) => w.id == parentId);
                    provider.saveScheduledWeek(w);
                  } else if (parentType == 'program') {
                    final p = context
                        .read<WorkoutProvider>()
                        .scheduledPrograms
                        .firstWhere((p) => p.id == parentId);
                    provider.saveScheduledProgram(p);
                  }
                }
                Navigator.pop(ctx);
                setState(() {});
              },
            ),

            // Delete Day
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: AppConstants.error,
              ),
              title: Text(
                'Delete Day',
                style: GoogleFonts.inter(color: AppConstants.error),
              ),
              subtitle: Text(
                'Permanently remove this day',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppConstants.textMuted,
                ),
              ),
              onTap: () {
                provider.removeScheduledDayFromParent(
                  day.id,
                  parentType,
                  parentId,
                );
                Navigator.pop(ctx);
                setState(() {});
              },
            ),

            // Delete Week
            if (parentType == 'week' || parentType == 'program')
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_rounded,
                  color: AppConstants.error,
                ),
                title: Text(
                  'Delete Week',
                  style: GoogleFonts.inter(color: AppConstants.error),
                ),
                subtitle: Text(
                  'Remove this entire week from the calendar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                onTap: () {
                  if (parentType == 'week') {
                    provider.removeScheduledWeek(parentId!);
                  } else if (parentType == 'program') {
                    final program = provider.scheduledPrograms.firstWhere(
                      (p) => p.id == parentId,
                    );
                    final week = provider.findWeekContainingDay(day.id);
                    if (week != null) {
                      program.weeks.removeWhere((w) => w.id == week.id);
                      provider.saveScheduledProgram(program);
                    }
                  }
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),

            // Delete Program
            if (parentType == 'program')
              ListTile(
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: AppConstants.error,
                ),
                title: Text(
                  'Delete Program',
                  style: GoogleFonts.inter(color: AppConstants.error),
                ),
                subtitle: Text(
                  'Remove this entire program from the calendar',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                onTap: () {
                  provider.removeScheduledProgram(parentId!);
                  Navigator.pop(ctx);
                  setState(() {});
                },
              ),

            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(DateTime date) {
    final provider = context.read<WorkoutProvider>();
    final sunday = Helpers.getSundayOfWeek(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) =>
          _ScheduleBottomSheet(date: date, sunday: sunday, provider: provider),
    );
  }

  Future<void> _triggerManualSeed(BuildContext context) async {
    final storage = context.read<StorageService>();
    final seeder = SeedDataService(storage);
    
    final shouldSeed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Load Default Content?', 
          style: GoogleFonts.inter(
            color: AppConstants.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will generously populate your Exercise Library with default exercises/tags and load the Hybrid Foundation 24-week program into your Catalogue.\n\nYour existing custom routines and exercises will not be erased.',
          style: GoogleFonts.inter(
            color: AppConstants.textSecondary,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppConstants.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.accentSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Load Data',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSeed == true && context.mounted) {
      await seeder.seedLibrary();
      if (context.mounted) {
        await context.read<ExerciseLibraryProvider>().reload();
        await context.read<WorkoutProvider>().reload();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Templates successfully generated and placed into your catalogue!',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: AppConstants.success,
          ),
        );
      }
    }
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) {
        final mediaStorage = context.read<MediaStorageService>();
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.9,
          padding: const EdgeInsets.all(AppConstants.paddingLG),
          child: Column(
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                AppConstants.accentPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: AppConstants.accentPrimary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Guide Book',
                          style: GoogleFonts.inter(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Learn how to use the app features & master your routines',
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
                              builder: (_) => const GuideBookScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                AppConstants.accentSecondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.library_add_rounded,
                            color: AppConstants.accentSecondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Load Base Data',
                          style: GoogleFonts.inter(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          'Repopulate the default exercise database & templates',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _triggerManualSeed(context);
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppConstants.accentSecondary
                                .withValues(alpha: 0.15),
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
                            color:
                                AppConstants.progressDay.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.import_export_rounded,
                            color: AppConstants.progressDay,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Import / Export Data',
                          style: GoogleFonts.inter(
                            color: AppConstants.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Backup or restore routines, logs, and exercises',
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
                              builder: (_) => ImportExportScreen(storage: storage),
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
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        );
      },
    );
  }

  void _showMonthYearPicker() {
    int selectedYear = _focusedDay.year;
    int selectedMonth = _focusedDay.month;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppConstants.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
              ),
              title: Text(
                'Jump to Month',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Month',
                            labelStyle: GoogleFonts.inter(
                              color: AppConstants.textMuted,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppConstants.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppConstants.accentPrimary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              dropdownColor: AppConstants.bgCard,
                              isExpanded: true,
                              value: selectedMonth,
                              items: List.generate(12, (i) => i + 1)
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(
                                        Helpers.formatDateShort(
                                          DateTime(2020, m, 1),
                                        ).split(' ')[0],
                                        style: GoogleFonts.inter(
                                          color: AppConstants.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setStateDialog(() => selectedMonth = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Year',
                            labelStyle: GoogleFonts.inter(
                              color: AppConstants.textMuted,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppConstants.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppConstants.accentPrimary,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              dropdownColor: AppConstants.bgCard,
                              isExpanded: true,
                              value: selectedYear,
                              items: List.generate(11, (i) => 2020 + i)
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text(
                                        '$y',
                                        style: GoogleFonts.inter(
                                          color: AppConstants.textPrimary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setStateDialog(() => selectedYear = v);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: AppConstants.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(selectedYear, selectedMonth, 1);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Jump'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Schedule Bottom Sheet (3-tab) ─────────────────────────────────

class _ScheduleBottomSheet extends StatefulWidget {
  final DateTime date;
  final DateTime sunday;
  final WorkoutProvider provider;

  const _ScheduleBottomSheet({
    required this.date,
    required this.sunday,
    required this.provider,
  });

  @override
  State<_ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<_ScheduleBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayTemplates = widget.provider.dayTemplates.toList()
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    final weekTemplates = widget.provider.weekTemplates.toList()
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
    final programTemplates = widget.provider.programTemplates.toList()
      ..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppConstants.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLG,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Workout',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'For ${Helpers.formatDate(widget.date)}',
                  style: GoogleFonts.inter(
                    color: AppConstants.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Days'),
              Tab(text: 'Weeks'),
              Tab(text: 'Programs'),
            ],
            indicatorColor: AppConstants.accentPrimary,
            labelColor: AppConstants.accentPrimary,
            unselectedLabelColor: AppConstants.textMuted,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Days tab
                _buildTemplateList(
                  templates: dayTemplates,
                  icon: Icons.today_rounded,
                  emptyLabel: 'No day templates yet',
                  onTap: (t) {
                    widget.provider.scheduleDay(t as DayWorkout, widget.date);
                    Navigator.pop(context);
                  },
                  onCreateOneShot: () =>
                      _showCreateOneShotDialog(context, 'Day'),
                  scrollController: scrollController,
                ),
                // Weeks tab
                _buildTemplateList(
                  templates: weekTemplates,
                  icon: Icons.view_week_rounded,
                  emptyLabel: 'No week templates yet',
                  subtitle: 'Starts ${Helpers.formatDateShort(widget.sunday)}',
                  onTap: (t) {
                    widget.provider.scheduleWeek(
                      t as WeekWorkout,
                      widget.sunday,
                    );
                    Navigator.pop(context);
                  },
                  onCreateOneShot: () =>
                      _showCreateOneShotDialog(context, 'Week'),
                  scrollController: scrollController,
                ),
                // Programs tab
                _buildTemplateList(
                  templates: programTemplates,
                  icon: Icons.calendar_month_rounded,
                  emptyLabel: 'No program templates yet',
                  subtitle: 'Starts ${Helpers.formatDateShort(widget.sunday)}',
                  onTap: (t) {
                    widget.provider.scheduleProgram(
                      t as ProgramWorkout,
                      widget.sunday,
                    );
                    Navigator.pop(context);
                  },
                  onCreateOneShot: () =>
                      _showCreateOneShotDialog(context, 'Program'),
                  scrollController: scrollController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateOneShotDialog(BuildContext context, String type) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New One-Shot $type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
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
              final title = titleController.text.trim().isEmpty
                  ? null
                  : titleController.text.trim();
              final note = noteController.text.trim().isEmpty
                  ? null
                  : noteController.text.trim();
              final desc = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();

              if (type == 'Day') {
                final day = DayWorkout(
                  title: title,
                  note: note,
                  description: desc,
                  isTemplate: false,
                  scheduledDate: widget.date,
                );
                Navigator.pop(ctx);
                Navigator.pop(context); // Close bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayEditorScreen(
                      day: day,
                      isTemplate: false,
                      isDraft: true,
                    ),
                  ),
                );
              } else if (type == 'Week') {
                final week = WeekWorkout(
                  title: title,
                  note: note,
                  description: desc,
                  isTemplate: false,
                  startDate: widget.sunday,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeekDetailScreen(
                      week: week,
                      isTemplate: false,
                      isDraft: true,
                    ),
                  ),
                );
              } else if (type == 'Program') {
                final prog = ProgramWorkout(
                  title: title,
                  note: note,
                  description: desc,
                  isTemplate: false,
                  startDate: widget.sunday,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgramDetailScreen(
                      program: prog,
                      isTemplate: false,
                      isDraft: true,
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList({
    required List<dynamic> templates,
    required IconData icon,
    required String emptyLabel,
    String? subtitle,
    required Function(dynamic) onTap,
    required VoidCallback onCreateOneShot,
    required ScrollController scrollController,
  }) {
    // Combine templates + completed history items
    final completedDays = widget.provider.allCompletedItems
        .where((log) => log['type'] == 'day')
        .toList();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      children: [
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppConstants.textMuted,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: onCreateOneShot,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(
              'Create One-Shot ${icon == Icons.today_rounded
                  ? 'Day'
                  : icon == Icons.view_week_rounded
                  ? 'Week'
                  : 'Program'}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
        if (templates.isEmpty && completedDays.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Icon(
                  icon,
                  size: 40,
                  color: AppConstants.textMuted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyLabel,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppConstants.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create templates in the Workouts tab',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
        // Templates
        if (templates.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Templates',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          ...templates.map((t) {
            final title = t.displayTitle as String;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppConstants.bgSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                child: InkWell(
                  onTap: () => onTap(t),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: AppConstants.accentPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              color: AppConstants.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (t is ProgramWorkout || t is WeekWorkout)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.list_alt_rounded,
                              color: AppConstants.accentTertiary,
                              size: 22,
                            ),
                            onPressed: () {
                              _showChildrenDialog(context, t);
                            },
                          )
                        else
                          Icon(
                            Icons.add_rounded,
                            color: AppConstants.accentPrimary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
        // Import from history
        if (completedDays.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'From History',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.textSecondary,
              ),
            ),
          ),
          ...completedDays.take(15).map((log) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppConstants.bgSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                child: InkWell(
                  onTap: () {
                    final day = log['item'] as DayWorkout;
                    final copy = day.deepCopy();
                    copy.isTemplate = false;
                    copy.scheduledDate = widget.date;
                    copy.completedDate = null;
                    widget.provider.scheduleDay(copy, widget.date);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: AppConstants.accentSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (log['item'] as DayWorkout).displayTitle,
                                style: GoogleFonts.inter(
                                  color: AppConstants.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                Helpers.formatDate(log['date'] as DateTime),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.add_rounded,
                          color: AppConstants.accentSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showChildrenDialog(BuildContext context, dynamic parent) {
    final isProgram = parent is ProgramWorkout;
    final title = parent.displayTitle;
    final children = isProgram ? parent.weeks : (parent as WeekWorkout).days;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        backgroundColor: AppConstants.bgCard,
        contentPadding: const EdgeInsets.only(top: 16, bottom: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: children.length,
            itemBuilder: (context, index) {
              final dynamic child = children[index];
              final childTitle = child.displayTitle as String;
              final childIcon = isProgram
                  ? Icons.view_week_rounded
                  : Icons.today_rounded;

              return ListTile(
                leading: Icon(
                  childIcon,
                  color: AppConstants.textMuted,
                  size: 20,
                ),
                title: Text(
                  childTitle,
                  style: GoogleFonts.inter(
                    color: AppConstants.textPrimary,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProgram)
                      IconButton(
                        icon: Icon(
                          Icons.list_alt_rounded,
                          color: AppConstants.accentTertiary,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showChildrenDialog(context, child);
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.add_rounded,
                        color: AppConstants.accentPrimary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (child is WeekWorkout) {
                          widget.provider.scheduleWeek(child, widget.sunday);
                        } else if (child is DayWorkout) {
                          widget.provider.scheduleDay(child, widget.date);
                        }
                        Navigator.pop(ctx);
                        Navigator.pop(this.context);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  if (child is WeekWorkout) {
                    widget.provider.scheduleWeek(child, widget.sunday);
                  } else if (child is DayWorkout) {
                    widget.provider.scheduleDay(child, widget.date);
                  }
                  Navigator.pop(ctx);
                  Navigator.pop(this.context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: AppConstants.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledDayCard extends StatelessWidget {
  final DayWorkout day;
  final String? parentType;
  final String? parentName;
  final double? parentProgress;
  final String? weekName;
  final double? weekProgress;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ScheduledDayCard({
    required this.day,
    this.parentType,
    this.parentName,
    this.parentProgress,
    this.weekName,
    this.weekProgress,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = day.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMD,
        vertical: AppConstants.paddingXS,
      ),
      child: Material(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Opacity(
            opacity: day.isHidden ? 0.5 : 1.0,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(
                  color: isComplete
                      ? (day.isFullyCompleted ? AppConstants.completion : AppConstants.warning).withValues(alpha: 0.6)
                      : AppConstants.border,
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
                              ? (day.isFullyCompleted ? AppConstants.completedGradient : LinearGradient(colors: [AppConstants.warning, AppConstants.warning.withValues(alpha: 0.7)]))
                              : AppConstants.accentGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isComplete
                              ? (day.isFullyCompleted ? Icons.check_rounded : Icons.warning_rounded)
                              : Icons.fitness_center_rounded,
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
                              day.displayTitle,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            // Program info row
                            if (parentName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      parentName!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                                              value: parentProgress ?? 0,
                                              backgroundColor: AppConstants.bgSurface,
                                              valueColor: AlwaysStoppedAnimation(
                                                AppConstants.progressProgram,
                                              ),
                                              minHeight: 3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Helpers.progressPercent(
                                            parentProgress ?? 0,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.progressProgram,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            // Week info row (only for programs)
                            if (weekName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      weekName!,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
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
                                              valueColor: AlwaysStoppedAnimation(
                                                AppConstants.progressWeek,
                                              ),
                                              minHeight: 3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Helpers.progressPercent(
                                            weekProgress ?? 0,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.progressWeek,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (day.exercises.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: day.progress,
                        backgroundColor: AppConstants.bgSurface,
                        valueColor: AlwaysStoppedAnimation(
                          AppConstants.progressDay,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${day.exercises.length} exercises \u2022 ${day.completedSets}/${day.totalSets} sets',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                        Text(
                          Helpers.progressPercent(day.progress),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.progressDay,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
