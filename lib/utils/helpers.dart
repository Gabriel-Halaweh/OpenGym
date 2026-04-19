import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  /// Format duration from seconds to MM:SS or HH:MM:SS
  static String formatDuration(int totalSeconds) {
    if (totalSeconds < 0) return '00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format final duration into textual units (e.g. 45D 12H 32M 25S)
  static String formatDurationLong(int totalSeconds) {
    if (totalSeconds <= 0) return '0S';
    final int days = totalSeconds ~/ 86400;
    final int hours = (totalSeconds % 86400) ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    final List<String> parts = [];
    if (days > 0) parts.add('${days}D');
    if (hours > 0) parts.add('${hours}H');
    if (minutes > 0) parts.add('${minutes}M');
    if (seconds > 0 || parts.isEmpty) parts.add('${seconds}S');

    return parts.join(' ');
  }

  /// Parse MM:SS or HH:MM:SS string to total seconds
  static int? parseDuration(String text) {
    final parts = text.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]);
      final s = int.tryParse(parts[1]);
      if (m != null && s != null) return m * 60 + s;
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final s = int.tryParse(parts[2]);
      if (h != null && m != null && s != null) {
        return h * 3600 + m * 60 + s;
      }
    }
    // Try parsing as raw seconds
    return int.tryParse(text);
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('d MMM, yyyy').format(date);
  }

  /// Format date for short display
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  /// Get the Sunday of the week containing the given date
  static DateTime getSundayOfWeek(DateTime date) {
    final daysSinceSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysSinceSunday);
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Progress percentage string
  static String progressPercent(double progress) {
    return '${(progress * 100).round()}%';
  }

  /// Detailed summary of an exercise session (e.g. "3 sets of 10 @ 100")
  static String getExerciseSummary(dynamic ex, {double? refWeight, bool showReps = true}) {
    if (ex.sets.isEmpty) return 'No sets';

    final setCounts = ex.sets.length;
    final firstSet = ex.sets.first;

    // Helper to get assumed time
    int? lastSeenTime;
    final List<int> effectiveTimes = [];
    for (final s in ex.sets) {
      final t = s.timeSeconds ?? s.value?.toInt();
      if (t != null && t > 0) {
        lastSeenTime = t;
        effectiveTimes.add(t);
      } else {
        effectiveTimes.add(lastSeenTime ?? ex.timerDurationSeconds);
      }
    }

    // Check if all sets are identical (reps + value/weight + effective time)
    bool uniform = true;
    for (var i = 1; i < ex.sets.length; i++) {
      final s = ex.sets[i];
      final prevS = ex.sets[i-1];
      if (s.reps != firstSet.reps ||
          (ex.isWeightedTimed ? s.weight != firstSet.weight : s.value != firstSet.value) ||
          (ex.isTimed && effectiveTimes[i] != effectiveTimes[0])) {
        uniform = false;
        break;
      }
    }

    String valStr(num? v) => v?.toInt().toString() ?? '-';
    
    String timeStr(int? s) {
      if (s == null || s <= 0) return '0S';
      return formatDurationLong(s);
    }

    if (uniform) {
      final reps = showReps ? "${firstSet.reps ?? 0} " : "";
      final time = timeStr(effectiveTimes[0]);

      if (ex.usePercentage) {
        final pctValue = firstSet.percent ?? (ex.isWeightedTimed ? (firstSet.weight ?? 0.0) : (firstSet.value ?? 0.0));
        if (refWeight != null && refWeight > 0) {
          final calculated = (pctValue / 100 * refWeight).round();
          if (ex.isTimed) {
            return '$setCounts sets $reps@ ${valStr(pctValue)}% ($calculated) for $time';
          }
          return '$setCounts sets $reps@ ${valStr(pctValue)}% ($calculated)';
        }
        if (ex.isTimed) {
          return '$setCounts sets $reps@ ${valStr(pctValue)}% for $time';
        }
        return '$setCounts sets $reps@ ${valStr(pctValue)}%';
      }

      if (ex.isTimed) {
        if (ex.isWeightedTimed) {
          final weight = firstSet.weight?.toInt() ?? 0;
          return '$setCounts sets $reps@ $weight for $time';
        }
        return '$setCounts sets of $time';
      }

      return '$setCounts sets $reps@ ${valStr(firstSet.value)}';
    } else {
      // Varying logic: list individual sets
      final List<String> parts = [];
      for (int i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        final sReps = showReps ? "${s.reps ?? 0}x" : "";
        final sTime = timeStr(effectiveTimes[i]);

        if (ex.usePercentage) {
          final pctValue = s.percent ?? (ex.isWeightedTimed ? (s.weight ?? 0.0) : (s.value ?? 0.0));
          String entry = "${valStr(pctValue)}%";
          if (refWeight != null && refWeight > 0) {
            entry += " (${(pctValue / 100 * refWeight).round()})";
          }
          if (ex.isTimed) {
            parts.add("$sReps$entry @ $sTime");
          } else {
            parts.add("$sReps$entry");
          }
        } else if (ex.isTimed) {
          if (ex.isWeightedTimed) {
            final weight = s.weight?.toInt() ?? 0;
            parts.add("$sReps$weight @ $sTime");
          } else {
            parts.add(sTime);
          }
        } else {
          parts.add("$sReps${valStr(s.value)}");
        }
      }
      return parts.join(", ");
    }
  }

  /// Get magnitude unit and divisor based on a maximum value
  static (String, double) getMagnitudeInfo(double maxValue) {
    if (maxValue.isInfinite || maxValue.isNaN || maxValue < 1000) {
      return ('', 1.0);
    }
    const units = ['k', 'm', 'b', 't', 'q', 'Q', 's'];
    double divisor = 1.0;
    String unit = '';
    
    for (int i = 0; i < units.length; i++) {
      if (maxValue / (divisor * 1000) >= 1) {
        divisor *= 1000;
        unit = units[i];
      } else {
        break;
      }
    }
    return (unit, divisor);
  }

  /// Format a value using a specific divisor and unit, with precision
  static String formatWithMagnitude(double value, double divisor, String unit, {int precision = 3}) {
    if (value.isInfinite || value.isNaN) return '∞';
    final scaled = value / divisor;
    if (value == 0) return '0$unit';
    
    // Remove trailing zeros for a cleaner look while keeping precision
    String formatted = scaled.toStringAsFixed(precision);
    if (formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return '$formatted$unit';
  }

  /// Format a number to a compact string (e.g., 1.5k for 1500)
  static String formatCompactNumber(double value) {
    final (unit, divisor) = getMagnitudeInfo(value);
    return formatWithMagnitude(value, divisor, unit, precision: 1);
  }

  /// Get a rounded maxY and nice interval for charts, targeting a specific number of increments.
  static (double, double) getAxisSpecs(double maxValue, {int increments = 8}) {
    if (maxValue <= 0) return (10.0, 1.25);
    
    // Crude interval to cover the range in roughly 'increments' steps
    double crudeInterval = maxValue / increments;
    
    // Scaling factor to work with normalized numbers near 1-10
    double exponent = (log(crudeInterval) / ln10).floorToDouble();
    double normalized = crudeInterval / pow(10, exponent);
    
    // Pick next nice step: 1.0, 1.25, 2.0, 2.5, 4.0, 5.0, 10.0
    double niceNormalized;
    if (normalized <= 1.0) niceNormalized = 1.0;
    else if (normalized <= 1.25) niceNormalized = 1.25;
    else if (normalized <= 2.0) niceNormalized = 2.0;
    else if (normalized <= 2.5) niceNormalized = 2.5;
    else if (normalized <= 4.0) niceNormalized = 4.0;
    else if (normalized <= 5.0) niceNormalized = 5.0;
    else niceNormalized = 10.0;
    
    double interval = niceNormalized * pow(10, exponent);
    
    // Adjust niceNormalized if interval * increments < maxValue
    while (interval * increments < maxValue) {
      if (niceNormalized == 1.0) niceNormalized = 1.25;
      else if (niceNormalized == 1.25) niceNormalized = 2.0;
      else if (niceNormalized == 2.0) niceNormalized = 2.5;
      else if (niceNormalized == 2.5) niceNormalized = 4.0;
      else if (niceNormalized == 4.0) niceNormalized = 5.0;
      else if (niceNormalized == 5.0) niceNormalized = 10.0;
      else { 
        niceNormalized = 1.0; 
        exponent += 1; 
      }
      interval = niceNormalized * pow(10, exponent);
    }
    
    return (interval * increments, interval);
  }

  /// Get a rounded maxY and nice interval for charts, specifically tailored to time/duration seconds.
  static (double, double) getTimeAxisSpecs(double maxSeconds, {int increments = 5}) {
    if (maxSeconds <= 0) return (10.0, 2.0);
    
    // Define clean rounded intervals in seconds
    final List<int> cleanIntervals = [
      1, 2, 5, 10, 15, 30, // seconds
      60, 120, 300, 600, 900, 1800, // 1m, 2m, 5m, 10m, 15m, 30m
      3600, 7200, 14400, 28800, 43200, // 1h, 2h, 4h, 8h, 12h
      86400, 172800, 432000, 864000, 1296000, 2592000 // 1d, 2d, 5d, 10d, 15d, 30d
    ];
    
    double crudeInterval = maxSeconds / increments;
    double bestInterval = cleanIntervals.last.toDouble();
    
    for (final interval in cleanIntervals) {
      // Find the first clean interval that covers the crude step size
      if (interval >= crudeInterval) {
        bestInterval = interval.toDouble();
        break;
      }
    }
    
    // Sometimes the clean interval is slightly too small to cover maxSeconds within 'increments' steps,
    // so we just increase the number of increments needed to cover.
    int steps = increments;
    while (bestInterval * steps < maxSeconds) {
      steps++;
    }
    
    return (bestInterval * steps, bestInterval);
  }

  /// Format an exercise name:
  /// - Trim leading/trailing whitespace
  /// - Replace multiple spaces with single space
  /// - Capitalize each word (Title Case)
  /// - Keep punctuation as is
  static String formatExerciseName(String name) {
    if (name.isEmpty) return name;
    
    // Replace multiple spaces with single space and trim
    String result = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    if (result.isEmpty) return result;

    // Title Case: Capitalize first letter of each word
    return result.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.length == 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Create a key for uniqueness comparison:
  /// - Strip all whitespace
  /// - Lowercase
  /// - Strip all punctuation
  static String toUniquenessKey(String name) {
    // Lowercase and strip all non-alphanumeric characters (except maybe digits)
    // Actually the user said "strip whitespace, capitalization and punctuations"
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '');
  }
}
