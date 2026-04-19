import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme_profile.dart';
import '../utils/constants.dart';
import 'custom_palette_screen.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AppThemeProfile> _filter(List<AppThemeProfile> themes) {
    if (_searchQuery.isEmpty) return themes;
    return themes
        .where((t) => t.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final activeThemeId = themeProvider.theme.id;
    final filteredPresets = _filter(themeProvider.presets);
    final filteredCustom = _filter(themeProvider.customThemes);

    return Scaffold(
      backgroundColor: AppConstants.bgDark,
      appBar: AppBar(
        backgroundColor: AppConstants.bgDark,
        elevation: 0,
        title: Text(
          'Appearance',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppConstants.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppConstants.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    color: AppConstants.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search themes...',
                    hintStyle: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppConstants.textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: AppConstants.textMuted,
                              size: 18,
                            ),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: AppConstants.bgCard,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: BorderSide(color: AppConstants.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: BorderSide(color: AppConstants.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMD,
                      ),
                      borderSide: BorderSide(color: AppConstants.accentPrimary),
                    ),
                  ),
                ),
              ),
              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppConstants.accentPrimary,
                labelColor: AppConstants.accentPrimary,
                unselectedLabelColor: AppConstants.textSecondary,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'Presets (${filteredPresets.length})'),
                  Tab(text: 'Custom (${filteredCustom.length})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ─── Presets Tab ───
          _buildThemeList(
            filteredPresets,
            activeThemeId,
            themeProvider,
            showEmptyPreset: true,
          ),

          // ─── Custom Tab ───
          _buildCustomTab(filteredCustom, activeThemeId, themeProvider),
        ],
      ),
    );
  }

  Widget _buildThemeList(
    List<AppThemeProfile> themes,
    String activeThemeId,
    ThemeProvider provider, {
    bool showEmptyPreset = false,
  }) {
    if (themes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.palette_outlined,
              color: AppConstants.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              showEmptyPreset ? 'No matching presets' : 'No matching themes',
              style: GoogleFonts.inter(
                color: AppConstants.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        80,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) =>
          _buildThemeCard(context, themes[index], activeThemeId, provider),
    );
  }

  Widget _buildCustomTab(
    List<AppThemeProfile> themes,
    String activeThemeId,
    ThemeProvider provider,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        AppConstants.paddingMD,
        80,
      ),
      children: [
        if (themes.isEmpty && _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: AppConstants.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No matching custom themes',
                    style: GoogleFonts.inter(
                      color: AppConstants.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (themes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.brush_outlined,
                    color: AppConstants.textMuted,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No custom themes yet',
                    style: GoogleFonts.inter(
                      color: AppConstants.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create one below!',
                    style: GoogleFonts.inter(
                      color: AppConstants.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...themes.map(
            (t) => _buildThemeCard(context, t, activeThemeId, provider),
          ),
        const SizedBox(height: 16),
        _buildAddCustomThemeButton(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    AppThemeProfile theme,
    String activeThemeId,
    ThemeProvider provider,
  ) {
    final isActive = theme.id == activeThemeId;

    return GestureDetector(
      onTap: () {
        provider.setTheme(theme.id);
      },
      onLongPress: () => _showThemeOptions(context, theme, provider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.bgCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusLG),
          border: Border.all(
            color: isActive ? AppConstants.accentPrimary : AppConstants.border,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color Swatches
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.bgDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.border, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    Expanded(flex: 2, child: Container(color: theme.bgSurface)),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(color: theme.accentPrimary),
                          ),
                          Expanded(
                            child: Container(color: theme.accentSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  if (isActive)
                    Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppConstants.accentPrimary,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle_rounded,
                color: AppConstants.accentPrimary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCustomThemeButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CustomPaletteScreen()),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusLG),
            border: Border.all(
              color: AppConstants.accentPrimary.withValues(alpha: 0.5),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: AppConstants.accentPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                'Create Custom Palette',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.accentPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeOptions(
    BuildContext context,
    AppThemeProfile theme,
    ThemeProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLG),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  theme.name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
              const Divider(),
              if (theme.isCustom) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: AppConstants.accentSecondary,
                  ),
                  title: Text(
                    'Edit Theme',
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomPaletteScreen(initialTheme: theme),
                      ),
                    );
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(
                    Icons.visibility_rounded,
                    color: AppConstants.accentSecondary,
                  ),
                  title: Text(
                    'View Details',
                    style: GoogleFonts.inter(color: AppConstants.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomPaletteScreen(
                          initialTheme: theme,
                          isReadOnly: true,
                        ),
                      ),
                    );
                  },
                ),
              ],
              ListTile(
                leading: Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppConstants.accentPrimary,
                ),
                title: Text(
                  'Set as Active',
                  style: GoogleFonts.inter(color: AppConstants.textPrimary),
                ),
                onTap: () {
                  provider.setTheme(theme.id);
                  Navigator.pop(ctx);
                },
              ),
              if (theme.isCustom)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: AppConstants.error,
                  ),
                  title: Text(
                    'Delete Theme',
                    style: GoogleFonts.inter(color: AppConstants.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirm(context, theme.id, theme.name, provider);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext context,
    String id,
    String name,
    ThemeProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text(
          'Delete Theme?',
          style: GoogleFonts.inter(color: AppConstants.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: GoogleFonts.inter(color: AppConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'No',
              style: GoogleFonts.inter(color: AppConstants.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCustomTheme(id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.inter(color: AppConstants.error),
            ),
          ),
        ],
      ),
    );
  }
}
