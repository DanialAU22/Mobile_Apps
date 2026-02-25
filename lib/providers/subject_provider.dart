import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/subject.dart';

class SubjectProvider extends ChangeNotifier {
  final List<Subject> _subjects = [];
  bool _isLoading = false;

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DatabaseHelper.instance.getSubjects();
      _subjects
        ..clear()
        ..addAll(data);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error loading subjects: $e\n$s');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      await DatabaseHelper.instance.insertSubject(subject);
      _subjects.add(subject);
      notifyListeners();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error adding subject: $e\n$s');
      }
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await DatabaseHelper.instance.updateSubject(subject);
      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
        notifyListeners();
      }
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error updating subject: $e\n$s');
      }
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      await DatabaseHelper.instance.deleteSubject(id);
      _subjects.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error deleting subject: $e\n$s');
      }
    }
  }

  Subject? findById(String? id) {
    if (id == null) return null;
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

