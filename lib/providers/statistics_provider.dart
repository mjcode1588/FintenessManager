import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

// 주간 통계 프로바이더
final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  final totalVolume = await database.getTotalVolumeByDateRange(weekStart, weekEnd);
  final workoutDays = await database.getWorkoutDaysByDateRange(weekStart, weekEnd);
  final bodyPartFrequency = await database.getExerciseFrequencyByBodyPart(weekStart, weekEnd);

  return {
    'totalVolume': totalVolume,
    'workoutDays': workoutDays,
    'bodyPartFrequency': bodyPartFrequency,
  };
});

// 월간 통계 프로바이더
final monthlyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  final totalVolume = await database.getTotalVolumeByDateRange(monthStart, monthEnd);
  final workoutDays = await database.getWorkoutDaysByDateRange(monthStart, monthEnd);
  final bodyPartFrequency = await database.getExerciseFrequencyByBodyPart(monthStart, monthEnd);

  return {
    'totalVolume': totalVolume,
    'workoutDays': workoutDays,
    'bodyPartFrequency': bodyPartFrequency,
  };
});

// 최근 몸무게 평균 프로바이더
final recentWeightAverageProvider = FutureProvider<double?>((ref) async {
  final database = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weekStart = now.subtract(const Duration(days: 7));

  final records = await database.getAllWeightRecords();
  final recentRecords = records.where((record) {
    final date = DateTime.parse(record['date'] as String);
    return date.isAfter(weekStart);
  }).toList();

  if (recentRecords.isEmpty) return null;

  final totalWeight = recentRecords.fold<double>(
    0.0,
    (sum, record) => sum + (record['weight'] as double),
  );

  return totalWeight / recentRecords.length;
});