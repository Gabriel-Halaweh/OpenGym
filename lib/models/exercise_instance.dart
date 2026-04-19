import 'package:uuid/uuid.dart';
import 'exercise_set.dart';

enum TimerMode { none, stopwatch, countdown }

class ExerciseInstance {
  final String id;
  String exerciseDefinitionId;
  String exerciseName; // Cached name for display
  List<String> exerciseTags; // Cached tags
  List<ExerciseSet> sets;
  TimerMode timerMode;
  int timerDurationSeconds; // Default/original timer value
  bool usePercentage;
  bool isWeightedTimed;

  ExerciseInstance({
    String? id,
    required this.exerciseDefinitionId,
    required this.exerciseName,
    List<String>? exerciseTags,
    List<ExerciseSet>? sets,
    this.timerMode = TimerMode.none,
    this.timerDurationSeconds = 60,
    this.usePercentage = false,
    this.isWeightedTimed = false,
  }) : id = id ?? const Uuid().v4(),
       exerciseTags = exerciseTags ?? [],
       sets = sets ?? [ExerciseSet()];

  bool get isTimed => timerMode != TimerMode.none;

  int get totalSets => sets.length;

  int get completedSets => sets.where((s) => s.isChecked).length;

  double get progress => totalSets == 0 ? 0.0 : completedSets / totalSets;

  bool get isCompleted => totalSets > 0 && completedSets == totalSets;

  int get nextUncompletedTime {
    int? lastEffectiveTime;
    for (var set in sets) {
      // Keep track of the last non-null time we've seen
      if (set.timeSeconds != null && set.timeSeconds! > 0) {
        lastEffectiveTime = set.timeSeconds;
      }
      
      if (!set.isChecked) {
        // If this set has a specific time, use it
        if (set.timeSeconds != null && set.timeSeconds! > 0) {
          return set.timeSeconds!;
        }
        // If it's blank, assume the time of the previous field (lastEffectiveTime)
        if (lastEffectiveTime != null) {
          return lastEffectiveTime;
        }
        // Otherwise fallback to the exercise default
        return timerDurationSeconds;
      }
    }
    return timerDurationSeconds;
  }

  ExerciseInstance deepCopy() {
    return ExerciseInstance(
      exerciseDefinitionId: exerciseDefinitionId,
      exerciseName: exerciseName,
      exerciseTags: List.from(exerciseTags),
      sets: sets.map((s) => s.deepCopy()).toList(),
      timerMode: timerMode,
      timerDurationSeconds: timerDurationSeconds,
      usePercentage: usePercentage,
      isWeightedTimed: isWeightedTimed,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseDefinitionId': exerciseDefinitionId,
    'exerciseName': exerciseName,
    'exerciseTags': exerciseTags,
    'sets': sets.map((s) => s.toJson()).toList(),
    'timerMode': timerMode.index,
    'timerDurationSeconds': timerDurationSeconds,
    'usePercentage': usePercentage,
    'isWeightedTimed': isWeightedTimed,
  };

  factory ExerciseInstance.fromJson(Map<String, dynamic> json) {
    return ExerciseInstance(
      id: json['id'] as String,
      exerciseDefinitionId: json['exerciseDefinitionId'] as String,
      exerciseName: json['exerciseName'] as String,
      exerciseTags: List<String>.from(json['exerciseTags'] ?? []),
      sets: (json['sets'] as List)
          .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      timerMode: TimerMode.values[json['timerMode'] as int? ?? 0],
      timerDurationSeconds: json['timerDurationSeconds'] as int? ?? 60,
      usePercentage: json['usePercentage'] as bool? ?? false,
      isWeightedTimed: json['isWeightedTimed'] as bool? ?? false,
    );
  }
}
