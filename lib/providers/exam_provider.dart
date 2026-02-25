import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/exam.dart';
import '../services/notification_service.dart';

class ExamProvider extends ChangeNotifier {
  final List<Exam> _exams = [];
  bool _isLoading = false;

  List<Exam> get exams => List.unmodifiable(_exams);
  bool get isLoading => _isLoading;

  Future<void> loadExams() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DatabaseHelper.instance.getExams();
      _exams
        ..clear()
        ..addAll(data);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error loading exams: $e\n$s');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExam(Exam exam) async {
    try {
      await DatabaseHelper.instance.insertExam(exam);
      _exams.add(exam);
      notifyListeners();
      await NotificationService.instance.scheduleExamReminder(exam);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error adding exam: $e\n$s');
      }
    }
  }

  Future<void> updateExam(Exam exam) async {
    try {
      await DatabaseHelper.instance.updateExam(exam);
      final index = _exams.indexWhere((e) => e.id == exam.id);
      if (index != -1) {
        _exams[index] = exam;
        notifyListeners();
        await NotificationService.instance.scheduleExamReminder(exam);
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error updating exam: $e\n$s');
      }
    }
  }

  Future<void> deleteExam(Exam exam) async {
    try {
      await DatabaseHelper.instance.deleteExam(exam.id);
      _exams.removeWhere((e) => e.id == exam.id);
      notifyListeners();
      await NotificationService.instance.cancelExamNotifications(exam.id);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error deleting exam: $e\n$s');
      }
    }
  }

  List<Exam> examsForDay(DateTime day) {
    return _exams.where((e) {
      if (e.dateTime == null) return false;
      final d = e.dateTime!;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<Exam> examsForNextDays(int days) {
    final now = DateTime.now();
    final end = now.add(Duration(days: days));
    return _exams.where((e) {
      final d = e.dateTime;
      if (d == null) return false;
      return !d.isBefore(now) && !d.isAfter(end);
    }).toList();
  }
}

