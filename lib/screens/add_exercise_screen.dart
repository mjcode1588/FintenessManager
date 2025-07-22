import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/exercise_type.dart';
import '../providers/database_provider.dart';
import '../providers/exercise_provider.dart';

class AddExerciseScreen extends ConsumerStatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  ExerciseCategory _selectedCategory = ExerciseCategory.weight;
  BodyPart _selectedBodyPart = BodyPart.chest;
  CountingMethod _selectedCountingMethod = CountingMethod.reps;
  WeightType _selectedWeightType = WeightType.weighted;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaultExercises();
  }

  Future<void> _initializeDefaultExercises() async {
    // 기본 운동들은 데이터베이스 초기화 시 자동으로 추가됩니다.
    // 여기서는 별도 작업이 필요하지 않습니다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 종류 추가'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '새 운동 추가',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '운동 이름',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '운동 이름을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<ExerciseCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: '운동 카테고리',
                      border: OutlineInputBorder(),
                    ),
                    items: ExerciseCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryName(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                        if (value == ExerciseCategory.cardio) {
                          _selectedWeightType = WeightType.bodyweight;
                          _selectedCountingMethod = CountingMethod.time;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  if (_selectedCategory == ExerciseCategory.weight)
                    DropdownButtonFormField<WeightType>(
                      value: _selectedWeightType,
                      decoration: const InputDecoration(
                        labelText: '무게 타입',
                        border: OutlineInputBorder(),
                      ),
                      items: WeightType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(_getWeightTypeName(type)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedWeightType = value!;
                        });
                      },
                    ),
                  if (_selectedCategory == ExerciseCategory.weight)
                    const SizedBox(height: 16),

                  DropdownButtonFormField<BodyPart>(
                    value: _selectedBodyPart,
                    decoration: const InputDecoration(
                      labelText: '운동 부위',
                      border: OutlineInputBorder(),
                    ),
                    items: BodyPart.values.map((bodyPart) {
                      return DropdownMenuItem(
                        value: bodyPart,
                        child: Text(_getBodyPartName(bodyPart)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBodyPart = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<CountingMethod>(
                    value: _selectedCountingMethod,
                    decoration: const InputDecoration(
                      labelText: '카운팅 방법',
                      border: OutlineInputBorder(),
                    ),
                    items: CountingMethod.values.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(_getCountingMethodName(method)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCountingMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addExercise,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('운동 추가'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final exerciseName = _nameController.text.trim();

    try {
      final database = ref.read(databaseProvider);
      final existingExercise = await database.getExerciseTypeByName(exerciseName);

      if (existingExercise != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 추가된 운동입니다.')),
          );
        }
      } else {
        await database.insertExerciseType({
          'name': exerciseName,
          'category': _selectedCategory.name,
          'body_part': _selectedBodyPart.name,
          'counting_method': _selectedCountingMethod.name,
          'weight_type': _selectedWeightType.name,
        });

        if (mounted) {
          ref.invalidate(exerciseTypesProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('운동이 추가되었습니다')),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryName(ExerciseCategory category) {
    switch (category) {
      case ExerciseCategory.weight:
        return '웨이트';
      case ExerciseCategory.cardio:
        return '유산소';
    }
  }

  String _getBodyPartName(BodyPart bodyPart) {
    switch (bodyPart) {
      case BodyPart.chest:
        return '가슴';
      case BodyPart.back:
        return '등';
      case BodyPart.shoulders:
        return '어깨';
      case BodyPart.arms:
        return '팔';
      case BodyPart.legs:
        return '다리';
      case BodyPart.core:
        return '코어';
      case BodyPart.cardio:
        return '유산소';
    }
  }

  String _getCountingMethodName(CountingMethod method) {
    switch (method) {
      case CountingMethod.reps:
        return '횟수';
      case CountingMethod.time:
        return '시간';
    }
  }

  String _getWeightTypeName(WeightType type) {
    switch (type) {
      case WeightType.bodyweight:
        return '맨몸운동';
      case WeightType.weighted:
        return '중량운동';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}