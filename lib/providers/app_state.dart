import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/calendar_event_model.dart';
import '../models/jump_model.dart';
import '../models/meal_model.dart';
import '../models/routine_task_model.dart';
import '../models/user_model.dart';
import '../models/water_log_model.dart';
import '../models/workout_model.dart';
import '../services/firebase_service.dart';
import '../services/jump_ai_service.dart';
import '../services/notification_service.dart';
import '../services/nutrition_service.dart';
import '../services/training_recommendation_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.firebaseService,
    required this.nutritionService,
    required this.jumpAiService,
    required this.notificationService,
    required this.trainingRecommendationService,
  });

  final FirebaseService firebaseService;
  final NutritionService nutritionService;
  final JumpAiService jumpAiService;
  final NotificationService notificationService;
  final TrainingRecommendationService trainingRecommendationService;
  final Uuid _uuid = const Uuid();

  SharedPreferences? _prefs;
  StreamSubscription<User?>? _authSubscription;

  bool _isReady = false;
  bool _isBusy = false;
  bool _demoMode = false;
  bool _hydrationRemindersEnabled = false;
  String? _lastError;

  UserProfile? _profile;
  List<MealModel> _meals = [];
  List<WaterLogModel> _waterLogs = [];
  List<WorkoutModel> _workouts = [];
  List<JumpModel> _jumps = [];
  List<CalendarEventModel> _events = [];
  List<RoutineTaskModel> _routineTasks = [];
  Map<String, String> _weeklyPlan = {};

  bool get isReady => _isReady;
  bool get isBusy => _isBusy;
  bool get isDemoMode => _demoMode;
  bool get hydrationRemindersEnabled => _hydrationRemindersEnabled;
  String? get lastError => _lastError;

  bool get isCloudEnabled => firebaseService.isCloudEnabled;
  bool get isAuthenticated => _demoMode || (firebaseService.isCloudEnabled && firebaseService.currentUser != null);
  bool get needsOnboarding => isAuthenticated && _profile == null;

  UserProfile? get profile => _profile;
  List<MealModel> get meals => List.unmodifiable(_meals);
  List<WaterLogModel> get waterLogs => List.unmodifiable(_waterLogs);
  List<WorkoutModel> get workouts => List.unmodifiable(_workouts);
  List<JumpModel> get jumpRecords => List.unmodifiable(_jumps);
  List<CalendarEventModel> get calendarEvents => List.unmodifiable(_events);
  List<RoutineTaskModel> get routineTasks => List.unmodifiable(_routineTasks);

  String get currentUserId {
    if (_demoMode) return 'demo-user';
    return firebaseService.currentUser?.uid ?? 'local-user';
  }

  String get currentEmail {
    if (_demoMode) return 'demo@jumptrack.app';
    return firebaseService.currentUser?.email ?? '';
  }

  Map<String, String> get weeklyPlan {
    if (_weeklyPlan.isEmpty && _profile != null) {
      return Map.unmodifiable(
        trainingRecommendationService.generateWeeklyPlan(
          profile: _profile!,
          upcomingEvents: upcomingEvents,
        ),
      );
    }
    return Map.unmodifiable(_weeklyPlan);
  }

  String get todayPlanFocus => planForDay(DateTime.now());

  NutritionTargets? get nutritionTargets {
    return nutritionTargetsFor(DateTime.now());
  }

  NutritionTargets? nutritionTargetsFor(DateTime day) {
    final user = _profile;
    if (user == null) return null;
    return nutritionService.calculateTargets(
      profile: user,
      hasMatch: hasMatchOnDate(day),
    );
  }

  List<MealModel> get mealsToday => mealsForDay(DateTime.now());
  List<WaterLogModel> get waterLogsToday => waterLogsForDay(DateTime.now());

  List<MealModel> mealsForDay(DateTime day) {
    final items = _meals.where((meal) => _sameDay(meal.timestamp, day)).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  List<WaterLogModel> waterLogsForDay(DateTime day) {
    final items = _waterLogs.where((log) => _sameDay(log.timestamp, day)).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  int get waterConsumedToday => waterLogsToday.fold(0, (sum, item) => sum + item.amountMl);
  double get caloriesConsumedToday => mealsToday.fold(0, (sum, item) => sum + item.calories);
  double get proteinConsumedToday => mealsToday.fold(0, (sum, item) => sum + item.protein);
  double get carbsConsumedToday => mealsToday.fold(0, (sum, item) => sum + item.carbs);
  double get fatConsumedToday => mealsToday.fold(0, (sum, item) => sum + item.fat);

  double get hydrationProgress {
    final target = nutritionTargets?.waterMl ?? 0;
    if (target <= 0) return 0;
    return (waterConsumedToday / target).clamp(0, 1).toDouble();
  }

  double get bestJumpCm {
    if (_jumps.isEmpty) return 0;
    return _jumps.map((e) => e.heightCm).reduce(math.max);
  }

  double get averageJumpCm {
    if (_jumps.isEmpty) return 0;
    return _jumps.map((e) => e.heightCm).reduce((a, b) => a + b) / _jumps.length;
  }

  double get jumpImprovementLast4Weeks => trainingRecommendationService.jumpImprovementLast4Weeks(_jumps);

  double get fatigueScore {
    return trainingRecommendationService.calculateFatigueScore(
      jumps: _jumps,
      workouts: _workouts,
      events: _events,
    );
  }

  List<String> get recommendations {
    final user = _profile;
    if (user == null) return const [];
    return trainingRecommendationService.generateRecommendations(
      profile: user,
      jumps: _jumps,
      workouts: _workouts,
      events: _events,
    );
  }

  List<CalendarEventModel> get upcomingEvents {
    final now = DateTime.now();
    final items = _events.where((event) => event.endTime.isAfter(now)).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  CalendarEventModel? get nextMatch {
    for (final event in upcomingEvents) {
      if (_isMatch(event)) return event;
    }
    return null;
  }

  bool get hasMatchWithin48Hours {
    final match = nextMatch;
    if (match == null) return false;
    final diff = match.startTime.difference(DateTime.now()).inHours;
    return diff >= 0 && diff <= 48;
  }

  int get completedWorkouts => _workouts.where((workout) => workout.completed).length;

  double get workoutCompletionRateLast7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final scheduled = _workouts.where((workout) => workout.scheduledAt.isAfter(cutoff)).toList();
    if (scheduled.isEmpty) return 1;
    final completed = scheduled.where((workout) => workout.completed).length;
    return (completed / scheduled.length).clamp(0, 1).toDouble();
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLocalCache();

    if (firebaseService.isCloudEnabled) {
      _authSubscription = firebaseService.authChanges.listen((user) {
        _handleAuthChange(user);
      });
      final current = firebaseService.currentUser;
      if (current != null) {
        await _handleAuthChange(current);
      }
    }

    if (_profile != null && _tasksForCurrentWeek().isEmpty) {
      await _generateRoutineForWeekInternal(anchorDay: DateTime.now(), force: false, syncToCloud: false);
    }

    if (_hydrationRemindersEnabled && _profile != null) {
      await _rescheduleHydrationReminders();
    }

    _isReady = true;
    notifyListeners();
  }

  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      if (!_demoMode) {
        notifyListeners();
      }
      return;
    }

    _demoMode = false;
    await refreshFromCloud();
  }

  Future<void> refreshFromCloud() async {
    if (!firebaseService.isCloudEnabled || firebaseService.currentUser == null) {
      return;
    }

    await _runBusy(() async {
      final userId = firebaseService.currentUser!.uid;
      final profile = await firebaseService.loadUserProfile(userId);
      final meals = await firebaseService.loadMeals(userId);
      final waterLogs = await firebaseService.loadWaterLogs(userId);
      final workouts = await firebaseService.loadWorkouts(userId);
      final jumps = await firebaseService.loadJumps(userId);
      final events = await firebaseService.loadCalendarEvents(userId);
      final routineTasks = await firebaseService.loadRoutineTasks(userId);
      final schedule = await firebaseService.loadTrainingSchedule(userId);

      _profile = profile ?? _profile;
      _meals = meals;
      _waterLogs = waterLogs;
      _workouts = workouts;
      _jumps = jumps;
      _events = events;
      _routineTasks = routineTasks;
      if (schedule.isNotEmpty) {
        _weeklyPlan = schedule;
      } else if (_profile != null) {
        _weeklyPlan = trainingRecommendationService.generateWeeklyPlan(
          profile: _profile!,
          upcomingEvents: upcomingEvents,
        );
        await firebaseService.saveTrainingSchedule(
          userId: userId,
          weekStart: trainingRecommendationService.startOfWeek(DateTime.now()),
          plan: _weeklyPlan,
        );
      }

      if (_profile != null && _tasksForCurrentWeek().isEmpty) {
        await _generateRoutineForWeekInternal(anchorDay: DateTime.now(), force: false, syncToCloud: true);
      }

      _sortState();
      await _saveLocalCache();
      if (_hydrationRemindersEnabled && _profile != null) {
        await _rescheduleHydrationReminders();
      }
    });
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    if (!firebaseService.isCloudEnabled) {
      _setError('Firebase is not configured. Add FlutterFire files to enable cloud login.');
      return false;
    }
    final result = await _runBusy<bool>(() async {
      await firebaseService.signInWithEmail(email: email.trim(), password: password.trim());
      return true;
    });
    return result ?? false;
  }

  Future<bool> registerWithEmail({required String email, required String password}) async {
    if (!firebaseService.isCloudEnabled) {
      _setError('Firebase is not configured. Add FlutterFire files to enable account creation.');
      return false;
    }
    final result = await _runBusy<bool>(() async {
      await firebaseService.registerWithEmail(email: email.trim(), password: password.trim());
      return true;
    });
    return result ?? false;
  }

  Future<bool> signInWithGoogle() async {
    if (!firebaseService.isCloudEnabled) {
      _setError('Firebase is not configured. Add FlutterFire files to enable Google login.');
      return false;
    }
    final result = await _runBusy<bool>(() async {
      await firebaseService.signInWithGoogle();
      return true;
    });
    return result ?? false;
  }

  Future<void> continueInDemoMode() async {
    _demoMode = true;
    _lastError = null;
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _runBusy(() async {
      if (firebaseService.isCloudEnabled && firebaseService.currentUser != null) {
        await firebaseService.signOut();
      }
      await _clearSession();
    });
  }

  Future<void> _clearSession() async {
    await notificationService.cancelHydrationReminders();
    _demoMode = false;
    _hydrationRemindersEnabled = false;
    _profile = null;
    _meals = [];
    _waterLogs = [];
    _workouts = [];
    _jumps = [];
    _events = [];
    _routineTasks = [];
    _weeklyPlan = {};
    _lastError = null;
    await _prefs?.remove('profile');
    await _prefs?.remove('meals');
    await _prefs?.remove('water_logs');
    await _prefs?.remove('workouts');
    await _prefs?.remove('jumps');
    await _prefs?.remove('events');
    await _prefs?.remove('routine_tasks');
    await _prefs?.remove('weekly_plan');
    await _prefs?.setBool('demo_mode', false);
    notifyListeners();
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    final normalized = profile.copyWith(
      userId: currentUserId,
      email: currentEmail,
      createdAt: _profile?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      workoutCount: _profile?.workoutCount ?? profile.workoutCount,
    );

    _profile = normalized;
    _weeklyPlan = trainingRecommendationService.generateWeeklyPlan(
      profile: normalized,
      upcomingEvents: upcomingEvents,
    );
    await _generateRoutineForWeekInternal(anchorDay: DateTime.now(), force: true, syncToCloud: false);

    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveUserProfile(normalized);
      await firebaseService.saveTrainingSchedule(
        userId: currentUserId,
        weekStart: trainingRecommendationService.startOfWeek(DateTime.now()),
        plan: _weeklyPlan,
      );
      for (final task in _tasksForCurrentWeek()) {
        await firebaseService.saveRoutineTask(task);
      }
    }

    if (_hydrationRemindersEnabled) {
      await _rescheduleHydrationReminders();
    }

    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> addManualMeal({
    required String name,
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
  }) async {
    final meal = MealModel(
      id: _uuid.v4(),
      userId: currentUserId,
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      timestamp: DateTime.now(),
      source: 'manual',
    );
    await _addMealInternal(meal);
  }

  Future<MealModel?> addMealFromBarcode(String barcode) async {
    final meal = await _runBusy<MealModel?>(() async {
      return nutritionService.fetchMealByBarcode(barcode: barcode, userId: currentUserId);
    });
    if (meal == null) {
      if (_lastError == null) {
        _setError('No product was found for this barcode.');
      }
      return null;
    }
    await _addMealInternal(meal);
    return meal;
  }

  Future<void> _addMealInternal(MealModel meal) async {
    _meals.insert(0, meal.copyWith(userId: currentUserId));
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveMeal(meal.copyWith(userId: currentUserId));
    }
  }

  Future<void> addWaterLog(int amountMl) async {
    final log = WaterLogModel(
      id: _uuid.v4(),
      userId: currentUserId,
      amountMl: amountMl,
      timestamp: DateTime.now(),
    );
    _waterLogs.insert(0, log);
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveWaterLog(log);
    }
  }

  Future<void> toggleHydrationReminders(bool enabled) async {
    _hydrationRemindersEnabled = enabled;
    if (enabled) {
      await _rescheduleHydrationReminders();
    } else {
      await notificationService.cancelHydrationReminders();
    }
    await _prefs?.setBool('hydration_reminders', enabled);
    notifyListeners();
  }

  Future<void> _rescheduleHydrationReminders() async {
    final target = nutritionTargets?.waterMl.round() ?? 0;
    await notificationService.scheduleDailyHydrationReminders(targetMl: target);
  }

  Future<void> createWorkout({
    required String title,
    required String description,
    required List<ExerciseModel> exercises,
    required DateTime scheduledAt,
  }) async {
    final workout = WorkoutModel(
      id: _uuid.v4(),
      userId: currentUserId,
      title: title,
      description: description,
      exercises: exercises,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
    );
    _workouts.insert(0, workout);
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveWorkout(workout);
    }
    if (scheduledAt.isAfter(DateTime.now())) {
      await notificationService.scheduleWorkoutReminder(scheduledAt, title: title);
    }
  }

  Future<void> completeWorkoutSession({
    required WorkoutModel workout,
    required List<bool> completedExercises,
    required Duration duration,
  }) async {
    final updatedExercises = <ExerciseModel>[];
    for (int i = 0; i < workout.exercises.length; i++) {
      updatedExercises.add(
        workout.exercises[i].copyWith(
          completed: i < completedExercises.length ? completedExercises[i] : false,
        ),
      );
    }

    final updatedWorkout = workout.copyWith(
      exercises: updatedExercises,
      completed: true,
      durationSeconds: duration.inSeconds,
      completedAt: DateTime.now(),
    );

    final index = _workouts.indexWhere((item) => item.id == workout.id);
    if (index >= 0) {
      _workouts[index] = updatedWorkout;
    }

    if (_profile != null) {
      _profile = _profile!.copyWith(
        workoutCount: _profile!.workoutCount + 1,
        updatedAt: DateTime.now(),
      );
    }

    _sortState();
    await _saveLocalCache();
    notifyListeners();

    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveWorkout(updatedWorkout);
      if (_profile != null) {
        await firebaseService.saveUserProfile(_profile!);
      }
    }

    if (fatigueScore >= 7) {
      final recoveryTime = DateTime.now().add(const Duration(hours: 18));
      await notificationService.scheduleRecoveryReminder(recoveryTime);
    }
  }

  Future<JumpModel> addManualJump(double heightCm) async {
    final airtime = math.sqrt(((heightCm / 100) * 8) / 9.81);
    final jump = JumpModel(
      id: _uuid.v4(),
      userId: currentUserId,
      heightCm: heightCm,
      airtimeSeconds: airtime,
      method: 'manual',
      timestamp: DateTime.now(),
    );
    await _addJumpInternal(jump);
    return jump;
  }

  Future<JumpModel?> addAiJumpFromVideo(String videoPath) async {
    final result = await _runBusy(() => jumpAiService.analyzeVideo(videoPath));
    if (result == null) return null;

    String? videoUrl;
    if (firebaseService.isCloudEnabled && !_demoMode) {
      try {
        videoUrl = await firebaseService.uploadJumpVideo(currentUserId, videoPath);
      } catch (_) {
        videoUrl = null;
      }
    }

    final jump = JumpModel(
      id: _uuid.v4(),
      userId: currentUserId,
      heightCm: result.jumpHeightCm,
      airtimeSeconds: result.airtimeSeconds,
      method: 'ai',
      timestamp: DateTime.now(),
      videoUrl: videoUrl,
    );
    await _addJumpInternal(jump);
    return jump;
  }

  Future<void> _addJumpInternal(JumpModel jump) async {
    _jumps.insert(0, jump);
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveJump(jump);
    }
  }

  Future<void> addCalendarEvent(CalendarEventModel event) async {
    _events.add(event.copyWith(userId: currentUserId));
    _sortState();

    if (_profile != null) {
      _weeklyPlan = trainingRecommendationService.generateWeeklyPlan(
        profile: _profile!,
        upcomingEvents: upcomingEvents,
      );
      await _generateRoutineForWeekInternal(anchorDay: event.startTime, force: false, syncToCloud: false);
    }

    await _saveLocalCache();
    notifyListeners();

    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveCalendarEvent(event.copyWith(userId: currentUserId));
      if (_weeklyPlan.isNotEmpty) {
        await firebaseService.saveTrainingSchedule(
          userId: currentUserId,
          weekStart: trainingRecommendationService.startOfWeek(event.startTime),
          plan: _weeklyPlan,
        );
      }
      for (final task in _routineTasks.where((task) => _sameWeek(task.date, event.startTime))) {
        await firebaseService.saveRoutineTask(task);
      }
    }

    if (_isMatch(event)) {
      await notificationService.scheduleMatchReminder(event);
    } else if (event.type == 'training') {
      await notificationService.scheduleWorkoutReminder(event.startTime, title: event.title);
    }
  }

  List<CalendarEventModel> eventsForDay(DateTime day) {
    final items = _events.where((event) => _sameDay(event.startTime, day)).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  bool hasMatchOnDate(DateTime day) {
    return _events.any((event) => _isMatch(event) && _sameDay(event.startTime, day));
  }

  List<RoutineTaskModel> tasksForDay(DateTime day) {
    final items = _routineTasks.where((task) => _sameDay(task.date, day)).toList();
    items.sort((a, b) => a.type.compareTo(b.type));
    return items;
  }

  double scoreForDay(DateTime day) {
    final tasks = tasksForDay(day);
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((task) => task.completed).length;
    return ((completed / tasks.length) * 10).clamp(0, 10).toDouble();
  }

  Future<void> addRoutineTask({
    required DateTime date,
    required String title,
    required String type,
  }) async {
    final task = RoutineTaskModel(
      id: _uuid.v4(),
      userId: currentUserId,
      title: title,
      type: type,
      date: DateTime(date.year, date.month, date.day),
    );
    _routineTasks.add(task);
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveRoutineTask(task);
    }
  }

  Future<void> toggleRoutineTask(RoutineTaskModel task, bool completed) async {
    final index = _routineTasks.indexWhere((item) => item.id == task.id);
    if (index < 0) return;
    final updated = task.copyWith(completed: completed);
    _routineTasks[index] = updated;
    _sortState();
    await _saveLocalCache();
    notifyListeners();
    if (firebaseService.isCloudEnabled && !_demoMode) {
      await firebaseService.saveRoutineTask(updated);
    }
  }

  Future<void> generateRoutineForWeek({DateTime? anchorDay, bool force = false}) async {
    await _generateRoutineForWeekInternal(
      anchorDay: anchorDay ?? DateTime.now(),
      force: force,
      syncToCloud: firebaseService.isCloudEnabled && !_demoMode,
    );
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> _generateRoutineForWeekInternal({
    required DateTime anchorDay,
    required bool force,
    required bool syncToCloud,
  }) async {
    final user = _profile;
    if (user == null) return;

    final plan = weeklyPlan;
    final generated = trainingRecommendationService.buildRoutineForWeek(
      profile: user,
      anchorDay: anchorDay,
      userId: currentUserId,
      plan: plan,
    );

    final weekStart = trainingRecommendationService.startOfWeek(anchorDay);
    if (force) {
      _routineTasks.removeWhere((task) => _sameWeek(task.date, weekStart));
    }

    for (final task in generated) {
      final exists = _routineTasks.any((existing) => existing.id == task.id);
      if (!exists) {
        _routineTasks.add(task);
        if (syncToCloud) {
          await firebaseService.saveRoutineTask(task);
        }
      }
    }

    _sortState();
  }

  String planForDay(DateTime day) {
    final key = DateFormat('EEEE').format(day);
    return weeklyPlan[key] ?? 'Performance work';
  }

  List<CalendarEventModel> upcomingEventsForDays(int days) {
    final cutoff = DateTime.now().add(Duration(days: days));
    final items = upcomingEvents.where((event) => event.startTime.isBefore(cutoff)).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  List<String> preGameMealSuggestions() {
    return nutritionService.preGameMealSuggestions();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(jumpAiService.dispose());
    super.dispose();
  }

  Future<void> _loadLocalCache() async {
    final prefs = _prefs;
    if (prefs == null) return;

    _demoMode = prefs.getBool('demo_mode') ?? false;
    _hydrationRemindersEnabled = prefs.getBool('hydration_reminders') ?? false;

    final profileJson = prefs.getString('profile');
    if (profileJson != null && profileJson.isNotEmpty) {
      _profile = UserProfile.fromMap(Map<String, dynamic>.from(jsonDecode(profileJson)));
    }

    _meals = _decodeList('meals', MealModel.fromMap);
    _waterLogs = _decodeList('water_logs', WaterLogModel.fromMap);
    _workouts = _decodeList('workouts', WorkoutModel.fromMap);
    _jumps = _decodeList('jumps', JumpModel.fromMap);
    _events = _decodeList('events', CalendarEventModel.fromMap);
    _routineTasks = _decodeList('routine_tasks', RoutineTaskModel.fromMap);

    final weeklyPlanJson = prefs.getString('weekly_plan');
    if (weeklyPlanJson != null && weeklyPlanJson.isNotEmpty) {
      final decoded = Map<String, dynamic>.from(jsonDecode(weeklyPlanJson));
      _weeklyPlan = decoded.map((key, value) => MapEntry(key, value.toString()));
    }

    _sortState();
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) fromMap) {
    final prefs = _prefs;
    if (prefs == null) return [];
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = List<dynamic>.from(jsonDecode(raw));
    return list.map((item) => fromMap(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> _saveLocalCache() async {
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.setBool('demo_mode', _demoMode);
    await prefs.setBool('hydration_reminders', _hydrationRemindersEnabled);

    if (_profile != null) {
      await prefs.setString('profile', jsonEncode(_sanitize(_profile!.toMap())));
    } else {
      await prefs.remove('profile');
    }

    await prefs.setString('meals', jsonEncode(_meals.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('water_logs', jsonEncode(_waterLogs.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('workouts', jsonEncode(_workouts.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('jumps', jsonEncode(_jumps.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('events', jsonEncode(_events.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('routine_tasks', jsonEncode(_routineTasks.map((item) => _sanitize(item.toMap())).toList()));
    await prefs.setString('weekly_plan', jsonEncode(_weeklyPlan));
  }

  dynamic _sanitize(dynamic value) {
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), _sanitize(val)));
    }
    if (value is Iterable) {
      return value.map(_sanitize).toList();
    }
    return value;
  }

  List<RoutineTaskModel> _tasksForCurrentWeek() {
    final monday = trainingRecommendationService.startOfWeek(DateTime.now());
    return _routineTasks.where((task) => _sameWeek(task.date, monday)).toList();
  }

  bool _sameWeek(DateTime left, DateTime right) {
    return trainingRecommendationService.startOfWeek(left) == trainingRecommendationService.startOfWeek(right);
  }

  bool _sameDay(DateTime left, DateTime right) {
    return DateUtils.isSameDay(left, right);
  }

  bool _isMatch(CalendarEventModel event) {
    return event.type == 'match' || event.type == 'friendly';
  }

  void _sortState() {
    _meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _waterLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _workouts.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    _jumps.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _events.sort((a, b) => a.startTime.compareTo(b.startTime));
    _routineTasks.sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      return a.type.compareTo(b.type);
    });
  }

  Future<T?> _runBusy<T>(Future<T> Function() action) async {
    _isBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      final result = await action();
      return result;
    } catch (error) {
      _setError(_friendlyError(error));
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _lastError = message;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    return text.replaceFirst('Exception: ', '').replaceFirst('firebase_auth/', '');
  }
}
