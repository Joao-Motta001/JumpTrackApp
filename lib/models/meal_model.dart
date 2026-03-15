import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readMealDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class MealModel {
  const MealModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.timestamp,
    this.barcode,
    this.source = 'manual',
    this.imageUrl,
    this.servingSize,
  });

  final String id;
  final String userId;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime timestamp;
  final String? barcode;
  final String source;
  final String? imageUrl;
  final String? servingSize;

  MealModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? timestamp,
    String? barcode,
    String? source,
    String? imageUrl,
    String? servingSize,
  }) {
    return MealModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      timestamp: timestamp ?? this.timestamp,
      barcode: barcode ?? this.barcode,
      source: source ?? this.source,
      imageUrl: imageUrl ?? this.imageUrl,
      servingSize: servingSize ?? this.servingSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'timestamp': timestamp,
      'barcode': barcode,
      'source': source,
      'imageUrl': imageUrl,
      'servingSize': servingSize,
    };
  }

  factory MealModel.fromMap(Map<String, dynamic> map) {
    return MealModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      timestamp: _readMealDate(map['timestamp']),
      barcode: map['barcode']?.toString(),
      source: map['source']?.toString() ?? 'manual',
      imageUrl: map['imageUrl']?.toString(),
      servingSize: map['servingSize']?.toString(),
    );
  }
}
