import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/day_workout.dart';
import '../models/week_workout.dart';
import '../models/program_workout.dart';
import '../providers/workout_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import 'day_editor_screen.dart';
import 'week_detail_screen.dart';
import 'program_detail_screen.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => WorkoutsScreenState();
}

class WorkoutsScreenState extends State<WorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {}

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCatalogue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
      ),
      builder: (ctx) => _CatalogueBottomSheet(initialIndex: _tabController.index),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<WorkoutProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Workouts',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_rounded),
            tooltip: 'Catalogue',
            onPressed: () => _showCatalogue(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Programs'),
            Tab(text: 'Weeks'),
            Tab(text: 'Days'),
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
        children: [
          _ProgramsTab(programs: provider.activeProgramTemplates),
          _WeeksTab(weeks: provider.activeWeekTemplates),
          _DaysTab(days: provider.activeDayTemplates),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workouts_create_fab',
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Create',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final currentTab = _tabController.index;
    switch (currentTab) {
      case 0:
        _createProgram(context);
        break;
      case 1:
        _createWeek(context);
        break;
      case 2:
        _createDay(context);
        break;
    }
  }

  void _createProgram(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Program'),
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
                decoration: const InputDecoration(
                  labelText: 'Note (appears on card)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (appears in detail)',
                ),
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
              final program = ProgramWorkout(
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                isTemplate: true,
              );
              context.read<WorkoutProvider>().saveProgramTemplate(program);
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProgramDetailScreen(program: program, isTemplate: true),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createWeek(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final descController = TextEditingController();

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
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Note (appears on card)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (appears in detail)',
                ),
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
              final week = WeekWorkout(
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                isTemplate: true,
              );
              context.read<WorkoutProvider>().saveWeekTemplate(week);
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      WeekDetailScreen(week: week, isTemplate: true),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createDay(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Day'),
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
                decoration: const InputDecoration(
                  labelText: 'Note (appears on card)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (appears in detail)',
                ),
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
              final day = DayWorkout(
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                note: noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? null
                    : descController.text.trim(),
                isTemplate: true,
              );
              context.read<WorkoutProvider>().saveDayTemplate(day);
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayEditorScreen(day: day, isTemplate: true),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── Programs Tab ───────────────────────────────────────────────────

class _ProgramsTab extends StatelessWidget {
  final List<ProgramWorkout> programs;

  const _ProgramsTab({required this.programs});

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return _emptyState('programs', Icons.calendar_month_rounded);
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: programs.length,
      buildDefaultDragHandles: true,
      onReorder: (oldIndex, newIndex) {
        context.read<WorkoutProvider>().reorderProgramTemplates(
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final p = programs[index];
        return _WorkoutCard(
          key: ValueKey(p.id),
          index: index,
          title: p.displayTitle,
          note: p.note,
          subtitle: '${p.weeks.length} week${p.weeks.length != 1 ? 's' : ''}',
          icon: Icons.calendar_month_rounded,
          gradient: AppConstants.purpleGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProgramDetailScreen(program: p, isTemplate: true),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppConstants.bgCard,
                title: Text('Remove from Active?', style: GoogleFonts.inter(color: AppConstants.textPrimary)),
                content: Text('This will move it to the Catalogue.', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      p.isActive = false;
                      context.read<WorkoutProvider>().saveProgramTemplate(p);
                      Navigator.pop(ctx);
                    },
                    child: Text('Remove', style: GoogleFonts.inter(color: AppConstants.error)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Weeks Tab ──────────────────────────────────────────────────────

class _WeeksTab extends StatelessWidget {
  final List<WeekWorkout> weeks;

  const _WeeksTab({required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) return _emptyState('weeks', Icons.view_week_rounded);
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: weeks.length,
      buildDefaultDragHandles: true,
      onReorder: (oldIndex, newIndex) {
        context.read<WorkoutProvider>().reorderWeekTemplates(
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final w = weeks[index];
        return _WorkoutCard(
          key: ValueKey(w.id),
          index: index,
          title: w.displayTitle,
          note: w.note,
          subtitle: '${w.days.length} day${w.days.length != 1 ? 's' : ''}',
          icon: Icons.view_week_rounded,
          gradient: AppConstants.warmGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeekDetailScreen(week: w, isTemplate: true),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppConstants.bgCard,
                title: Text('Remove from Active?', style: GoogleFonts.inter(color: AppConstants.textPrimary)),
                content: Text('This will move it to the Catalogue.', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      w.isActive = false;
                      context.read<WorkoutProvider>().saveWeekTemplate(w);
                      Navigator.pop(ctx);
                    },
                    child: Text('Remove', style: GoogleFonts.inter(color: AppConstants.error)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Days Tab ───────────────────────────────────────────────────────

class _DaysTab extends StatelessWidget {
  final List<DayWorkout> days;

  const _DaysTab({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return _emptyState('days', Icons.today_rounded);
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: days.length,
      buildDefaultDragHandles: true,
      onReorder: (oldIndex, newIndex) {
        context.read<WorkoutProvider>().reorderDayTemplates(
          oldIndex,
          newIndex,
        );
      },
      itemBuilder: (context, index) {
        final d = days[index];
        return _WorkoutCard(
          key: ValueKey(d.id),
          index: index,
          title: d.displayTitle,
          note: d.note,
          subtitle:
              '${d.exercises.length} exercise${d.exercises.length != 1 ? 's' : ''}',
          icon: Icons.today_rounded,
          gradient: AppConstants.accentGradient,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DayEditorScreen(day: d, isTemplate: true),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppConstants.bgCard,
                title: Text('Remove from Active?', style: GoogleFonts.inter(color: AppConstants.textPrimary)),
                content: Text('This will move it to the Catalogue.', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppConstants.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () {
                      d.isActive = false;
                      context.read<WorkoutProvider>().saveDayTemplate(d);
                      Navigator.pop(ctx);
                    },
                    child: Text('Remove', style: GoogleFonts.inter(color: AppConstants.error)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Shared Card ────────────────────────────────────────────────────

class _WorkoutCard extends StatelessWidget {
  final int index;
  final String title;
  final String? note;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _WorkoutCard({
    super.key,
    required this.index,
    required this.title,
    this.note,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.onLongPress,
  });

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
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: AppConstants.border,
              ),
            ),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppConstants.textMuted,
                      size: 24,
                    ),
                  ),
                ),
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
                      if (note != null && note!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note!,
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _emptyState(String type, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 56,
          color: AppConstants.textMuted.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          'No $type yet',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap + to create one',
          style: GoogleFonts.inter(fontSize: 13, color: AppConstants.textMuted),
        ),
      ],
    ),
  );
}

// ── Catalogue Bottom Sheet ──────────────────────────────────────────

class _CatalogueBottomSheet extends StatefulWidget {
  final int initialIndex;

  const _CatalogueBottomSheet({this.initialIndex = 0});

  @override
  State<_CatalogueBottomSheet> createState() => _CatalogueBottomSheetState();
}

class _CatalogueBottomSheetState extends State<_CatalogueBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();
    final inactivePrograms = provider.inactiveProgramTemplates;
    final inactiveWeeks = provider.inactiveWeekTemplates;
    final inactiveDays = provider.inactiveDayTemplates;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppConstants.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Catalogue',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppConstants.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(),
            labelColor: AppConstants.textPrimary,
            unselectedLabelColor: AppConstants.textMuted,
            indicatorColor: AppConstants.accentSecondary,
            dividerColor: AppConstants.border,
            tabs: const [
              Tab(text: 'Programs'),
              Tab(text: 'Weeks'),
              Tab(text: 'Days'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(
                  inactivePrograms,
                  'programs',
                  Icons.calendar_month_rounded,
                  (id) => provider.deleteProgramTemplate(id),
                  (item) {
                    item.isActive = true;
                    provider.saveProgramTemplate(item);
                  },
                ),
                _buildList(
                  inactiveWeeks,
                  'weeks',
                  Icons.view_week_rounded,
                  (id) => provider.deleteWeekTemplate(id),
                  (item) {
                    item.isActive = true;
                    provider.saveWeekTemplate(item);
                  },
                ),
                _buildList(
                  inactiveDays,
                  'days',
                  Icons.today_rounded,
                  (id) => provider.deleteDayTemplate(id),
                  (item) {
                    item.isActive = true;
                    provider.saveDayTemplate(item);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<dynamic> items,
    String type,
    IconData icon,
    Function(String) onDelete,
    Function(dynamic) onRestore,
  ) {
    if (items.isEmpty) return _emptyState(type, icon);
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
            vertical: AppConstants.paddingXS,
          ),
          child: Material(
            color: AppConstants.bgCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMD),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppConstants.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.displayTitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppConstants.accentSecondary,
                    ),
                    tooltip: 'Add to Active',
                    onPressed: () => onRestore(item),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppConstants.error,
                    ),
                    tooltip: 'Permanently Delete',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppConstants.bgCard,
                          title: Text(
                            'Permanently Delete?',
                            style: GoogleFonts.inter(
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          content: Text(
                            'This cannot be undone.',
                            style: GoogleFonts.inter(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                onDelete(item.id);
                                Navigator.pop(ctx);
                              },
                              child: Text(
                                'Delete',
                                style: GoogleFonts.inter(
                                  color: AppConstants.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
