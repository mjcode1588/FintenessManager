import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/weight_provider.dart';

class AddExerciseRecordDialog extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> exerciseTypes;
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onSave;

  const AddExerciseRecordDialog({
    super.key,
    required this.exerciseTypes,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  ConsumerState<AddExerciseRecordDialog> createState() => _AddExerciseRecordDialogState();
}

class _AddExerciseRecordDialogState extends ConsumerState<AddExerciseRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  int _sets = 1;

  String? _selectedCategory;
  int? _selectedExerciseTypeId;
  
  String? bodypartextension(String? part) {
    switch (part) {
      case 'chest':
        return '가슴';
      case 'back':
        return '등';
      case 'shoulders':
        return '어깨';
      case 'arms':
        return '팔';
      case 'legs':
        return '다리';
      case 'core':
        return '코어';
      case 'cardio':
        return '유산소';
    }
    return part;
  }

  List<String> get _categories =>
      widget.exerciseTypes.map((e) => e['body_part'] as String? ?? '기타')
          .map((part) => bodypartextension(part) ?? part)
          .toSet()
          .toList();

  List<Map<String, dynamic>> get _filteredExerciseTypes =>
      widget.exerciseTypes.where((e) => 
          bodypartextension(e['body_part'] as String?) == _selectedCategory ||
          e['body_part'] == _selectedCategory)
      .toList();

  Map<String, dynamic>? get _selectedExerciseType => _filteredExerciseTypes.isNotEmpty
      ? _filteredExerciseTypes.firstWhere(
          (e) => e['id'] == _selectedExerciseTypeId,
          orElse: () => _filteredExerciseTypes.first,
        )
      : null;

  void _updateWeightForBodyweight(double? latestWeight) {
    if (_selectedExerciseType?['weight_type'] == 'bodyweight' && latestWeight != null) {
      // 맨몸운동의 경우 몸무게의 2/3을 자동으로 설정
      final bodyweightLoad = (latestWeight * 2 / 3);
      _weightController.text = bodyweightLoad.toStringAsFixed(1);
    } else if (_selectedExerciseType?['weight_type'] == 'weighted') {
      // 중량운동의 경우 기존 값 유지하거나 비우기
      if (_weightController.text.isEmpty) {
        _weightController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('운동 기록 추가'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '운동 부위',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedExerciseTypeId = null;
                    _weightController.clear(); // 카테고리 변경 시 중량 필드 초기화
                  });
                },
                validator: (value) {
                  if (value == null) return '운동 부위를 선택해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedExerciseTypeId,
                decoration: const InputDecoration(
                  labelText: '운동 선택',
                  border: OutlineInputBorder(),
                ),
                items: _filteredExerciseTypes.map((exercise) {
                  return DropdownMenuItem(
                    value: exercise['id'] as int,
                    child: Text(exercise['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedExerciseTypeId = value;
                  });
                  // 운동 선택 후 몸무게 기반 중량 설정
                  final latestWeightAsync = ref.read(latestWeightProvider);
                  latestWeightAsync.whenData((latestWeight) {
                    _updateWeightForBodyweight(latestWeight);
                  });
                },
                validator: (value) {
                  if (value == null) return '운동을 선택해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedExerciseType?['counting_method'] == 'reps') ...[
                // 중량 입력 필드
                if (_selectedExerciseType?['weight_type'] == 'weighted')
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: '무게 (kg)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_selectedExerciseType?['weight_type'] == 'bodyweight')
                  Consumer(
                    builder: (context, ref, child) {
                      final latestWeightAsync = ref.watch(latestWeightProvider);
                      return latestWeightAsync.when(
                        data: (latestWeight) {
                          if (latestWeight != null && _weightController.text.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _updateWeightForBodyweight(latestWeight);
                            });
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _weightController,
                                decoration: InputDecoration(
                                  labelText: '중량 (kg) - 몸무게 기준 자동 계산',
                                  border: const OutlineInputBorder(),
                                  helperText: latestWeight != null 
                                    ? '최신 몸무게: ${latestWeight.toStringAsFixed(1)}kg → 적용 중량: ${(latestWeight * 2 / 3).toStringAsFixed(1)}kg'
                                    : '몸무게 기록을 먼저 추가해주세요',
                                  helperMaxLines: 2,
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: false, // 항상 편집 가능하도록 변경
                              ),
                              if (latestWeight == null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, 
                                           color: Colors.orange.shade600, 
                                           size: 16),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '맨몸운동의 중량 계산을 위해 몸무게를 먼저 기록해주세요.',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              '몸무게 정보를 불러오는 중...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        error: (error, stackTrace) {
                          print('몸무게 데이터 로드 오류: $error');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  labelText: '중량 (kg) - 수동 입력',
                                  border: OutlineInputBorder(),
                                  helperText: '몸무게 정보를 불러올 수 없어 수동 입력이 필요합니다',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, 
                                         color: Colors.red.shade600, 
                                         size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '몸무게 데이터를 불러올 수 없습니다. 오류: ${error.toString()}',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                if (_selectedExerciseType?['weight_type'] == 'weighted' || 
                    _selectedExerciseType?['weight_type'] == 'bodyweight')
                  const SizedBox(height: 16),
                // 횟수 입력 필드
                TextFormField(
                  controller: _repsController,
                  decoration: const InputDecoration(
                    labelText: '횟수',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '횟수를 입력해주세요';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 세트 수 선택
                Row(
                  children: [
                    const Expanded(
                      child: Text('세트 수', style: TextStyle(fontSize: 16)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        setState(() {
                          if (_sets > 1) _sets--;
                        });
                      },
                    ),
                    Text(_sets.toString(), style: const TextStyle(fontSize: 16)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        setState(() {
                          _sets++;
                        });
                      },
                    ),
                  ],
                ),
              ] else if (_selectedExerciseType?['counting_method'] == 'time') ...[
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: '시간 (초)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '시간을 입력해주세요';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: '메모 (선택사항)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(onPressed: _saveRecord, child: const Text('저장')),
      ],
    );
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;
    final record = {
      'exerciseTypeId': _selectedExerciseType?['id'] as int,
      'date': widget.selectedDate,
      'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
      'reps': _repsController.text.isNotEmpty ? int.parse(_repsController.text) : null,
      'duration': _durationController.text.isNotEmpty ? int.parse(_durationController.text) : null,
      'sets': _sets,
      'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
    };
    widget.onSave(record);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}