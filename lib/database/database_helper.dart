import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/subject.dart';
import '../models/task.dart';
import '../models/exam.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const _databaseName = 'study_planner.db';
  static const _databaseVersion = 1;

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

    await batch.commit();
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint('Upgrading database from $oldVersion to $newVersion');
    }
    // Add migration steps when bumping _databaseVersion.
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
}

