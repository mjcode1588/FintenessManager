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

// 부위별 운동 상세 정보 프로바이더 (오프셋 기반)
final bodyPartExerciseDetailsProvider =
    FutureProvider.family<Map<String, List<Map<String, dynamic>>>, int>((
      ref,
      weekOffset,
    ) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;
      final now = DateTime.now();
      final weekStart = now.subtract(
        Duration(days: now.weekday - 1 - (weekOffset * 7)),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      final result = await db.rawQuery(
        '''
    SELECT 
      et.body_part,
      et.name as exercise_name,
      COUNT(*) as frequency,
      SUM(er.sets) as total_sets,
      AVG(er.weight) as avg_weight,
      AVG(er.reps) as avg_reps,
      SUM(er.weight * er.reps * er.sets) as total_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.body_part, et.name
    ORDER BY et.body_part, total_volume DESC
  ''',
        [
          weekStart.toIso8601String().split('T')[0],
          weekEnd.toIso8601String().split('T')[0],
        ],
      );

      final Map<String, List<Map<String, dynamic>>> bodyPartExercises = {};

      for (final row in result) {
        final bodyPart = row['body_part'] as String;
        final exerciseData = {
          'exercise_name': row['exercise_name'] as String,
          'frequency': row['frequency'] as int,
          'total_sets': row['total_sets'] as int?,
          'avg_weight': (row['avg_weight'] as num?)?.toDouble(),
          'avg_reps': (row['avg_reps'] as num?)?.toDouble(),
          'total_volume': (row['total_volume'] as num?)?.toDouble(),
        };

        if (!bodyPartExercises.containsKey(bodyPart)) {
          bodyPartExercises[bodyPart] = [];
        }
        bodyPartExercises[bodyPart]!.add(exerciseData);
      }

      return bodyPartExercises;
    });

// 월간 부위별 운동 상세 정보 프로바이더
final monthlyBodyPartExerciseDetailsProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final result = await db.rawQuery(
        '''
    SELECT 
      et.body_part,
      et.name as exercise_name,
      COUNT(*) as frequency,
      SUM(er.sets) as total_sets,
      AVG(er.weight) as avg_weight,
      AVG(er.reps) as avg_reps,
      SUM(er.weight * er.reps * er.sets) as total_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    GROUP BY et.body_part, et.name
    ORDER BY et.body_part, total_volume DESC
  ''',
        [
          monthStart.toIso8601String().split('T')[0],
          monthEnd.toIso8601String().split('T')[0],
        ],
      );

      final Map<String, List<Map<String, dynamic>>> bodyPartExercises = {};

      for (final row in result) {
        final bodyPart = row['body_part'] as String;
        final exerciseData = {
          'exercise_name': row['exercise_name'] as String,
          'frequency': row['frequency'] as int,
          'total_sets': row['total_sets'] as int?,
          'avg_weight': (row['avg_weight'] as num?)?.toDouble(),
          'avg_reps': (row['avg_reps'] as num?)?.toDouble(),
          'total_volume': (row['total_volume'] as num?)?.toDouble(),
        };

        if (!bodyPartExercises.containsKey(bodyPart)) {
          bodyPartExercises[bodyPart] = [];
        }
        bodyPartExercises[bodyPart]!.add(exerciseData);
      }

      return bodyPartExercises;
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

