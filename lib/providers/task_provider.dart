import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String? _filterSubjectId;
  String? _searchQuery;
  bool? _filterCompleted;
  bool _filterOverdue = false;
  String? _filterPriority;

  List<Task> get allTasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get filterSubjectId => _filterSubjectId;
  String? get searchQuery => _searchQuery;

  List<Task> get visibleTasks {
    if (_filterSubjectId == null &&
        _searchQuery == null &&
        _filterCompleted == null &&
        !_filterOverdue &&
        _filterPriority == null) {
      return List.unmodifiable(_tasks);
    }
    return _tasks.where((t) {
      if (_filterSubjectId != null && t.subjectId != _filterSubjectId) {
        return false;
      }
      if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
        final q = _searchQuery!.toLowerCase();
        if (!t.title.toLowerCase().contains(q) &&
            !(t.description?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }
      if (_filterCompleted != null && t.isCompleted != _filterCompleted) {
        return false;
      }
      if (_filterOverdue && !t.isOverdue) return false;
      if (_filterPriority != null && t.priority != _filterPriority) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    final completed = _tasks.where((t) => t.isCompleted).length;
    return completed / _tasks.length;
  }

  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((t) => t.isCompleted).length;

  List<Task> get overdueTasks =>
      _tasks.where((t) => t.isOverdue).toList(growable: false);

  List<Task> get highPriorityUpcoming {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.isCompleted) return false;
      if (t.priority != 'high') return false;
      if (t.deadline == null) return true;
      return !t.deadline!.isBefore(now);
    }).toList(growable: false);
  }

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

  /// Load tasks with SQL-level filters for Tasks screen when filters are applied.
  Future<List<Task>> fetchFilteredTasks() async {
    if (_searchQuery == null &&
        _filterCompleted == null &&
        !_filterOverdue &&
        _filterPriority == null &&
        _filterSubjectId == null) {
      return _tasks;
    }
    return DatabaseHelper.instance.getTasksFiltered(
      searchQuery: _searchQuery,
      isCompleted: _filterCompleted,
      overdueOnly: _filterOverdue ? true : null,
      priority: _filterPriority,
      subjectId: _filterSubjectId,
    );
  }

  void setFilterSubject(String? subjectId) {
    if (_filterSubjectId == subjectId) return;
    _filterSubjectId = subjectId;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setFilters({
    bool? completed,
    bool? overdue,
    String? priority,
  }) {
    if (_filterCompleted == completed &&
        _filterOverdue == (overdue ?? false) &&
        _filterPriority == priority) return;
    _filterCompleted = completed;
    _filterOverdue = overdue ?? false;
    _filterPriority = priority;
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

  /// Computes next occurrence date for recurring tasks.
  DateTime? _nextRecurrenceDate(Task task) {
    if (task.deadline == null) return null;
    final end = task.recurrenceEndDate;
    if (end != null && task.deadline!.isAfter(end)) return null;

    DateTime next;
    switch (task.recurrenceType) {
      case 'daily':
        next = task.deadline!.add(const Duration(days: 1));
        break;
      case 'weekly':
        next = task.deadline!.add(const Duration(days: 7));
        break;
      case 'monthly':
        next = DateTime(
          task.deadline!.year,
          task.deadline!.month + 1,
          task.deadline!.day,
          task.deadline!.hour,
          task.deadline!.minute,
        );
        break;
      default:
        return null;
    }
    if (end != null && next.isAfter(end)) return null;
    return next;
  }

  /// Returns true if next occurrence was created (for recurring tasks).
  Future<bool> toggleCompletion(Task task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);

    if (updated.isCompleted &&
        task.isRecurring &&
        task.recurrenceType != null &&
        task.recurrenceType!.isNotEmpty) {
      final nextDate = _nextRecurrenceDate(task);
      if (nextDate != null) {
        final nextTask = Task(
          id: generateId(),
          subjectId: task.subjectId,
          title: task.title,
          description: task.description,
          deadline: nextDate,
          priority: task.priority,
          isCompleted: false,
          isRecurring: true,
          recurrenceType: task.recurrenceType,
          recurrenceEndDate: task.recurrenceEndDate,
        );
        await addTask(nextTask);
        await NotificationService.instance.scheduleTaskReminder(nextTask);
        return true;
      }
    }
    return false;
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
