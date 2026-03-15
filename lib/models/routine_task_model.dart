import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readRoutineDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class RoutineTaskModel {
  const RoutineTaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.date,
    this.completed = false,
  });

  final String id;
  final String userId;
  final String title;
  final String type;
  final DateTime date;
  final bool completed;

  RoutineTaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? type,
    DateTime? date,
    bool? completed,
  }) {
    return RoutineTaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'date': date,
      'completed': completed,
    };
  }

  factory RoutineTaskModel.fromMap(Map<String, dynamic> map) {
    return RoutineTaskModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? 'training',
      date: _readRoutineDate(map['date']),
      completed: map['completed'] == true,
    );
  }
}
