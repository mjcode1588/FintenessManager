import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import 'database_provider.dart';

// 모든 몸무게 기록 프로바이더
final weightRecordsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final database = ref.watch(databaseProvider);
  return await database.getAllWeightRecords();
});

// 특정 날짜의 몸무게 기록 프로바이더
final weightRecordByDateProvider = 
    FutureProvider.family<Map<String, dynamic>?, DateTime>((ref, date) async {
  final database = ref.watch(databaseProvider);
  return await database.getWeightRecordByDate(date);
});

// 몸무게 기록 관리 프로바이더
final weightRecordNotifierProvider = 
    StateNotifierProvider<WeightRecordNotifier, AsyncValue<void>>((ref) {
  return WeightRecordNotifier(ref.watch(databaseProvider));
});

class WeightRecordNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseHelper _database;

  WeightRecordNotifier(this._database) : super(const AsyncValue.data(null));

  Future<void> addWeightRecord({
    required DateTime date,
    required double weight,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _database.insertWeightRecord({
        'date': date.toIso8601String(),
        'weight': weight,
        'notes': notes,
      });
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateWeightRecord(Map<String, dynamic> record) async {
    state = const AsyncValue.loading();
    try {
      await _database.updateWeightRecord(record);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteWeightRecord(int id) async {
    state = const AsyncValue.loading();
    try {
      await _database.deleteWeightRecord(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}