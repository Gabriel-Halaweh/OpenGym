import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'services/seed_data.dart';
import 'services/media_storage_service.dart';
import 'providers/exercise_library_provider.dart';
import 'providers/workout_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/workouts_screen.dart';
import 'screens/library_screen.dart';
import 'screens/charts_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/guide_book_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Style system UI
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppConstants.bgCard,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage
  final storage = StorageService();
  await storage.init();

  // Initialize media storage
  final mediaStorage = MediaStorageService();
  await mediaStorage.initialize();

  runApp(WorkoutApp(storage: storage, mediaStorage: mediaStorage));
}

class WorkoutApp extends StatelessWidget {
  final StorageService storage;
  final MediaStorageService mediaStorage;

  const WorkoutApp({
    super.key,
    required this.storage,
    required this.mediaStorage,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => ThemeProvider(storage)),
        ChangeNotifierProvider(create: (_) => ExerciseLibraryProvider(storage)),
        ChangeNotifierProvider(create: (_) => WorkoutProvider(storage)),
        ChangeNotifierProvider.value(value: mediaStorage),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'OpenGym',
            debugShowCheckedModeBanner: false,
            theme: AppConstants.getTheme(themeProvider.theme),
            home: MainScaffold(),
          );
        },
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 2; // Start on Home

  final _workoutsKey = GlobalKey<WorkoutsScreenState>();

  late final _screens = [
    WorkoutsScreen(key: _workoutsKey),
    const LibraryScreen(),
    const HomeScreen(),
    const ChartsScreen(),
    const CameraScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndOfferSeed();
    });
  }

  Future<void> _checkAndOfferSeed() async {
    final workoutApp = context.findAncestorWidgetOfExactType<WorkoutApp>();
    if (workoutApp == null) return;

    final seeder = SeedDataService(workoutApp.storage);
    final isLibraryEmpty = seeder.isLibraryEmpty;
    final isProgramsEmpty = workoutApp.storage.getProgramTemplates().isEmpty;

    if (!isLibraryEmpty && !isProgramsEmpty) {
      if (mounted) {
        final storage = workoutApp.storage;
        if (!storage.getHasSeenWelcome()) {
           _showWelcomeDialog(storage);
        }
      }
      return;
    }

    final title = isLibraryEmpty
        ? 'Populate Exercise Library?'
        : 'Load 24-Week Program?';
    final content = isLibraryEmpty
        ? 'Your exercise library is empty. Would you like to load 120+ exercises with tags and the 24-week Hybrid Foundation program?'
        : 'Your program templates are empty. Would you like to load the 24-week Hybrid Foundation program?';
    final buttonText = isLibraryEmpty ? 'Load Data' : 'Load Program';

    final shouldSeed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(title, style: TextStyle(color: AppConstants.textPrimary)),
        content: Text(
          content,
          style: TextStyle(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No thanks'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(buttonText),
          ),
        ],
      ),
    );

    if (shouldSeed == true && mounted) {
      if (isLibraryEmpty) {
        await seeder.seedLibrary();
      } else if (isProgramsEmpty) {
        await seeder.seedPrograms();
      }
      // Refresh providers
      if (mounted) {
        if (isLibraryEmpty) {
          await context.read<ExerciseLibraryProvider>().reload();
        }
        await context.read<WorkoutProvider>().reload();
      }
    }

    if (mounted) {
      final workoutApp = context.findAncestorWidgetOfExactType<WorkoutApp>();
      if (workoutApp != null) {
        final storage = workoutApp.storage;
        if (!storage.getHasSeenWelcome()) {
          _showWelcomeDialog(storage);
        }
      }
    }
  }

  void _showWelcomeDialog(StorageService storage) {
    bool doNotShowAgain = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            ),
            title: Text(
              'Welcome to OpenGym!',
              style: GoogleFonts.inter(
                color: AppConstants.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We highly recommend checking out the Guide Book to learn how to master your routines and get the most out of the app.',
                  style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: doNotShowAgain,
                        activeColor: AppConstants.accentPrimary,
                        onChanged: (val) {
                          setDialogState(() {
                            doNotShowAgain = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            doNotShowAgain = !doNotShowAgain;
                          });
                        },
                        child: Text(
                          'Do not show again',
                          style: GoogleFonts.inter(
                            color: AppConstants.textPrimary,
                            fontSize: 14,
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
                onPressed: () {
                  if (doNotShowAgain) storage.saveHasSeenWelcome(true);
                  Navigator.pop(ctx);
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    color: AppConstants.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accentPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusSM),
                  ),
                ),
                onPressed: () {
                  if (doNotShowAgain) storage.saveHasSeenWelcome(true);
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GuideBookScreen()),
                  );
                },
                child: Text(
                  'Open Guide Book',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 5% bottom padding for Android nav bar
    final bottomPadding =
        MediaQuery.of(context).size.height * AppConstants.bottomNavSafety;

    return PopScope(
      canPop: _currentIndex == 2, // Only allow pop (minimize) from Home
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Navigate back to Home
          setState(() => _currentIndex = 2);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: AppConstants.border, width: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_rounded),
                  activeIcon: Icon(Icons.fitness_center_rounded),
                  label: 'Workouts',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.library_books_rounded),
                  activeIcon: Icon(Icons.library_books_rounded),
                  label: 'Library',
                ),
                BottomNavigationBarItem(
                  icon: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppConstants.accentPrimary,
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  activeIcon: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppConstants.accentPrimary,
                    child: const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  activeIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Charts',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt_rounded),
                  activeIcon: Icon(Icons.camera_alt_rounded),
                  label: 'Camera',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
