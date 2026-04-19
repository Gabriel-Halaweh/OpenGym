import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_theme_profile.dart';
import '../data/preset_themes.dart';

class AppConstants {
  static AppThemeProfile theme = PresetThemes.defaultBlue;
  // ── Colors ──────────────────────────────────────────────────────
  static Color get bgDark => theme.bgDark;
  static Color get bgCard => theme.bgCard;
  static Color get bgCardHover => theme.bgCardHover;
  static Color get bgSurface => theme.bgSurface;
  static Color get bgElevated => theme.bgElevated;

  static Color get accentPrimary => theme.accentPrimary;
  static Color get accentSecondary => theme.accentSecondary;
  static Color get accentTertiary => theme.accentTertiary;
  static Color get accentWarm => theme.accentWarm;
  static Color get accentGold => theme.accentGold;

  static Color get textPrimary => theme.textPrimary;
  static Color get textSecondary => theme.textSecondary;
  static Color get textMuted => theme.textMuted;

  static Color get success => theme.success;
  static Color get warning => theme.warning;
  static Color get error => theme.error;
  static Color get info => theme.info;
  static Color get completion => theme.completion;

  static Color get border => theme.border;
  static Color get borderHighlight => theme.borderHighlight;

  // Progress bar colors
  static Color get progressProgram => theme.progressProgram;
  static Color get progressWeek => theme.progressWeek;
  static Color get progressDay => theme.progressDay;

  // ── Gradients ──────────────────────────────────────────────────
  static LinearGradient get accentGradient => theme.accentGradient;
  static LinearGradient get warmGradient => theme.warmGradient;
  static LinearGradient get purpleGradient => theme.purpleGradient;
  static LinearGradient get progressGradient => theme.progressGradient;
  static LinearGradient get completedGradient => theme.completedGradient;

  // ── Spacing ───────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // ── Animation Durations ───────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);

  // ── Android Bottom Nav Safety ─────────────────────────────────
  static const double bottomNavSafety = 0.0; // SafeArea handles this

  // ── Theme ─────────────────────────────────────────────────────
  static void updateTheme(AppThemeProfile newTheme) {
    theme = newTheme;
  }

  static ThemeData getTheme(AppThemeProfile currentTheme) {
    updateTheme(currentTheme);
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentPrimary,
      colorScheme: ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        tertiary: accentTertiary,
        surface: bgCard,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
        outline: border,
      ),
      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: paddingMD,
          vertical: paddingSM,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
      ),
      iconTheme: IconThemeData(color: textSecondary, size: 22),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 0),
      tabBarTheme: TabBarThemeData(
        indicatorColor: accentPrimary,
        labelColor: accentPrimary,
        unselectedLabelColor: textMuted,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgSurface,
        selectedColor: accentPrimary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: textSecondary),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          borderSide: BorderSide(color: accentPrimary, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        hintStyle: GoogleFonts.inter(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMD,
          vertical: paddingSM + 4,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.inter(fontSize: 12, color: textMuted),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgElevated,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
    );
  }
}
