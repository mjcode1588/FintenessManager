// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExerciseRecordImpl _$$ExerciseRecordImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseRecordImpl(
      id: (json['id'] as num).toInt(),
      exerciseTypeId: (json['exerciseTypeId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num?)?.toInt(),
      duration: (json['duration'] as num?)?.toInt(),
      sets: (json['sets'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      exerciseName: json['exerciseName'] as String? ?? '',
    );

Map<String, dynamic> _$$ExerciseRecordImplToJson(
  _$ExerciseRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'exerciseTypeId': instance.exerciseTypeId,
  'date': instance.date.toIso8601String(),
  'weight': instance.weight,
  'reps': instance.reps,
  'duration': instance.duration,
  'sets': instance.sets,
  'notes': instance.notes,
  'exerciseName': instance.exerciseName,
};
