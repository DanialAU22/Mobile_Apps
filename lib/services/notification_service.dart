import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    _initialized = true;
  }

  int _taskDayBeforeId(String taskId) => taskId.hashCode & 0x3fffffff;
  int _examHourBeforeId(String examId) =>
      (examId.hashCode & 0x3fffffff) + 1000000;
  static const int _dailyStudyId = 9999999;

  Future<void> scheduleTaskReminder(Task task) async {
    if (!_initialized) return;
    if (task.deadline == null) return;

    final reminderTime = task.deadline!.subtract(const Duration(days: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _taskDayBeforeId(task.id);
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Task Reminder',
      'Tomorrow: ${task.title}',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tasks_channel',
          'Tasks',
          channelDescription: 'Task deadline reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> scheduleExamReminder(Exam exam) async {
    if (!_initialized) return;
    if (exam.dateTime == null) return;

    final reminderTime = exam.dateTime!.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = _examHourBeforeId(exam.id);
    final tzTime = tz.TZDateTime.from(reminderTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      'Exam Reminder',
      'In 1 hour: ${exam.title}',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exams_channel',
          'Exams',
          channelDescription: 'Exam reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> scheduleDailyStudyReminder() async {
    if (!_initialized) return;

    final now = DateTime.now();
    DateTime next6pm = DateTime(now.year, now.month, now.day, 18);
    if (!next6pm.isAfter(now)) {
      next6pm = next6pm.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(next6pm, tz.local);

    await _plugin.zonedSchedule(
      _dailyStudyId,
      'Study Time',
      'Daily reminder to review your subjects.',
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_study_channel',
          'Daily Study',
          channelDescription: 'Daily study reminder at 6 PM',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
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

