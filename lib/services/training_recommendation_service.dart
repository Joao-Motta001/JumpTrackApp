import 'dart:math' as math;

import '../models/calendar_event_model.dart';
import '../models/jump_model.dart';
import '../models/routine_task_model.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';

class TrainingRecommendationService {
  Map<String, String> generateWeeklyPlan({required UserProfile profile, required List<CalendarEventModel> upcomingEvents}) {
    final plan = <String, String>{
      'Monday': 'Lower body strength',
      'Tuesday': 'Plyometrics',
      'Wednesday': 'Recovery',
      'Thursday': 'Explosive training',
      'Friday': 'Core stability',
      'Saturday': 'Match preparation',
      'Sunday': 'Rest',
    };

    if (profile.trainingDays <= 4) {
      plan['Tuesday'] = 'Explosive lower body';
      plan['Wednesday'] = 'Mobility and recovery';
      plan['Friday'] = 'Full-body power';
    }

    if (profile.goals.contains('increase endurance')) {
      plan['Wednesday'] = 'Aerobic capacity + mobility';
    }

    if (profile.goals.contains('increase strength')) {
      plan['Monday'] = 'Heavy lower body strength';
      plan['Thursday'] = 'Upper body + posterior chain';
    }

    final hasWeekendMatch = upcomingEvents.any((e) => _isMatch(e) && e.startTime.weekday >= DateTime.friday);
    if (hasWeekendMatch) {
      plan['Friday'] = 'Primer session + mobility';
      plan['Saturday'] = 'Match preparation';
      plan['Sunday'] = 'Recovery and hydration';
    }

    return plan;
  }

  List<String> generateRecommendations({
    required UserProfile profile,
    required List<JumpModel> jumps,
    required List<WorkoutModel> workouts,
    required List<CalendarEventModel> events,
  }) {
    final recommendations = <String>[];

    final improvement = jumpImprovementLast4Weeks(jumps);
    if (improvement < 2) {
      recommendations.add('Jump improvement is under 2 cm over 4 weeks — increase strength emphasis.');
    }

    final fatigue = calculateFatigueScore(jumps: jumps, workouts: workouts, events: events);
    if (fatigue >= 7) {
      recommendations.add('Fatigue looks elevated — add recovery work and reduce max-intensity volume.');
    }

    final matchSoon = events.any((event) => _isMatch(event) && event.startTime.isAfter(DateTime.now()) && event.startTime.difference(DateTime.now()).inHours <= 48);
    if (matchSoon) {
      recommendations.add('Match in the next 48h — reduce training intensity and bias mobility + activation.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Training balance looks solid — stay consistent and focus on execution quality this week.');
    }

    return recommendations;
  }

  double calculateFatigueScore({
    required List<JumpModel> jumps,
    required List<WorkoutModel> workouts,
    required List<CalendarEventModel> events,
  }) {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentWorkouts = workouts.where((w) => w.completed && w.completedAt != null && w.completedAt!.isAfter(sevenDaysAgo)).length;
    final recentMatches = events.where((e) => _isMatch(e) && e.startTime.isAfter(sevenDaysAgo)).length;

    double jumpDrop = 0;
    if (jumps.length >= 4) {
      final recent = jumps.take(2).map((e) => e.heightCm).toList();
      final previous = jumps.skip(2).take(2).map((e) => e.heightCm).toList();
      if (recent.isNotEmpty && previous.isNotEmpty) {
        final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
        final previousAvg = previous.reduce((a, b) => a + b) / previous.length;
        jumpDrop = math.max(0, previousAvg - recentAvg);
      }
    }

    final score = (recentWorkouts * 1.2) + (recentMatches * 2) + (jumpDrop * 0.4);
    return score.clamp(0, 10).toDouble();
  }

  double jumpImprovementLast4Weeks(List<JumpModel> jumps) {
    if (jumps.length < 4) return 0;
    final now = DateTime.now();
    final recent = jumps.where((j) => now.difference(j.timestamp).inDays <= 14).map((e) => e.heightCm).toList();
    final older = jumps.where((j) {
      final days = now.difference(j.timestamp).inDays;
      return days > 14 && days <= 28;
    }).map((e) => e.heightCm).toList();

    if (recent.isEmpty || older.isEmpty) return 0;
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    return recentAvg - olderAvg;
  }

  List<RoutineTaskModel> buildRoutineForWeek({
    required UserProfile profile,
    required DateTime anchorDay,
    required String userId,
    required Map<String, String> plan,
  }) {
    final monday = startOfWeek(anchorDay);
    final tasks = <RoutineTaskModel>[];

    final weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final taskTypes = <String, List<String>>{
      'training': ['training'],
      'mobility': ['mobility'],
      'nutrition goal': ['nutrition goal'],
      'recovery': ['recovery'],
      'hydration target': ['hydration target'],
    };

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final name = weekdayNames[i];
      final focus = plan[name] ?? 'Performance work';
      final dayTasks = <MapEntry<String, String>>[
        MapEntry('training', focus),
        const MapEntry('mobility', '10–15 min mobility flow'),
        const MapEntry('nutrition goal', 'Hit protein and carb targets'),
        const MapEntry('hydration target', 'Complete hydration target'),
      ];
      if (focus.toLowerCase().contains('recovery') || name == 'Sunday') {
        dayTasks.add(const MapEntry('recovery', 'Sleep 8h + recovery habits'));
      }

      for (final entry in dayTasks) {
        tasks.add(
          RoutineTaskModel(
            id: '${userId}_${date.toIso8601String()}_${entry.key}_${entry.value.hashCode}',
            userId: userId,
            title: entry.value,
            type: taskTypes[entry.key]!.first,
            date: date,
          ),
        );
      }
    }

    return tasks;
  }

  DateTime startOfWeek(DateTime date) {
    final only = DateTime(date.year, date.month, date.day);
    return only.subtract(Duration(days: only.weekday - 1));
  }

  bool _isMatch(CalendarEventModel event) => event.type == 'match' || event.type == 'friendly';
}
