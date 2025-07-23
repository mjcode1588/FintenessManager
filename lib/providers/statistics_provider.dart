import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

// 주간 통계 프로바이더
final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  return await _getStatsForPeriod(database, weekStart, weekEnd);
});

// 월간 통계 프로바이더
final monthlyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  return await _getStatsForPeriod(database, monthStart, monthEnd);
});

// 최근 몸무게 평균 프로바이더
final recentWeightAverageProvider = FutureProvider<double?>((ref) async {
  final database = ref.watch(databaseProvider);
  final records = await database.getAllWeightRecords();

  if (records.isEmpty) return null;

  // 최근 7일간의 평균
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));

  final recentRecords = records.where((record) {
    final date = DateTime.parse(record['date'] as String);
    return date.isAfter(weekAgo);
  }).toList();

  if (recentRecords.isEmpty) return null;

  final totalWeight = recentRecords.fold<double>(
    0.0,
    (sum, record) => sum + (record['weight'] as double),
  );

  return totalWeight / recentRecords.length;
});

// 1RM 추정치 프로바이더
final oneRMEstimatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final database = ref.watch(databaseProvider);
  final db = await database.database;

  // 주요 운동들의 최고 기록을 가져와서 1RM 추정
  final result = await db.rawQuery('''
    SELECT et.name, MAX(er.weight * er.reps * 0.0333 + er.weight) as estimated_1rm
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE er.weight IS NOT NULL AND er.reps IS NOT NULL
    AND et.name IN ('벤치프레스', '스쿼트', '데드리프트', '숄더프레스')
    GROUP BY et.name
    HAVING estimated_1rm > 0
  ''');

  final estimates = <String, double>{};
  for (final row in result) {
    final name = row['name'] as String;
    final estimate = (row['estimated_1rm'] as num).toDouble();
    estimates[name] = estimate;
  }

  return estimates;
});

// 월간 볼륨 추이 프로바이더
final monthlyVolumeTrendProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  final db = await database.database;

  final result = await db.rawQuery('''
    SELECT 
      strftime('%Y-%W', date) as week,
      SUM(weight * reps * sets) as total_volume
    FROM exercise_records
    WHERE weight IS NOT NULL AND reps IS NOT NULL AND sets IS NOT NULL
    AND date >= date('now', '-12 weeks')
    GROUP BY strftime('%Y-%W', date)
    ORDER BY week
  ''');

  return result
      .map(
        (row) => {
          'week': row['week'] as String,
          'total_volume': (row['total_volume'] as num?)?.toDouble() ?? 0.0,
        },
      )
      .toList();
});

// 특정 주의 상세 통계 프로바이더 (오프셋 기반)
final weeklyDetailedStatsWithOffsetProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, weekOffset) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;
      final now = DateTime.now();
      final weekStart = now.subtract(
        Duration(days: now.weekday - 1 - (weekOffset * 7)),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      return await _getDetailedStatsForPeriod(db, weekStart, weekEnd);
    });

// 특정 주의 기본 통계 프로바이더 (오프셋 기반)
final weeklyStatsWithOffsetProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, weekOffset) async {
      final database = ref.watch(databaseProvider);
      final now = DateTime.now();
      final weekStart = now.subtract(
        Duration(days: now.weekday - 1 - (weekOffset * 7)),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      return await _getStatsForPeriod(database, weekStart, weekEnd);
    });

// 이번 주 상세 통계 프로바이더
final weeklyDetailedStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  final db = await database.database;
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  return await _getDetailedStatsForPeriod(db, weekStart, weekEnd);
});

// 상세 통계를 위한 공통 함수
Future<Map<String, dynamic>> _getDetailedStatsForPeriod(
  dynamic db,
  DateTime weekStart,
  DateTime weekEnd,
) async {
  // 가장 많이 한 운동 Top 3
  final topExercisesResult = await db.rawQuery(
    '''
    SELECT 
      et.name, 
      COUNT(*) as count,
      SUM(er.sets) as total_sets,
      SUM(er.weight * er.reps * er.sets) as total_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.name
    ORDER BY count DESC
    LIMIT 3
  ''',
    [
      weekStart.toIso8601String().split('T')[0],
      weekEnd.toIso8601String().split('T')[0],
    ],
  );

  // 부위별 운동 분포
  final bodyPartDistribution = await db.rawQuery(
    '''
    SELECT 
      et.body_part,
      COUNT(*) as count,
      SUM(er.sets) as total_sets
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.body_part
    ORDER BY count DESC
  ''',
    [
      weekStart.toIso8601String().split('T')[0],
      weekEnd.toIso8601String().split('T')[0],
    ],
  );

  // 일별 운동 기록
  final dailyWorkouts = await db.rawQuery(
    '''
    SELECT 
      DATE(date) as workout_date,
      COUNT(DISTINCT exercise_type_id) as exercise_count,
      SUM(sets) as total_sets,
      SUM(weight * reps * sets) as daily_volume
    FROM exercise_records
    WHERE DATE(date) BETWEEN ? AND ?
    GROUP BY DATE(date)
    ORDER BY workout_date
  ''',
    [
      weekStart.toIso8601String().split('T')[0],
      weekEnd.toIso8601String().split('T')[0],
    ],
  );

  // 개인 기록 갱신
  final personalRecords = await db.rawQuery(
    '''
    WITH MaxRecords AS (
      SELECT 
        exercise_type_id,
        MAX(weight) as max_weight,
        MAX(weight * reps * 0.0333 + weight) as estimated_1rm
      FROM exercise_records
      WHERE DATE(date) < ?
      GROUP BY exercise_type_id
    )
    SELECT 
      et.name,
      er.weight,
      er.reps,
      (er.weight * er.reps * 0.0333 + er.weight) as current_1rm
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    LEFT JOIN MaxRecords mr ON er.exercise_type_id = mr.exercise_type_id
    WHERE DATE(er.date) BETWEEN ? AND ?
    AND er.weight IS NOT NULL
    AND (mr.max_weight IS NULL OR er.weight > mr.max_weight)
    ORDER BY er.date DESC
  ''',
    [
      weekStart.toIso8601String().split('T')[0],
      weekStart.toIso8601String().split('T')[0],
      weekEnd.toIso8601String().split('T')[0],
    ],
  );

  return {
    'topExercises': topExercisesResult
        .map(
          (row) => {
            'name': row['name'] as String,
            'count': row['count'] as int,
            'total_sets': row['total_sets'] as int?,
            'total_volume': (row['total_volume'] as num?)?.toDouble(),
          },
        )
        .toList(),
    'bodyPartDistribution': bodyPartDistribution
        .map(
          (row) => {
            'body_part': row['body_part'] as String,
            'count': row['count'] as int,
            'total_sets': row['total_sets'] as int?,
          },
        )
        .toList(),
    'dailyWorkouts': dailyWorkouts
        .map(
          (row) => {
            'date': row['workout_date'] as String,
            'exercise_count': row['exercise_count'] as int,
            'total_sets': row['total_sets'] as int?,
            'daily_volume': (row['daily_volume'] as num?)?.toDouble(),
          },
        )
        .toList(),
    'personalRecords': personalRecords
        .map(
          (row) => {
            'name': row['name'] as String,
            'weight': (row['weight'] as num?)?.toDouble(),
            'reps': row['reps'] as int?,
            'estimated_1rm': (row['current_1rm'] as num?)?.toDouble(),
          },
        )
        .toList(),
  };
}

