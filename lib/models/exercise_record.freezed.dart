// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ExerciseRecord _$ExerciseRecordFromJson(Map<String, dynamic> json) {
  return _ExerciseRecord.fromJson(json);
}

/// @nodoc
mixin _$ExerciseRecord {
  int get id => throw _privateConstructorUsedError;
  int get exerciseTypeId => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  double? get weight => throw _privateConstructorUsedError; // kg
  int? get reps => throw _privateConstructorUsedError; // 횟수
  int? get duration => throw _privateConstructorUsedError; // 시간 (초)
  int? get sets => throw _privateConstructorUsedError; // 세트 수
  String? get notes => throw _privateConstructorUsedError; // 메모
  String get exerciseName => throw _privateConstructorUsedError;

  /// Serializes this ExerciseRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExerciseRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExerciseRecordCopyWith<ExerciseRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExerciseRecordCopyWith<$Res> {
  factory $ExerciseRecordCopyWith(
    ExerciseRecord value,
    $Res Function(ExerciseRecord) then,
  ) = _$ExerciseRecordCopyWithImpl<$Res, ExerciseRecord>;
  @useResult
  $Res call({
    int id,
    int exerciseTypeId,
    DateTime date,
    double? weight,
    int? reps,
    int? duration,
    int? sets,
    String? notes,
    String exerciseName,
  });
}

/// @nodoc
class _$ExerciseRecordCopyWithImpl<$Res, $Val extends ExerciseRecord>
    implements $ExerciseRecordCopyWith<$Res> {
  _$ExerciseRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExerciseRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseTypeId = null,
    Object? date = null,
    Object? weight = freezed,
    Object? reps = freezed,
    Object? duration = freezed,
    Object? sets = freezed,
    Object? notes = freezed,
    Object? exerciseName = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            exerciseTypeId: null == exerciseTypeId
                ? _value.exerciseTypeId
                : exerciseTypeId // ignore: cast_nullable_to_non_nullable
                      as int,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            weight: freezed == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double?,
            reps: freezed == reps
                ? _value.reps
                : reps // ignore: cast_nullable_to_non_nullable
                      as int?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int?,
            sets: freezed == sets
                ? _value.sets
                : sets // ignore: cast_nullable_to_non_nullable
                      as int?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            exerciseName: null == exerciseName
                ? _value.exerciseName
                : exerciseName // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExerciseRecordImplCopyWith<$Res>
    implements $ExerciseRecordCopyWith<$Res> {
  factory _$$ExerciseRecordImplCopyWith(
    _$ExerciseRecordImpl value,
    $Res Function(_$ExerciseRecordImpl) then,
  ) = __$$ExerciseRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int exerciseTypeId,
    DateTime date,
    double? weight,
    int? reps,
    int? duration,
    int? sets,
    String? notes,
    String exerciseName,
  });
}

/// @nodoc
class __$$ExerciseRecordImplCopyWithImpl<$Res>
    extends _$ExerciseRecordCopyWithImpl<$Res, _$ExerciseRecordImpl>
    implements _$$ExerciseRecordImplCopyWith<$Res> {
  __$$ExerciseRecordImplCopyWithImpl(
    _$ExerciseRecordImpl _value,
    $Res Function(_$ExerciseRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExerciseRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseTypeId = null,
    Object? date = null,
    Object? weight = freezed,
    Object? reps = freezed,
    Object? duration = freezed,
    Object? sets = freezed,
    Object? notes = freezed,
    Object? exerciseName = null,
  }) {
    return _then(
      _$ExerciseRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        exerciseTypeId: null == exerciseTypeId
            ? _value.exerciseTypeId
            : exerciseTypeId // ignore: cast_nullable_to_non_nullable
                  as int,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        weight: freezed == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double?,
        reps: freezed == reps
            ? _value.reps
            : reps // ignore: cast_nullable_to_non_nullable
                  as int?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int?,
        sets: freezed == sets
            ? _value.sets
            : sets // ignore: cast_nullable_to_non_nullable
                  as int?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        exerciseName: null == exerciseName
            ? _value.exerciseName
            : exerciseName // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseRecordImpl extends _ExerciseRecord {
  const _$ExerciseRecordImpl({
    required this.id,
    required this.exerciseTypeId,
    required this.date,
    this.weight,
    this.reps,
    this.duration,
    this.sets,
    this.notes,
    this.exerciseName = '',
  }) : super._();

  factory _$ExerciseRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseRecordImplFromJson(json);

  @override
  final int id;
  @override
  final int exerciseTypeId;
  @override
  final DateTime date;
  @override
  final double? weight;
  // kg
  @override
  final int? reps;
  // 횟수
  @override
  final int? duration;
  // 시간 (초)
  @override
  final int? sets;
  // 세트 수
  @override
  final String? notes;
  // 메모
  @override
  @JsonKey()
  final String exerciseName;

  @override
  String toString() {
    return 'ExerciseRecord(id: $id, exerciseTypeId: $exerciseTypeId, date: $date, weight: $weight, reps: $reps, duration: $duration, sets: $sets, notes: $notes, exerciseName: $exerciseName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseTypeId, exerciseTypeId) ||
                other.exerciseTypeId == exerciseTypeId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    exerciseTypeId,
    date,
    weight,
    reps,
    duration,
    sets,
    notes,
    exerciseName,
  );

  /// Create a copy of ExerciseRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseRecordImplCopyWith<_$ExerciseRecordImpl> get copyWith =>
      __$$ExerciseRecordImplCopyWithImpl<_$ExerciseRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseRecordImplToJson(this);
  }
}

abstract class _ExerciseRecord extends ExerciseRecord {
  const factory _ExerciseRecord({
    required final int id,
    required final int exerciseTypeId,
    required final DateTime date,
    final double? weight,
    final int? reps,
    final int? duration,
    final int? sets,
    final String? notes,
    final String exerciseName,
  }) = _$ExerciseRecordImpl;
  const _ExerciseRecord._() : super._();

  factory _ExerciseRecord.fromJson(Map<String, dynamic> json) =
      _$ExerciseRecordImpl.fromJson;

  @override
  int get id;
  @override
  int get exerciseTypeId;
  @override
  DateTime get date;
  @override
  double? get weight; // kg
  @override
  int? get reps; // 횟수
  @override
  int? get duration; // 시간 (초)
  @override
  int? get sets; // 세트 수
  @override
  String? get notes; // 메모
  @override
  String get exerciseName;

  /// Create a copy of ExerciseRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseRecordImplCopyWith<_$ExerciseRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
