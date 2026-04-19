import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/exercise_definition.dart';
import '../providers/exercise_library_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'package:provider/provider.dart';

import 'tags_manager_screen.dart';
import '../widgets/tag_selection_sheet.dart';
import '../widgets/exercise_stats_dialog.dart';
import '../providers/workout_provider.dart';
import '../services/media_storage_service.dart';
import '../widgets/album_selection_sheet.dart';
import '../widgets/timer_picker_dialog.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  List<String> _selectedTags = [];
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: AppConstants.animMedium,
    );
    _fabAnimController.forward();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final provider = context.watch<ExerciseLibraryProvider>();
    final exercises = provider.searchExercises(
      _searchQuery,
      tagFilters: _selectedTags,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Exercise Library',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list_rounded),
                if (_selectedTags.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConstants.accentSecondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              final tags = await TagSelectionSheet.show(
                context,
                allTags: context.read<ExerciseLibraryProvider>().tags,
                initialSelectedTags: _selectedTags,
                tagParents: context.read<ExerciseLibraryProvider>().tagParents,
              );
              if (tags != null) {
                setState(() => _selectedTags = tags);
              }
            },
            tooltip: 'Filter by Tags',
          ),
          IconButton(
            icon: const Icon(Icons.style_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TagsManagerScreen()),
            ),
            tooltip: 'Manage Tags',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.paddingMD,
              AppConstants.paddingSM,
              AppConstants.paddingMD,
              AppConstants.paddingSM,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.bgSurface,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppConstants.textMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMD,
                    vertical: AppConstants.paddingSM + 4,
                  ),
                ),
              ),
            ),
          ),

          // Active filter chips (optional, just to show what's selected)
          if (_selectedTags.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMD,
                ),
                children: _selectedTags
                    .map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            tag,
                            style: GoogleFonts.inter(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _selectedTags.remove(tag));
                          },
                          backgroundColor: AppConstants.accentPrimary
                              .withValues(alpha: 0.2),
                          side: BorderSide.none,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercises.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      return _ExerciseListTile(
                        exercise: exercises[index],
                        onTap: () => _showEditDialog(exercises[index]),
                        onDelete: () => _confirmDelete(exercises[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.elasticOut,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'library_new_exercise_fab',
          onPressed: _showCreateDialog,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'New Exercise',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppConstants.accentPrimary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppConstants.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty && _selectedTags.isEmpty
                ? 'No exercises yet'
                : 'No matching exercises',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedTags.isEmpty
                ? 'Tap + to create your first exercise'
                : 'Try a different search or filter',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppConstants.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    _showExerciseDialog(null);
  }

  void _showEditDialog(ExerciseDefinition exercise) {
    _showExerciseDialog(exercise);
  }

  void _showExerciseDialog(ExerciseDefinition? exercise) {
    final nameController = TextEditingController(text: exercise?.name ?? '');
    final selectedTags = List<String>.from(exercise?.tags ?? []);
    int timerMode = exercise?.timerMode ?? 0;
    int timerDuration = exercise?.timerDurationSeconds ?? 60;
    bool usePercentage = exercise?.usePercentage ?? false;
    bool isWeightedTimed = exercise?.isWeightedTimed ?? false;
    String currentDefaultAlbum = exercise?.defaultAlbum ?? '';

    final provider = context.read<ExerciseLibraryProvider>();
    final isEditing = exercise != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Exercise' : 'New Exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: !isEditing,
                  style: GoogleFonts.inter(color: AppConstants.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    hintText: 'e.g., Bench Press',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tags',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Show selected tags
                if (selectedTags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedTags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppConstants.accentPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppConstants.accentPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final tags = await TagSelectionSheet.show(
                      ctx,
                      allTags: provider.tags,
                      initialSelectedTags: selectedTags,
                      tagParents: provider.tagParents,
                      onCreateTag: (tag) async {
                        provider.addTag(tag);
                      },
                    );
                    if (tags != null) {
                      setDialogState(() {
                        selectedTags.clear();
                        selectedTags.addAll(tags);
                      });
                    }
                  },
                  icon: const Icon(Icons.style_rounded, size: 18),
                  label: Text(
                    selectedTags.isEmpty ? 'Select Tags' : 'Change Tags',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.accentPrimary,
                    side: BorderSide(color: AppConstants.border),
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Default Settings',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Use % of Max Weight', style: GoogleFonts.inter(fontSize: 14)),
                  value: usePercentage,
                  activeThumbColor: AppConstants.accentGold,
                  onChanged: (v) => setDialogState(() => usePercentage = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Is Weighted Timed', style: GoogleFonts.inter(fontSize: 14)),
                  value: isWeightedTimed,
                  activeThumbColor: AppConstants.accentSecondary,
                  onChanged: (v) => setDialogState(() => isWeightedTimed = v),
                ),
                Row(
                  children: [
                    Text('Timer Default', style: GoogleFonts.inter(fontSize: 14)),
                    const Spacer(),
                    DropdownButton<int>(
                      dropdownColor: AppConstants.bgCard,
                      value: timerMode,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('None')),
                        DropdownMenuItem(value: 1, child: Text('Stopwatch')),
                        DropdownMenuItem(value: 2, child: Text('Countdown')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => timerMode = v);
                      },
                    ),
                  ],
                ),
                if (timerMode == 2) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Duration (sec)', style: GoogleFonts.inter(fontSize: 14)),
                      const Spacer(),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          key: ValueKey(timerDuration),
                          initialValue: timerDuration.toString(),
                          readOnly: true,
                          onTap: () async {
                            final res = await TimerPickerDialog.show(ctx, initialSeconds: timerDuration);
                            if (res != null) {
                              setDialogState(() {
                                timerDuration = res;
                              });
                            }
                          },
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(color: AppConstants.textPrimary),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 32),
                Text(
                  'Media Settings',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final mediaProvider = context.read<MediaStorageService>();
                    final albums = await mediaProvider.getAlbums();
                    final albumNames = albums.map((a) => a.name).toList();
                    
                    if (ctx.mounted) {
                      final selected = await AlbumSelectionSheet.show(
                        ctx,
                        allAlbums: albumNames,
                        initialSelectedAlbum: currentDefaultAlbum,
                        onCreateAlbum: (name) => mediaProvider.ensureAlbum(name),
                      );
                      if (selected != null) {
                        setDialogState(() => currentDefaultAlbum = selected);
                      }
                    }
                  },
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: Text(
                    currentDefaultAlbum.isEmpty ? 'Select Album' : currentDefaultAlbum,
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppConstants.accentPrimary,
                    side: BorderSide(color: AppConstants.border),
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
              onPressed: () async {
                final name = Helpers.formatExerciseName(nameController.text);
                if (name.isEmpty) return;
                
                final def = ExerciseDefinition(
                  id: isEditing ? exercise.id : null,
                  name: name,
                  tags: selectedTags,
                  timerMode: timerMode,
                  timerDurationSeconds: timerDuration,
                  usePercentage: usePercentage,
                  isWeightedTimed: isWeightedTimed,
                  defaultAlbum: currentDefaultAlbum,
                );

                bool success;
                if (isEditing) {
                  success = await provider.updateExercise(def);
                } else {
                  success = await provider.addExercise(def);
                }

                if (!success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('An exercise with this name already exists.'),
                      backgroundColor: AppConstants.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (context.mounted) Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.accentPrimary,
              ),
              child: Text(
                isEditing ? 'Save' : 'Create',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(ExerciseDefinition exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exercise'),
        content: Text('Delete "${exercise.name}"? This cannot be undone.'),
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
              context.read<ExerciseLibraryProvider>().deleteExercise(
                exercise.id,
              );
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.error),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  final ExerciseDefinition exercise;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExerciseListTile({
    required this.exercise,
    required this.onTap,
    required this.onDelete,
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
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          splashColor: AppConstants.accentPrimary.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            decoration: BoxDecoration(
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
                        exercise.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      if (exercise.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: exercise.tags
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppConstants.accentPrimary
                                          .withValues(alpha: 0.15),
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
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showExerciseStatsDialog(
                      context,
                      exercise.id,
                      exercise.name,
                      false,
                    );
                  },
                  icon: Icon(
                    Icons.bar_chart_rounded,
                    color: (() {
                      final level = context.watch<WorkoutProvider>().getExerciseDataLevel(exercise.id, false, false);
                      if (level == 2) return AppConstants.progressDay;
                      if (level == 1) return AppConstants.progressWeek;
                      return AppConstants.textMuted.withValues(alpha: 0.3);
                    })(),
                    size: 20,
                  ),
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppConstants.textMuted,
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