// 부위별 볼륨 추이 프로바이더 (주별)
final bodyPartVolumeTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, (int, String)>((
      ref,
      params,
    ) async {
      final (weekOffset, bodyPart) = params;
      final database = ref.watch(databaseProvider);
      final db = await database.database;
      final now = DateTime.now();
      final weekStart = now.subtract(
        Duration(days: now.weekday - 1 - (weekOffset * 7)),
      );
      final weekEnd = weekStart.add(const Duration(days: 6));

      final result = await db.rawQuery(
        '''
    SELECT 
      DATE(er.date) as date,
      SUM(er.weight * er.reps * er.sets) as volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    AND et.body_part = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
    GROUP BY DATE(er.date)
    ORDER BY DATE(er.date)
  ''',
        [
          weekStart.toIso8601String().split('T')[0],
          weekEnd.toIso8601String().split('T')[0],
          bodyPart,
        ],
      );

      return result
          .map(
            (row) => {
              'date': row['date'] as String,
              'volume': (row['volume'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    });

// 부위별 볼륨 추이 프로바이더 (월별)
final monthlyBodyPartVolumeTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      bodyPart,
    ) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final result = await db.rawQuery(
        '''
    SELECT 
      strftime('%Y-%W', er.date) as week,
      SUM(er.weight * er.reps * er.sets) as volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE DATE(er.date) BETWEEN ? AND ?
    AND et.body_part = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
    GROUP BY strftime('%Y-%W', er.date)
    ORDER BY week
  ''',
        [
          monthStart.toIso8601String().split('T')[0],
          monthEnd.toIso8601String().split('T')[0],
          bodyPart,
        ],
      );

      return result
          .map(
            (row) => {
              'date': row['week'] as String,
              'volume': (row['volume'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    });

// 부위별 개인 기록 프로바이더
final bodyPartPersonalRecordsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      bodyPart,
    ) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      final result = await db.rawQuery(
        '''
    SELECT 
      et.name as exercise_name,
      MAX(er.weight) as max_weight,
      MAX(er.reps) as max_reps,
      MAX(er.weight * er.reps * 0.0333 + er.weight) as estimated_1rm
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.body_part = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL
    GROUP BY et.name
    HAVING max_weight > 0
    ORDER BY estimated_1rm DESC
  ''',
        [bodyPart],
      );

      return result
          .map(
            (row) => {
              'exercise_name': row['exercise_name'] as String,
              'max_weight': (row['max_weight'] as num?)?.toDouble(),
              'max_reps': row['max_reps'] as int?,
              'estimated_1rm': (row['estimated_1rm'] as num?)?.toDouble(),
            },
          )
          .toList();
    });
// 전체 기간 부위별 운동 상세 정보 프로바이더
final allTimeBodyPartExerciseDetailsProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      final result = await db.rawQuery(
        '''
    SELECT 
      et.body_part,
      et.name as exercise_name,
      COUNT(*) as frequency,
      SUM(er.sets) as total_sets,
      AVG(er.weight) as avg_weight,
      AVG(er.reps) as avg_reps,
      SUM(er.weight * er.reps * er.sets) as total_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    GROUP BY et.body_part, et.name
    ORDER BY et.body_part, total_volume DESC
  ''',
      );

      final Map<String, List<Map<String, dynamic>>> bodyPartExercises = {};

      for (final row in result) {
        final bodyPart = row['body_part'] as String;
        final exerciseData = {
          'exercise_name': row['exercise_name'] as String,
          'frequency': row['frequency'] as int,
          'total_sets': row['total_sets'] as int?,
          'avg_weight': (row['avg_weight'] as num?)?.toDouble(),
          'avg_reps': (row['avg_reps'] as num?)?.toDouble(),
          'total_volume': (row['total_volume'] as num?)?.toDouble(),
        };

        if (!bodyPartExercises.containsKey(bodyPart)) {
          bodyPartExercises[bodyPart] = [];
        }
        bodyPartExercises[bodyPart]!.add(exerciseData);
      }

      return bodyPartExercises;
    });

// 전체 기간 부위별 통계 프로바이더
final allTimeBodyPartStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, bodyPart) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      final result = await db.rawQuery(
        '''
    SELECT 
      COUNT(*) as frequency,
      SUM(er.sets) as total_sets,
      AVG(er.weight) as avg_weight,
      AVG(er.reps) as avg_reps,
      SUM(er.weight * er.reps * er.sets) as total_volume,
      COUNT(DISTINCT et.name) as exercise_count
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.body_part = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
  ''',
        [bodyPart],
      );

      final row = result.first;
      return {
        'frequency': row['frequency'] as int,
        'total_sets': row['total_sets'] as int?,
        'avg_weight': (row['avg_weight'] as num?)?.toDouble(),
        'avg_reps': (row['avg_reps'] as num?)?.toDouble(),
        'total_volume': (row['total_volume'] as num?)?.toDouble(),
        'exercise_count': row['exercise_count'] as int,
      };
    });

