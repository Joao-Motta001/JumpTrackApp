import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _readJumpDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

class JumpModel {
  const JumpModel({
    required this.id,
    required this.userId,
    required this.heightCm,
    required this.airtimeSeconds,
    required this.method,
    required this.timestamp,
    this.videoUrl,
  });

  final String id;
  final String userId;
  final double heightCm;
  final double airtimeSeconds;
  final String method;
  final DateTime timestamp;
  final String? videoUrl;

  JumpModel copyWith({
    String? id,
    String? userId,
    double? heightCm,
    double? airtimeSeconds,
    String? method,
    DateTime? timestamp,
    String? videoUrl,
  }) {
    return JumpModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      heightCm: heightCm ?? this.heightCm,
      airtimeSeconds: airtimeSeconds ?? this.airtimeSeconds,
      method: method ?? this.method,
      timestamp: timestamp ?? this.timestamp,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'heightCm': heightCm,
      'airtimeSeconds': airtimeSeconds,
      'method': method,
      'timestamp': timestamp,
      'videoUrl': videoUrl,
    };
  }

  factory JumpModel.fromMap(Map<String, dynamic> map) {
    return JumpModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 0,
      airtimeSeconds: (map['airtimeSeconds'] as num?)?.toDouble() ?? 0,
      method: map['method']?.toString() ?? 'manual',
      timestamp: _readJumpDate(map['timestamp']),
      videoUrl: map['videoUrl']?.toString(),
    );
  }
}
