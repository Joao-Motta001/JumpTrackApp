import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WorkoutTimerController {
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  Timer? _timer;
  DateTime? _startedAt;
  Duration _base = Duration.zero;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _startedAt;
      if (start == null) return;
      elapsed.value = _base + DateTime.now().difference(start);
    });
  }

  void pause() {
    final start = _startedAt;
    if (start != null) {
      _base += DateTime.now().difference(start);
    }
    _startedAt = null;
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    pause();
    _base = Duration.zero;
    elapsed.value = Duration.zero;
  }

  void dispose() {
    _timer?.cancel();
    elapsed.dispose();
  }
}

class WorkoutTimer extends StatelessWidget {
  const WorkoutTimer({super.key, required this.controller, this.label = 'Workout Time'});

  final WorkoutTimerController controller;
  final String label;

  String _format(Duration value) {
    final hours = value.inHours.toString().padLeft(2, '0');
    final minutes = (value.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: controller.elapsed,
      builder: (context, value, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              _format(value),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        );
      },
    );
  }
}
