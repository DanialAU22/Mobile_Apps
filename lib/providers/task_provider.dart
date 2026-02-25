import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/task.dart';
import '../services/notification_service.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String? _filterSubjectId;

  List<Task> get allTasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get filterSubjectId => _filterSubjectId;

  List<Task> get visibleTasks {
    if (_filterSubjectId == null) return List.unmodifiable(_tasks);
    return _tasks
        .where((t) => t.subjectId == _filterSubjectId)
        .toList(growable: false);
  }

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    final completed = _tasks.where((t) => t.isCompleted).length;
    return completed / _tasks.length;
  }

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DatabaseHelper.instance.getTasks();
      _tasks
        ..clear()
        ..addAll(data);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error loading tasks: $e\n$s');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterSubject(String? subjectId) {
    _filterSubjectId = subjectId;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    try {
      await DatabaseHelper.instance.insertTask(task);
      _tasks.add(task);
      notifyListeners();
      await NotificationService.instance.scheduleTaskReminder(task);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error adding task: $e\n$s');
      }
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await DatabaseHelper.instance.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
        await NotificationService.instance.scheduleTaskReminder(task);
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error updating task: $e\n$s');
      }
    }
  }

  Future<void> toggleCompletion(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);
  }

  Future<void> deleteTask(Task task) async {
    try {
      await DatabaseHelper.instance.deleteTask(task.id);
      _tasks.removeWhere((t) => t.id == task.id);
      notifyListeners();
      await NotificationService.instance.cancelTaskNotifications(task.id);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error deleting task: $e\n$s');
      }
    }
  }

  List<Task> tasksForDay(DateTime day) {
    return _tasks.where((t) {
      if (t.deadline == null) return false;
      final d = t.deadline!;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<Task> tasksForNextDays(int days) {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return _tasks.where((t) {
      final d = t.deadline;
      if (d == null) return false;
      return !d.isBefore(now) && !d.isAfter(end);
    }).toList();
  }
}

