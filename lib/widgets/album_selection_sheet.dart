import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../services/media_storage_service.dart';

class AlbumSelectionSheet extends StatefulWidget {
  final List<String> allAlbums;
  final String? initialSelectedAlbum;
  final Function(String)? onCreateAlbum;

  const AlbumSelectionSheet({
    super.key,
    required this.allAlbums,
    this.initialSelectedAlbum,
    this.onCreateAlbum,
  });

  static Future<String?> show(
    BuildContext context, {
    required List<String> allAlbums,
    String? initialSelectedAlbum,
    Function(String)? onCreateAlbum,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppConstants.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: AlbumSelectionSheet(
          allAlbums: allAlbums,
          initialSelectedAlbum: initialSelectedAlbum,
          onCreateAlbum: onCreateAlbum,
        ),
      ),
    );
  }

  @override
  State<AlbumSelectionSheet> createState() => _AlbumSelectionSheetState();
}

class _AlbumSelectionSheetState extends State<AlbumSelectionSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late List<String> _currentAllAlbums;
  String? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _currentAllAlbums = List.from(widget.allAlbums);
    _selectedAlbum = widget.initialSelectedAlbum;
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

  @override
  Widget build(BuildContext context) {
    final filteredAlbums = _currentAllAlbums
        .where((a) => a.toLowerCase().contains(_searchQuery))
        .toList();

    final showCreateOption = _searchQuery.isNotEmpty &&
        !_currentAllAlbums.any((a) => a.toLowerCase() == _searchQuery);

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
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: AppConstants.textSecondary),
                ),
              ),
              const Spacer(),
              if (_selectedAlbum != null && _selectedAlbum!.isNotEmpty)
                TextButton(
                  onPressed: () => Navigator.pop(context, ""),
                  child: Text(
                    'Clear Selection',
                    style: GoogleFonts.inter(color: AppConstants.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select Default Album',
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
              hintText: 'Search or create album...',
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
              itemCount: filteredAlbums.length + (showCreateOption ? 1 : 0),
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
                    onTap: () {
                      final newAlbum = MediaStorageService.capitalizeAlbumName(_searchController.text.trim());
                      if (widget.onCreateAlbum != null) {
                        widget.onCreateAlbum!(newAlbum);
                      }
                      Navigator.pop(context, newAlbum);
                    },
                  );
                }

                final album = filteredAlbums[showCreateOption ? index - 1 : index];
                final isSelected = _selectedAlbum == album;

                return ListTile(
                  leading: Icon(
                    Icons.auto_stories_rounded,
                    color: isSelected ? AppConstants.accentPrimary : AppConstants.textMuted,
                  ),
                  title: Text(
                    album,
                    style: GoogleFonts.inter(
                      color: isSelected ? AppConstants.accentPrimary : AppConstants.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: AppConstants.accentPrimary)
                      : null,
                  onTap: () {
                    Navigator.pop(context, album);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
