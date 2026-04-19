import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'import_conflict_screen.dart';

class ImportExportScreen extends StatefulWidget {
  final StorageService storage;

  const ImportExportScreen({super.key, required this.storage});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final Map<String, bool> _selectedCategories = {};
  final Map<String, Set<String>> _selectedItems = {};

  Future<void> _exportToClipboard() async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final itemIds = _selectedItems.map((k, v) => MapEntry(k, v.toList()));
      final jsonStr = await widget.storage.exportData(
        categories: _selectedCategories,
        itemIds: itemIds,
      );
      await Clipboard.setData(ClipboardData(text: jsonStr));
      scaffold.showSnackBar(
        const SnackBar(content: Text('Selection exported to clipboard!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Error exporting: $e'), backgroundColor: AppConstants.error),
      );
    }
  }

  Future<void> _handleImport(String jsonStr) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final analysis = await widget.storage.analyzeImport(jsonStr);
      
      if (!analysis.isValid) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('Import Failed: ${analysis.errorMessage}'),
            backgroundColor: AppConstants.error,
          ),
        );
        return;
      }

      if (analysis.conflicts.isNotEmpty) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImportConflictScreen(
              storage: widget.storage,
              analysis: analysis,
            ),
          ),
        );
      } else {
        await widget.storage.executeImport(analysis, {});
        if (mounted) {
          context.read<WorkoutProvider>().reload();
          context.read<ExerciseLibraryProvider>().reload();
        }
        scaffold.showSnackBar(
          const SnackBar(content: Text('Data imported successfully!')),
        );
      }
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Error importing: $e'), backgroundColor: AppConstants.error),
      );
    }
  }

  Future<void> _importFromClipboard() async {
    final scaffold = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.isEmpty) {
      scaffold.showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
      return;
    }
    await _handleImport(data.text!);
  }

  Future<void> _exportToFile() async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      final itemIds = _selectedItems.map((k, v) => MapEntry(k, v.toList()));
      final jsonStr = await widget.storage.exportData(
        categories: _selectedCategories,
        itemIds: itemIds,
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      String? outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Select location to save backup',
        fileName: 'OpenGym_Backup.json',
        bytes: bytes,
      );

      if (outputPath == null) return; // User canceled the picker

      scaffold.showSnackBar(
        const SnackBar(content: Text('Backup saved successfully!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Error exporting to file: $e'), backgroundColor: AppConstants.error),
      );
    }
  }

  Future<void> _importFromFile() async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return; // User canceled

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();
      await _handleImport(jsonStr);
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Error importing from file: $e'), backgroundColor: AppConstants.error),
      );
    }
  }



  Widget _buildSelectionTree() {
    final exercises = context.watch<ExerciseLibraryProvider>().exercises;
    final dayTemplates = context.watch<WorkoutProvider>().dayTemplates;
    final weekTemplates = context.watch<WorkoutProvider>().weekTemplates;
    final programTemplates = context.watch<WorkoutProvider>().programTemplates;
    final scheduledPrograms = context.watch<WorkoutProvider>().scheduledPrograms;
    final scheduledWeeks = context.watch<WorkoutProvider>().scheduledWeeks;
    final scheduledDays = context.watch<WorkoutProvider>().scheduledDays;
    final measurementsGroupBy = context.watch<WorkoutProvider>().measurementTypes;
    final tags = context.watch<ExerciseLibraryProvider>().tags;
    final tagParents = context.watch<ExerciseLibraryProvider>().tagParents;
    
    final customThemesRaw = widget.storage.getCustomThemes();
    final List<Map<String, String>> customThemes = customThemesRaw.map((t) {
      final decoded = jsonDecode(t);
      return {'id': decoded['id'].toString(), 'title': decoded['name'].toString()};
    }).toList();

    // Add App Preferences as its own "whole" item in theme settings
    final themeItems = [
      {'id': 'all_prefs', 'title': 'Active App Settings & Preferences'},
      ...customThemes,
    ];

    return Column(
      children: [
        _buildCategoryTile(
          'Exercises',
          'exercises',
          exercises.map((e) => {'id': e.id, 'title': e.name}).toList(),
          Icons.fitness_center_rounded,
        ),
        _buildCategoryTile(
          'Day Templates',
          'day_templates',
          dayTemplates.map((e) => {'id': e.id, 'title': e.displayTitle}).toList(),
          Icons.calendar_view_day_rounded,
        ),
        _buildCategoryTile(
          'Week Templates',
          'week_templates',
          weekTemplates.map((e) => {'id': e.id, 'title': e.title}).toList(),
          Icons.view_week_rounded,
        ),
        _buildCategoryTile(
          'Program Templates',
          'program_templates',
          programTemplates.map((e) => {'id': e.id, 'title': e.title}).toList(),
          Icons.assignment_rounded,
        ),
        _buildCategoryTile(
          'Scheduled Programs',
          'scheduled_programs',
          scheduledPrograms.map((e) => {'id': e.id, 'title': e.title}).toList(),
          Icons.event_available_rounded,
        ),
        _buildCategoryTile(
          'Scheduled Weeks',
          'scheduled_weeks',
          scheduledWeeks.map((e) => {'id': e.id, 'title': e.title}).toList(),
          Icons.event_note_rounded,
        ),
        _buildCategoryTile(
          'Scheduled Days',
          'scheduled_days',
          scheduledDays.map((e) => {'id': e.id, 'title': e.displayTitle}).toList(),
          Icons.event_rounded,
        ),
        _buildCategoryTile(
          'Measurements',
          'measurements',
          measurementsGroupBy.map((t) => {'id': t, 'title': t.toUpperCase()}).toList(),
          Icons.straighten_rounded,
        ),
        _buildCategoryTile(
          'Tags & Hierarchy',
          'tags',
          tags.map((t) => {'id': t, 'title': t}).toList(),
          Icons.label_important_rounded,
          tagParents: tagParents,
        ),
        _buildCategoryTile(
          'Custom Themes & Settings',
          'theme',
          themeItems,
          Icons.palette_rounded,
        ),
      ],
    );
  }

  void _showSelectionDialog(String title, String key, List<Map<String, String?>> items, IconData icon, {Map<String, String>? tagParents}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DataSelectionSheet(
        title: title,
        items: items,
        icon: icon,
        initialSelectedItems: _selectedItems[key] ?? {},
        initialSelectAll: _selectedCategories[key] ?? false,
        tagParents: tagParents,
        onChanged: (selectedItems, selectAll) {
          setState(() {
            if (selectAll) {
              _selectedCategories[key] = true;
              _selectedItems.remove(key);
            } else {
              _selectedCategories[key] = false;
              if (selectedItems.isEmpty) {
                _selectedItems.remove(key);
              } else {
                _selectedItems[key] = selectedItems;
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildCategoryTile(String title, String key, List<Map<String, String?>> items, IconData icon, {Map<String, String>? tagParents}) {
    bool isAllSelected = _selectedCategories[key] ?? false;
    int selectedCount = _selectedItems[key]?.length ?? 0;
    bool hasSelection = isAllSelected || selectedCount > 0;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: hasSelection ? AppConstants.accentPrimary.withValues(alpha: 0.15) : AppConstants.bgSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: hasSelection ? AppConstants.accentPrimary : AppConstants.textMuted, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppConstants.textPrimary,
        ),
      ),
      subtitle: Text(
        isAllSelected ? (key == 'measurements' ? 'Full history selected' : 'Full category selected') : (selectedCount > 0 ? '$selectedCount items selected' : 'No items selected'),
        style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppConstants.textMuted),
      onTap: () => _showSelectionDialog(title, key, items, icon, tagParents: tagParents),
    );
  }
  void _confirmImport(VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Importing data will overwrite existing conflicting items. Do you wish to continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = _selectedCategories.values.any((v) => v) || _selectedItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Import / Export',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingLG),
        child: Column(
          children: [
            _CardWrapper(
              title: 'Select Data to Export',
              subtitle: 'Leave blank to export everything',
              icon: Icons.checklist_rtl_rounded,
              color: AppConstants.accentPrimary,
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.bgSurface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppConstants.border),
                ),
                child: _buildSelectionTree(),
              ),
            ),

            const SizedBox(height: 24),

            _CardWrapper(
              title: 'Export Actions',
              subtitle: hasSelection ? 'Export selected items' : 'Full system backup',
              icon: Icons.upload_rounded,
              color: AppConstants.accentSecondary,
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportToClipboard,
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Copy JSON to Clipboard'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _exportToFile,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Save Selection as File'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppConstants.accentSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _CardWrapper(
              title: 'Import Actions',
              subtitle: 'Import data from external sources',
              icon: Icons.download_rounded,
              color: AppConstants.accentGold,
              child: Column(
                children: [
                   OutlinedButton.icon(
                    onPressed: _importFromClipboard,
                    icon: const Icon(Icons.paste_rounded, size: 20),
                    label: const Text('Import from Clipboard'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _confirmImport(_importFromFile),
                    icon: const Icon(Icons.file_open_rounded, size: 20),
                    label: const Text('Open Backup File'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: AppConstants.accentGold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataSelectionSheet extends StatefulWidget {
  final String title;
  final List<Map<String, String?>> items;
  final IconData icon;
  final Set<String> initialSelectedItems;
  final bool initialSelectAll;
  final Map<String, String>? tagParents;
  final Function(Set<String>, bool) onChanged;

  const _DataSelectionSheet({
    required this.title,
    required this.items,
    required this.icon,
    required this.initialSelectedItems,
    required this.initialSelectAll,
    this.tagParents,
    required this.onChanged,
  });

  @override
  State<_DataSelectionSheet> createState() => _DataSelectionSheetState();
}

class _DataSelectionSheetState extends State<_DataSelectionSheet> {
  late Set<String> _selectedIds;
  late bool _selectAll;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedItems);
    _selectAll = widget.initialSelectAll;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final title = item['title']?.toLowerCase() ?? 'untitled';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppConstants.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
            child: Row(
              children: [
                Icon(widget.icon, color: AppConstants.accentPrimary, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppConstants.border),
                    ),
                    filled: true,
                    fillColor: AppConstants.bgCard,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectAll ? 'Selection: All Items' : 'Selection: Individual',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.textSecondary),
                      ),
                    ),
                    Switch(
                      value: _selectAll,
                      onChanged: (val) {
                        setState(() {
                          _selectAll = val;
                          if (val) _selectedIds.clear();
                        });
                        widget.onChanged(_selectedIds, _selectAll);
                      },
                      activeThumbColor: AppConstants.accentPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredItems.length,
              itemBuilder: (ctx, index) {
                final item = filteredItems[index];
                final id = item['id']!;
                final isSelected = _selectAll || _selectedIds.contains(id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: _selectAll
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIds.add(id);
                              if (widget.tagParents != null) {
                                String? current = widget.tagParents![id];
                                while (current != null) {
                                  _selectedIds.add(current);
                                  current = widget.tagParents![current];
                                }
                              }
                            } else {
                              _selectedIds.remove(id);
                              // UNSELECT descendants because they depend on this
                              if (widget.tagParents != null) {
                                void removeDescendants(String p) {
                                  widget.tagParents!.forEach((child, parent) {
                                    if (parent == p) {
                                      _selectedIds.remove(child);
                                      removeDescendants(child);
                                    }
                                  });
                                }
                                removeDescendants(id);
                              }
                            }
                          });
                          widget.onChanged(_selectedIds, _selectAll);
                        },
                  title: Text(
                    item['title'] ?? 'Untitled',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  activeColor: AppConstants.accentPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm Selection'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget child;

  const _CardWrapper({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
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
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