// 운동별 진행 상황 분석 프로바이더
final exerciseProgressAnalysisProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, exerciseName) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      // 기본 통계
      final basicStats = await db.rawQuery(
        '''
    SELECT 
      COUNT(DISTINCT DATE(er.date)) as total_sessions,
      SUM(er.weight * er.reps * er.sets) as total_volume,
      AVG(er.weight * er.reps * er.sets) as avg_volume_per_session,
      MAX(er.weight) as max_weight
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.name = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
  ''',
        [exerciseName],
      );

      // 최근 트렌드 분석 (최근 5회 vs 이전 5회)
      final recentSessions = await db.rawQuery(
        '''
    SELECT 
      DATE(er.date) as date,
      SUM(er.weight * er.reps * er.sets) as session_volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.name = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
    GROUP BY DATE(er.date)
    ORDER BY DATE(er.date) DESC
    LIMIT 10
  ''',
        [exerciseName],
      );

      String trend = 'stable';
      if (recentSessions.length >= 6) {
        final recent5 = recentSessions.take(5).toList();
        final previous5 = recentSessions.skip(5).take(5).toList();
        
        final recentAvg = recent5.fold<double>(0.0, (sum, session) => 
          sum + ((session['session_volume'] as num?)?.toDouble() ?? 0.0)) / recent5.length;
        final previousAvg = previous5.fold<double>(0.0, (sum, session) => 
          sum + ((session['session_volume'] as num?)?.toDouble() ?? 0.0)) / previous5.length;
        
        if (recentAvg > previousAvg * 1.1) {
          trend = 'increasing';
        } else if (recentAvg < previousAvg * 0.9) {
          trend = 'decreasing';
        }
      }

      final row = basicStats.first;
      return {
        'total_sessions': row['total_sessions'] as int,
        'total_volume': (row['total_volume'] as num?)?.toDouble() ?? 0.0,
        'avg_volume_per_session': (row['avg_volume_per_session'] as num?)?.toDouble() ?? 0.0,
        'max_weight': (row['max_weight'] as num?)?.toDouble() ?? 0.0,
        'recent_trend': trend,
      };
    });

// 운동별 볼륨 트렌드 프로바이더
final exerciseVolumeTrendProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, exerciseName) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      final result = await db.rawQuery(
        '''
    SELECT 
      DATE(er.date) as date,
      SUM(er.weight * er.reps * er.sets) as volume
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.name = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL AND er.sets IS NOT NULL
    GROUP BY DATE(er.date)
    ORDER BY DATE(er.date) DESC
    LIMIT 20
  ''',
        [exerciseName],
      );

      return result
          .map(
            (row) => {
              'date': row['date'] as String,
              'volume': (row['volume'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList()
          .reversed
          .toList();
    });

// 운동별 중량/횟수 진행 프로바이더
final exerciseWeightRepsProgressProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, exerciseName) async {
      final database = ref.watch(databaseProvider);
      final db = await database.database;

      final result = await db.rawQuery(
        '''
    SELECT 
      DATE(er.date) as date,
      MAX(er.weight) as max_weight,
      MAX(er.reps) as max_reps,
      SUM(er.sets) as total_sets,
      MAX(er.weight * er.reps * 0.0333 + er.weight) as estimated_1rm
    FROM exercise_records er
    JOIN exercise_types et ON er.exercise_type_id = et.id
    WHERE et.name = ?
    AND er.weight IS NOT NULL AND er.reps IS NOT NULL
    GROUP BY DATE(er.date)
    ORDER BY DATE(er.date) DESC
    LIMIT 15
  ''',
        [exerciseName],
      );

      return result
          .map(
            (row) => {
              'date': row['date'] as String,
              'max_weight': (row['max_weight'] as num?)?.toDouble() ?? 0.0,
              'max_reps': row['max_reps'] as int? ?? 0,
              'total_sets': row['total_sets'] as int? ?? 0,
              'estimated_1rm': (row['estimated_1rm'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList()
          .reversed
          .toList();
    });
