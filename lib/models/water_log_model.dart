import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readWaterDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class WaterLogModel {
  const WaterLogModel({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.timestamp,
  });

  final String id;
  final String userId;
  final int amountMl;
  final DateTime timestamp;

  WaterLogModel copyWith({
    String? id,
    String? userId,
    int? amountMl,
    DateTime? timestamp,
  }) {
    return WaterLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amountMl: amountMl ?? this.amountMl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amountMl': amountMl,
      'timestamp': timestamp,
    };
  }

  factory WaterLogModel.fromMap(Map<String, dynamic> map) {
    return WaterLogModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      amountMl: (map['amountMl'] as num?)?.toInt() ?? 0,
      timestamp: _readWaterDate(map['timestamp']),
    );
  }
}
