import 'package:flutter/material.dart';

class AppThemeProfile {
  final String id;
  final String name;
  final bool isCustom;

  // Backgrounds
  final Color bgDark;
  final Color bgCard;
  final Color bgCardHover;
  final Color bgSurface;
  final Color bgElevated;

  // Accents
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color accentWarm;
  final Color accentGold;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color completion;

  // Borders
  final Color border;
  final Color borderHighlight;

  // Progress bar colors
  final Color progressProgram;
  final Color progressWeek;
  final Color progressDay;

  const AppThemeProfile({
    required this.id,
    required this.name,
    this.isCustom = false,
    required this.bgDark,
    required this.bgCard,
    required this.bgCardHover,
    required this.bgSurface,
    required this.bgElevated,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentWarm,
    required this.accentGold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.completion,
    required this.border,
    required this.borderHighlight,
    required this.progressProgram,
    required this.progressWeek,
    required this.progressDay,
  });

  // Derived Gradients
  LinearGradient get accentGradient => LinearGradient(
    colors: [accentPrimary, accentSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get warmGradient => LinearGradient(
    colors: [accentWarm, accentGold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get purpleGradient => LinearGradient(
    colors: [accentTertiary, accentPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  LinearGradient get progressGradient =>
      LinearGradient(colors: [success.withValues(alpha: 0.7), success]);

  LinearGradient get completedGradient =>
      LinearGradient(colors: [completion, completion.withValues(alpha: 0.7)]);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCustom': isCustom,
      'bgDark': bgDark.toARGB32(),
      'bgCard': bgCard.toARGB32(),
      'bgCardHover': bgCardHover.toARGB32(),
      'bgSurface': bgSurface.toARGB32(),
      'bgElevated': bgElevated.toARGB32(),
      'accentPrimary': accentPrimary.toARGB32(),
      'accentSecondary': accentSecondary.toARGB32(),
      'accentTertiary': accentTertiary.toARGB32(),
      'accentWarm': accentWarm.toARGB32(),
      'accentGold': accentGold.toARGB32(),
      'textPrimary': textPrimary.toARGB32(),
      'textSecondary': textSecondary.toARGB32(),
      'textMuted': textMuted.toARGB32(),
      'success': success.toARGB32(),
      'warning': warning.toARGB32(),
      'error': error.toARGB32(),
      'info': info.toARGB32(),
      'completion': completion.toARGB32(),
      'border': border.toARGB32(),
      'borderHighlight': borderHighlight.toARGB32(),
      'progressProgram': progressProgram.toARGB32(),
      'progressWeek': progressWeek.toARGB32(),
      'progressDay': progressDay.toARGB32(),
    };
  }

  factory AppThemeProfile.fromJson(Map<String, dynamic> json) {
    return AppThemeProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      isCustom: json['isCustom'] as bool? ?? true,
      bgDark: Color(json['bgDark'] as int),
      bgCard: Color(json['bgCard'] as int),
      bgCardHover: Color(json['bgCardHover'] as int),
      bgSurface: Color(json['bgSurface'] as int),
      bgElevated: Color(json['bgElevated'] as int),
      accentPrimary: Color(json['accentPrimary'] as int),
      accentSecondary: Color(json['accentSecondary'] as int),
      accentTertiary: Color(json['accentTertiary'] as int),
      accentWarm: Color(json['accentWarm'] as int),
      accentGold: Color(json['accentGold'] as int),
      textPrimary: Color(json['textPrimary'] as int),
      textSecondary: Color(json['textSecondary'] as int),
      textMuted: Color(json['textMuted'] as int),
      success: Color(json['success'] as int),
      warning: Color(json['warning'] as int),
      error: Color(json['error'] as int),
      info: Color(json['info'] as int),
      completion: json['completion'] != null
          ? Color(json['completion'] as int)
          : Color(json['success'] as int),
      border: Color(json['border'] as int),
      borderHighlight: Color(json['borderHighlight'] as int),
      progressProgram: json['progressProgram'] != null
          ? Color(json['progressProgram'] as int)
          : Color(json['accentTertiary'] as int),
      progressWeek: json['progressWeek'] != null
          ? Color(json['progressWeek'] as int)
          : Color(json['accentSecondary'] as int),
      progressDay: json['progressDay'] != null
          ? Color(json['progressDay'] as int)
          : Color(json['success'] as int),
    );
  }

  AppThemeProfile copyWith({
    String? id,
    String? name,
    bool? isCustom,
    Color? bgDark,
    Color? bgCard,
    Color? bgCardHover,
    Color? bgSurface,
    Color? bgElevated,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? accentTertiary,
    Color? accentWarm,
    Color? accentGold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? completion,
    Color? border,
    Color? borderHighlight,
    Color? progressProgram,
    Color? progressWeek,
    Color? progressDay,
  }) {
    return AppThemeProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isCustom: isCustom ?? this.isCustom,
      bgDark: bgDark ?? this.bgDark,
      bgCard: bgCard ?? this.bgCard,
      bgCardHover: bgCardHover ?? this.bgCardHover,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      accentTertiary: accentTertiary ?? this.accentTertiary,
      accentWarm: accentWarm ?? this.accentWarm,
      accentGold: accentGold ?? this.accentGold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      completion: completion ?? this.completion,
      border: border ?? this.border,
      borderHighlight: borderHighlight ?? this.borderHighlight,
      progressProgram: progressProgram ?? this.progressProgram,
      progressWeek: progressWeek ?? this.progressWeek,
      progressDay: progressDay ?? this.progressDay,
    );
  }
}
