import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'camera_view_page.dart';
import 'media_view_page.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';
import '../widgets/media_calendar_picker.dart';
import '../widgets/video_thumbnail_player.dart';
import '../services/media_storage_service.dart';
import '../models/media_item.dart';
import 'gallery_picker_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart';

// ============================================================
// Shared helpers for all mockups
// ============================================================

final _dummyPoses = [
  'Front Relaxed',
  'Back Relaxed',
  'Side Left',
  'Side Right',
  'Front Double Biceps',
  'Back Double Biceps',
  'Side Chest',
  'Most Muscular',
];

final _dummyExercises = [
  'Squat',
  'Bench Press',
  'Deadlift',
  'Overhead Press',
  'Barbell Row',
];

final _dummyDates = [
  'Mar 1, 2026',
  'Feb 15, 2026',
  'Feb 1, 2026',
  'Jan 15, 2026',
  'Jan 1, 2026',
  'Dec 15, 2025',
];

Widget _placeholderTile({
  double width = 100,
  double height = 100,
  String? label,
  IconData icon = Icons.image_rounded,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppConstants.bgElevated,
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
      border: Border.all(color: AppConstants.border),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppConstants.textMuted.withValues(alpha: 0.4),
          size: 28,
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppConstants.textMuted,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}

Widget _mockFab(BuildContext context) {
  return FloatingActionButton(
    backgroundColor: AppConstants.accentPrimary,
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraViewPage()),
      );
    },
    child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
  );
}

void _showToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppConstants.bgElevated,
    ),
  );
}

Widget _mockActionBar(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        _chipButton(context, Icons.compare_rounded, 'Compare'),
        const SizedBox(width: 8),
        _chipButton(context, Icons.timelapse_rounded, 'Time-lapse'),
        const SizedBox(width: 8),
        _chipButton(context, Icons.person_outline_rounded, 'Onion Skin'),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.search_rounded, color: AppConstants.textSecondary),
          onPressed: () => _showToast(context, 'Search'),
        ),
      ],
    ),
  );
}

Widget _chipButton(BuildContext context, IconData icon, String label) {
  return ActionChip(
    avatar: Icon(icon, size: 16, color: AppConstants.accentPrimary),
    label: Text(
      label,
      style: GoogleFonts.inter(fontSize: 12, color: AppConstants.textPrimary),
    ),
    backgroundColor: AppConstants.bgElevated,
    side: BorderSide(color: AppConstants.border),
    onPressed: () => _showToast(context, '$label view'),
  );
}

// ============================================================
// MOCKUP 1: Instagram-Style Grid with Dropdown Filter
// ============================================================

class MockupOneScreen extends StatefulWidget {
  const MockupOneScreen({super.key});
  @override
  State<MockupOneScreen> createState() => _MockupOneState();
}

