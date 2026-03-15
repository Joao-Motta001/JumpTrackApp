import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_event_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _local.initialize(settings);
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _local
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    try {
      await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'JumpTrack';
        final body = message.notification?.body ?? 'New update';
        showInstant(title: title, body: body);
      });
    } catch (_) {
      // Firebase not configured yet. Local notifications still work.
    }

    _initialized = true;
  }

  Future<void> showInstant({required String title, required String body}) {
    return _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      _details(),
    );
  }

  Future<void> scheduleDailyHydrationReminders({int targetMl = 0}) async {
    await cancelHydrationReminders();
    for (int hour = 9; hour <= 21; hour += 2) {
      final scheduled = _nextOccurrence(hour, 0);
      await _local.zonedSchedule(
        1000 + hour,
        'Hydration check',
        targetMl > 0
            ? 'Stay on pace for ${(targetMl / 1000).toStringAsFixed(1)} L today.'
            : 'Time to drink water and stay explosive.',
        scheduled,
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancelHydrationReminders() async {
    for (int hour = 9; hour <= 21; hour += 2) {
      await _local.cancel(1000 + hour);
    }
  }

  Future<void> scheduleWorkoutReminder(DateTime when, {String title = 'Workout reminder'}) async {
    if (when.isBefore(DateTime.now())) return;
    await _local.zonedSchedule(
      when.millisecondsSinceEpoch.remainder(1000000),
      title,
      'Your JumpTrack workout is coming up.',
      tz.TZDateTime.from(when, tz.local),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleMatchReminder(CalendarEventModel event) async {
    final twentyFourHours = event.startTime.subtract(const Duration(hours: 24));
    final twoHours = event.startTime.subtract(const Duration(hours: 2));

    if (twentyFourHours.isAfter(DateTime.now())) {
      await _local.zonedSchedule(
        event.startTime.millisecondsSinceEpoch.remainder(1000000) + 1,
        'Match day tomorrow',
        '${event.title} is in 24 hours. Increase carbs and hydration today.',
        tz.TZDateTime.from(twentyFourHours, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (twoHours.isAfter(DateTime.now())) {
      await _local.zonedSchedule(
        event.startTime.millisecondsSinceEpoch.remainder(1000000) + 2,
        'Match soon',
        '${event.title} starts in about 2 hours. Choose a light carb-focused meal.',
        tz.TZDateTime.from(twoHours, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  Future<void> scheduleRecoveryReminder(DateTime when) async {
    if (when.isBefore(DateTime.now())) return;
    await _local.zonedSchedule(
      when.millisecondsSinceEpoch.remainder(1000000) + 3,
      'Recovery reminder',
      'Mobility, sleep, and hydration will protect your jump performance.',
      tz.TZDateTime.from(when, tz.local),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'jumptrack_main',
      'JumpTrack Notifications',
      channelDescription: 'Workout, hydration, recovery and match reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
