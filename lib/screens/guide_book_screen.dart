import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../widgets/guide_visuals.dart';
import 'guide_detail_screen.dart';

class GuideBookScreen extends StatelessWidget {
  const GuideBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
              vertical: AppConstants.paddingLG,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildWelcomeSection(),
                const SizedBox(height: 32),
                _buildSectionTitle('Home & Planning'),
                const SizedBox(height: 16),
                _GuideCard(
                  icon: Icons.home_rounded,
                  iconColor: AppConstants.accentPrimary,
                  title: 'Calendar & Home',
                  description:
                      'The home screen provides a daily view of your schedule. Use the calendar to quickly jump to any date or swipe to navigate days.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Calendar & Home',
                        content: _getHomeContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.play_circle_fill_rounded,
                  iconColor: AppConstants.accentSecondary,
                  title: 'Routine',
                  description:
                      'Start your workout, log your sets, and track your active timer throughout your session.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Routine',
                        content: _getRoutineContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.copy_rounded,
                  iconColor: AppConstants.accentTertiary,
                  title: 'Templates',
                  description:
                      'Build the blueprints for your training. Create and organize single-day routines, reusable weeks, and multi-week programs.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Templates',
                        content: _getSchedulingContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.fitness_center_rounded,
                  iconColor: AppConstants.accentWarm, // shifted colors down
                  title: 'Exercise Library',
                  description:
                      'The central database for all your movements. Define how exercises track data and where form checks are saved.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Exercise Library',
                        content: _getExercisesContent(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Progress & Stats'),
                const SizedBox(height: 16),
                _GuideCard(
                  icon: Icons.auto_graph_rounded,
                  iconColor: AppConstants.accentWarm,
                  title: 'Charts',
                  description:
                      'Analyze your progress over time with interactive charts. Track 1RM estimates, total volume, and consistency trends.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Charts',
                        content: _getChartsContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.menu_book_rounded,
                  iconColor: AppConstants.progressDay,
                  title: 'The Log Book',
                  description:
                      'A complete history of every session you\'ve logged. Access past performance, notes, and specific lift data chronologically.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'The Log Book',
                        content: _getLogBookContent(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Visual Progress'),
                const SizedBox(height: 16),
                _GuideCard(
                  icon: Icons.collections_rounded,
                  iconColor: AppConstants.accentGold,
                  title: 'Progress Gallery',
                  description:
                      'Manage your workout memories in the gallery. Organize photos and videos into custom albums for better tracking.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Progress Gallery',
                        content: _getGalleryContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.camera_alt_rounded,
                  iconColor: AppConstants.accentPrimary,
                  title: 'Camera',
                  description:
                      'Capture form check videos or progress photos directly inside the app. Media is automatically sorted into your workout library.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Camera',
                        content: _getCameraContent(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('System & Style'),
                const SizedBox(height: 16),
                _GuideCard(
                  icon: Icons.palette_rounded,
                  iconColor: AppConstants.accentSecondary,
                  title: 'Themes and Colors',
                  description:
                      'Personalize your dashboard with premium color palettes. Choose from presets or create a custom theme that fits your style.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Themes and Colors',
                        content: _getThemesContent(),
                      ),
                    ),
                  ),
                ),
                _GuideCard(
                  icon: Icons.save_rounded,
                  iconColor: AppConstants.success,
                  title: 'Data Management',
                  description:
                      'Take control of your data. Export your entire profile as a JSON file for local backup or import it to restore your progress.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GuideDetailScreen(
                        title: 'Data Management',
                        content: _getDataContent(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppConstants.bgDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        title: Text(
          'Guide Book',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.accentPrimary,
                    AppConstants.accentSecondary,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -20,
              child: Opacity(
                opacity: 0.15,
                child: Icon(
                  Icons.menu_book_rounded,
                  size: 250,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppConstants.bgDark.withValues(alpha: 0.8),
                    AppConstants.bgDark,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guide & Manual',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SelectionArea(
          child: Text(
            'Master every feature and customize your experience. Tap on any card below to learn more about a specific topic with interactive examples.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppConstants.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppConstants.accentPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppConstants.textMuted,
          ),
        ),
      ],
    );
  }

  // --- CONTENT BUILDERS ---

  List<dynamic> _getHomeContent() {
    return [
      TextSpan(
          text: 'Using the Home Screen\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text:
              'The home screen is where you track your day-to-day progress. Use the calendar to navigate and the list below to see your tasks.\n'),
      
      _buildSectionHeader('The Calendar'),
      const TextSpan(
          text:
              'This is your main tool for seeing your training history and future plans.\n'),
      
      GuideVisuals.dummyCalendar(),

      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Scheduling: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Hold down (long-press) on any day to add a workout.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'One-Shots: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Quickly create a new workout on the fly without using a template.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Picking a Day: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Tap any day to see the workouts for that date.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Today: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Tap the "Today" icon '),
        WidgetSpan(child: Icon(Icons.today_rounded, color: AppConstants.textPrimary, size: 18)),
        const TextSpan(text: ' to come back to the current day instantly.\n'),
      ]),

      _buildSectionHeader('What the Dots Mean'),
      const TextSpan(
          text:
              'The dots below a date tell you the status of that day\'s workouts:\n'),
      
      GuideVisuals.dotLegend([
        {'color': AppConstants.accentPrimary, 'label': 'Planned: A workout is scheduled.'},
        {'color': AppConstants.completion, 'label': 'Finished: You did all the sets.'},
        {'color': AppConstants.warning, 'label': 'Started: You did some sets but not all.'},
        {'color': AppConstants.accentGold, 'label': 'Active: You are currently working out.'},
        {'color': AppConstants.error, 'label': 'Missed: An unfinished workout from yesterday.'},
      ]),

      _buildSectionHeader('Workout List & Progress'),
      const TextSpan(
          text:
              'Workouts for the picked day appear as cards below the calendar.\n'),
      
      GuideVisuals.workoutCard(
        title: 'Morning Lift',
        dayProgress: 0.50,
        completedSets: 5,
        totalSets: 10,
      ),

      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Progress Bars: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'The bars fill up as you check off sets. One bar means a simple workout, three bars mean a program.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Swiping: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Swipe sideways on the cards to jump between days quickly.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Managing: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Hold down (long-press) on a card to hide it or delete it.'),
      ]),
    ];
  }

  Widget _buildSectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: AppConstants.accentPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppConstants.textPrimary,
        ),
      ),
    );
  }

  List<dynamic> _getSchedulingContent() {
    return [
      TextSpan(
          text: 'Building Your Workouts\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text:
              'Templates and routines are the blueprints for your training. You can build simple one-day workouts or complex multi-week programs.\n'),
      
      _buildSectionHeader('Template Types'),
      const TextSpan(
          text:
              'In the "Workouts" tab, you can manage three levels of organization:\n'),
      
      GuideVisuals.templateItem(
        title: 'Linear Muscle Growth',
        subtitle: '8 weeks • 4 days/week',
        note: 'Focus on compound lifts',
        icon: Icons.calendar_month_rounded,
        gradient: AppConstants.purpleGradient,
      ),
      
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Programs: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Collections of weeks. Good for long-term tracking.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Weeks: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'A set of 1-7 days that you can reuse together.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Days (Routines): ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'A single session containing specific exercises.\n'),
      ]),

      _buildSectionHeader('The Catalogue Library'),
      TextSpan(children: [
        const TextSpan(text: 'You may accumulate many templates over time. To keep your work organized:\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Active vs. Catalogue: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Your main list only shows the templates you currently use. You can "long-press" and remove any active template to safely tuck it away into your overall Catalogue.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Retrieving Items: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Tap the '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.inventory_2_rounded, size: 16, color: AppConstants.textPrimary),
        ),
        const TextSpan(text: ' icon at the top of the screen to open your Catalogue, where you can browse historic templates and restore them to your active list.'),
      ]),

      _buildSectionHeader('Building a Routine'),
      const TextSpan(
          text:
              'When you create or edit a Day, you enter the routine builder. This is where you pick your exercises.\n'),

      GuideVisuals.exerciseRow(
        name: 'Bench Press',
        sets: [
          {'reps': '8', 'weight': '80kg'},
          {'reps': '8', 'weight': '80kg'},
        ],
      ),

      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Adding: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Tap "+ Add Exercise" to pick from your library.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Reordering: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Hold and drag exercises to change their order.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Templates vs. Active: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Editing a template doesn\'t affect your history. It only changes how the workout looks next time you schedule it.'),
      ]),

      _buildSectionHeader('Builder Controls'),
      TextSpan(children: [
        const TextSpan(text: 'On the top-right of each exercise, you\'ll see several icons:\n'),
        const TextSpan(text: '• '),
        WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.bar_chart_rounded,
                size: 18, color: AppConstants.progressDay)),
        TextSpan(text: ' Stats: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.progressDay)),
        const TextSpan(
            text:
                'Provides a quick look at your past performance and personal records for this specific lift.\n'),
        const TextSpan(text: '• '),
        WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.percent_rounded,
                size: 18, color: AppConstants.accentGold)),
        TextSpan(text: ' Percentage: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentGold)),
        const TextSpan(
            text:
                'Switches between flat weight (like 80kg) and a percentage of your One-Rep Max.\n'),
        const TextSpan(text: '• '),
        WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(Icons.timer_off_rounded,
                size: 18, color: AppConstants.textMuted)),
        TextSpan(text: ' Timers: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(
            text:
                'Tap to choose between an active Stopwatch (measure your performance), a rest Countdown timer, or no timer at all.'),
      ]),
    ];
  }
  List<dynamic> _getRoutineContent() {
    return [
      TextSpan(
          text: 'Starting a Routine\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text:
              'Every workout begins with a Roadmap. When you tap a scheduled day or a draft on your Calendar, you\'re presented with the Routine Overview screen.\n'),
      
      _buildSectionHeader('Routine Overview'),
      const TextSpan(text: 'This screen allows you to review your planned lifts, check off any items you\'ve already completed (which will be highlighted in green), and ensure your equipment is ready before you hit "Start".\n'),
      GuideVisuals.startRoutineDummy(),

      const SizedBox(height: 16),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'The Template Rule: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Editing a routine from this screen (using the "Edit Routine" button) modifies this '),
        const TextSpan(text: 'specific session only', style: TextStyle(fontStyle: FontStyle.italic)),
        const TextSpan(text: '. This allows you to swap exercises or adjust sets on-the-fly without permanently changing your original Template.\n'),
      ]),

      _buildSectionHeader('Smart Weight Logic (%)'),
      TextSpan(children: [
        const TextSpan(text: 'If your routine includes exercises marked with the '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.percent_rounded, size: 14, color: AppConstants.accentGold),
        ),
        const TextSpan(text: ' MAX icon, the app performs a real-time calculation when you enter the session:\n'),
        const TextSpan(text: '\n1. '),
        const TextSpan(text: 'The app scans your entire history for your absolute Heaviest Lift for that exercise.\n'),
        const TextSpan(text: '2. '),
        const TextSpan(text: 'It applies your prescribed percentage to that max.\n'),
        const TextSpan(text: '3. '),
        const TextSpan(text: 'Example: If your Max Bench is 100kg and your template calls for 80%, the app will automatically pre-fill 80kg for you.\n'),
      ]),

      _buildSectionHeader('The Active Interface'),
      const TextSpan(text: 'Once you tap "Start", the app enters a focused, immersive mode. Navigation is handled through a horizontal carousel. Swipe left or right to move between exercises or the final stats page.\n'),
      GuideVisuals.activeWorkoutDummy(),

      const SizedBox(height: 16),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Logging Sets: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Tap the checkbox at the end of a row to mark a set as complete. This triggers a haptic click and starts your rest timer if enabled.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'The Camera: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'The '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.camera_alt_rounded, size: 14, color: AppConstants.accentPrimary),
        ),
        const TextSpan(text: ' icon in the header opens a smart camera that routes photos directly to this exercise\'s designated folder (e.g., "Form Checks").\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Finishing: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Swipe to the very last page to find the "Finish Routine" button. This will log your workout to the archive and calculate your final stats.\n'),
      ]),

      _buildSectionHeader('Post-Workout Analytics'),
      const TextSpan(text: 'After finishing, you\'ll see a high-level summary of your performance. These stats are permanently archived in your Log Book and reflected in your progress charts.\n'),
      Row(
        children: [
          Expanded(child: GuideVisuals.statCardDummy('VOLUME', '12,450 lb', Icons.fitness_center_rounded)),
          const SizedBox(width: 12),
          Expanded(child: GuideVisuals.statCardDummy('DURATION', '1h 05m', Icons.timer_rounded)),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: GuideVisuals.statCardDummy('PEAK LIFT', '315 lb', Icons.emoji_events_rounded)),
          const SizedBox(width: 12),
          Expanded(child: GuideVisuals.statCardDummy('SETS', '15 / 15', Icons.layers_rounded)),
        ],
      ),

      _buildSectionHeader('Partial Completions'),
      TextSpan(children: [
        const TextSpan(text: 'Life happens, and sometimes you need to cut a session short. The app is built to handle this gracefully:\n'),
        const TextSpan(text: '\n• '),
        TextSpan(text: 'Finishing Early: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.warning)),
        const TextSpan(text: 'If you swipe to the Finish page without checking off every set, the app will warn you and then mark the session as '),
        TextSpan(text: 'LOGGED INCOMPLETE', style: TextStyle(fontWeight: FontWeight.w900, color: AppConstants.warning)),
        const TextSpan(text: '. This status turns the workout icon yellow on your calendar.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Stat Accuracy: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.textPrimary)),
        const TextSpan(text: 'Only unchecked sets are ignored. Any work you did complete will still be logged to your history and included in your volume totals, ensuring your progress tracking remains accurate even during off-days.\n'),
      ]),
    ];
  }

  List<dynamic> _getExercisesContent() {
    return [
      TextSpan(
          text: 'Exercise Library\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text: 'The Exercise Library is the centralized database where all movements are defined and stored. It serves as the master list when building templates or starting a single-day routine.\n'),

      _buildSectionHeader('Finding & Filtering'),
      const TextSpan(text: 'Use the top search bar to locate exercises by name or use the filter icon to isolate specific muscle groups or equipment tags. Each entry includes a name, assigned tags, and a stats indicator that reflects how much historical data is available for that movement.\n'),
      GuideVisuals.exerciseLibraryDummy(),

      _buildSectionHeader('Intelligent Configuration'),
      const TextSpan(text: 'By pre-configuring exercise parameters, you minimize manual data entry during active sessions. These technical flags define how the app behaves when that specific movement is reached in a routine:\n'),
      GuideVisuals.exerciseBlueprintDummy(),

      const SizedBox(height: 16),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Smart Weight (%): ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentGold)),
        const TextSpan(text: 'Enable this to automatically pre-fill set weights based on a percentage of your historical "Peak Lift". This ensures your targets are always accurate to your current strength level.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Timer Mode: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Pre-configure the timer type to save time. Choose a '),
        TextSpan(text: 'Stopwatch', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: ' for tracking total duration (e.g., AMRAP) or a '),
        TextSpan(text: 'Countdown', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: ' for fixed-duration sets like Planks.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Media Routing: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Set a target album for each exercise. When you use the camera while performing that specific exercise during a routine, all media is automatically routed and saved to that folder for organized form checks.\n'),
      ]),

      _buildSectionHeader('Organization & Tags'),
      TextSpan(children: [
        const TextSpan(text: 'Custom categorization is managed via the '),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Icon(Icons.style_rounded, size: 14, color: AppConstants.accentPrimary),
        ),
        const TextSpan(text: ' icon. From the Tags Manager, you can create muscle groups, equipment types, or movement patterns. These tags are used throughout the app to filter tags, map charts, and generate statistics.\n'),
      ]),

      _buildSectionHeader('Managing Data'),
      const TextSpan(text: 'Each exercise row features a '),
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(Icons.bar_chart_rounded, size: 16, color: AppConstants.progressDay),
      ),
      const TextSpan(text: ' chart icon. Tapping this provides instant access to long-term performance trends and 1RM history for that specific movement. Modification of an exercise definition will update its configuration for all future sessions where that exercise is referenced.\n'),
      const SizedBox(height: 12),
      GuideVisuals.exerciseStatsRow(),
    ];
  }

  List<dynamic> _getChartsContent() {
    return [
      TextSpan(
          text: 'The Precision of Progress\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(text: 'The Charts screen converts your raw training logs into visual trends, allowing you to identify plateaus, celebrate strength gains, and audit your long-term progression.\n'),
      
      _buildSectionHeader('Data Categories (Tabs)'),
      const SizedBox(height: 8),
      GuideVisuals.chartsTabsDummy(),
      const SizedBox(height: 16),
      const TextSpan(text: 'The screen is divided into three distinct tabs, each serving a different analytical purpose:\n'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Exercises: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Analyze the performance of a specific movement over time.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Tags: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.progressDay)),
        const TextSpan(text: 'View an aggregated macro-perspective (e.g., total volume for all "Chest" exercises).\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Custom: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentGold)),
        const TextSpan(text: 'Log and track bodily measurements outside of workouts, such as body weight or waist size.\n'),
      ]),

      _buildSectionHeader('Dynamic Filtering'),
      const SizedBox(height: 8),
      GuideVisuals.chartsFiltersDummy(),
      const SizedBox(height: 16),
      const TextSpan(text: 'Within the analytical tabs, apply filters to precisely define the graph:\n'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Variants: ', style: TextStyle(fontWeight: FontWeight.w800)),
        const TextSpan(text: 'Toggle between "Strength", "Timed", or "Wgt-Timed" to load the correct selection list.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Metrics: ', style: TextStyle(fontWeight: FontWeight.w800)),
        const TextSpan(text: 'For Strength exercises, rotate the Y-Axis to display Total Volume, Reps, Average Weight, or Maximum Weight.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Dates: ', style: TextStyle(fontWeight: FontWeight.w800)),
        const TextSpan(text: 'Frame your data using quick constraints (1W, 1M, 1Y) or custom start/end points.\n'),
      ]),

      _buildSectionHeader('Configuring the Graph'),
      const SizedBox(height: 8),
      GuideVisuals.chartsChartAreaDummy(),
      const SizedBox(height: 16),
      const TextSpan(text: 'Adjust how the X-Axis resolves your historical data points:\n'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Session Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: 'Plots each recorded workout sequentially side-by-side (1, 2, 3...). This creates a visually smooth linear progression curve, ignoring rest days.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Date Mode: ', style: TextStyle(fontWeight: FontWeight.bold)),
        const TextSpan(text: 'Plots your data against an absolute timeline. This highlights real-time frequency distribution and pauses in training.\n'),
      ]),
      const SizedBox(height: 12),
      const TextSpan(children: [
        TextSpan(text: 'Interactive Intelligence: ', style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: 'The graph dynamically scales to fit your data. Tapping on points reveals exact values and dates.\n'),
      ]),

      _buildSectionHeader('Historical Log'),
      const SizedBox(height: 8),
      GuideVisuals.historicalLogDummy(),
      const SizedBox(height: 16),
      const TextSpan(text: 'Below the chart, a reverse-chronological ledger provides an exact accounting of every generated plot shown above, marking new Personal Records with a golden badge.\n'),
    ];
  }

  List<dynamic> _getLogBookContent() {
    return [
      TextSpan(
          text: 'The Historical Archive\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text: 'Every completed workout, week, or program is automatically recorded in the Log Book. Entries are organized in reverse chronological order for easy reference and performance auditing.\n'),

      _buildSectionHeader('Chronological History'),
      const TextSpan(text: 'The primary feed provides a high-level summary of each session. Entries identify the workout type, volume trends, and completion status at a glance.\n'),
      const SizedBox(height: 12),
      GuideVisuals.logBookEntry(
        title: 'Push Day A', 
        date: 'Mar 20, 2026', 
        subtitle: 'Vol: 12,450  •  Reps: 45  •  Sets: 8',
        type: 'day',
      ),
      GuideVisuals.logBookEntry(
        title: 'Strength Week 4', 
        date: 'Mar 18, 2026', 
        subtitle: 'Vol: 85,200  •  Sets: 42',
        type: 'week',
      ),

      _buildSectionHeader('Session Performance Statistics'),
      const TextSpan(text: 'Selecting an entry opens a dedicated statistics view. This view displays the same performance metrics generated at the end of a session, including volume distribution, duration, and peak lift data for that specific date.\n'),
      const SizedBox(height: 12),
      GuideVisuals.logBookDetailsDummy(),

      _buildSectionHeader('Interaction & Management'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Data Review: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Selection of a log entry allows for a granular review of the exercises, weights, and repetitions recorded during the session.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Log Management: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.error)),
        const TextSpan(text: 'Long-press any entry to access management functions. Workouts can be "Un-completed" to remove them from the historical record if they were logged in error.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Completion Status: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.warning)),
        const TextSpan(text: 'Entries with the "Partially Complete" indicator denote sessions where performance targets were only partially met or sets were left unchecked.\n'),
      ]),
    ];
  }

  List<dynamic> _getGalleryContent() {
    return [
      TextSpan(
          text: 'The Progress Gallery\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text: 'The Gallery is a private, internal vault for your training media. It keeps your workout photos and form-check videos separate from your device\'s main camera roll while providing advanced organizational tools.\n'),
      
      _buildSectionHeader('Albums & Organization'),
      const TextSpan(text: 'Media is organized into custom albums. You can create albums for specific purposes, such as "Physique Tracking" or "Squat Form," to keep your progress structured.\n'),
      const SizedBox(height: 12),
      const GalleryGridDummy(),

      _buildSectionHeader('Navigation & Gestures'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Dynamic Grid: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Use pinch-to-zoom gestures inside any album to instantly change the number of columns. Switch between a detailed single-row view or a high-density grid for fast scanning.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Bulk Selection: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Long-press any item to enter selection mode, then drag your finger across the grid to select multiple items in a single motion.\n'),
      ]),
      const SizedBox(height: 12),
      const ZoomIllustrationDummy(),

      _buildSectionHeader('Visual Comparison'),
      const TextSpan(text: 'Access advanced comparison tools by selecting media from your albums or using the global Compare tool. These features let you audit body composition changes or form improvements with precision.\n'),
      const SizedBox(height: 12),
      const CompareDummy(),
      const SizedBox(height: 12),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Side by Side: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Place two images or videos next to each other. Use the drag-and-drop timeline to assign "Before" and "After" slots, then use the split-slider to scrub between the two frames.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Onion Skin: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Overlay two images with adjustable transparency. This is ideal for checking posture or muscle symmetry by "ghosting" the after image over the before image.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Time-lapse: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentTertiary)),
        const TextSpan(text: 'Create a dynamic sequence from an entire album or a specific date range. Control the playback speed and scrub through your entire transformation journey chronologically.\n'),
      ]),

      _buildSectionHeader('Management & Export'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Internal Storage: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentTertiary)),
        const TextSpan(text: 'Media captured or imported into the app is stored within the app\'s private directory to protect your privacy and clear your primary gallery.\n'),
        TextSpan(text: 'Universal Export: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.success)),
        const TextSpan(text: 'To share media externally, use the Export function in the Multi-Select or Full-Screen view. This saves a copy to your device\'s native gallery.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Sorting: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.textMuted)),
        const TextSpan(text: 'Toggle between "Newest First" and "Oldest First" in the album view to track your journey from either direction.\n'),
      ]),
    ];
  }

  List<dynamic> _getCameraContent() {
    return [
      TextSpan(
          text: 'Media Capture & AI Alignment\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(
          text: 'The built-in camera is a high-performance tool specifically designed for fitness tracking. It eliminates the friction of switching apps and ensures all your training media is categorized as you capture it.\n'),
      const SizedBox(height: 12),
      const CameraInterfaceDummy(),

      _buildSectionHeader('Interface & Controls'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Capture Modes: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Slide between PHOTO and VIDEO at the bottom of the screen. All media is captured unfiltered and in high resolution to ensure the most accurate visual tracking and AI alignment.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Smart Routing: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Use the folder icon at the top-left to select a target album before capturing. If you launch the camera from a specific exercise, it will automatically route media to that exercise\'s default album.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Tools & Utility: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentTertiary)),
        const TextSpan(text: 'Tap the center bubble to access the Countdown Timer (2s, 5s, 10s), Flash controls, and the AI Pose Engine.\n'),
      ]),

      _buildSectionHeader('AI Pose Engine & Auto-Capture'),
      const TextSpan(
          text: 'The Pose Engine uses real-time skeletal tracking to help you replicate consistent poses between check-ins. This is the ultimate tool for visual progress tracking.\n'),
      const SizedBox(height: 12),
      const PoseEngineDummy(),
      const SizedBox(height: 12),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Ghost Overlay: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'When enabled, the app analyzes the most recent photos in your target album and overlays a "Ghost Skeleton" on the preview. This allows you to stand in exactly the same spot and match your previous posture.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Auto-Match Capture: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.success)),
        const TextSpan(text: 'Once your live skeleton matches the ghost anchor (95%+ accuracy), the app will detect a "Match" and trigger a 3-second stable-hold countdown to automatically snap the photo. No hands required.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Symmetry Logic: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.warning)),
        const TextSpan(text: 'The engine intelligently handles shots from different sides, automatically mirroring the ghost anatomy if it detects you are posing in the opposite direction.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Mirror Correction: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentTertiary)),
        const TextSpan(text: 'Selfie-style previews are mirrored live for a natural feel, but the system automatically resolves the final image to its true anatomical orientation. This ensures that "Left" and "Right" are consistent across all check-ins, regardless of which camera was used.\n'),
      ]),

    ];
  }

  List<dynamic> _getThemesContent() {
    return [
      TextSpan(
          text: 'Themes and Colors\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(text: 'Personalize your training environment by selecting an existing theme or creating your own custom palette.\n'),

      _buildSectionHeader('Selecting a Theme'),
      const TextSpan(text: 'Browse the collection of high-contrast themes designed for visibility. Tap any theme card to apply the colors across the entire application instantly.\n'),
      const SizedBox(height: 12),
      GuideVisuals.themeStackDummy(),
      const SizedBox(height: 12),
      const TextSpan(text: 'Each theme updates the backgrounds, cards, primary buttons, and chart data points to maintain a unified visual style.\n'),

      _buildSectionHeader('Using the Custom Editor'),
      const TextSpan(text: 'Open the custom theme maker to modify individual color tokens. The editor provides a live view of app components to show how your changes look in real time.\n'),
      const SizedBox(height: 12),
      GuideVisuals.themeEditorDummy(),
      const SizedBox(height: 16),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Color Tabs: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'Switch between background, accent, text, and status folders to find the specific color you wish to edit.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'HEX Code Input: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'Enter precise values into the HEX field. This allows you to match specific color codes from other platforms or design tools.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Copy and Paste: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentTertiary)),
        const TextSpan(text: 'Use the copy button to save a color value to your clipboard. Use the paste button to apply a HEX code you have copied from elsewhere.\n'),
      ]),

      _buildSectionHeader('History and Saving'),
      TextSpan(children: [
        const TextSpan(text: 'Use the '),
        TextSpan(text: 'Undo', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentPrimary)),
        const TextSpan(text: ' ('),
        WidgetSpan(child: Icon(Icons.undo_rounded, size: 14, color: AppConstants.textPrimary)),
        const TextSpan(text: ') and '),
        TextSpan(text: 'Redo', style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentSecondary)),
        const TextSpan(text: ' ('),
        WidgetSpan(child: Icon(Icons.redo_rounded, size: 14, color: AppConstants.textPrimary)),
        const TextSpan(text: ') buttons to cycle through your last 50 changes. When you are satisfied with your layout, tap Save Theme to store the palette to your profile.\n'),
      ]),

      _buildSectionHeader('Backups'),
      const TextSpan(text: 'Your custom themes are saved within your application data. Exporting your data to a file will include all your custom themes so you can restore them on a new device later.'),
    ];
  }


  List<dynamic> _getDataContent() {
    return [
      TextSpan(
          text: 'Taking Care of Your Data\n',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppConstants.textPrimary)),
      const TextSpan(text: 'This app is built with privacy in mind. Everything you do, including your workouts, PRs, and progress photos, stays right on your phone. Nothing is uploaded to a cloud server, which means you have total control.\n'),
      
      _buildSectionHeader('Saving a Backup'),
      const TextSpan(text: 'Since your data only lives on your device, it is a good idea to save a backup once in a while. If you lose your phone or delete the app, your history will be lost unless you have a backup file saved somewhere safe.\n'),
      const SizedBox(height: 12),
      GuideVisuals.dataManagementDummy(),
      const SizedBox(height: 16),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Save to File: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.success)),
        const TextSpan(text: 'This creates a small JSON file. You can save this to your device folder, email it to yourself, or put it on your Google Drive.\n'),
        const TextSpan(text: '• '),
        TextSpan(text: 'Copy JSON: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentSecondary)),
        const TextSpan(text: 'This copies all your data as text so you can paste it into a note or send it in a message.\n'),
      ]),

      _buildSectionHeader('Loading a Backup'),
      const TextSpan(text: 'If you get a new phone or need to restore your old data, you can use the Import feature. Just pick your saved backup file and the app will load everything back into your local data.\n'),
      TextSpan(children: [
        const TextSpan(text: '\n1. '),
        const TextSpan(text: 'Tap "Open Backup File" and find your saved JSON.\n'),
        const TextSpan(text: '2. '),
        const TextSpan(text: 'The app will check the file to make sure it is valid.\n'),
        const TextSpan(text: '3. '),
        const TextSpan(text: 'Confirm the change to bring your old workouts into your current list.\n'),
      ]),

      _buildSectionHeader('Photos and Videos'),
      TextSpan(children: [
        const TextSpan(text: '• '),
        TextSpan(text: 'Media Backup: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.accentPrimary)),
        const TextSpan(text: 'The backup file handles your workout text, but it doesn\'t actually contain your physical photos. To keep your photos safe, make sure you back up the "OpenGym" folder in your regular phone gallery.'),
      ]),
    ];
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _GuideCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMD),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryGridDummy extends StatelessWidget {
  const GalleryGridDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PHYSIQUE ALBUM',
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppConstants.textMuted,
                      letterSpacing: 1)),
              Icon(Icons.grid_view_rounded,
                  size: 14, color: AppConstants.accentPrimary),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            children: List.generate(
                6,
                (i) => Container(
                      decoration: BoxDecoration(
                        color: [
                          AppConstants.accentPrimary.withValues(alpha: 0.1),
                          AppConstants.accentSecondary.withValues(alpha: 0.1),
                          AppConstants.accentTertiary.withValues(alpha: 0.1),
                          AppConstants.accentWarm.withValues(alpha: 0.1),
                          AppConstants.progressDay.withValues(alpha: 0.1),
                          AppConstants.progressWeek.withValues(alpha: 0.1),
                        ][i % 6],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppConstants.border.withValues(alpha: 0.5)),
                      ),
                      child: i == 1
                          ? Stack(
                              children: [
                                Center(
                                    child: Icon(Icons.play_circle_fill_rounded,
                                        color: AppConstants.textPrimary.withValues(alpha: 0.3), size: 20)),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                        color: AppConstants.accentPrimary,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded,
                                        color: Colors.white, size: 10),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                                  child: Icon(
                                      (i % 3 == 0) ? Icons.play_circle_fill_rounded : Icons.photo_rounded,
                                      color: AppConstants.textPrimary.withValues(alpha: 0.15), size: 24)),
                    )),
          ),
          const SizedBox(height: 12),
          Text('6 ITEMS • UPDATED TODAY',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textMuted)),
        ],
      ),
    );
  }
}

