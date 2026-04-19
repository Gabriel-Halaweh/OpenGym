import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_library_provider.dart';
import '../utils/constants.dart';

class TagsManagerScreen extends StatefulWidget {
  const TagsManagerScreen({super.key});

  @override
  State<TagsManagerScreen> createState() => _TagsManagerScreenState();
}

class _TagsManagerScreenState extends State<TagsManagerScreen> {
  final _newTagController = TextEditingController();

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _newTagController.text.trim();
    if (tag.isNotEmpty) {
      context.read<ExerciseLibraryProvider>().addTag(tag);
      _newTagController.clear();
    }
  }

  void _confirmDeleteTag(String tag) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tag'),
        content: Text(
          'Are you sure you want to delete the tag "$tag"? This will also remove it from any exercises currently using it.',
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
              context.read<ExerciseLibraryProvider>().removeTag(tag);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseLibraryProvider>();
    final tags = provider.tags;
    final tagParents = provider.tagParents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Tags',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMD),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTagController,
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add new tag...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSM,
                        ),
                        borderSide: BorderSide(color: AppConstants.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusSM,
                        ),
                        borderSide: BorderSide(color: AppConstants.border),
                      ),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _addTag,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppConstants.accentPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSM,
                      ),
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tags.isEmpty
                ? Center(
                    child: Text(
                      'No tags created yet.',
                      style: GoogleFonts.inter(color: AppConstants.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: tags.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final currentParent = tagParents[tag];

                      // Available parent options: all tags except the current tag and its descendants to avoid cycles
                      final descendants = provider.getDescendantTags(tag);
                      final availableParents = tags
                          .where((t) => !descendants.contains(t))
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMD,
                          vertical: AppConstants.paddingSM,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                tag,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    'Select Parent',
                                    style: GoogleFonts.inter(
                                      color: AppConstants.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  value: currentParent,
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: null,
                                      child: Text(
                                        'None',
                                        style: GoogleFonts.inter(
                                          color: AppConstants.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    ...availableParents.map(
                                      (pTag) => DropdownMenuItem(
                                        value: pTag,
                                        child: Text(
                                          pTag,
                                          style: GoogleFonts.inter(
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (newParent) {
                                    provider.setTagParent(tag, newParent);
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: AppConstants.textMuted,
                              ),
                              onPressed: () => _confirmDeleteTag(tag),
                              tooltip: 'Delete Tag',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
