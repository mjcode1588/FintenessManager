import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/exercise_type.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    if (kIsWeb) {
      // 웹에서는 간단한 파일명만 사용
      path = 'fitness_app.db';
    } else {
      // 모바일에서는 기존 방식 사용
      path = join(await getDatabasesPath(), 'fitness_app.db');
    }
    
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 운동 종류 테이블
    await db.execute('''
      CREATE TABLE exercise_types(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        body_part TEXT NOT NULL,
        counting_method TEXT NOT NULL,
        weight_type TEXT NOT NULL DEFAULT 'weighted'
      )
    ''');

    // 운동 기록 테이블
    await db.execute('''
      CREATE TABLE exercise_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_type_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        weight REAL,
        reps INTEGER,
        duration INTEGER,
        sets INTEGER,
        notes TEXT,
        FOREIGN KEY (exercise_type_id) REFERENCES exercise_types (id)
      )
    ''');

    // 몸무게 기록 테이블
    await db.execute('''
      CREATE TABLE weight_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        notes TEXT
      )
    ''');

    // 기본 운동 종류 데이터 삽입
    await _insertDefaultExercises(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // weight_type 컬럼 추가
      await db.execute('ALTER TABLE exercise_types ADD COLUMN weight_type TEXT NOT NULL DEFAULT "weighted"');
    }
  }

  Future<void> _insertDefaultExercises(Database db) async {
    for (final exerciseData in DefaultExercises.exercises) {
      await db.insert('exercise_types', {
        'name': exerciseData['name'],
        'category': exerciseData['category'],
        'body_part': exerciseData['bodyPart'],
        'counting_method': exerciseData['countingMethod'],
      });
    }
  }

  // 운동 종류 관련 메서드
  Future<List<Map<String, dynamic>>> getAllExerciseTypes() async {
    final db = await database;
    return await db.query('exercise_types');
  }

  Future<List<Map<String, dynamic>>> getExerciseTypesByBodyPart(String bodyPart) async {
    final db = await database;
    return await db.query(
      'exercise_types',
      where: 'body_part = ?',
      whereArgs: [bodyPart],
    );
  }

  Future<int> insertExerciseType(Map<String, dynamic> exerciseType) async {
    final db = await database;
    return await db.insert('exercise_types', exerciseType);
  }

  Future<int> updateExerciseType(Map<String, dynamic> exerciseType) async {
    final db = await database;
    return await db.update(
      'exercise_types',
      exerciseType,
      where: 'id = ?',
      whereArgs: [exerciseType['id']],
    );
  }

  Future<int> deleteExerciseType(int id) async {
    final db = await database;
    return await db.delete(
      'exercise_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 운동 기록 관련 메서드
  Future<List<Map<String, dynamic>>> getExerciseRecordsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    return await db.rawQuery('''
      SELECT er.*, et.name as exercise_name, et.category, et.counting_method
      FROM exercise_records er
      JOIN exercise_types et ON er.exercise_type_id = et.id
      WHERE DATE(er.date) = ?
      ORDER BY er.id DESC
    ''', [dateStr]);
  }

  Future<int> insertExerciseRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('exercise_records', record);
  }

  Future<int> updateExerciseRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.update(
      'exercise_records',
      record,
      where: 'id = ?',
      whereArgs: [record['id']],
    );
  }

  Future<int> deleteExerciseRecord(int id) async {
    final db = await database;
    return await db.delete(
      'exercise_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 몸무게 기록 관련 메서드
  Future<List<Map<String, dynamic>>> getAllWeightRecords() async {
    final db = await database;
    return await db.query(
      'weight_records',
      orderBy: 'date DESC',
    );
  }

  Future<Map<String, dynamic>?> getWeightRecordByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final results = await db.query(
      'weight_records',
      where: 'DATE(date) = ?',
      whereArgs: [dateStr],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> insertWeightRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.insert('weight_records', record);
  }

  Future<int> updateWeightRecord(Map<String, dynamic> record) async {
    final db = await database;
    return await db.update(
      'weight_records',
      record,
      where: 'id = ?',
      whereArgs: [record['id']],
    );
  }

  Future<int> deleteWeightRecord(int id) async {
    final db = await database;
    return await db.delete(
      'weight_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 통계 관련 메서드
  Future<double> getTotalVolumeByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT SUM(weight * reps * sets) as total_volume
      FROM exercise_records
      WHERE DATE(date) BETWEEN ? AND ?
      AND weight IS NOT NULL AND reps IS NOT NULL AND sets IS NOT NULL
    ''', [startStr, endStr]);
    
    return (result.first['total_volume'] as double?) ?? 0.0;
  }

  Future<int> getWorkoutDaysByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT DATE(date)) as workout_days
      FROM exercise_records
      WHERE DATE(date) BETWEEN ? AND ?
    ''', [startStr, endStr]);
    
    return (result.first['workout_days'] as int?) ?? 0;
  }

  Future<Map<String, int>> getExerciseFrequencyByBodyPart(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = start.toIso8601String().split('T')[0];
    final endStr = end.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT et.body_part, COUNT(*) as frequency
      FROM exercise_records er
      JOIN exercise_types et ON er.exercise_type_id = et.id
      WHERE DATE(er.date) BETWEEN ? AND ?
      GROUP BY et.body_part
    ''', [startStr, endStr]);
    
    Map<String, int> frequency = {};
    for (final row in result) {
      frequency[row['body_part'] as String] = row['frequency'] as int;
    }
    return frequency;
  }
}