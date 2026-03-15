import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../models/calendar_event_model.dart';
import '../models/jump_model.dart';
import '../models/meal_model.dart';
import '../models/routine_task_model.dart';
import '../models/user_model.dart';
import '../models/water_log_model.dart';
import '../models/workout_model.dart';

class FirebaseService {
  FirebaseService({required this.isCloudEnabled});

  final bool isCloudEnabled;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  static bool hasRealConfiguration() {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      return options.projectId != 'jumptrack-placeholder' &&
          !options.apiKey.contains('REPLACE_WITH') &&
          options.apiKey.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> bootstrap() async {
    if (!hasRealConfiguration()) return false;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      return true;
    } catch (_) {
      return false;
    }
  }

  User? get currentUser => isCloudEnabled ? _auth.currentUser : null;
  Stream<User?> get authChanges => isCloudEnabled ? _auth.authStateChanges() : const Stream.empty();

  Future<UserCredential> signInWithEmail({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.userId).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> loadUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  Future<void> saveMeal(MealModel meal) async {
    await _db.collection('meals').doc(meal.id).set(meal.toMap(), SetOptions(merge: true));
  }

  Future<List<MealModel>> loadMeals(String userId) async {
    final query = await _db.collection('meals').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => MealModel.fromMap(doc.data())).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> saveWaterLog(WaterLogModel log) async {
    await _db.collection('water_logs').doc(log.id).set(log.toMap(), SetOptions(merge: true));
  }

  Future<List<WaterLogModel>> loadWaterLogs(String userId) async {
    final query = await _db.collection('water_logs').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => WaterLogModel.fromMap(doc.data())).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> saveWorkout(WorkoutModel workout) async {
    await _db.collection('workouts').doc(workout.id).set(workout.toMap(), SetOptions(merge: true));
  }

  Future<List<WorkoutModel>> loadWorkouts(String userId) async {
    final query = await _db.collection('workouts').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => WorkoutModel.fromMap(doc.data())).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> saveJump(JumpModel jump) async {
    await _db.collection('jump_records').doc(jump.id).set(jump.toMap(), SetOptions(merge: true));
  }

  Future<List<JumpModel>> loadJumps(String userId) async {
    final query = await _db.collection('jump_records').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => JumpModel.fromMap(doc.data())).toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> saveRoutineTask(RoutineTaskModel task) async {
    await _db.collection('routine_tasks').doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  Future<List<RoutineTaskModel>> loadRoutineTasks(String userId) async {
    final query = await _db.collection('routine_tasks').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => RoutineTaskModel.fromMap(doc.data())).toList();
    items.sort((a, b) => a.date.compareTo(b.date));
    return items;
  }

  Future<void> saveCalendarEvent(CalendarEventModel event) async {
    await _db.collection('calendar_events').doc(event.id).set(event.toMap(), SetOptions(merge: true));
  }

  Future<List<CalendarEventModel>> loadCalendarEvents(String userId) async {
    final query = await _db.collection('calendar_events').where('userId', isEqualTo: userId).get();
    final items = query.docs.map((doc) => CalendarEventModel.fromMap(doc.data())).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  Future<void> saveTrainingSchedule({
    required String userId,
    required DateTime weekStart,
    required Map<String, String> plan,
  }) async {
    final id = '${userId}_${weekStart.toIso8601String()}';
    await _db.collection('training_schedule').doc(id).set({
      'id': id,
      'userId': userId,
      'weekStart': weekStart,
      'plan': plan,
    }, SetOptions(merge: true));
  }

  Future<Map<String, String>> loadTrainingSchedule(String userId) async {
    final query = await _db.collection('training_schedule').where('userId', isEqualTo: userId).get();
    if (query.docs.isEmpty) return {};
    final docs = [...query.docs];
    docs.sort((a, b) {
      final aDate = (a.data()['weekStart'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = (b.data()['weekStart'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    final planData = docs.first.data()['plan'];
    if (planData is Map<String, dynamic>) {
      return planData.map((key, value) => MapEntry(key, value.toString()));
    }
    if (planData is Map) {
      return planData.map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    return {};
  }

  Future<String?> uploadJumpVideo(String userId, String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Invalid video path');
    }
    final ref = _storage.ref().child('jump_videos/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }
}
