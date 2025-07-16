import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise_record.freezed.dart';
part 'exercise_record.g.dart';

@freezed
class ExerciseRecord with _$ExerciseRecord {
  const factory ExerciseRecord({
    required int id,
    required int exerciseTypeId,
    required DateTime date,
    double? weight, // kg
    int? reps, // 횟수
    int? duration, // 시간 (초)
    int? sets, // 세트 수
    String? notes, // 메모
  }) = _ExerciseRecord;

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) =>
      _$ExerciseRecordFromJson(json);
}