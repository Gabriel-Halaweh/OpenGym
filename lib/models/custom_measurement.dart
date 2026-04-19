import 'package:uuid/uuid.dart';

class CustomMeasurement {
  final String id;
  String type; // e.g., 'weight', 'body_fat', 'waist', etc.
  double value;
  String? unit; // e.g., 'lbs', 'kg', '%', 'in', 'cm'
  DateTime date;
  String? note;

  CustomMeasurement({
    String? id,
    required this.type,
    required this.value,
    this.unit,
    DateTime? date,
    this.note,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'value': value,
    'unit': unit,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory CustomMeasurement.fromJson(Map<String, dynamic> json) {
    return CustomMeasurement(
      id: json['id'] as String?,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String?,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}
