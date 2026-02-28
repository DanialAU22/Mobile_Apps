import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../models/exam.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.local);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Timezone init error: $e');
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initializationSettings);

    // Android 13+ requires runtime notification permission.
    // If denied, scheduling may succeed but notifications won't show; don't crash the app.
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notification permission request error: $e');
      }
    }

    _initialized = true;
  }

  int _taskDayBeforeId(String taskId) => taskId.hashCode & 0x3fffffff;
  int _examHourBeforeId(String examId) =>
      (examId.hashCode & 0x3fffffff) + 1000000;
  static const int _dailyStudyId = 9999999;

  Future<void> _zonedScheduleWithExactFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } on PlatformException catch (e) {
      // Android 12+ can block exact alarms unless user explicitly allows them.
      if (e.code == 'exact_alarms_not_permitted') {
        if (kDebugMode) {
          debugPrint(
            'Exact alarms not permitted; falling back to inexact scheduling.',
          );
        }
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchDateTimeComponents,
        );
        return;
      }
      rethrow;
    }
  }

  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) return;
    if (task.deadline == null) return;

    final reminderTime = task.deadline!.subtract(const Duration(days: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _taskDayBeforeId(task.id);
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _zonedScheduleWithExactFallback(
      id: id,
      title: 'Task Reminder',
      body: 'Tomorrow: ${task.title}',
      scheduledDate: tzTime,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Tasks',
          channelDescription: 'Task deadline reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      matchDateTimeComponents: null,
    );
  }

  Future<void> scheduleExamReminder(Exam exam) async {
    if (!_initialized) return;
    if (exam.dateTime == null) return;

    final reminderTime = exam.dateTime!.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _examHourBeforeId(exam.id);
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _zonedScheduleWithExactFallback(
      id: id,
      title: 'Exam Reminder',
      body: 'In 1 hour: ${exam.title}',
      scheduledDate: tzTime,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'exams_channel',
          'Exams',
          channelDescription: 'Exam reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      matchDateTimeComponents: null,
    );
  }

  Future<void> scheduleDailyStudyReminder({int hour = 18, int minute = 0}) async {
    if (!_initialized) return;

    await cancelDailyStudyReminder();

    final now = DateTime.now();
    DateTime next =
        DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(next, tz.local);

    await _zonedScheduleWithExactFallback(
      id: _dailyStudyId,
      title: 'Study Time',
      body: 'Daily reminder to review your subjects.',
      scheduledDate: tzTime,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_study_channel',
          'Daily Study',
          channelDescription: 'Daily study reminder',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    if (!_initialized) return;
    await _plugin.cancel(_taskDayBeforeId(taskId));
  }

  Future<void> cancelExamNotifications(String examId) async {
    if (!_initialized) return;
    await _plugin.cancel(_examHourBeforeId(examId));
  }

  Future<void> cancelDailyStudyReminder() async {
    if (!_initialized) return;
    await _plugin.cancel(_dailyStudyId);
  }
}

