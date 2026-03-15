import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readWorkoutDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class ExerciseModel {
  const ExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    this.notes = '',
    this.videoUrl = '',
    this.completed = false,
  });

  final String name;
  final int sets;
  final int reps;
  final double weight;
  final String notes;
  final String videoUrl;
  final bool completed;

  ExerciseModel copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weight,
    String? notes,
    String? videoUrl,
    bool? completed,
  }) {
    return ExerciseModel(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'notes': notes,
      'videoUrl': videoUrl,
      'completed': completed,
    };
  }

  factory ExerciseModel.fromMap(Map<String, dynamic> map) {
    return ExerciseModel(
      name: map['name']?.toString() ?? '',
      sets: (map['sets'] as num?)?.toInt() ?? 0,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      notes: map['notes']?.toString() ?? '',
      videoUrl: map['videoUrl']?.toString() ?? '',
      completed: map['completed'] == true,
    );
  }
}

class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.exercises,
    required this.createdAt,
    required this.scheduledAt,
    this.completed = false,
    this.durationSeconds = 0,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final List<ExerciseModel> exercises;
  final DateTime createdAt;
  final DateTime scheduledAt;
  final bool completed;
  final int durationSeconds;
  final DateTime? completedAt;

  WorkoutModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<ExerciseModel>? exercises,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? completed,
    int? durationSeconds,
    DateTime? completedAt,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completed: completed ?? this.completed,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'scheduledAt': scheduledAt,
      'completed': completed,
      'durationSeconds': durationSeconds,
      'completedAt': completedAt,
    };
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      exercises: (map['exercises'] as List<dynamic>? ?? const [])
          .map((item) => ExerciseModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      createdAt: _readWorkoutDate(map['createdAt']),
      scheduledAt: _readWorkoutDate(map['scheduledAt']),
      completed: map['completed'] == true,
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      completedAt: map['completedAt'] == null ? null : _readWorkoutDate(map['completedAt']),
    );
  }
}