class ZoomIllustrationDummy extends StatelessWidget {
  const ZoomIllustrationDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppConstants.accentPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.photo_rounded, color: AppConstants.accentPrimary.withValues(alpha: 0.4), size: 20),
                 ),
                 const SizedBox(width: 8),
                 Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppConstants.accentSecondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.play_circle_fill_rounded, color: AppConstants.accentSecondary.withValues(alpha: 0.4), size: 20),
                 ),
                 const SizedBox(width: 8),
                 Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppConstants.accentTertiary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Icon(Icons.photo_rounded, color: AppConstants.accentTertiary.withValues(alpha: 0.4), size: 20),
                 ),
              ],
            ),
          ),
          Center(
            child: Icon(Icons.zoom_out_map_rounded,
                color: AppConstants.accentSecondary.withValues(alpha: 0.6),
                size: 48),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Text('PINCH TO ADJUST GRID COLUMNS',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppConstants.textMuted)),
          ),
        ],
      ),
    );
  }
}

class CompareDummy extends StatelessWidget {
  const CompareDummy({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.accentWarm.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_rounded,
                      color: AppConstants.accentWarm.withValues(alpha: 0.4), size: 32),
                  const SizedBox(height: 8),
                  Text('JAN 1',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.textMuted)),
                ],
              ),
            ),
          ),
          Container(
            width: 2,
            height: 140,
            color: AppConstants.accentPrimary.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.accentPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_rounded,
                      color: AppConstants.accentPrimary.withValues(alpha: 0.4), size: 32),
                  const SizedBox(height: 8),
                  Text('MAR 21',
                      style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppConstants.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
