import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../services/storage_service.dart';
import '../services/media_storage_service.dart';
import '../services/seed_data.dart';
import '../utils/constants.dart';

class DeleteDataScreen extends StatelessWidget {
  final StorageService storage;

  const DeleteDataScreen({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Data',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        children: [
          Text(
            'Select a category to delete. Each action requires confirmation.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppConstants.textMuted,
            ),
          ),
          const SizedBox(height: 20),

          _DeleteTile(
            icon: Icons.fitness_center_rounded,
            color: AppConstants.accentPrimary,
            title: 'Exercises & Tags',
            subtitle: 'Remove all exercises from the library and all tags',
            onTap: () => _confirmDelete(
              context,
              'Exercises & Tags',
              'This will delete all exercises and their associated tags from the library.',
              () async {
                await storage.clearExercisesAndTags();
                if (context.mounted) {
                  context.read<ExerciseLibraryProvider>().reload();
                }
              },
              onAfter: () => _offerReseed(context),
            ),
          ),

          _DeleteTile(
            icon: Icons.calendar_view_day_rounded,
            color: AppConstants.accentSecondary,
            title: 'Day Templates',
            subtitle: 'Remove all saved day workout templates',
            onTap: () => _confirmDelete(
              context,
              'Day Templates',
              'This will delete all your day workout templates.',
              () => context.read<WorkoutProvider>().clearDayTemplates(),
            ),
          ),

          _DeleteTile(
            icon: Icons.view_week_rounded,
            color: AppConstants.accentTertiary,
            title: 'Week Templates',
            subtitle: 'Remove all saved week workout templates',
            onTap: () => _confirmDelete(
              context,
              'Week Templates',
              'This will delete all your week workout templates.',
              () => context.read<WorkoutProvider>().clearWeekTemplates(),
            ),
          ),

          _DeleteTile(
            icon: Icons.event_note_rounded,
            color: Colors.deepPurple,
            title: 'Program Templates',
            subtitle: 'Remove all saved program workout templates',
            onTap: () => _confirmDelete(
              context,
              'Program Templates',
              'This will delete all your program workout templates.',
              () => context.read<WorkoutProvider>().clearProgramTemplates(),
            ),
          ),

          _DeleteTile(
            icon: Icons.calendar_month_rounded,
            color: Colors.teal,
            title: 'Scheduled Workouts',
            subtitle:
                'Remove all scheduled days, weeks, and programs from the calendar',
            onTap: () => _confirmDelete(
              context,
              'Scheduled Workouts',
              'This will delete all scheduled workouts and their completion history from the calendar.',
              () => context.read<WorkoutProvider>().clearSchedule(),
            ),
          ),

          _DeleteTile(
            icon: Icons.straighten_rounded,
            color: Colors.amber,
            title: 'Custom Measurements',
            subtitle:
                'Remove all logged body measurements (weight, body fat, etc.)',
            onTap: () => _confirmDelete(
              context,
              'Custom Measurements',
              'This will delete all your custom measurement entries.',
              () => context.read<WorkoutProvider>().clearMeasurements(),
            ),
          ),

          _DeleteTile(
            icon: Icons.perm_media_rounded,
            color: Colors.pink,
            title: 'Media (Photos & Videos)',
            subtitle: 'Permanently delete all workout albums, photos, and videos',
            onTap: () => _confirmDelete(
              context,
              'Media',
              'This will permanently delete all your workout albums, photos, and videos from the app.',
              () => context.read<MediaStorageService>().clearAllMedia(),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          _DeleteTile(
            icon: Icons.delete_forever_rounded,
            color: AppConstants.error,
            title: 'Delete Everything',
            subtitle: 'Permanently remove ALL data including themes and media',
            onTap: () => _confirmDeleteAll(context),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String label,
    String message,
    Future<void> Function() onDelete, {
    VoidCallback? onAfter,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppConstants.error, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete $label?',
                style: GoogleFonts.inter(
                  color: AppConstants.textPrimary,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
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
            onPressed: () async {
              await onDelete();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$label deleted')));
                onAfter?.call();
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.bgCard,
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: AppConstants.error, size: 24),
              const SizedBox(width: 8),
              Text(
                'Delete All Data',
                style: GoogleFonts.inter(color: AppConstants.error),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will permanently delete ALL workouts, templates, schedules, logs, measurements, and themes.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type DELETE to confirm:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'DELETE',
                  isDense: true,
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () async {
                      // Clear Hive data
                      await context.read<WorkoutProvider>().clearAllData();
                      
                      // Clear Media files
                      if (context.mounted) {
                        await context.read<MediaStorageService>().clearAllMedia();
                      }

                      // Refresh library
                      if (context.mounted) {
                        context.read<ExerciseLibraryProvider>().reload();
                      }
                      
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All data has been deleted'),
                          ),
                        );
                        _offerReseed(context);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.error,
              ),
              child: const Text('Delete Everything'),
            ),
          ],
        ),
      ),
    );
  }

  void _offerReseed(BuildContext context) {
    final seeder = SeedDataService(storage);
    if (!seeder.isLibraryEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Populate Exercise Library?',
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
        ),
        content: Text(
          'Your exercise library is now empty. Would you like to load 350+ exercises with tags?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppConstants.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No thanks'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await seeder.seedLibrary();
              if (context.mounted) {
                context.read<ExerciseLibraryProvider>().reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exercise library loaded!')),
                );
              }
            },
            child: const Text('Load Exercises'),
          ),
        ],
      ),
    );
  }
}

class _DeleteTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeleteTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = color == AppConstants.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(
                color: isDestructive
                    ? AppConstants.error.withValues(alpha: 0.3)
                    : AppConstants.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: isDestructive
                              ? AppConstants.error
                              : AppConstants.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
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
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppConstants.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