// 공통 통계 계산 함수
Future<Map<String, dynamic>> _getStatsForPeriod(
  DatabaseHelper database,
  DateTime start,
  DateTime end,
) async {
  final db = await database.database;

  // 총 볼륨 계산
  final volumeResult = await db.rawQuery(
    '''
    SELECT SUM(weight * reps * sets) as total_volume
    FROM exercise_records
    WHERE DATE(date) BETWEEN ? AND ?
    AND weight IS NOT NULL AND reps IS NOT NULL AND sets IS NOT NULL
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final totalVolume =
      (volumeResult.first['total_volume'] as num?)?.toDouble() ?? 0.0;

  // 운동 일수 계산
  final workoutDaysResult = await db.rawQuery(
    '''
    SELECT COUNT(DISTINCT DATE(date)) as workout_days
    FROM exercise_records
    WHERE DATE(date) BETWEEN ? AND ?
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final workoutDays = (workoutDaysResult.first['workout_days'] as int?) ?? 0;

  // 총 운동 시간 계산 (duration이 있는 운동들)
  final durationResult = await db.rawQuery(
    '''
    SELECT SUM(duration) as total_duration
    FROM exercise_records
    WHERE DATE(date) BETWEEN ? AND ?
    AND duration IS NOT NULL
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final totalDuration =
      (durationResult.first['total_duration'] as num?)?.toInt() ?? 0;

  // 총 세트 수 계산
  final setsResult = await db.rawQuery(
    '''
    SELECT SUM(sets) as total_sets
    FROM exercise_records
    WHERE DATE(date) BETWEEN ? AND ?
    AND sets IS NOT NULL
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final totalSets = (setsResult.first['total_sets'] as num?)?.toInt() ?? 0;

  // 부위별 볼륨 계산
  final bodyPartVolumeResult = await db.rawQuery(
    '''
    SELECT et.body_part, SUM(er.weight * er.reps * er.sets) as volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
    GROUP BY et.body_part
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final bodyPartVolume = <String, double>{};
  for (final row in bodyPartVolumeResult) {
    final bodyPart = row['body_part'] as String;
    final volume = (row['volume'] as num?)?.toDouble() ?? 0.0;
    bodyPartVolume[bodyPart] = volume;
  }

  // 부위별 운동 빈도 계산
  final bodyPartFrequencyResult = await db.rawQuery(
    '''
    SELECT et.body_part, COUNT(*) as frequency
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.body_part
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final bodyPartFrequency = <String, int>{};
  for (final row in bodyPartFrequencyResult) {
    final bodyPart = row['body_part'] as String;
    final frequency = row['frequency'] as int;
    bodyPartFrequency[bodyPart] = frequency;
  }

  // 가장 많이 한 운동 Top 5
  final topExercisesResult = await db.rawQuery(
    '''
    SELECT 
      et.name, 
      COUNT(*) as count,
      SUM(er.weight * er.reps * er.sets) as total_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.name
    ORDER BY count DESC
    LIMIT 5
  ''',
    [
      start.toIso8601String().split('T')[0],
      end.toIso8601String().split('T')[0],
    ],
  );

  final top5Exercises = topExercisesResult
      .map(
        (row) => {
          'name': row['name'] as String,
          'count': row['count'] as int,
          'total_volume': (row['total_volume'] as num?)?.toDouble(),
        },
      )
      .toList();

  return {
    'totalVolume': totalVolume,
    'workoutDays': workoutDays,
    'totalDuration': totalDuration,
    'totalSets': totalSets,
    'bodyPartVolume': bodyPartVolume,
    'bodyPartFrequency': bodyPartFrequency,
    'top5Exercises': top5Exercises,
  };
}
