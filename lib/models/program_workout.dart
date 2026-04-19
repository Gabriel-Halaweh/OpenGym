import 'package:uuid/uuid.dart';
import 'week_workout.dart';

class ProgramWorkout {
  final String id;
  String? title;
  String? note;
  String? description;
  List<WeekWorkout> weeks;
  bool isTemplate;
  bool isActive;
  DateTime? startDate;
  DateTime? completedDate;

  ProgramWorkout({
    String? id,
    this.title,
    this.note,
    this.description,
    List<WeekWorkout>? weeks,
    this.isTemplate = false,
    this.isActive = true,
    this.startDate,
    this.completedDate,
  }) : id = id ?? const Uuid().v4(),
       weeks = weeks ?? [];

  String get displayTitle => title ?? 'Untitled Program';

  int get totalSets => weeks.fold(0, (sum, w) => sum + w.totalSets);

  int get completedSets => weeks.fold(0, (sum, w) => sum + w.completedSets);

  double get progress => totalSets == 0 ? 0.0 : completedSets / totalSets;

  bool get isCompleted => totalSets > 0 && completedSets == totalSets;

  ProgramWorkout deepCopy({bool asTemplate = false}) {
    return ProgramWorkout(
      title: title,
      note: note,
      description: description,
      weeks: weeks.map((w) => w.deepCopy(asTemplate: asTemplate)).toList(),
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
    'weeks': weeks.map((w) => w.toJson()).toList(),
    'isTemplate': isTemplate,
    'isActive': isActive,
    'startDate': startDate?.toIso8601String(),
    'completedDate': completedDate?.toIso8601String(),
  };

  factory ProgramWorkout.fromJson(Map<String, dynamic> json) {
    return ProgramWorkout(
      id: json['id'] as String,
      title: json['title'] as String?,
      note: json['note'] as String?,
      description: json['description'] as String?,
      weeks:
          (json['weeks'] as List?)
              ?.map((w) => WeekWorkout.fromJson(w as Map<String, dynamic>))
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
