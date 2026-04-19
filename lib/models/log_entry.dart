import 'package:uuid/uuid.dart';

class LogEntry {
  final String id;
  final String type; // 'day', 'week', 'program'
  final String title;
  final DateTime completedDate;
  final DateTime? startDate;
  final int totalSets;
  final int completedSets;
  final Map<String, dynamic> workoutData; // Snapshot of the workout

  LogEntry({
    String? id,
    required this.type,
    required this.title,
    required this.completedDate,
    this.startDate,
    required this.totalSets,
    required this.completedSets,
    required this.workoutData,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'completedDate': completedDate.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'totalSets': totalSets,
    'completedSets': completedSets,
    'workoutData': workoutData,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      completedDate: DateTime.parse(json['completedDate'] as String),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      totalSets: json['totalSets'] as int,
      completedSets: json['completedSets'] as int,
      workoutData: json['workoutData'] as Map<String, dynamic>,
    );
  }
}
