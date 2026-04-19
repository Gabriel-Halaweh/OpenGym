import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_theme_profile.dart';
import '../data/preset_themes.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;

  static const String defaultThemeId = 'preset_default';

  late AppThemeProfile _currentTheme;
  List<AppThemeProfile> _customThemes = [];

  ThemeProvider(this._storageService) {
    _loadThemeData();
  }

  AppThemeProfile get theme => _currentTheme;
  List<AppThemeProfile> get presets => PresetThemes.all;
  List<AppThemeProfile> get customThemes => _customThemes;

  List<AppThemeProfile> get allThemes => [
    ...PresetThemes.all,
    ..._customThemes,
  ];

  void _loadThemeData() {
    // Load custom themes
    final customThemeJsons = _storageService.getCustomThemes();
    _customThemes = customThemeJsons
        .map((jsonStr) => AppThemeProfile.fromJson(jsonDecode(jsonStr)))
        .toList();

    // Load active theme
    final activeId = _storageService.getActiveThemeId() ?? defaultThemeId;
    _currentTheme = allThemes.firstWhere(
      (t) => t.id == activeId,
      orElse: () => PresetThemes.defaultBlue,
    );
    AppConstants.theme = _currentTheme;
  }

  void setTheme(String id) {
    final newTheme = allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => PresetThemes.defaultBlue,
    );
    _currentTheme = newTheme;
    AppConstants.theme = newTheme;
    _storageService.saveActiveThemeId(id);
    notifyListeners();
  }

  void addCustomTheme(AppThemeProfile themeProfile) {
    // If updating existing custom theme
    final index = _customThemes.indexWhere((t) => t.id == themeProfile.id);
    if (index >= 0) {
      _customThemes[index] = themeProfile;
    } else {
      _customThemes.add(themeProfile);
    }
    _saveCustomThemes();

    if (_currentTheme.id == themeProfile.id) {
      _currentTheme = themeProfile;
      AppConstants.theme = themeProfile;
      notifyListeners();
    }
  }

  void deleteCustomTheme(String id) {
    _customThemes.removeWhere((t) => t.id == id);
    _saveCustomThemes();

    if (_currentTheme.id == id) {
      setTheme(defaultThemeId);
    } else {
      notifyListeners();
    }
  }

  void _saveCustomThemes() {
    final jsons = _customThemes.map((t) => jsonEncode(t.toJson())).toList();
    _storageService.saveCustomThemes(jsons);
  }
}
