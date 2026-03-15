import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_pose_detection/flutter_pose_detection.dart';

class JumpAnalysisResult {
  const JumpAnalysisResult({
    required this.jumpHeightCm,
    required this.airtimeSeconds,
    required this.bestHipTravel,
    required this.detectionRate,
    required this.accelerationMode,
  });

  final double jumpHeightCm;
  final double airtimeSeconds;
  final double bestHipTravel;
  final double detectionRate;
  final String accelerationMode;
}

class JumpAiService {
  JumpAiService() : _detector = NpuPoseDetector(config: PoseDetectorConfig.realtime());

  final NpuPoseDetector _detector;
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _detector.initialize();
    _detector.videoAnalysisProgress.listen((dynamic event) {
      try {
        progress.value = (event.progress as num).toDouble();
      } catch (_) {}
    });
    _initialized = true;
  }

  Future<JumpAnalysisResult> analyzeVideo(String videoPath) async {
    await _ensureInitialized();
    progress.value = 0;
    final dynamic result = await _detector.analyzeVideo(videoPath, frameInterval: 3);

    final List<_FrameMeasurement> frames = [];
    for (final dynamic frame in result.frames as Iterable<dynamic>) {
      final dynamic poseResult = frame.result;
      if (poseResult == null || poseResult.hasPoses != true) continue;
      final dynamic pose = poseResult.firstPose;
      if (pose == null) continue;

      final dynamic leftHip = pose.getLandmark(LandmarkType.leftHip);
      final dynamic rightHip = pose.getLandmark(LandmarkType.rightHip);
      final dynamic leftAnkle = pose.getLandmark(LandmarkType.leftAnkle);
      final dynamic rightAnkle = pose.getLandmark(LandmarkType.rightAnkle);
      if (leftHip == null || rightHip == null || leftAnkle == null || rightAnkle == null) continue;

      final hipY = ((leftHip.y as num).toDouble() + (rightHip.y as num).toDouble()) / 2;
      final ankleY = ((leftAnkle.y as num).toDouble() + (rightAnkle.y as num).toDouble()) / 2;
      final stamp = (frame.timestampSeconds as num?)?.toDouble() ?? 0;
      frames.add(_FrameMeasurement(timestamp: stamp, hipY: hipY, ankleY: ankleY));
    }

    if (frames.length < 6) {
      throw Exception('Not enough pose frames detected. Try recording in better lighting.');
    }

    final baselineFrames = frames.take(6).toList();
    final baselineHip = baselineFrames.map((e) => e.hipY).reduce((a, b) => a + b) / baselineFrames.length;
    final baselineAnkle = baselineFrames.map((e) => e.ankleY).reduce((a, b) => a + b) / baselineFrames.length;
    final minHip = frames.map((e) => e.hipY).reduce(math.min);
    final minAnkle = frames.map((e) => e.ankleY).reduce(math.min);

    final hipTravel = baselineHip - minHip;
    final ankleTravel = baselineAnkle - minAnkle;
    final threshold = math.max(0.018, ankleTravel * 0.35);

    final airborne = frames.where((f) {
      final ankleLift = baselineAnkle - f.ankleY;
      final hipLift = baselineHip - f.hipY;
      return ankleLift > threshold && hipLift > threshold / 2;
    }).toList();

    if (airborne.length < 2) {
      throw Exception('Unable to isolate takeoff and landing frames.');
    }

    final takeoff = airborne.first.timestamp;
    final landing = airborne.last.timestamp;
    final airtime = landing - takeoff;
    if (airtime <= 0 || airtime > 1.5) {
      throw Exception('Airtime calculation looked invalid. Record a cleaner side-on jump video.');
    }

    final jumpHeightCm = ((9.81 * airtime * airtime) / 8) * 100;
    progress.value = 1;

    return JumpAnalysisResult(
      jumpHeightCm: jumpHeightCm,
      airtimeSeconds: airtime,
      bestHipTravel: hipTravel,
      detectionRate: ((result.detectionRate as num?)?.toDouble() ?? 0) * 100,
      accelerationMode: _detector.accelerationMode.name,
    );
  }

  Future<void> dispose() async {
    await _detector.dispose();
    progress.dispose();
  }
}

class _FrameMeasurement {
  const _FrameMeasurement({required this.timestamp, required this.hipY, required this.ankleY});

  final double timestamp;
  final double hipY;
  final double ankleY;
}
