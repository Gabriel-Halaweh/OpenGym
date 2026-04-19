import 'package:uuid/uuid.dart';

class ExerciseDefinition {
  final String id;
  String name;
  List<String> tags;
  int timerMode; // 0: none, 1: stopwatch, 2: countdown
  int timerDurationSeconds;
  bool usePercentage;
  bool isWeightedTimed;
  String defaultAlbum;

  ExerciseDefinition({
    String? id,
    required this.name,
    List<String>? tags,
    this.timerMode = 0,
    this.timerDurationSeconds = 60,
    this.usePercentage = false,
    this.isWeightedTimed = false,
    this.defaultAlbum = "",
  })  : id = id ?? const Uuid().v4(),
        tags = tags ?? [];

  ExerciseDefinition copyWith({
    String? name,
    List<String>? tags,
    int? timerMode,
    int? timerDurationSeconds,
    bool? usePercentage,
    bool? isWeightedTimed,
    String? defaultAlbum,
  }) {
    return ExerciseDefinition(
      id: id,
      name: name ?? this.name,
      tags: tags ?? List.from(this.tags),
      timerMode: timerMode ?? this.timerMode,
      timerDurationSeconds: timerDurationSeconds ?? this.timerDurationSeconds,
      usePercentage: usePercentage ?? this.usePercentage,
      isWeightedTimed: isWeightedTimed ?? this.isWeightedTimed,
      defaultAlbum: defaultAlbum ?? this.defaultAlbum,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tags': tags,
        'timerMode': timerMode,
        'timerDurationSeconds': timerDurationSeconds,
        'usePercentage': usePercentage,
        'isWeightedTimed': isWeightedTimed,
        'defaultAlbum': defaultAlbum,
      };

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) {
    return ExerciseDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      timerMode: json['timerMode'] as int? ?? 0,
      timerDurationSeconds: json['timerDurationSeconds'] as int? ?? 60,
      usePercentage: json['usePercentage'] as bool? ?? false,
      isWeightedTimed: json['isWeightedTimed'] as bool? ?? false,
      defaultAlbum: json['defaultAlbum'] as String? ?? "",
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
