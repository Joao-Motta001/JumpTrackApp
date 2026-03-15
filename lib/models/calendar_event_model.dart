import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readEventDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class CalendarEventModel {
  const CalendarEventModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.description = '',
  });

  final String id;
  final String userId;
  final String title;
  final String type;
  final DateTime startTime;
  final DateTime endTime;
  final String description;

  CalendarEventModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    String? description,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
    };
  }

  factory CalendarEventModel.fromMap(Map<String, dynamic> map) {
    return CalendarEventModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      type: map['type']?.toString() ?? 'training',
      startTime: _readEventDate(map['startTime']),
      endTime: _readEventDate(map['endTime']),
      description: map['description']?.toString() ?? '',
    );
  }
}
