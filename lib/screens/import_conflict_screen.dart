import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_library_provider.dart';

class ImportConflictScreen extends StatefulWidget {
  final StorageService storage;
  final ImportAnalysis analysis;

  const ImportConflictScreen({
    super.key,
    required this.storage,
    required this.analysis,
  });

  @override
  State<ImportConflictScreen> createState() => _ImportConflictScreenState();
}

class _ImportConflictScreenState extends State<ImportConflictScreen> {
  // mapped importedEx.id -> boolean (true = use local, false = overwrite with imported)
  final Map<String, bool> _useLocalChoices = {};

  @override
  void initState() {
    super.initState();
    // Default to resolving everything to KEEP LOCAL
    for (var conflict in widget.analysis.conflicts) {
      _useLocalChoices[conflict.imported.id] = true;
    }
  }

  Future<void> _execute() async {
    final scaffold = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      await widget.storage.executeImport(widget.analysis, _useLocalChoices);
      if (mounted) {
        context.read<WorkoutProvider>().reload();
        context.read<ExerciseLibraryProvider>().reload();
      }
      scaffold.showSnackBar(
        const SnackBar(content: Text('Data imported successfully!')),
      );
      // pop back twice to return to Settings/Home
      nav.pop(); 
      nav.pop();
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Error executing import: $e', style: const TextStyle(color: Colors.white)), backgroundColor: AppConstants.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resolve Conflicts', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            color: AppConstants.bgCard,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppConstants.accentGold, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We found ${widget.analysis.conflicts.length} exercises in the imported file that have the same name as your existing exercises but different tags.',
                    style: GoogleFonts.inter(fontSize: 14, color: AppConstants.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.paddingLG),
              itemCount: widget.analysis.conflicts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 24),
              itemBuilder: (ctx, i) {
                final conflict = widget.analysis.conflicts[i];
                final local = conflict.local;
                final imported = conflict.imported;

                final useLocal = _useLocalChoices[imported.id] ?? true;

                return Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMD),
                  decoration: BoxDecoration(
                    color: AppConstants.bgCard,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    border: Border.all(color: AppConstants.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        local.name,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ResolutionColumn(
                              title: 'Keep Existing',
                              isSelected: useLocal,
                              tags: local.tags,
                              compareAgainst: imported.tags,
                              onSelect: () => setState(() => _useLocalChoices[imported.id] = true),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _ResolutionColumn(
                              title: 'Use Imported',
                              isSelected: !useLocal,
                              tags: imported.tags,
                              compareAgainst: local.tags,
                              onSelect: () => setState(() => _useLocalChoices[imported.id] = false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.paddingLG),
            child: FilledButton(
              onPressed: _execute,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Complete Import',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionColumn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final List<String> tags;
  final List<String> compareAgainst;
  final VoidCallback onSelect;

  const _ResolutionColumn({
    required this.title,
    required this.isSelected,
    required this.tags,
    required this.compareAgainst,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final otherTagsLower = compareAgainst.map((e) => e.toLowerCase()).toSet();
    
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppConstants.paddingMD),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.bgSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isSelected ? AppConstants.accentPrimary : AppConstants.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (tags.isEmpty)
              Text('No tags', style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textMuted))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: tags.map((t) {
                  final isMatch = otherTagsLower.contains(t.toLowerCase());
                  final bgColor = isMatch ? AppConstants.progressDay.withValues(alpha: 0.15) : AppConstants.error.withValues(alpha: 0.15);
                  final txColor = isMatch ? AppConstants.progressDay : AppConstants.error;
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: txColor),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
