import 'package:uuid/uuid.dart';

class ExerciseSet {
  final String id;
  int? reps;
  double? value;
  double? weight; // Added for weighted-timed exercises
  double? percent; // Original percentage of max
  bool isChecked;
  int? timeSeconds; // For timed exercises
  bool isPercentage; // Not really used if we have percent, but keeping for compatibility

  ExerciseSet({
    String? id,
    this.reps,
    this.value,
    this.weight,
    this.percent,
    this.isChecked = false,
    this.timeSeconds,
    this.isPercentage = false,
  }) : id = id ?? const Uuid().v4();

  ExerciseSet deepCopy() {
    return ExerciseSet(
      reps: reps,
      value: value,
      weight: weight,
      percent: percent,
      isChecked: false, // Reset on copy
      timeSeconds: timeSeconds,
      isPercentage: isPercentage,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reps': reps,
    'value': value,
    'weight': weight,
    'percent': percent, // Save percent
    'isChecked': isChecked,
    'timeSeconds': timeSeconds,
    'isPercentage': isPercentage,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'] as String,
      reps: json['reps'] as int?,
      value: (json['value'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      percent: (json['percent'] as num?)?.toDouble(), // Load percent
      isChecked: json['isChecked'] as bool? ?? false,
      timeSeconds: json['timeSeconds'] as int?,
      isPercentage: json['isPercentage'] as bool? ?? false,
    );
  }
}
