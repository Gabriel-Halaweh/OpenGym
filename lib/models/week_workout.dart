import 'package:uuid/uuid.dart';
import 'day_workout.dart';

class WeekWorkout {
  final String id;
  String? title;
  String? note;
  String? description;
  List<DayWorkout> days; // Up to 7 days, mapped to dayOfWeek
  bool isTemplate;
  bool isActive;
  DateTime? startDate; // Sunday of the week
  DateTime? completedDate;

  WeekWorkout({
    String? id,
    this.title,
    this.note,
    this.description,
    List<DayWorkout>? days,
    this.isTemplate = false,
    this.isActive = true,
    this.startDate,
    this.completedDate,
  }) : id = id ?? const Uuid().v4(),
       days = days ?? [];

  String get displayTitle => title ?? 'Untitled Week';

  int get totalSets =>
      days.where((d) => !d.isHidden).fold(0, (sum, d) => sum + d.totalSets);

  int get completedSets =>
      days.where((d) => !d.isHidden).fold(0, (sum, d) => sum + d.completedSets);

  double get progress => totalSets == 0 ? 0.0 : completedSets / totalSets;

  bool get isCompleted => totalSets > 0 && completedSets == totalSets;

  /// Get the day for a specific day of week (0=Sun..6=Sat) or null
  DayWorkout? getDayForWeekday(int dayOfWeek) {
    try {
      return days.firstWhere((d) => d.dayOfWeek == dayOfWeek);
    } catch (_) {
      return null;
    }
  }

  WeekWorkout deepCopy({bool asTemplate = false}) {
    return WeekWorkout(
      title: title,
      note: note,
      description: description,
      days: days.map((d) => d.deepCopy(asTemplate: asTemplate)).toList(),
      isTemplate: asTemplate,
      isActive: isActive,
      startDate: asTemplate ? null : startDate,
      completedDate: null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'note': note,
    'description': description,
    'days': days.map((d) => d.toJson()).toList(),
    'isTemplate': isTemplate,
    'isActive': isActive,
    'startDate': startDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
  };

  factory WeekWorkout.fromJson(Map<String, dynamic> json) {
    return WeekWorkout(
      id: json['id'] as String,
      title: json['title'] as String?,
      note: json['note'] as String?,
      description: json['description'] as String?,
      days:
          (json['days'] as List?)
              ?.map((d) => DayWorkout.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      isTemplate: json['isTemplate'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
    );
  }
}
