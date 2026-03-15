import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.volleyballPosition,
    required this.trainingDays,
    required this.matchDays,
    required this.goals,
    this.workoutCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String email;
  final String name;
  final int age;
  final double height;
  final double weight;
  final String volleyballPosition;
  final int trainingDays;
  final int matchDays;
  final List<String> goals;
  final int workoutCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? userId,
    String? email,
    String? name,
    int? age,
    double? height,
    double? weight,
    String? volleyballPosition,
    int? trainingDays,
    int? matchDays,
    List<String>? goals,
    int? workoutCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      volleyballPosition: volleyballPosition ?? this.volleyballPosition,
      trainingDays: trainingDays ?? this.trainingDays,
      matchDays: matchDays ?? this.matchDays,
      goals: goals ?? this.goals,
      workoutCount: workoutCount ?? this.workoutCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'volleyballPosition': volleyballPosition,
      'trainingDays': trainingDays,
      'matchDays': matchDays,
      'goals': goals,
      'workoutCount': workoutCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toDouble() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      volleyballPosition: map['volleyballPosition']?.toString() ?? '',
      trainingDays: (map['trainingDays'] as num?)?.toInt() ?? 0,
      matchDays: (map['matchDays'] as num?)?.toInt() ?? 0,
      goals: List<String>.from(map['goals'] ?? const <String>[]),
      workoutCount: (map['workoutCount'] as num?)?.toInt() ?? 0,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }
}
