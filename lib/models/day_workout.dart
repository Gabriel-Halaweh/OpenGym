import 'package:uuid/uuid.dart';
import 'exercise_instance.dart';

class DayWorkout {
  final String id;
  String? title;
  String? note;
  String? description;
  int? dayOfWeek; // 0=Sun, 1=Mon, ... 6=Sat. Null for standalone templates.
  List<ExerciseInstance> exercises;
  bool isTemplate;
  bool isHidden;
  bool isActive;
  DateTime? scheduledDate;
  DateTime? startedDate;
  DateTime? completedDate;
  bool _isCompleted;

  DayWorkout({
    String? id,
    this.title,
    this.note,
    this.description,
    this.dayOfWeek,
    List<ExerciseInstance>? exercises,
    this.isTemplate = false,
    this.isHidden = false,
    this.isActive = true,
    this.scheduledDate,
    this.startedDate,
    this.completedDate,
    bool? isCompleted,
  }) : id = id ?? const Uuid().v4(),
       _isCompleted = isCompleted ?? false,
       exercises = exercises ?? [];

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String get dayName =>
      dayOfWeek != null ? dayNames[dayOfWeek!] : (title ?? 'Untitled Day');

  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return dayOfWeek != null ? '${dayNames[dayOfWeek!]} — $title' : title!;
    }
    return dayOfWeek != null ? dayNames[dayOfWeek!] : 'Untitled Day';
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.totalSets);

  int get completedSets => exercises.fold(0, (sum, e) => sum + e.completedSets);

  double get progress => totalSets == 0 ? 0.0 : completedSets / totalSets;

  bool get isFullyCompleted => totalSets > 0 && completedSets == totalSets;

  bool get isCompleted => _isCompleted || isFullyCompleted;

  set isCompleted(bool value) => _isCompleted = value;

  DayWorkout deepCopy({bool asTemplate = false}) {
    return DayWorkout(
      title: title,
      note: note,
      description: description,
      dayOfWeek: dayOfWeek,
      exercises: exercises.map((e) => e.deepCopy()).toList(),
      isTemplate: asTemplate,
      isHidden: isHidden,
      isActive: isActive,
      scheduledDate: asTemplate ? null : scheduledDate,
      startedDate: null,
      completedDate: null,
      isCompleted: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'description': description,
    'dayOfWeek': dayOfWeek,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'isTemplate': isTemplate,
    'isHidden': isHidden,
    'isActive': isActive,
    'scheduledDate': scheduledDate?.toIso8601String(),
    'startedDate': startedDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
    'isCompleted': _isCompleted,
  };

  factory DayWorkout.fromJson(Map<String, dynamic> json) {
    return DayWorkout(
      id: json['id'] as String,
      title: json['title'] as String?,
      note: json['note'] as String?,
      description: json['description'] as String?,
      dayOfWeek: json['dayOfWeek'] as int?,
      exercises:
          (json['exercises'] as List?)
              ?.map((e) => ExerciseInstance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isTemplate: json['isTemplate'] as bool? ?? false,
      isHidden: json['isHidden'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'] as String)
          : null,
      startedDate: json['startedDate'] != null
          ? DateTime.parse(json['startedDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}
