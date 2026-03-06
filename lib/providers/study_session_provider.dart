import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/study_session.dart';

class StudySessionProvider extends ChangeNotifier {
  final List<StudySession> _sessions = [];
  bool _isLoading = false;

  List<StudySession> get sessions => List.unmodifiable(_sessions);
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await DatabaseHelper.instance.getStudySessions();
      _sessions
        ..clear()
        ..addAll(data);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error loading study sessions: $e\n$s');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSession(StudySession session) async {
    try {
      await DatabaseHelper.instance.insertStudySession(session);
      _sessions.insert(0, session);
      notifyListeners();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error adding study session: $e\n$s');
      }
      rethrow;
    }
  }

  Future<int> getProductivityStreak() async {
    try {
      return await DatabaseHelper.instance.getProductivityStreak();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error getting streak: $e\n$s');
      }
      return 0;
    }
  }

  Future<Map<String, int>> getWeeklyStudyMinutes() async {
    try {
      return await DatabaseHelper.instance.getWeeklyStudyTimeMinutes();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error getting weekly study: $e\n$s');
      }
      return {};
    }
  }

  Future<String?> getMostStudiedSubjectId() async {
    try {
      return await DatabaseHelper.instance.getMostStudiedSubjectId();
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('Error getting most studied: $e\n$s');
      }
      return null;
    }
  }
}
