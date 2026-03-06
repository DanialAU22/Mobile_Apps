import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _databaseName = 'study_planner.db';
  static const _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableSubjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        subjectId TEXT,
        title TEXT NOT NULL,
        description TEXT,
        deadline TEXT,
        priority TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurrenceType TEXT,
        recurrenceEndDate TEXT,
        FOREIGN KEY (subjectId) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableExams (
        id TEXT PRIMARY KEY,
        subjectId TEXT,
        title TEXT NOT NULL,
        dateTime TEXT,
        location TEXT,
        FOREIGN KEY (subjectId) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableStudySessions (
        id TEXT PRIMARY KEY,
        subjectId TEXT,
        duration INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (subjectId) REFERENCES $tableSubjects (id) ON DELETE SET NULL
      )
    ''');

    _createIndexes(batch);
    await batch.commit();
  }

  void _createIndexes(Batch batch) {
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_subjectId ON $tableTasks(subjectId)',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON $tableTasks(deadline)',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_isCompleted ON $tableTasks(isCompleted)',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_study_sessions_subjectId ON $tableStudySessions(subjectId)',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_study_sessions_date ON $tableStudySessions(date)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint('Upgrading database from $oldVersion to $newVersion');
    }
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE $tableTasks ADD COLUMN isRecurring INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE $tableTasks ADD COLUMN recurrenceType TEXT
      ''');
      await db.execute('''
        ALTER TABLE $tableTasks ADD COLUMN recurrenceEndDate TEXT
      ''');
      await db.execute('''
        CREATE TABLE $tableStudySessions (
          id TEXT PRIMARY KEY,
          subjectId TEXT,
          duration INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (subjectId) REFERENCES $tableSubjects (id) ON DELETE SET NULL
        )
      ''');
      final batch = db.batch();
      _createIndexes(batch);
      await batch.commit();
    }
  }

  // SUBJECTS CRUD

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return db.insert(
      tableSubjects,
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subject>> getSubjects() async {
    final db = await database;
    final maps = await db.query(
      tableSubjects,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return db.update(
      tableSubjects,
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(String id) async {
    final db = await database;
    return db.delete(
      tableSubjects,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // TASKS CRUD

  Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert(
      tableTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final maps = await db.query(
      tableTasks,
      orderBy: 'deadline IS NULL, deadline ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getTasksFiltered({
    String? searchQuery,
    bool? isCompleted,
    bool? overdueOnly,
    String? priority,
    String? subjectId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR description LIKE ?)');
      final pattern = '%${searchQuery.trim()}%';
      args.addAll([pattern, pattern]);
    }
    if (isCompleted != null) {
      conditions.add('isCompleted = ?');
      args.add(isCompleted ? 1 : 0);
    }
    if (overdueOnly == true) {
      conditions.add('isCompleted = 0 AND deadline IS NOT NULL AND deadline < ?');
      args.add(DateTime.now().toIso8601String());
    }
    if (priority != null && priority.isNotEmpty) {
      conditions.add('priority = ?');
      args.add(priority);
    }
    if (subjectId != null && subjectId.isNotEmpty) {
      conditions.add('subjectId = ?');
      args.add(subjectId);
    }

    final whereClause =
        conditions.isEmpty ? null : conditions.join(' AND ');
    final maps = await db.query(
      tableTasks,
      where: whereClause,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'deadline IS NULL, deadline ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return db.delete(
      tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ANALYTICS - Optimized SQL queries

  Future<int> getOverdueTasksCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as c FROM $tableTasks
      WHERE isCompleted = 0 AND deadline IS NOT NULL AND deadline < ?
    ''', [DateTime.now().toIso8601String()]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getCompletionTrendLast30Days() async {
    final db = await database;
    final start = DateTime.now().subtract(const Duration(days: 30));
    final result = await db.rawQuery('''
      SELECT DATE(deadline) as d, COUNT(*) as c
      FROM $tableTasks
      WHERE isCompleted = 1 AND deadline >= ?
      GROUP BY DATE(deadline)
    ''', [start.toIso8601String()]);
    final map = <String, int>{};
    for (final row in result) {
      final d = row['d'] as String?;
      if (d != null) map[d] = row['c'] as int? ?? 0;
    }
    return map;
  }

  Future<int> getProductivityStreak() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(date) as d FROM $tableStudySessions
      ORDER BY d DESC
    ''');
    if (result.isEmpty) return 0;
    int streak = 0;
    DateTime? lastDate;
    final today = DateTime.now();
    for (final row in result) {
      final dStr = row['d'] as String?;
      if (dStr == null) continue;
      final dt = DateTime.tryParse(dStr);
      if (dt == null) continue;
      final dtNorm = DateTime(dt.year, dt.month, dt.day);
      if (lastDate == null) {
        final todayNorm = DateTime(today.year, today.month, today.day);
        final diff = todayNorm.difference(dtNorm).inDays;
        if (diff > 1) break;
        streak = 1;
        lastDate = dtNorm;
      } else {
        final diff = lastDate.difference(dtNorm).inDays;
        if (diff == 1) {
          streak++;
          lastDate = dtNorm;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  Future<Map<String, int>> getWeeklyStudyTimeMinutes() async {
    final db = await database;
    final weekAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final result = await db.rawQuery('''
      SELECT DATE(date) as d, SUM(duration) as total
      FROM $tableStudySessions
      WHERE date >= ?
      GROUP BY DATE(date)
    ''', [weekAgo]);
    final map = <String, int>{};
    for (final row in result) {
      final d = row['d'] as String?;
      if (d != null) map[d] = (row['total'] as num?)?.toInt() ?? 0;
    }
    return map;
  }

  Future<String?> getMostStudiedSubjectId() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT subjectId, SUM(duration) as total FROM $tableStudySessions
      WHERE subjectId IS NOT NULL
      GROUP BY subjectId
      ORDER BY total DESC
      LIMIT 1
    ''');
    if (result.isEmpty) return null;
    return result.first['subjectId'] as String?;
  }

  // STUDY SESSIONS CRUD

  Future<int> insertStudySession(StudySession session) async {
    final db = await database;
    return db.insert(
      tableStudySessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<StudySession>> getStudySessions() async {
    final db = await database;
    final maps = await db.query(
      tableStudySessions,
      orderBy: 'date DESC',
    );
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<List<StudySession>> getStudySessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      tableStudySessions,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<int> getTotalStudyMinutesBySubject(String subjectId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(duration), 0) as total
      FROM $tableStudySessions
      WHERE subjectId = ?
    ''', [subjectId]);
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  // EXAMS CRUD

  Future<int> insertExam(Exam exam) async {
    final db = await database;
    return db.insert(
      tableExams,
      exam.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Exam>> getExams() async {
    final db = await database;
    final maps = await db.query(
      tableExams,
      orderBy: 'dateTime IS NULL, dateTime ASC',
    );
    return maps.map((m) => Exam.fromMap(m)).toList();
  }

  Future<int> updateExam(Exam exam) async {
    final db = await database;
    return db.update(
      tableExams,
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(String id) async {
    final db = await database;
    return db.delete(
      tableExams,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // BATCH & RAW for export/import

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final subjects = await db.query(tableSubjects);
    final tasks = await db.query(tableTasks);
    final exams = await db.query(tableExams);
    final sessions = await db.query(tableStudySessions);
    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'subjects': subjects,
      'tasks': tasks,
      'exams': exams,
      'studySessions': sessions,
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      if (data['subjects'] != null) {
        for (final row in data['subjects'] as List) {
          await txn.insert(tableSubjects, row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['tasks'] != null) {
        for (final row in data['tasks'] as List) {
          await txn.insert(tableTasks, row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['exams'] != null) {
        for (final row in data['exams'] as List) {
          await txn.insert(tableExams, row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      if (data['studySessions'] != null) {
        for (final row in data['studySessions'] as List) {
          await txn.insert(tableStudySessions, row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableStudySessions);
      await txn.delete(tableTasks);
      await txn.delete(tableExams);
      await txn.delete(tableSubjects);
    });
  }
}
