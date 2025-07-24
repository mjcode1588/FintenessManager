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

// 최신 몸무게 기록 프로바이더
final latestWeightProvider = FutureProvider<double?>((ref) async {
  try {
    final database = ref.watch(databaseProvider);
    final records = await database.getAllWeightRecords();
    
    print('몸무게 기록 개수: ${records.length}');
    if (records.isNotEmpty) {
      print('첫 번째 기록: ${records.first}');
    }
    
    if (records.isEmpty) return null;
    
    // 날짜순으로 정렬하여 가장 최신 기록 반환
    final sortedRecords = List<Map<String, dynamic>>.from(records);
    sortedRecords.sort((a, b) {
      final dateA = a['date'] != null ? DateTime.parse(a['date'] as String) : DateTime(1970);
      final dateB = b['date'] != null ? DateTime.parse(b['date'] as String) : DateTime(1970);
      return dateB.compareTo(dateA); // 최신 날짜가 먼저 오도록 내림차순 정렬
    });
    
    final latestWeight = (sortedRecords.first['weight'] as num?)?.toDouble();
  
    print('최신 몸무게: $latestWeight');
    return latestWeight;
  } catch (e, stackTrace) {
    print('latestWeightProvider 오류: $e');
    print('스택 트레이스: $stackTrace');
    rethrow;
  }
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