class _MockupOneState extends State<MockupOneScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final categories = ['All', 'Physique', 'Exercises'];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layout 1: Instagram Grid',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showToast(context, 'Filter options'),
          ),
        ],
      ),
      floatingActionButton: _mockFab(context),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = categories[i] == _selectedCategory;
                return ChoiceChip(
                  label: Text(
                    categories[i],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : AppConstants.textPrimary,
                    ),
                  ),
                  selected: selected,
                  selectedColor: AppConstants.accentPrimary,
                  backgroundColor: AppConstants.bgElevated,
                  side: BorderSide(
                    color: selected
                        ? AppConstants.accentPrimary
                        : AppConstants.border,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = categories[i]),
                );
              },
            ),
          ),

          // Pose/Exercise sub-filter
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dummyPoses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0
                        ? AppConstants.accentPrimary.withValues(alpha: 0.15)
                        : AppConstants.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: i == 0
                          ? AppConstants.accentPrimary
                          : AppConstants.border,
                    ),
                  ),
                  child: Text(
                    _dummyPoses[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: i == 0
                          ? AppConstants.accentPrimary
                          : AppConstants.textSecondary,
                      fontWeight: i == 0 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Action bar
          _mockActionBar(context),

          // Photo grid
          Expanded(
            child: FutureBuilder<List<MediaItem>>(
              future: context.read<MediaStorageService>().getAllMedia(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                // Very basic filtering (just for show)
                final filteredItems = _selectedCategory == 'All'
                    ? items
                    : items
                          .where(
                            (i) =>
                                i.albumName.contains(_selectedCategory) ||
                                _dummyPoses.contains(i.albumName),
                          )
                          .toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      'No media found',
                      style: GoogleFonts.inter(color: AppConstants.textMuted),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, i) {
                    final item = filteredItems[i];
                    final isVideo = item.mediaType == 'video';

                    return GestureDetector(
                      onTap: () =>
                          _showToast(context, 'View media ${item.fileName}'),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppConstants.bgElevated,
                          border: Border.all(
                            color: AppConstants.border,
                            width: 0.5,
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Show real image for both photos and videos (assuming we have thumbnails or just file for videos, though videos won't render directly in Image.file easily without a plugin. For now we will just use the file, which usually fails for MP4. So we fallback to an icon if it's a video)
                            if (isVideo)
                              Center(
                                child: Icon(
                                  Icons.videocam_rounded,
                                  color: AppConstants.textMuted.withValues(
                                    alpha: 0.3,
                                  ),
                                  size: 32,
                                ),
                              )
                            else
                              Image.file(
                                File(item.filePath),
                                fit: BoxFit.cover,
                                cacheWidth: 250, // Optimize memory for grid
                              ),

                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.dateTaken.month}/${item.dateTaken.day}/${item.dateTaken.year}',
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (isVideo)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 18,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOCKUP 2: Netflix-Style Horizontal Rows
// ============================================================

class MockupTwoScreen extends StatelessWidget {
  const MockupTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layout 2: Netflix Scroll',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      floatingActionButton: _mockFab(context),
      body: ListView(
        children: [
          // Quick actions
          _mockActionBar(context),
          const SizedBox(height: 8),

          // Recent section
          _sectionHeader(context, 'Recent'),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 8,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _showToast(context, 'View recent $i'),
                child: _placeholderTile(
                  width: 100,
                  height: 140,
                  label: _dummyDates[i % _dummyDates.length],
                  icon: i % 3 == 0
                      ? Icons.videocam_rounded
                      : Icons.image_rounded,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pose rows
          ..._dummyPoses.take(5).map((pose) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(context, pose),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _showToast(context, '$pose photo $i'),
                      child: _placeholderTile(
                        width: 90,
                        height: 120,
                        label: _dummyDates[i % _dummyDates.length],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),

          // Exercise rows
          _sectionHeader(
            context,
            'Exercise Form Videos',
            icon: Icons.fitness_center_rounded,
          ),
          ..._dummyExercises.take(3).map((ex) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 4),
                  child: Text(
                    ex,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _showToast(context, '$ex video $i'),
                      child: _placeholderTile(
                        width: 130,
                        height: 100,
                        label: _dummyDates[i % _dummyDates.length],
                        icon: Icons.videocam_rounded,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static Widget _sectionHeader(
    BuildContext context,
    String title, {
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppConstants.accentPrimary),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AlbumDetailScreen(albumName: title),
              ),
            ),
            child: Text(
              'See all',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppConstants.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOCKUP 3: Album Folders
// ============================================================

class MockupThreeScreen extends StatelessWidget {
  const MockupThreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final allAlbums = [
      ..._dummyPoses.map(
        (p) => _AlbumInfo(
          p,
          Icons.person_rounded,
          '${(p.hashCode % 12).abs() + 1} photos',
        ),
      ),
      ..._dummyExercises.map(
        (e) => _AlbumInfo(
          e,
          Icons.fitness_center_rounded,
          '${(e.hashCode % 8).abs() + 1} videos',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layout 3: Album Folders',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_rounded),
            onPressed: () => _showToast(context, 'Create new album'),
          ),
        ],
      ),
      floatingActionButton: _mockFab(context),
      body: Column(
        children: [
          _mockActionBar(context),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: allAlbums.length,
              itemBuilder: (context, i) {
                final album = allAlbums[i];
                return GestureDetector(
                  onTap: () => _showToast(context, 'Open album: ${album.name}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppConstants.bgCard,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusLG,
                      ),
                      border: Border.all(color: AppConstants.border),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppConstants.bgElevated,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.radiusLG),
                              ),
                            ),
                            child: Icon(
                              album.icon,
                              size: 48,
                              color: AppConstants.textMuted.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                album.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                album.count,
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

class _AlbumInfo {
  final String name;
  final IconData icon;
  final String count;
  const _AlbumInfo(this.name, this.icon, this.count);
}

// ============================================================
// MOCKUP 4: Calendar Journal
// ============================================================

class MockupFourScreen extends StatefulWidget {
  const MockupFourScreen({super.key});
  @override
  State<MockupFourScreen> createState() => _MockupFourState();
}

class _MockupFourState extends State<MockupFourScreen> {
  int _selectedDayIndex = 3; // mock "today"

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final days = List.generate(31, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Layout 4: Calendar Journal',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      floatingActionButton: _mockFab(context),
      body: Column(
        children: [
          // Month header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _showToast(context, 'Previous month'),
                ),
                Expanded(
                  child: Text(
                    'March 2026',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => _showToast(context, 'Next month'),
                ),
              ],
            ),
          ),

          // Day selector strip
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final selected = i == _selectedDayIndex;
                final hasMedia = i % 3 == 0 || i % 5 == 0;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    width: 42,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppConstants.accentPrimary
                          : AppConstants.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppConstants.accentPrimary
                            : AppConstants.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${days[i]}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppConstants.textPrimary,
                          ),
                        ),
                        if (hasMedia)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppConstants.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // action bar
          _mockActionBar(context),

          // Day's media
          Expanded(
            child: _selectedDayIndex % 3 == 0 || _selectedDayIndex % 5 == 0
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Pose photos for this day
                      Text(
                        'Physique Check-In',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 3,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            return GestureDetector(
                              onTap: () =>
                                  _showToast(context, 'View pose photo'),
                              child: _placeholderTile(
                                width: 110,
                                height: 160,
                                label: _dummyPoses[i],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Exercise Videos',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(2, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GestureDetector(
                            onTap: () => _showToast(context, 'Play video'),
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppConstants.bgCard,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD,
                                ),
                                border: Border.all(color: AppConstants.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: AppConstants.bgElevated,
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                            left: Radius.circular(
                                              AppConstants.radiusMD,
                                            ),
                                          ),
                                    ),
                                    child: Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: AppConstants.textMuted.withValues(
                                        alpha: 0.4,
                                      ),
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _dummyExercises[i],
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '0:45',
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
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_rounded,
                          size: 48,
                          color: AppConstants.textMuted.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No media for this day',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppConstants.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              _showToast(context, 'Camera would open'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Add Entry',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MOCKUP 5: Comparison-Focused Layout
// ============================================================

class MockupFiveScreen extends StatefulWidget {
  const MockupFiveScreen({super.key});
  @override
  State<MockupFiveScreen> createState() => _MockupFiveState();
}

class _MockupFiveState extends State<MockupFiveScreen> with SingleTickerProviderStateMixin {
  double _sliderValue = 0.5;
  String _selectedAlbum = 'Front Relaxed';
  String _selectedTool = 'Side by Side';
  DateTime? _timelapseStart;
  DateTime _timelapseEnd = DateTime.now();
  double _timelapsePosition = 0.0;

  MediaItem? _beforeItem;
  MediaItem? _afterItem;

  // Real timeline items loaded from sandbox
  List<MediaItem> _timelineItems = [];
  bool _isLoading = true;
  List<AlbumInfo> _albums = [];
  bool _isDraggingTimelineItem = false;

  late AnimationController _playController;
  bool _isPlaying = false;
  int _playDirection = 0; // 0: stopped, 1: forward, -1: reverse
  double _playSpeed = 1.0;

  void _cycleSpeed() {
    setState(() {
      if (_playSpeed == 0.25) {
        _playSpeed = 0.5;
      } else if (_playSpeed == 0.5) {
        _playSpeed = 1.0;
      } else if (_playSpeed == 1.0) {
        _playSpeed = 2.0;
      } else if (_playSpeed == 2.0) {
        _playSpeed = 4.0;
      } else {
        _playSpeed = 0.25;
      }

      if (_isPlaying) {
        // Hot-swap duration while playing
        final photos = _getFilteredPhotos();
        if (photos.length >= 2) {
          _playController.duration = Duration(milliseconds: (photos.length * (450 / _playSpeed)).toInt());
          // Resume in current direction
          if (_playDirection == 1) {
            _playController.forward(from: _playController.value);
          } else {
            _playController.reverse(from: _playController.value);
          }
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _playController = AnimationController(vsync: this);
    _playController.addListener(() {
      if (_isPlaying && mounted) {
        setState(() {
          _timelapsePosition = _playController.value;
        });
      }
    });

    _playController.addStatusListener((status) {
      if (_isPlaying && mounted) {
        if (status == AnimationStatus.completed) {
          _playController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _playController.forward();
        }
      }
    });

    // Load initial data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _playController.dispose();
    super.dispose();
  }

  List<MediaItem> _getFilteredPhotos() {
    final filtered = _timelineItems.where((i) {
      if (i.mediaType != 'photo') return false;
      if (_timelapseStart == null) return true;
      final date = DateTime(i.dateTaken.year, i.dateTaken.month, i.dateTaken.day);
      final start = DateTime(_timelapseStart!.year, _timelapseStart!.month, _timelapseStart!.day);
      final end = DateTime(_timelapseEnd.year, _timelapseEnd.month, _timelapseEnd.day);
      return date.compareTo(start) >= 0 && date.compareTo(end) <= 0;
    }).toList();
    filtered.sort((a, b) => a.dateTaken.compareTo(b.dateTaken));
    return filtered;
  }

  void _togglePlay({bool reverse = false}) {
    final photos = _getFilteredPhotos();
    if (photos.length < 2) {
      if (_isPlaying) {
        setState(() {
          _isPlaying = false;
          _playDirection = 0;
          _playController.stop();
        });
      }
      return;
    }

    final targetDir = reverse ? -1 : 1;

    setState(() {
      if (_isPlaying && _playDirection == targetDir) {
        _isPlaying = false;
        _playDirection = 0;
        _playController.stop();
      } else {
        _isPlaying = true;
        _playDirection = targetDir;
        final msPerFrame = 450 / _playSpeed;
        _playController.duration = Duration(milliseconds: (photos.length * msPerFrame).toInt());
        _playController.value = _timelapsePosition;
        if (reverse) {
          _playController.reverse();
        } else {
          _playController.forward();
        }
      }
    });
  }

  Future<void> _loadData() async {
    final storage = context.read<MediaStorageService>();
    final allAlbums = await storage.getAlbums();
    final albums = allAlbums.where((a) => a.itemCount > 0).toList();

    setState(() {
      _albums = albums;
      if (albums.isNotEmpty && !albums.any((a) => a.name == _selectedAlbum)) {
        _selectedAlbum = albums.first.name;
      }
    });

    await _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    setState(() => _isLoading = true);
    final storage = context.read<MediaStorageService>();
    final items = await storage.getMediaForAlbum(_selectedAlbum);
    setState(() {
      _timelineItems = items;
      _isLoading = false;

      // Initialize start and end dates to oldest photo and today if not set
      if (_timelineItems.isNotEmpty && _timelapseStart == null) {
        final sorted = List<MediaItem>.from(_timelineItems)
          ..sort((a, b) => a.dateTaken.compareTo(b.dateTaken));
        _timelapseStart = sorted.first.dateTaken;
        _timelapseEnd = DateTime.now();
      } else if (_timelapseStart == null) {
        _timelapseStart = DateTime.now().subtract(const Duration(days: 30));
        _timelapseEnd = DateTime.now();
      }

      // Clear before/after if we switch albums
      _beforeItem = null;
      _afterItem = null;
    });
  }

  int get _timelapseFrameCount {
    if (_timelapseStart == null) return 2;
    final days = _timelapseEnd.difference(_timelapseStart!).inDays;
    return (days / 14).clamp(2, 20).toInt();
  }

  int get _currentFrame =>
      (_timelapsePosition * (_timelapseFrameCount - 1)).round();
  String get _currentFrameDate {
    if (_timelapseStart == null) return '';
    final days = _timelapseEnd.difference(_timelapseStart!).inDays;
    final offset = (_timelapsePosition * days).round();
    final d = _timelapseStart!.add(Duration(days: offset));
    return '${d.month}/${d.day}/${d.year}';
  }

  String _slotForItem(MediaItem item) {
    if (_beforeItem?.filePath == item.filePath) return 'before';
    if (_afterItem?.filePath == item.filePath) return 'after';
    return '';
  }

  static const _beforeColor = Color(0xFF2196F3);
  static const _afterColor = Color(0xFFFF9800);

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final isTimelapse = _selectedTool == 'Time-lapse';
    final isCompare = !isTimelapse;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compare',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Album selector "Drop-down" (Now a searchable picker)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: InkWell(
                  onTap: () => _showAlbumSearchPicker(context),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.bgCard,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      border: Border.all(color: AppConstants.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_rounded,
                          color: AppConstants.accentPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedAlbum,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.search_rounded,
                          color: AppConstants.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.expand_more_rounded,
                          color: AppConstants.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Time-lapse date pickers
              if (_timelapseStart != null) _buildTimelapseDateBar(),

              // Comparison panel (Side by Side / Onion Skin)
              if (isCompare) _buildComparisonPanel(context),

              // Time-lapse panel
              if (isTimelapse) _buildTimelapsePanel(),

              // Onion skin slider / Scrub bar
              if (isCompare) _buildSlider(),

              // Timeline carousel with drag support
              if (isCompare) ...[
                Builder(
                  builder: (context) {
                    final filtered = _timelineItems.where((i) {
                      if (_timelapseStart == null) return true;
                      final date = DateTime(
                        i.dateTaken.year,
                        i.dateTaken.month,
                        i.dateTaken.day,
                      );
                      final start = DateTime(
                        _timelapseStart!.year,
                        _timelapseStart!.month,
                        _timelapseStart!.day,
                      );
                      final end = DateTime(
                        _timelapseEnd.year,
                        _timelapseEnd.month,
                        _timelapseEnd.day,
                      );
                      return date.compareTo(start) >= 0 &&
                          date.compareTo(end) <= 0;
                    }).toList();

                    final photos = filtered
                        .where((i) => i.mediaType == 'photo')
                        .toList();
                    final videos = filtered
                        .where((i) => i.mediaType == 'video')
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (photos.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 4,
                              bottom: 6,
                              right: 16,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Photos',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '• hold and drag an image to assign it',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppConstants.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 105,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: photos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) =>
                                  _buildDraggableTimelineItem(
                                    context,
                                    photos[i],
                                  ),
                            ),
                          ),
                        ],
                        if (videos.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              top: 12,
                              bottom: 6,
                            ),
                            child: Text(
                              'Videos',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 105,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: videos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) =>
                                  _buildDraggableTimelineItem(
                                    context,
                                    videos[i],
                                  ),
                            ),
                          ),
                        ],
                        if (filtered.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                'No media found for the selected dates.',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 120),
            ],
          ),

          // Floating Tool Selector "Snackbar"
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.paddingOf(context).bottom + 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppConstants.bgCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppConstants.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _toolCard(
                      context,
                      Icons.compare_rounded,
                      'Side by Side',
                    ),
                  ),
                  Expanded(
                    child: _toolCard(
                      context,
                      Icons.layers_rounded,
                      'Onion Skin',
                    ),
                  ),
                  Expanded(
                    child: _toolCard(
                      context,
                      Icons.timelapse_rounded,
                      'Time-lapse',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlbumSearchPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Align(
        alignment: const Alignment(0, -0.7), // Positioned high up
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _AlbumSearchPicker(
            albums: _albums,
            initialAlbum: _selectedAlbum,
            onSelected: (album) {
              setState(() {
                _selectedAlbum = album;
                _loadTimeline();
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppConstants.textMuted),
        ),
      ],
    );
  }

  Widget _buildDraggableTimelineItem(BuildContext context, MediaItem item) {
    final slot = _slotForItem(item);
    final borderColor = slot == 'before'
        ? _beforeColor
        : slot == 'after'
        ? _afterColor
        : AppConstants.border;
    final borderWidth = slot.isNotEmpty ? 2.5 : 1.0;

    return LongPressDraggable<MediaItem>(
      data: item,
      delay: const Duration(milliseconds: 300),
      onDragStarted: () => setState(() => _isDraggingTimelineItem = true),
      onDragEnd: (_) => setState(() => _isDraggingTimelineItem = false),
      onDraggableCanceled: (_, __) =>
          setState(() => _isDraggingTimelineItem = false),
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppConstants.bgElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppConstants.accentPrimary, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.mediaType == 'video'
                ? VideoThumbnailPlayer(filePath: item.filePath)
                : Image.file(
                    File(item.filePath),
                    fit: BoxFit.cover,
                    cacheWidth: 150,
                  ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _timelineTileContent(item, borderColor, borderWidth),
      ),
      child: _timelineTileContent(item, borderColor, borderWidth),
    );
  }

  Widget _renderMedia(
    MediaItem item, {
    BoxFit fit = BoxFit.cover,
    double opacity = 1.0,
  }) {
    final content = item.mediaType == 'video'
        ? VideoThumbnailPlayer(filePath: item.filePath)
        : Image.file(
            File(item.filePath),
            fit: fit,
            cacheWidth: 1000, // Premium resolution for comparison
            gaplessPlayback: true,
          );

    if (opacity < 1.0) {
      return Opacity(opacity: opacity, child: content);
    }
    return content;
  }

  Widget _timelineTileContent(
    MediaItem item,
    Color borderColor,
    double borderWidth,
  ) {
    final slot = _slotForItem(item);
    final isVideo = item.mediaType == 'video';

    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppConstants.bgElevated,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusMD - 1),
                child: isVideo
                    ? VideoThumbnailPlayer(filePath: item.filePath)
                    : Image.file(
                        File(item.filePath),
                        fit: BoxFit.cover,
                        cacheWidth: 140,
                      ),
              ),
              if (isVideo)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${item.dateTaken.month}/${item.dateTaken.day}/${item.dateTaken.year % 100}',
          style: GoogleFonts.inter(fontSize: 10, color: AppConstants.textMuted),
        ),
      ],
    );
  }

  Widget _buildComparisonPanel(BuildContext context) {
    final showSplit =
        _selectedTool == 'Side by Side' || _isDraggingTimelineItem;
    final overrideSliderValue = _isDraggingTimelineItem ? 0.5 : _sliderValue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 320,
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppConstants.border),
      ),
      child: Stack(
        children: [
          // 1. Comparison Output
          if (_beforeItem != null && _afterItem != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base image (Always after for Side by Side/Split, before for Onion Skin)
                    if (showSplit)
                      _renderMedia(_afterItem!)
                    else
                      _renderMedia(_beforeItem!),

                    // Top overlay
                    if (showSplit)
                      ClipRect(
                        clipper: _SplitClipper(overrideSliderValue),
                        child: _renderMedia(_beforeItem!),
                      )
                    else if (_selectedTool == 'Onion Skin')
                      _renderMedia(_afterItem!, opacity: _sliderValue),
                  ],
                ),
              ),
            )
          else ...[
            if (_beforeItem != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: MediaQuery.of(context).size.width / 2 - 16,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppConstants.radiusLG),
                  ),
                  child: _renderMedia(_beforeItem!),
                ),
              ),
            if (_afterItem != null)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                left: MediaQuery.of(context).size.width / 2 - 16,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppConstants.radiusLG),
                  ),
                  child: _renderMedia(_afterItem!),
                ),
              ),
          ],

          // 2. Drop Targets (Rendered ON TOP of the images so they catch drops)
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: DragTarget<MediaItem>(
                    onAcceptWithDetails: (details) =>
                        setState(() => _beforeItem = details.data),
                    builder: (context, candidates, _) => GestureDetector(
                      onTap: _beforeItem == null
                          ? () => _openImageChooser(context, 'Before')
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: candidates.isNotEmpty
                              ? _beforeColor.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(AppConstants.radiusLG),
                          ),
                          border: candidates.isNotEmpty
                              ? Border.all(color: _beforeColor, width: 2)
                              : (_isDraggingTimelineItem
                                    ? Border.all(
                                        color: AppConstants.bgCard.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      )
                                    : null),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_beforeItem == null) ...[
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: AppConstants.accentPrimary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Before',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _beforeColor,
                                ),
                              ),
                              Text(
                                'Hold and drag',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // After drop target
                Expanded(
                  child: DragTarget<MediaItem>(
                    onAcceptWithDetails: (details) =>
                        setState(() => _afterItem = details.data),
                    builder: (context, candidates, _) => GestureDetector(
                      onTap: _afterItem == null
                          ? () => _openImageChooser(context, 'After')
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: candidates.isNotEmpty
                              ? _afterColor.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(AppConstants.radiusLG),
                          ),
                          border: candidates.isNotEmpty
                              ? Border.all(color: _afterColor, width: 2)
                              : (_isDraggingTimelineItem
                                    ? Border.all(
                                        color: AppConstants.bgCard.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1,
                                      )
                                    : null),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_afterItem == null) ...[
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 40,
                                color: AppConstants.accentPrimary.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'After',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _afterColor,
                                ),
                              ),
                              Text(
                                'Hold and drag',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scrubber Line
          if (showSplit && _beforeItem != null && _afterItem != null)
            Positioned(
              left:
                  (MediaQuery.of(context).size.width - 32) *
                      overrideSliderValue -
                  1,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: AppConstants.accentPrimary),
            ),

          // 4. Clear Buttons
          if (_beforeItem != null)
            Positioned(
              top: 4,
              left: 4,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _beforeItem = null),
              ),
            ),
          if (_afterItem != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.red),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _afterItem = null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Before',
            style: GoogleFonts.inter(fontSize: 12, color: _beforeColor),
          ),
          Expanded(
            child: Slider(
              value: _sliderValue,
              onChanged: (v) => setState(() => _sliderValue = v),
              activeColor: AppConstants.accentPrimary,
              inactiveColor: AppConstants.border,
            ),
          ),
          Text(
            'After',
            style: GoogleFonts.inter(fontSize: 12, color: _afterColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelapseDateBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(color: AppConstants.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final allPhotos = await context
                      .read<MediaStorageService>()
                      .getAllMedia();
                  if (!mounted) return;
                  final r =
                      await MediaCalendarPicker.showRangePickerWithInitialSelector(
                        context,
                        allPhotos,
                        'start',
                        initialRange: DateTimeRange(
                          start:
                              _timelapseStart ??
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: _timelapseEnd,
                        ),
                      );
                  if (r != null) {
                    setState(() {
                      _timelapseStart = r.start;
                      _timelapseEnd = r.end;
                    });
                  }
                },
                child: Column(
                  children: [
                    Text(
                      'Start',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppConstants.accentPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _timelapseStart != null
                              ? '${_timelapseStart!.month}/${_timelapseStart!.day}/${_timelapseStart!.year}'
                              : '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 30, color: AppConstants.border),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final allPhotos = await context
                      .read<MediaStorageService>()
                      .getAllMedia();
                  if (!mounted) return;
                  final r =
                      await MediaCalendarPicker.showRangePickerWithInitialSelector(
                        context,
                        allPhotos,
                        'end',
                        initialRange: DateTimeRange(
                          start:
                              _timelapseStart ??
                              DateTime.now().subtract(const Duration(days: 30)),
                          end: _timelapseEnd,
                        ),
                      );
                  if (r != null) {
                    setState(() {
                      _timelapseStart = r.start;
                      _timelapseEnd = r.end;
                    });
                  }
                },
                child: Column(
                  children: [
                    Text(
                      'End',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: AppConstants.accentPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_timelapseEnd.month}/${_timelapseEnd.day}/${_timelapseEnd.year}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelapsePanel() {
    final photos = _getFilteredPhotos();
    final hasPhotos = photos.isNotEmpty;
    final maxIndex = hasPhotos ? photos.length - 1 : 0;
    final currentIndex = hasPhotos
        ? (_timelapsePosition * maxIndex).round().clamp(0, maxIndex)
        : 0;

    final currentItemDate = hasPhotos
        ? '${photos[currentIndex].dateTaken.month}/${photos[currentIndex].dateTaken.day}/${photos[currentIndex].dateTaken.year}'
        : _currentFrameDate;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 320,
          decoration: BoxDecoration(
            color: AppConstants.bgCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(color: AppConstants.border),
          ),
          child: Stack(
            children: [
              if (!hasPhotos)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: AppConstants.textMuted.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No photos found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                    child: Image.file(
                      File(photos[currentIndex].filePath),
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                      gaplessPlayback: true,
                    ),
                  ),
                ),

              if (hasPhotos) ...[
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Text(
                      'Frame ${currentIndex + 1} / ${photos.length} • $currentItemDate',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  if (hasPhotos)
                    Text(
                      '${photos.first.dateTaken.month}/${photos.first.dateTaken.day}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    )
                  else
                    Text(
                      _timelapseStart != null
                          ? '${_timelapseStart!.month}/${_timelapseStart!.day}'
                          : '',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                  Expanded(
                    child: Slider(
                      value: _timelapsePosition,
                      onChanged: (v) {
                        if (_isPlaying) _togglePlay(reverse: _playDirection == -1);
                        setState(() => _timelapsePosition = v);
                      },
                      activeColor: AppConstants.accentPrimary,
                      inactiveColor: AppConstants.border,
                    ),
                  ),
                  if (hasPhotos)
                    Text(
                      '${photos.last.dateTaken.month}/${photos.last.dateTaken.day}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    )
                  else
                    Text(
                      '${_timelapseEnd.month}/${_timelapseEnd.day}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppConstants.textMuted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reverse play button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Transform.scale(
                      scaleX: -1,
                      child: Icon(
                        (_isPlaying && _playDirection == -1)
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        size: 40,
                        color: AppConstants.accentPrimary,
                      ),
                    ),
                    onPressed: () => _togglePlay(reverse: true),
                  ),
                  const SizedBox(width: 24),
                  // Speed Control
                  GestureDetector(
                    onTap: _cycleSpeed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppConstants.accentPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppConstants.accentPrimary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _playSpeed < 1 ? '${_playSpeed}x' : '${_playSpeed.toInt()}x',
                        style: GoogleFonts.inter(
                          color: AppConstants.accentPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Forward play button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      (_isPlaying && _playDirection == 1)
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      size: 40,
                      color: AppConstants.accentPrimary,
                    ),
                    onPressed: () => _togglePlay(reverse: false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolCard(BuildContext context, IconData icon, String label) {
    final sel = _selectedTool == label;
    return GestureDetector(
      onTap: () {
        if (_isPlaying) _togglePlay(reverse: _playDirection == -1);
        setState(() => _selectedTool = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppConstants.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: sel ? Colors.white : AppConstants.textMuted,
              size: 18,
            ),
            const SizedBox(height: 2),
            Text(
              label == 'Side by Side' ? 'Side/Side' : label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                color: sel ? Colors.white : AppConstants.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _openImageChooser(BuildContext context, String slot) async {
    final result = await Navigator.push<MediaItem>(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageChooserScreen(
          slot: slot,
          beforeItem: _beforeItem,
          afterItem: _afterItem,
          timelineItems: _timelineItems,
        ),
      ),
    );
    if (result != null) {
      setState(() {
        if (slot == 'Before') {
          _beforeItem = result;
        } else {
          _afterItem = result;
        }
      });
    }
  }
}

// ============================================================
// Image Chooser Page (opened when tapping Before or After panel)
// ============================================================

class _ImageChooserScreen extends StatefulWidget {
  final String slot;
  final MediaItem? beforeItem;
  final MediaItem? afterItem;
  final List<MediaItem> timelineItems;
  const _ImageChooserScreen({
    required this.slot,
    this.beforeItem,
    this.afterItem,
    this.timelineItems = const [],
  });

  @override
  State<_ImageChooserScreen> createState() => _ImageChooserScreenState();
}

class _ImageChooserScreenState extends State<_ImageChooserScreen> {
  bool _isAlbumMode = true;

  static const _beforeColor = Color(0xFF2196F3);
  static const _afterColor = Color(0xFFFF9800);

  String _slotForItem(MediaItem item) {
    if (widget.beforeItem?.filePath == item.filePath) return 'before';
    if (widget.afterItem?.filePath == item.filePath) return 'after';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select ${widget.slot} Image',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Column(
        children: [
          // Photo / Album toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppConstants.bgCard,
                borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                border: Border.all(color: AppConstants.border),
              ),
              child: Row(
                children: [
                  _toggleTab(
                    'Photos',
                    Icons.photo_library_rounded,
                    !_isAlbumMode,
                    () => setState(() => _isAlbumMode = false),
                  ),
                  _toggleTab(
                    'Albums',
                    Icons.folder_rounded,
                    _isAlbumMode,
                    () => setState(() => _isAlbumMode = true),
                  ),
                ],
              ),
            ),
          ),

          // Recently Compared carousel with highlights
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  size: 16,
                  color: AppConstants.accentPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Recently Compared',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.timelineItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = widget.timelineItems[i];
                final slot = _slotForItem(item);
                final borderColor = slot == 'before'
                    ? _beforeColor
                    : slot == 'after'
                    ? _afterColor
                    : AppConstants.accentPrimary.withValues(alpha: 0.3);
                final borderWidth = slot.isNotEmpty ? 2.5 : 1.0;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, item),
                  child: Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppConstants.bgElevated,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMD - 1,
                          ),
                          child: item.mediaType == 'video'
                              ? VideoThumbnailPlayer(item: item)
                              : Image.file(
                                  File(item.filePath),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 24),

          // Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isAlbumMode
                  ? _buildAlbumGrid(context)
                  : _buildPhotoRows(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTab(
    String label,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppConstants.accentPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusMD - 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppConstants.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppConstants.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoRows(BuildContext context) {
    return FutureBuilder<List<AlbumInfo>>(
      future: context.read<MediaStorageService>().getAlbums(),
      builder: (context, albumsSnapshot) {
        if (albumsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allAlbums = albumsSnapshot.data ?? [];
        final albums = allAlbums.where((a) => a.itemCount > 0).toList();
        if (albums.isEmpty) return const Center(child: Text('No albums found'));

        return FutureBuilder<List<List<MediaItem>>>(
          future: Future.wait(
            albums.map(
              (a) =>
                  context.read<MediaStorageService>().getMediaForAlbum(a.name),
            ),
          ),
          builder: (context, mediaSnapshot) {
            if (mediaSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final mediaLists = mediaSnapshot.data ?? [];

            return ListView.builder(
              key: const ValueKey('photo-rows'),
              itemCount: albums.length,
              itemBuilder: (context, albumIndex) {
                final album = albums[albumIndex];
                final mediaItems = mediaLists[albumIndex];
                if (mediaItems.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: Text(
                        album.name,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: mediaItems.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final item = mediaItems[i];
                          final slot = _slotForItem(item);
                          final borderColor = slot == 'before'
                              ? _beforeColor
                              : slot == 'after'
                              ? _afterColor
                              : AppConstants.border;
                          final borderWidth = slot.isNotEmpty ? 2.5 : 1.0;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              width: 75,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppConstants.bgElevated,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMD,
                                ),
                                border: Border.all(
                                  color: borderColor,
                                  width: borderWidth,
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radiusMD - 1,
                                    ),
                                    child: item.mediaType == 'video'
                                        ? VideoThumbnailPlayer(item: item)
                                        : Image.file(
                                            File(item.filePath),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumGrid(BuildContext context) {
    return FutureBuilder<List<AlbumInfo>>(
      future: context.read<MediaStorageService>().getAlbums(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allAlbums = snapshot.data ?? [];
        final albums = allAlbums.where((a) => a.itemCount > 0).toList();
        if (albums.isEmpty) return const Center(child: Text('No albums found'));

        return GridView.builder(
          key: const ValueKey('album-grid'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: albums.length,
          itemBuilder: (context, i) {
            final album = albums[i];
            return GestureDetector(
              onTap: () async {
                final selected = await Navigator.push<MediaItem>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(
                      albumName: album.name,
                      isPicker: true,
                    ),
                  ),
                );
                if (selected != null && context.mounted) {
                  Navigator.pop(context, selected);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.bgCard,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  border: Border.all(color: AppConstants.border),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: FutureBuilder<List<MediaItem>>(
                        future: context
                            .read<MediaStorageService>()
                            .getMediaForAlbum(album.name),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? [];
                          // Find first photo for cover, if it's a video skip it or if no photo just grab first
                          final firstPhoto = items
                              .where((i) => i.mediaType == 'photo')
                              .firstOrNull;
                          final firstItem =
                              firstPhoto ??
                              (items.isNotEmpty ? items.first : null);
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppConstants.bgElevated,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.radiusLG),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.radiusLG),
                              ),
                              child: firstItem != null
                                  ? Image.file(
                                      File(firstItem.filePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.broken_image_rounded,
                                        size: 36,
                                        color: AppConstants.textMuted
                                            .withValues(alpha: 0.3),
                                      ),
                                    )
                                  : Icon(
                                      Icons.folder_rounded,
                                      size: 36,
                                      color: AppConstants.textMuted.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        album.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// Album Detail Screen — grid with filters, sort, pinch-to-zoom
// ============================================================

class AlbumDetailScreen extends StatefulWidget {
  final String albumName;
  final DateTimeRange? filterRange;
  final bool isPicker;
  final Set<MediaItem>? selectedItems;
  final ValueChanged<MediaItem>? onToggleSelection;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    this.filterRange,
    this.isPicker = false,
    this.selectedItems,
    this.onToggleSelection,
  });

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  int _columns = 3;
  String _sortMode = 'Newest'; // 'Newest', 'Oldest'
  late Future<List<MediaItem>> _mediaFuture;
  late MediaStorageService _ms;
  int _pointerCount = 0;
  double _baseScale = 1.0;
  final ScrollController _scrollController = ScrollController();
  ScrollPhysics _gridPhysics = const AlwaysScrollableScrollPhysics();
  
  // Drag Selection State
  int? _dragStartIndex;
  int? _lastDragIndex;
  bool _isDragging = false;
  bool _dragSelects = true; // true if selecting, false if deselecting
  Set<MediaItem> _selectionAtStart = {};
  Timer? _autoScrollTimer;
  double _lastPointerY = 0;

  late Set<MediaItem> _internalSelectedItems;
  Set<MediaItem> get _selectedItems =>
      widget.selectedItems ?? _internalSelectedItems;
  bool get _isSelectionMode => _selectedItems.isNotEmpty;

  void _onToggleSelection(MediaItem item) {
    if (widget.onToggleSelection != null) {
      widget.onToggleSelection!(item);
      setState(() {});
    } else {
      setState(() {
        if (_internalSelectedItems.contains(item)) {
          _internalSelectedItems.remove(item);
        } else {
          _internalSelectedItems.add(item);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _internalSelectedItems = {};
    _ms = context.read<MediaStorageService>();
    _refreshMedia();
    _ms.addListener(_refreshMedia);
  }

  @override
  void didUpdateWidget(covariant AlbumDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterRange != widget.filterRange) {
      _refreshMedia();
    }
  }

  void _refreshMedia() {
    if (!mounted) return;
    setState(() {
      _mediaFuture = _ms.getMediaForAlbum(
        widget.albumName,
        filter: widget.filterRange,
      );
    });
  }

  @override
  void dispose() {
    _ms.removeListener(_refreshMedia);
    _scrollController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  void _updateRangeSelection(int start, int end, List<MediaItem> allItems) {
    setState(() {
      _lastDragIndex = end;
    });
  }

  void _updateGridPhysics() {
    setState(() {
      _gridPhysics = (_pointerCount >= 2 || _isDragging)
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics();
    });

    // Interrupt ongoing scroll if we're entering zoom or drag mode
    if ((_pointerCount >= 2 || _isDragging) && _scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.offset);
    }
  }

  int? _calculateIndexAtPos(Offset localPos, double gridWidth, int itemCount) {
    if (itemCount == 0) return null;
    const double padding = 2.0;
    const double spacing = 2.0;
    final double availWidth = gridWidth - (2 * padding);
    final double itemWidth = (availWidth - ((_columns - 1) * spacing)) / _columns;
    final double rowHeight = itemWidth + spacing;
    
    final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final double relativeY = localPos.dy + scrollOffset - padding;
    final double relativeX = localPos.dx - padding;

    if (relativeY < 0) return 0;
    
    final int row = (relativeY / rowHeight).floor();
    final int col = (relativeX / (itemWidth + spacing)).floor().clamp(0, _columns - 1);
    
    final int index = row * _columns + col;
    if (index < 0) return 0;
    if (index >= itemCount) return itemCount - 1;
    return index;
  }

  void _maybeStartAutoSelectionScroll(double viewportHeight, List<MediaItem> allItems, double viewportWidth) {
    _autoScrollTimer?.cancel();
    if (!_isDragging) return;

    const double edgeSize = 120.0;
    double scrollAmount = 0;

    if (_lastPointerY < edgeSize) {
      scrollAmount = -((edgeSize - _lastPointerY) / 1.5).clamp(2.0, 20.0);
    } else if (_lastPointerY > viewportHeight - edgeSize) {
      scrollAmount = ((_lastPointerY - (viewportHeight - edgeSize)) / 1.5).clamp(2.0, 20.0);
    }

    if (scrollAmount != 0) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!_isDragging || !_scrollController.hasClients) {
          timer.cancel();
          return;
        }

        final double newOffset = (_scrollController.offset + scrollAmount).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        
        if (newOffset != _scrollController.offset) {
          _scrollController.jumpTo(newOffset);
          // Re-calculate index under stationary finger during scroll
          final index = _calculateIndexAtPos(Offset(0, _lastPointerY), viewportWidth, allItems.length);
          if (index != null && index != _lastDragIndex) {
            _lastDragIndex = index;
            _updateRangeSelection(_dragStartIndex!, index, allItems);
          }
        }
      });
    }
  }

  void _stopDragging() {
    _isDragging = false;
    _dragStartIndex = null;
    _lastDragIndex = null;
    _autoScrollTimer?.cancel();
    _updateGridPhysics();
  }

  void _importMedia() async {
    final ms = context.read<MediaStorageService>();
    final List<AssetEntity>? assets = await Navigator.push<List<AssetEntity>>(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPickerScreen(targetAlbumName: widget.albumName),
      ),
    );

    if (assets != null && assets.isNotEmpty && mounted) {
      final count = await ms.importFromAssets(widget.albumName, assets);
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count files into ${widget.albumName}'),
            backgroundColor: AppConstants.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refreshMedia();
      }
    }
  }

  List<MediaItem> _applySort(List<MediaItem> allItems) {
    var items = List<MediaItem>.from(allItems);

    // Sort
    if (_sortMode == 'Newest') {
      items.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
    } else {
      items.sort((a, b) => a.dateTaken.compareTo(b.dateTaken));
    }
    return items;
  }

  void _onScaleUpdate(double scale) {
    // Sensitivity: ratio must move by at least 0.3 to trigger a column change
    const double threshold = 0.3;
    final double ratio = _baseScale / scale;

    if (ratio > 1.0 + threshold) {
      if (_columns < 6) {
        setState(() {
          _columns++;
          _baseScale = scale;
        });
      }
    } else if (ratio < 1.0 - threshold) {
      if (_columns > 2) {
        setState(() {
          _columns--;
          _baseScale = scale;
        });
      }
    }
  }

  void _clearSelection() {
    if (widget.onToggleSelection != null && widget.selectedItems != null) {
      final toRemove = List<MediaItem>.from(widget.selectedItems!);
      for (final item in toRemove) {
        widget.onToggleSelection!(item);
      }
      setState(() {});
    } else {
      setState(() {
        _internalSelectedItems.clear();
      });
    }
  }

  void _toggleSelection(MediaItem item) {
    _onToggleSelection(item);
  }

  Future<void> _bulkDelete() async {
    if (_selectedItems.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete ${_selectedItems.length} items?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final itemsToDelete = _selectedItems.toList();
      _clearSelection();
      await _ms.deleteMediaList(itemsToDelete);
      _refreshMedia();
    }
  }

  Future<void> _bulkMove() async {
    if (_selectedItems.isEmpty) return;
    
    final targetAlbum = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BulkMoveAlbumPicker(
        items: _selectedItems.toList(),
      ),
    );

    if (targetAlbum != null && mounted) {
      final itemsToMove = _selectedItems.toList();
      _clearSelection();
      await _ms.moveMediaList(itemsToMove, targetAlbum);
      _refreshMedia();
    }
  }

  Future<void> _bulkExport() async {
    if (_selectedItems.isEmpty) return;
    final itemsToExport = _selectedItems.toList();
    
    _clearSelection();
    
    _toast(context, 'Exporting ${itemsToExport.length} items to gallery...');
    final count = await _ms.exportToGallery(itemsToExport);
    
    if (mounted) {
      _toast(context, 'Successfully exported $count items.');
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppConstants.bgElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: AppConstants.accentPrimary.withValues(alpha: 0.1),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _clearSelection,
                ),
                title: Text(
                  '${_selectedItems.length} selected',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _bulkExport,
                    tooltip: 'Export to gallery',
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_rounded),
                    onPressed: _bulkMove,
                    tooltip: 'Move selected',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded),
                    onPressed: _bulkDelete,
                    color: Colors.redAccent,
                    tooltip: 'Delete selected',
                  ),
                  const SizedBox(width: 8),
                ],
              )
            : AppBar(
                title: Text(
                  widget.albumName,
                  style:
                      GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () => _importMedia(),
                    tooltip: 'Import into this album',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
      body: FutureBuilder<List<MediaItem>>(
        future: _mediaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var allItems = snapshot.data ?? [];
          final items = _applySort(allItems);

          return Column(
            children: [
              // Sort & info bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      '${items.length} items${widget.filterRange != null ? ' (Filtered)' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppConstants.textMuted,
                      ),
                    ),
                    const Spacer(),
                    // Sort toggle
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppConstants.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppConstants.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [_sortChip('Newest'), _sortChip('Oldest')],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      _pointerCount++;
                      _updateGridPhysics();
                    },
                    onPointerMove: (event) {
                      if (_isDragging) {
                        _lastPointerY = event.localPosition.dy;
                        final index = _calculateIndexAtPos(
                          event.localPosition,
                          constraints.maxWidth,
                          items.length,
                        );
                        if (index != null && index != _lastDragIndex) {
                          _lastDragIndex = index;
                          _updateRangeSelection(_dragStartIndex!, index, items);
                          HapticFeedback.selectionClick();
                        }
                        _maybeStartAutoSelectionScroll(
                          constraints.maxHeight,
                          items,
                          constraints.maxWidth,
                        );
                      }
                    },
                    onPointerUp: (event) {
                      _pointerCount = (_pointerCount - 1).clamp(0, 10);
                      if (_isDragging) {
                        // Commit changes
                        final range = [_dragStartIndex!, _lastDragIndex!]..sort();
                        for (int i = range[0]; i <= range[1]; i++) {
                          final item = items[i];
                          final wasSelected = _selectionAtStart.contains(item);
                          if (_dragSelects != wasSelected) {
                            _onToggleSelection(item);
                          }
                        }
                        _stopDragging();
                      }
                      _updateGridPhysics();
                    },
                    onPointerCancel: (event) {
                      _pointerCount = (_pointerCount - 1).clamp(0, 10);
                      if (_isDragging) _stopDragging();
                      _updateGridPhysics();
                    },
                    child: GestureDetector(
                      onScaleStart: (_) => _baseScale = 1.0,
                      onScaleUpdate: (details) => _onScaleUpdate(details.scale),
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                'No media found matching criteria.',
                                style: GoogleFonts.inter(
                                  color: AppConstants.textMuted,
                                ),
                              ),
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              physics: _gridPhysics,
                              padding: const EdgeInsets.only(
                                left: 2,
                                right: 2,
                                top: 2,
                                bottom: 50,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _columns,
                                crossAxisSpacing: 2,
                                mainAxisSpacing: 2,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final item = items[i];
                                
                                // Real-time selection calc
                                bool isSelected = _selectedItems.contains(item);
                                if (_isDragging && _dragStartIndex != null && _lastDragIndex != null) {
                                  final range = [_dragStartIndex!, _lastDragIndex!]..sort();
                                  if (i >= range[0] && i <= range[1]) {
                                    isSelected = _dragSelects;
                                  } else {
                                    isSelected = _selectionAtStart.contains(item);
                                  }
                                }

                                final dateStr = DateFormat(
                                  'MMM d, yyyy',
                                ).format(item.dateTaken);


                                return GestureDetector(
                                  onTap: () {
                                    if (_isSelectionMode) {
                                      _toggleSelection(item);
                                    } else if (widget.isPicker) {
                                      Navigator.pop(context, item);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MediaViewPage(
                                            items: items,
                                            initialIndex: i,
                                            selectedItems: _selectedItems,
                                            onToggleSelection: _toggleSelection,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onLongPress: widget.isPicker
                                      ? null
                                      : () {
                                          if (!_isSelectionMode) {
                                            HapticFeedback.mediumImpact();
                                            setState(() {
                                              _isDragging = true;
                                              _dragStartIndex = i;
                                              _lastDragIndex = i;
                                              _selectionAtStart =
                                                  Set.from(_selectedItems);
                                              _dragSelects = true;
                                              _updateGridPhysics();
                                            });
                                          } else {
                                            HapticFeedback.lightImpact();
                                            setState(() {
                                              _isDragging = true;
                                              _dragStartIndex = i;
                                              _lastDragIndex = i;
                                              _selectionAtStart =
                                                  Set.from(_selectedItems);
                                              _dragSelects =
                                                  !_selectionAtStart
                                                      .contains(item);
                                              _updateGridPhysics();
                                            });
                                          }
                                        },
                                  child: Hero(
                                    tag: item.filePath,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          padding: isSelected
                                              ? const EdgeInsets.all(8)
                                              : EdgeInsets.zero,
                                          color: isSelected
                                              ? AppConstants.accentPrimary
                                                  .withValues(alpha: 0.3)
                                              : AppConstants.bgElevated,
                                          child: ClipRRect(
                                            borderRadius: isSelected
                                                ? BorderRadius.circular(8)
                                                : BorderRadius.zero,
                                            child: item.mediaType == 'video'
                                                ? VideoThumbnailPlayer(
                                                    item: item)
                                                : Image.file(
                                                    File(item.filePath),
                                                    fit: BoxFit.cover,
                                                    cacheWidth: 300, // Optimize memory for detail grid
                                                    errorBuilder:
                                                        (_, __, ___) => Icon(
                                                      Icons
                                                          .broken_image_rounded,
                                                      color: AppConstants
                                                          .textMuted
                                                          .withValues(
                                                        alpha: 0.3,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    AppConstants.accentPrimary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        if (item.mediaType == 'video')
                                          const Positioned(
                                            top: 4,
                                            right: 4,
                                            child: Icon(
                                              Icons.play_circle_fill_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              dateStr,
                                              style: GoogleFonts.inter(
                                                fontSize: 9,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _sortChip(String label) {
    final selected = _sortMode == label;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppConstants.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppConstants.textMuted,
          ),
        ),
      ),
    );
  }

  void _showDeleteMediaDialog(BuildContext context, MediaItem item) {
    final mediaStorage = context.read<MediaStorageService>();
    final label = item.mediaType == 'video' ? 'Video' : 'Photo';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                item.fileName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.drive_file_move_rounded,
                color: AppConstants.accentPrimary,
              ),
              title: Text(
                'Move to Album',
                style: GoogleFonts.inter(color: AppConstants.textPrimary),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GridMoveToAlbumScreen(
                      item: item,
                      onMoved: () => setState(() {}),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: Text(
                'Delete $label',
                style: GoogleFonts.inter(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => AlertDialog(
                    backgroundColor: AppConstants.bgCard,
                    title: Text(
                      'Delete $label?',
                      style: GoogleFonts.inter(
                        color: AppConstants.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Text(
                      'Delete "${item.fileName}"? This cannot be undone.',
                      style: GoogleFonts.inter(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dCtx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () async {
                          await mediaStorage.deleteMedia(item.filePath);
                          if (dCtx.mounted) {
                            Navigator.pop(dCtx);
                            setState(() {});
                          }
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _GridMoveToAlbumScreen extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onMoved;
  const _GridMoveToAlbumScreen({required this.item, required this.onMoved});

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.watch<MediaStorageService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Move to Album',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: FutureBuilder<List<AlbumInfo>>(
        future: mediaStorage.getAlbums(),
        builder: (context, snapshot) {
          final albums = snapshot.data ?? [];
          final targets = albums
              .where((a) => a.name != item.albumName)
              .toList();

          if (targets.isEmpty) {
            return Center(
              child: Text(
                'No other albums to move to.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppConstants.textMuted,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: targets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final album = targets[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppConstants.bgCard,
                leading: Icon(
                  Icons.folder_rounded,
                  color: AppConstants.accentPrimary,
                ),
                title: Text(
                  album.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${album.itemCount} items',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppConstants.textMuted,
                ),
                onTap: () async {
                  await mediaStorage.moveMedia(item.filePath, album.name);
                  onMoved();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Moved to ${album.name}',
                          style: GoogleFonts.inter(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppConstants.bgElevated,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double fraction;
  _SplitClipper(this.fraction);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fraction, size.height);
  }

  @override
  bool shouldReclip(_SplitClipper oldClipper) =>
      oldClipper.fraction != fraction;
}

class _AlbumSearchPicker extends StatefulWidget {
  final List<AlbumInfo> albums;
  final String? initialAlbum;
  final ValueChanged<String> onSelected;

  const _AlbumSearchPicker({
    required this.albums,
    this.initialAlbum,
    required this.onSelected,
  });

  @override
  State<_AlbumSearchPicker> createState() => _AlbumSearchPickerState();
}

class _AlbumSearchPickerState extends State<_AlbumSearchPicker> {
  late List<AlbumInfo> _filteredAlbums;
  // ignore: unused_field
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredAlbums = widget.albums;
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      _filteredAlbums = widget.albums
          .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Select Album',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppConstants.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: false,
              style: GoogleFonts.inter(color: AppConstants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search albums...',
                hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppConstants.textMuted,
                ),
                filled: true,
                fillColor: AppConstants.bgElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filter,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: _filteredAlbums.isEmpty
                ? Center(
                    child: Text(
                      'No albums found',
                      style: GoogleFonts.inter(color: AppConstants.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    itemCount: _filteredAlbums.length,
                    itemBuilder: (context, i) {
                      final album = _filteredAlbums[i];
                      final isSelected = album.name == widget.initialAlbum;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            widget.onSelected(album.name);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppConstants.accentPrimary.withValues(
                                      alpha: 0.1,
                                    )
                                  : AppConstants.bgElevated.withValues(
                                      alpha: 0.5,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppConstants.accentPrimary
                                    : AppConstants.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppConstants.accentPrimary
                                        : AppConstants.border.withValues(
                                            alpha: 0.1,
                                          ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.folder_rounded,
                                    size: 20,
                                    color: isSelected
                                        ? Colors.white
                                        : AppConstants.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        album.name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${album.photoCount} photos • ${album.videoCount} videos',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: AppConstants.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: AppConstants.accentPrimary,
                                  ),
                              ],
                            ),
                          ),
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

class BulkMoveAlbumPicker extends StatelessWidget {
  final List<MediaItem> items;
  const BulkMoveAlbumPicker({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final mediaStorage = context.watch<MediaStorageService>();
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Text(
                  'Move ${items.length} items to...',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          FutureBuilder<List<AlbumInfo>>(
            future: mediaStorage.getAlbums(),
            builder: (context, snapshot) {
              final albums = snapshot.data ?? [];
              if (albums.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No albums available'),
                );
              }

              return Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  itemCount: albums.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final album = albums[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: AppConstants.bgElevated,
                      leading: const Icon(Icons.folder_rounded),
                      title: Text(
                        album.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, album.name),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
