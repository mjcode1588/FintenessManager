import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/exercise_type.dart';
import 'database_provider.dart';

// 운동 종류 목록 프로바이더
final exerciseTypesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.getAllExerciseTypes();
});

// 부위별 운동 종류 프로바이더
final exerciseTypesByBodyPartProvider = 
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, bodyPart) async {
  final database = ref.watch(databaseProvider);
  return await database.getExerciseTypesByBodyPart(bodyPart);
});

// 특정 날짜의 운동 기록 프로바이더
final exerciseRecordsByDateProvider = 
    FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  final database = ref.watch(databaseProvider);
  return await database.getExerciseRecordsByDate(date);
});

// 운동 기록 관리 프로바이더
final exerciseRecordNotifierProvider = 
    StateNotifierProvider<ExerciseRecordNotifier, AsyncValue<void>>((ref) {
  return ExerciseRecordNotifier(ref.watch(databaseProvider));
});

class ExerciseRecordNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _database;

  ExerciseRecordNotifier(this._database) : super(const AsyncValue.data(null));

  Future<void> addExerciseRecord({
    required int exerciseTypeId,
    required DateTime date,
    double? weight,
    int? reps,
    int? duration,
    int? sets,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _database.insertExerciseRecord({
        'exercise_type_id': exerciseTypeId,
        'date': date.toIso8601String(),
        'weight': weight,
        'reps': reps,
        'duration': duration,
        'sets': sets,
        'notes': notes,
      });
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateExerciseRecord(Map<String, dynamic> record) async {
    state = const AsyncValue.loading();
    try {
      await _database.updateExerciseRecord(record);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteExerciseRecord(int id) async {
    state = const AsyncValue.loading();
    try {
      await _database.deleteExerciseRecord(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}