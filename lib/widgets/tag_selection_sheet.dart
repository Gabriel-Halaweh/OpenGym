import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';

class TagSelectionSheet extends StatefulWidget {
  final List<String> allTags;
  final List<String> initialSelectedTags;
  final Map<String, String>? tagParents;
  final Future<void> Function(String)? onCreateTag;

  const TagSelectionSheet({
    super.key,
    required this.allTags,
    required this.initialSelectedTags,
    this.tagParents,
    this.onCreateTag,
  });

  static Future<List<String>?> show(
    BuildContext context, {
    required List<String> allTags,
    required List<String> initialSelectedTags,
    Map<String, String>? tagParents,
    Future<void> Function(String)? onCreateTag,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.8,
        child: TagSelectionSheet(
          allTags: allTags,
          initialSelectedTags: initialSelectedTags,
          tagParents: tagParents,
          onCreateTag: onCreateTag,
        ),
      ),
    );
  }

  @override
  State<TagSelectionSheet> createState() => _TagSelectionSheetState();
}

class _TagSelectionSheetState extends State<TagSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late List<String> _selectedTags;
  late List<String> _currentAllTags;

  @override
  void initState() {
    super.initState();
    _selectedTags = List.from(widget.initialSelectedTags);
    _currentAllTags = List.from(widget.allTags);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getAncestors(String tag) {
    final ancestors = <String>[];
    String? current = widget.tagParents?[tag];
    while (current != null) {
      if (!ancestors.contains(current)) {
        ancestors.add(current);
      } else {
        break; // break cycle just in case
      }
      current = widget.tagParents?[current];
    }
    return ancestors;
  }

  bool _hasSelectedChildren(String tag) {
    return _selectedTags.any((t) {
      return _getAncestors(t).contains(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = _currentAllTags
        .where((t) => t.toLowerCase().contains(_searchQuery))
        .toList();

    final showCreateOption =
        _searchQuery.isNotEmpty &&
        widget.onCreateTag != null &&
        !_currentAllTags.any((t) => t.toLowerCase() == _searchQuery);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppConstants.paddingLG,
        right: AppConstants.paddingLG,
        top: AppConstants.paddingLG,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppConstants.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select Tags',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            style: GoogleFonts.inter(color: AppConstants.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search or add tags...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppConstants.textMuted,
              ),
              filled: true,
              fillColor: AppConstants.bgSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTags.length + (showCreateOption ? 1 : 0),
              itemBuilder: (context, index) {
                if (showCreateOption && index == 0) {
                  return ListTile(
                    leading: Icon(
                      Icons.add_circle_rounded,
                      color: AppConstants.accentPrimary,
                    ),
                    title: Text(
                      'Create "$_searchQuery"',
                      style: GoogleFonts.inter(
                        color: AppConstants.accentPrimary,
                      ),
                    ),
                    onTap: () async {
                      final newTag = _searchController.text.trim();
                      if (widget.onCreateTag != null) {
                        await widget.onCreateTag!(newTag);
                      }
                      setState(() {
                        _currentAllTags.add(newTag);
                        _currentAllTags.sort();
                        _selectedTags.add(newTag);
                        _searchController.clear();
                      });
                    },
                  );
                }

                final tag = filteredTags[showCreateOption ? index - 1 : index];
                final isSelected = _selectedTags.contains(tag);
                final hasSelectedChildren = _hasSelectedChildren(tag);
                final isDisabled = isSelected && hasSelectedChildren;

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: isDisabled
                      ? null
                      : (val) {
                          setState(() {
                            if (val == true) {
                              _selectedTags.add(tag);
                              final ancestors = _getAncestors(tag);
                              for (final anc in ancestors) {
                                if (!_selectedTags.contains(anc)) {
                                  _selectedTags.add(anc);
                                }
                              }
                            } else {
                              // Unchecking is safe since it's not disabled
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                  title: Text(
                    tag,
                    style: GoogleFonts.inter(
                      color: isDisabled
                          ? AppConstants.textMuted
                          : AppConstants.textPrimary,
                      fontStyle: isDisabled
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                  activeColor: isDisabled
                      ? AppConstants.textMuted
                      : AppConstants.accentPrimary,
                  checkColor: Colors.white,
                  side: BorderSide(color: AppConstants.textMuted),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.paddingMD,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _selectedTags),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
