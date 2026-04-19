import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/app_theme_profile.dart';
import '../utils/constants.dart';

class CustomPaletteScreen extends StatefulWidget {
  final AppThemeProfile? initialTheme;
  final bool isReadOnly;

  const CustomPaletteScreen({
    super.key,
    this.initialTheme,
    this.isReadOnly = false,
  });

  @override
  State<CustomPaletteScreen> createState() => _CustomPaletteScreenState();
}

class _CustomPaletteScreenState extends State<CustomPaletteScreen>
    with SingleTickerProviderStateMixin {
  late AppThemeProfile _draftTheme;
  late AppThemeProfile _originalTheme;
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hexController = TextEditingController();
  final List<AppThemeProfile> _undoStack = [];
  final List<AppThemeProfile> _redoStack = [];

  int _selectedColorIndex = 0;
  int _selectedGroupIndex = 0;

  // Color groups matching theme model
  static const List<String> _groupLabels = [
    'BG',
    'Accent',
    'Text',
    'Status',
    'Progress',
    'Border',
  ];

  static const List<IconData> _groupIcons = [
    Icons.dark_mode_rounded,
    Icons.palette_rounded,
    Icons.text_fields_rounded,
    Icons.info_outline_rounded,
    Icons.trending_up_rounded,
    Icons.crop_square_rounded,
  ];

  // Field keys per group (must match AppThemeProfile fields)
  static const List<List<String>> _groupFields = [
    ['bgDark', 'bgCard', 'bgCardHover', 'bgSurface', 'bgElevated'],
    ['accentPrimary', 'accentSecondary', 'accentTertiary', 'accentWarm', 'accentGold'],
    ['textPrimary', 'textSecondary', 'textMuted'],
    ['success', 'warning', 'error', 'info', 'completion'],
    ['progressProgram', 'progressWeek', 'progressDay'],
    ['border', 'borderHighlight'],
  ];

  static const List<List<String>> _groupFieldLabels = [
    ['App BG', 'Card', 'Card Hover', 'Surface', 'Elevated'],
    ['Primary', 'Secondary', 'Tertiary', 'Warm', 'Gold'],
    ['Primary', 'Secondary', 'Muted'],
    ['Success', 'Warning', 'Error', 'Info', 'Completion'],
    ['Program', 'Week', 'Day'],
    ['Border', 'Highlight'],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groupLabels.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _selectedGroupIndex = _tabController.index;
        _selectedColorIndex = 0;
        _syncHexField();
      });
    });

    if (widget.initialTheme != null) {
      _draftTheme = widget.initialTheme!;
    } else {
      final currentTheme = context.read<ThemeProvider>().theme;
      _draftTheme = currentTheme.copyWith(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: 'My Custom Theme',
        isCustom: true,
      );
    }
    _originalTheme = _draftTheme;
    _nameController.text = _draftTheme.name;
    _nameController.addListener(() {
      _draftTheme = _draftTheme.copyWith(name: _nameController.text);
    });
    _syncHexField();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  // ─── Color Read/Write Helpers ───

  Color _getColorForField(String field) {
    switch (field) {
      case 'bgDark': return _draftTheme.bgDark;
      case 'bgCard': return _draftTheme.bgCard;
      case 'bgCardHover': return _draftTheme.bgCardHover;
      case 'bgSurface': return _draftTheme.bgSurface;
      case 'bgElevated': return _draftTheme.bgElevated;
      case 'accentPrimary': return _draftTheme.accentPrimary;
      case 'accentSecondary': return _draftTheme.accentSecondary;
      case 'accentTertiary': return _draftTheme.accentTertiary;
      case 'accentWarm': return _draftTheme.accentWarm;
      case 'accentGold': return _draftTheme.accentGold;
      case 'textPrimary': return _draftTheme.textPrimary;
      case 'textSecondary': return _draftTheme.textSecondary;
      case 'textMuted': return _draftTheme.textMuted;
      case 'success': return _draftTheme.success;
      case 'warning': return _draftTheme.warning;
      case 'error': return _draftTheme.error;
      case 'info': return _draftTheme.info;
      case 'completion': return _draftTheme.completion;
      case 'border': return _draftTheme.border;
      case 'borderHighlight': return _draftTheme.borderHighlight;
      case 'progressProgram': return _draftTheme.progressProgram;
      case 'progressWeek': return _draftTheme.progressWeek;
      case 'progressDay': return _draftTheme.progressDay;
      default: return Colors.white;
    }
  }

  void _pushUndo() {
    _undoStack.add(_draftTheme);
    _redoStack.clear(); // Clear redo on new action
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _redoStack.add(_draftTheme);
      _draftTheme = _undoStack.removeLast();
      _syncHexField();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _undoStack.add(_draftTheme);
      _draftTheme = _redoStack.removeLast();
      _syncHexField();
    });
  }

  void _setColorForField(String field, Color c) {
    setState(() {
      switch (field) {
        case 'bgDark': _draftTheme = _draftTheme.copyWith(bgDark: c); break;
        case 'bgCard': _draftTheme = _draftTheme.copyWith(bgCard: c); break;
        case 'bgCardHover': _draftTheme = _draftTheme.copyWith(bgCardHover: c); break;
        case 'bgSurface': _draftTheme = _draftTheme.copyWith(bgSurface: c); break;
        case 'bgElevated': _draftTheme = _draftTheme.copyWith(bgElevated: c); break;
        case 'accentPrimary': _draftTheme = _draftTheme.copyWith(accentPrimary: c); break;
        case 'accentSecondary': _draftTheme = _draftTheme.copyWith(accentSecondary: c); break;
        case 'accentTertiary': _draftTheme = _draftTheme.copyWith(accentTertiary: c); break;
        case 'accentWarm': _draftTheme = _draftTheme.copyWith(accentWarm: c); break;
        case 'accentGold': _draftTheme = _draftTheme.copyWith(accentGold: c); break;
        case 'textPrimary': _draftTheme = _draftTheme.copyWith(textPrimary: c); break;
        case 'textSecondary': _draftTheme = _draftTheme.copyWith(textSecondary: c); break;
        case 'textMuted': _draftTheme = _draftTheme.copyWith(textMuted: c); break;
        case 'success': _draftTheme = _draftTheme.copyWith(success: c); break;
        case 'warning': _draftTheme = _draftTheme.copyWith(warning: c); break;
        case 'error': _draftTheme = _draftTheme.copyWith(error: c); break;
        case 'info': _draftTheme = _draftTheme.copyWith(info: c); break;
        case 'completion': _draftTheme = _draftTheme.copyWith(completion: c); break;
        case 'border': _draftTheme = _draftTheme.copyWith(border: c); break;
        case 'borderHighlight': _draftTheme = _draftTheme.copyWith(borderHighlight: c); break;
        case 'progressProgram': _draftTheme = _draftTheme.copyWith(progressProgram: c); break;
        case 'progressWeek': _draftTheme = _draftTheme.copyWith(progressWeek: c); break;
        case 'progressDay': _draftTheme = _draftTheme.copyWith(progressDay: c); break;
      }
    });
  }

  Color get _activeColor {
    final fields = _groupFields[_selectedGroupIndex];
    final idx = _selectedColorIndex.clamp(0, fields.length - 1);
    return _getColorForField(fields[idx]);
  }

  String get _activeLabel {
    final labels = _groupFieldLabels[_selectedGroupIndex];
    final idx = _selectedColorIndex.clamp(0, labels.length - 1);
    return labels[idx];
  }

  String get _activeField {
    final fields = _groupFields[_selectedGroupIndex];
    final idx = _selectedColorIndex.clamp(0, fields.length - 1);
    return fields[idx];
  }

  void _syncHexField() {
    final c = _activeColor;
    _hexController.text =
        c.toARGB32().toRadixString(16).substring(2).toUpperCase();
  }

  void _applyHex(String hex) {
    hex = hex.trim().replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return;
    _pushUndo();
    _setColorForField(_activeField, Color(value));
    _syncHexField();
  }

  void _saveTheme() {
    if (_draftTheme.name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a theme name', style: GoogleFonts.inter()),
        ),
      );
      return;
    }
    context.read<ThemeProvider>().addCustomTheme(_draftTheme);
    context.read<ThemeProvider>().setTheme(_draftTheme.id);
    Navigator.pop(context);
  }

  Future<bool> _onWillPop() async {
    if (widget.isReadOnly) return true;
    final bool isDirty =
        _draftTheme.toJson().toString() != _originalTheme.toJson().toString();
    if (!isDirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.bgCard,
        title: Text('Unsaved Changes',
            style: GoogleFonts.inter(color: AppConstants.textPrimary)),
        content: Text(
            'You have unsaved changes. Would you like to save them before leaving?',
            style: GoogleFonts.inter(color: AppConstants.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Discard',
                style: GoogleFonts.inter(color: AppConstants.error)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _saveTheme();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final fields = _groupFields[_selectedGroupIndex];
    final labels = _groupFieldLabels[_selectedGroupIndex];
    final safeIdx = _selectedColorIndex.clamp(0, fields.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppConstants.bgDark,
        body: SafeArea(
          child: Column(
            children: [
              // ═══ TOP: App Bar + Tabs + Dots ═══
              _buildTopToolbar(fields, labels, safeIdx),

              // ═══ CENTER: Live Preview Mockups ═══
              Expanded(child: _buildLivePreview()),

              // ═══ BOTTOM: Color Editor ═══
              if (!widget.isReadOnly) _buildBottomEditor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopToolbar(List<String> fields, List<String> labels, int safeIdx) {
    return Container(
      color: AppConstants.bgDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar with name + undo + save
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppConstants.textPrimary, size: 20),
                  onPressed: () async {
                    final bool shouldPop = await _onWillPop();
                    if (shouldPop && context.mounted) Navigator.pop(context);
                  },
                ),
                Expanded(
                  child: widget.isReadOnly
                      ? Text(_draftTheme.name,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppConstants.textPrimary),
                          textAlign: TextAlign.center)
                      : TextField(
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppConstants.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Theme Name',
                            hintStyle: GoogleFonts.inter(
                                color: AppConstants.textMuted, fontSize: 16),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                ),
                if (!widget.isReadOnly) ...[
                  IconButton(
                    icon: Icon(Icons.undo_rounded,
                        color: _undoStack.isNotEmpty
                            ? AppConstants.textPrimary
                            : AppConstants.textMuted.withValues(alpha: 0.3),
                        size: 20),
                    onPressed: _undoStack.isNotEmpty ? _undo : null,
                    tooltip: 'Undo',
                  ),
                  IconButton(
                    icon: Icon(Icons.redo_rounded,
                        color: _redoStack.isNotEmpty
                            ? AppConstants.textPrimary
                            : AppConstants.textMuted.withValues(alpha: 0.3),
                        size: 20),
                    onPressed: _redoStack.isNotEmpty ? _redo : null,
                    tooltip: 'Redo',
                  ),
                  TextButton(
                    onPressed: _saveTheme,
                    child: Text('Save',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppConstants.accentPrimary)),
                  ),
                ] else
                  const SizedBox(width: 48),
              ],
            ),
          ),

          // Group tabs
          SizedBox(
            height: 40,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppConstants.accentPrimary,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppConstants.accentPrimary,
              unselectedLabelColor: AppConstants.textMuted,
              labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500, fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              tabs: List.generate(_groupLabels.length, (i) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_groupIcons[i], size: 14),
                    const SizedBox(width: 4),
                    Text(_groupLabels[i]),
                  ],
                ),
              )),
            ),
          ),

          // Color dots + label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(fields.length, (i) {
                    final color = _getColorForField(fields[i]);
                    final isSelected = i == safeIdx;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorIndex = i;
                          _syncHexField();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: isSelected ? 32 : 24,
                        height: isSelected ? 32 : 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppConstants.textPrimary
                                : AppConstants.border,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 6),
                Text(
                  _activeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppConstants.border),
        ],
      ),
    );
  }

  // ─── Live Preview Mockups (context-aware per group) ───
  // Each mock below is a faithful replica of a real app widget,
  // using only t.<field> for colors to guarantee accuracy.

  Widget _buildLivePreview() {
    final t = _draftTheme;
    final List<Widget> widgets = [];

    switch (_selectedGroupIndex) {
      case 0: // BG — show all bg colors via real widget replicas
        // bgDark: shown by this container's own background
        // bgCard: shown by the ScheduledDayCard
        // bgCardHover: shown by a highlighted/hovered card variant
        // bgSurface: shown by input field + chip + progress track
        // bgElevated: shown by the bottom sheet + snackbar replica
        widgets.addAll([
          _mockScheduledDayCard(t),
          const SizedBox(height: 12),
          _mockHoveredCard(t),
          const SizedBox(height: 12),
          _mockSurfaceWidgets(t),
          const SizedBox(height: 12),
          _mockElevatedSheet(t),
          const SizedBox(height: 12),
          _mockSnackBar(t),
        ]);
        break;
      case 1: // Accent — show accented elements
        widgets.addAll([
          _mockScheduledDayCard(t),
          const SizedBox(height: 12),
          _mockActiveHeader(t),
          const SizedBox(height: 12),
          _mockHistoryRow(t),
          const SizedBox(height: 12),
          _mockWorkoutTools(t),
          const SizedBox(height: 12),
          _mockExerciseRowWithBadge(t),
          const SizedBox(height: 12),
          _mockAccentGradientButton(t),
        ]);
        break;
      case 2: // Text — show text hierarchy
        widgets.addAll([
          _mockDescriptionBox(t),
          const SizedBox(height: 12),
          _mockScheduledDayCard(t),
          const SizedBox(height: 12),
          _mockBottomSheetDialog(t),
        ]);
        break;
      case 3: // Status — show status-colored elements
        widgets.addAll([
          _mockScheduledDayCard(t, completed: true),
          const SizedBox(height: 12),
          _mockScheduledDayCard(t, partial: true),
          const SizedBox(height: 12),
          _mockStatusIndicators(t),
        ]);
        break;
      case 4: // Progress — show progress bars
        widgets.addAll([
          _mockScheduledDayCard(t, showProgress: true),
        ]);
        break;
      case 5: // Border — show bordered elements
        widgets.addAll([
          _mockBorderPreview(t),
          const SizedBox(height: 12),
          _mockScheduledDayCard(t),
        ]);
        break;
    }

    return Container(
      color: t.bgDark,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...widgets,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── BG Group: Real widget replicas showing each bg color ───

  // bgCardHover — replica of _ScheduledDayCard in pressed/hovered state
  Widget _mockHoveredCard(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: t.bgCardHover, // ← the key color for this widget
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [t.accentPrimary, t.accentSecondary]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fitness_center_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pull Day B',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    )),
                Text('Card hover / pressed state',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: t.textMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // bgSurface — replica of real input field, chip, and progress track
  Widget _mockSurfaceWidgets(AppThemeProfile t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input field — real InputDecoration uses bgSurface as fillColor
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMD,
            vertical: AppConstants.paddingSM + 4,
          ),
          decoration: BoxDecoration(
            color: t.bgSurface, // ← the key color
            borderRadius: BorderRadius.circular(AppConstants.radiusSM),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text('Search exercises...',
                    style: GoogleFonts.inter(color: t.textMuted)),
              ),
              Icon(Icons.search_rounded, color: t.textMuted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Chips — real ChipTheme uses bgSurface
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Chest', 'Back', 'Legs'].map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: t.bgSurface, // ← the key color
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(color: t.border),
            ),
            child: Text(tag,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: t.textSecondary,
                )),
          )).toList(),
        ),
        const SizedBox(height: 10),
        // Progress track — real progress bars use bgSurface for the track
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.5,
            backgroundColor: t.bgSurface, // ← the key color (track)
            valueColor: AlwaysStoppedAnimation(t.progressDay),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  // bgElevated — replica of the "Edit Exercise" bottom sheet (active_workout_screen.dart)
  Widget _mockElevatedSheet(AppThemeProfile t) {
    return Container(
      decoration: BoxDecoration(
        color: t.bgElevated, // ← the key color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EDIT EXERCISE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                    color: t.textPrimary,
                  )),
              Icon(Icons.close_rounded, color: t.textSecondary, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          // Input field inside elevated sheet
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMD,
              vertical: AppConstants.paddingSM + 4,
            ),
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: BorderRadius.circular(AppConstants.radiusSM),
              border: Border.all(color: t.border),
            ),
            child: Text('Bench Press',
                style: GoogleFonts.inter(color: t.textPrimary)),
          ),
          const SizedBox(height: 16),
          // Save button
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: t.accentPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text('SAVE CHANGES',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ),
        ],
      ),
    );
  }

  // bgElevated — SnackBar replica (constants.dart SnackBarTheme uses bgElevated)
  Widget _mockSnackBar(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: t.bgElevated, // ← the key color
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: t.success, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Workout saved successfully',
                style: GoogleFonts.inter(color: t.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── Replica: _ScheduledDayCard (home_screen.dart) ───
  // Exact structure from _ScheduledDayCard.build()

  Widget _mockScheduledDayCard(AppThemeProfile t, {
    bool completed = false,
    bool partial = false,
    bool showProgress = false,
  }) {
    final Color borderColor;
    final Gradient iconGradient;
    final IconData icon;

    if (completed) {
      borderColor = t.completion.withValues(alpha: 0.6);
      iconGradient = LinearGradient(colors: [t.completion, t.completion.withValues(alpha: 0.7)]);
      icon = Icons.check_rounded;
    } else if (partial) {
      borderColor = t.warning.withValues(alpha: 0.6);
      iconGradient = LinearGradient(colors: [t.warning, t.warning.withValues(alpha: 0.7)]);
      icon = Icons.warning_rounded;
    } else {
      borderColor = t.border;
      iconGradient = LinearGradient(colors: [t.accentPrimary, t.accentSecondary]);
      icon = Icons.fitness_center_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon — matches real: 36×36, gradient bg, rounded 8
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title — real uses fontSize: 15, w600, textPrimary
                    Text('Push Day A',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        )),
                    if (showProgress) ...[
                      const SizedBox(height: 6),
                      // Program label — real uses fontSize: 11, w500, accentTertiary
                      Text('Hypertrophy Program',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: t.accentTertiary,
                          )),
                      const SizedBox(height: 4),
                      // Program progress — real uses LinearProgressIndicator
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.65,
                                backgroundColor: t.bgSurface,
                                valueColor: AlwaysStoppedAnimation(t.progressProgram),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('65%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: t.progressProgram,
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Week label — real uses accentPrimary
                      Text('Week 3',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: t.accentPrimary,
                          )),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: 0.4,
                                backgroundColor: t.bgSurface,
                                valueColor: AlwaysStoppedAnimation(t.progressWeek),
                                minHeight: 3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('40%',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: t.progressWeek,
                              )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Day progress bar — real uses progressDay + bgSurface
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completed ? 1.0 : (partial ? 0.6 : 0.3),
              backgroundColor: t.bgSurface,
              valueColor: AlwaysStoppedAnimation(t.progressDay),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          // Footer — real uses fontSize: 12 textMuted, fontSize: 14 w700 progressDay
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('4 exercises • ${completed ? "12/12" : (partial ? "7/12" : "3/12")} sets',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: t.textMuted,
                  )),
              Text(completed ? '100%' : (partial ? '58%' : '25%'),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: t.progressDay,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Replica: Active Workout Glass Header (_buildGlassHeader) ───

  Widget _mockActiveHeader(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.bgCard.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: t.accentPrimary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise title — real uses Outfit w800 18px accentPrimary
          Text('BENCH PRESS',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: t.accentPrimary,
              )),
          const SizedBox(height: 8),
          // Tag chips — real uses accentPrimary with 0.08 bg, 0.2 border
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['CHEST', 'PUSH'].map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: t.accentPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: t.accentPrimary.withValues(alpha: 0.2)),
              ),
              child: Text(tag,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: t.accentPrimary,
                  )),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Replica: Accent gradient button (FilledButton in active_workout) ───

  Widget _mockAccentGradientButton(AppThemeProfile t) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: t.accentPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text('START ROUTINE',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          )),
    );
  }

  // ─── Replica: "From History" row (home_screen.dart line ~1453) ───
  // Uses accentSecondary for the history icon and the add icon

  Widget _mockHistoryRow(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: t.accentSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pull Day B',
                    style: GoogleFonts.inter(
                      color: t.textPrimary,
                      fontWeight: FontWeight.w500,
                    )),
                Text('Mar 22, 2026',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: t.textMuted,
                    )),
              ],
            ),
          ),
          Icon(Icons.add_rounded, color: t.accentSecondary, size: 20),
        ],
      ),
    );
  }

  // ─── Replica: Active workout header tools (active_workout_screen.dart ~850) ───
  // AUTO-PLAY uses accentSecondary, REST timer uses accentWarm

  Widget _mockWorkoutTools(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          // AUTO-PLAY toggle — real uses accentSecondary
          _mockToolChip(t, Icons.play_circle_filled_rounded, 'AUTO-PLAY',
              t.accentSecondary, true),
          Container(
            width: 1, height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: t.border,
          ),
          // REST timer — real uses accentWarm
          Expanded(
            child: _mockToolChip(t, Icons.timer_outlined, 'REST: 30s',
                t.accentWarm, true),
          ),
          Container(
            width: 1, height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: t.border,
          ),
          // Manual timers — inactive
          _mockToolChip(t, Icons.history_rounded, '30s',
              t.textMuted, false),
          const SizedBox(width: 8),
          _mockToolChip(t, Icons.update_rounded, '1m',
              t.textMuted, false),
        ],
      ),
    );
  }

  Widget _mockToolChip(AppThemeProfile t, IconData icon, String label,
      Color color, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: isActive ? color : t.textMuted),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isActive ? color : t.textMuted,
            )),
      ],
    );
  }

  // ─── Replica: Exercise row with accentTertiary icon + accentGold % badge ───
  // From home_screen.dart line ~1396 (list_alt icon) + day_overview_screen.dart line ~173 (% badge)

  Widget _mockExerciseRowWithBadge(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSM),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center_rounded, color: t.accentPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Bench Press',
                style: GoogleFonts.inter(
                  color: t.textPrimary,
                  fontWeight: FontWeight.w500,
                )),
          ),
          // List icon — real uses accentTertiary (home_screen.dart ~1396)
          Icon(Icons.list_alt_rounded, color: t.accentTertiary, size: 22),
          const SizedBox(width: 12),
          // % MAX badge — exact replica from day_overview_screen.dart ~173-195
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: t.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.percent_rounded, size: 12, color: t.accentGold),
                const SizedBox(width: 2),
                Text('MAX',
                    style: TextStyle(
                      color: t.accentGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Replica: Description box (day_overview_screen.dart ~48-63) ───
  // textSecondary used for description text, textPrimary for header

  Widget _mockDescriptionBox(AppThemeProfile t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMD),
      decoration: BoxDecoration(
        color: t.bgSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header — real uses textSecondary (home_screen.dart ~1427)
          Text('From History',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              )),
          const SizedBox(height: 8),
          // Description text — real uses textSecondary (day_overview ~59)
          Text(
            'Focus on compound chest and shoulder movements with progressive overload.',
            style: GoogleFonts.inter(
              color: t.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          // Hint/subtle text — real uses textMuted
          Text(
            'Tap Edit Routine to customize',
            style: GoogleFonts.inter(
              color: t.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Replica: Bottom Sheet dialog (from _showThemeOptions / _showItemOptions) ───

  Widget _mockBottomSheetDialog(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLG),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle — real
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Title — real uses fontSize: 18, w700, textPrimary
          Text('Push Day A',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: t.textPrimary,
              )),
          const SizedBox(height: 16),
          // Option rows — matches real ListTile structure
          _mockOptionRow(t, Icons.visibility_off_rounded, 'Hide', 'Exclude from calendar progress',
              t.textPrimary),
          _mockOptionRow(t, Icons.delete_outline_rounded, 'Delete Day', 'Permanently remove this day',
              t.error),
        ],
      ),
    );
  }

  Widget _mockOptionRow(AppThemeProfile t, IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: color,
                    )),
                Text(subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: t.textMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Replica: Status indicators (from ScheduledDayCard border + icon states) ───

  Widget _mockStatusIndicators(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status Colors',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary)),
          const SizedBox(height: 12),
          _mockStatusRow(t, Icons.check_circle_rounded, 'Success', t.success),
          const SizedBox(height: 8),
          _mockStatusRow(t, Icons.warning_rounded, 'Warning', t.warning),
          const SizedBox(height: 8),
          _mockStatusRow(t, Icons.error_rounded, 'Error', t.error),
          const SizedBox(height: 8),
          _mockStatusRow(t, Icons.info_rounded, 'Info', t.info),
          const SizedBox(height: 8),
          _mockStatusRow(t, Icons.emoji_events_rounded, 'Completion', t.completion),
        ],
      ),
    );
  }

  Widget _mockStatusRow(AppThemeProfile t, IconData icon, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary)),
        ),
        Text(
          '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
          style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w500, color: t.textMuted),
        ),
      ],
    );
  }

  // ─── Border Group ───

  Widget _mockBorderPreview(AppThemeProfile t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: t.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Border Preview',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: t.textPrimary)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.border),
            ),
            child: Row(
              children: [
                Icon(Icons.crop_square_rounded, size: 16, color: t.border),
                const SizedBox(width: 8),
                Text('border',
                    style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: t.borderHighlight, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.highlight_rounded, size: 16, color: t.borderHighlight),
                const SizedBox(width: 8),
                Text('borderHighlight',
                    style: GoogleFonts.inter(fontSize: 12, color: t.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Color Editor ───

  Widget _buildBottomEditor() {
    final c = _activeColor;
    final r = (c.r * 255).roundToDouble();
    final g = (c.g * 255).roundToDouble();
    final b = (c.b * 255).roundToDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.bgCard,
        border: Border(top: BorderSide(color: AppConstants.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hex row
          Row(
            children: [
              // Color preview
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.border, width: 2),
                ),
              ),
              const SizedBox(width: 10),
              Text('#',
                  style: GoogleFonts.inter(
                      color: AppConstants.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Expanded(
                child: TextField(
                  controller: _hexController,
                  style: GoogleFonts.inter(
                      color: AppConstants.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    border: InputBorder.none,
                    hintText: 'FF5500',
                    hintStyle: GoogleFonts.inter(color: AppConstants.textMuted),
                  ),
                  maxLength: 6,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  onSubmitted: _applyHex,
                ),
              ),
              _miniIconButton(Icons.check_rounded, AppConstants.accentPrimary,
                  () => _applyHex(_hexController.text)),
              _miniIconButton(Icons.copy_rounded, AppConstants.textMuted, () {
                final hex =
                    '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                Clipboard.setData(ClipboardData(text: hex));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Copied $hex', style: GoogleFonts.inter()),
                      duration: const Duration(seconds: 1)),
                );
              }),
              _miniIconButton(Icons.paste_rounded, AppConstants.textMuted,
                  () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  _applyHex(data!.text!);
                }
              }),
            ],
          ),
          const SizedBox(height: 6),
          // RGB sliders — compact (push undo on start)
          _compactSlider('R', r, Colors.red, (v) {
            _setColorForField(
                _activeField, Color.fromARGB(255, v.toInt(), g.toInt(), b.toInt()));
            _syncHexField();
          }, onStart: _pushUndo),
          _compactSlider('G', g, Colors.green, (v) {
            _setColorForField(
                _activeField, Color.fromARGB(255, r.toInt(), v.toInt(), b.toInt()));
            _syncHexField();
          }, onStart: _pushUndo),
          _compactSlider('B', b, Colors.blue, (v) {
            _setColorForField(
                _activeField, Color.fromARGB(255, r.toInt(), g.toInt(), v.toInt()));
            _syncHexField();
          }, onStart: _pushUndo),
        ],
      ),
    );
  }

  Widget _compactSlider(
      String label, double value, Color activeColor, ValueChanged<double> onChanged,
      {VoidCallback? onStart}) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(label,
                style: GoogleFonts.inter(
                    color: activeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: activeColor,
                inactiveTrackColor: activeColor.withValues(alpha: 0.15),
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 255,
                onChangeStart: onStart != null ? (_) => onStart() : null,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(value.toInt().toString(),
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                    color: AppConstants.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _miniIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
