import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/exercise_type.dart';
import '../providers/exercise_provider.dart';
import '../providers/database_provider.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseTypesAsync = ref.watch(exerciseTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('운동 종류 관리'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            onPressed: () => context.go('/add-exercise'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: exerciseTypesAsync.when(
        data: (exerciseTypes) {
          if (exerciseTypes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '등록된 운동이 없습니다.\n새로운 운동을 추가해보세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // 부위별로 그룹화
          final groupedExercises = <String, List<Map<String, dynamic>>>{};
          for (final exercise in exerciseTypes) {
            final bodyPart = exercise['body_part'] as String;
            groupedExercises.putIfAbsent(bodyPart, () => []).add(exercise);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedExercises.length,
            itemBuilder: (context, index) {
              final bodyPart = groupedExercises.keys.elementAt(index);
              final exercises = groupedExercises[bodyPart]!;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    _getBodyPartName(bodyPart),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  leading: Icon(_getBodyPartIcon(bodyPart)),
                  children: exercises.map((exercise) {
                    return ListTile(
                      title: Text(exercise['name'] as String),
                      subtitle: Text(
                        '${_getCategoryName(exercise['category'] as String)} • ${_getCountingMethodName(exercise['counting_method'] as String)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showEditExerciseDialog(context, ref, exercise),
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () => _showDeleteConfirmDialog(context, ref, exercise),
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }

  Future<void> _showEditExerciseDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> exercise) async {
    final nameController = TextEditingController(text: exercise['name'] as String);
    String selectedCategory = exercise['category'] as String;
    String selectedBodyPart = exercise['body_part'] as String;
    String selectedCountingMethod = exercise['counting_method'] as String;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '운동 이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: '운동 카테고리',
                  border: OutlineInputBorder(),
                ),
                items: ['weight', 'cardio'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryName(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedBodyPart,
                decoration: const InputDecoration(
                  labelText: '운동 부위',
                  border: OutlineInputBorder(),
                ),
                items: ['chest', 'back', 'shoulders', 'arms', 'legs', 'core', 'cardio'].map((bodyPart) {
                  return DropdownMenuItem(
                    value: bodyPart,
                    child: Text(_getBodyPartName(bodyPart)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedBodyPart = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCountingMethod,
                decoration: const InputDecoration(
                  labelText: '카운트 방식',
                  border: OutlineInputBorder(),
                ),
                items: ['reps', 'time'].map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(_getCountingMethodName(method)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCountingMethod = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('운동 이름을 입력해주세요')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedExercise = {
        ...exercise,
        'name': nameController.text,
        'category': selectedCategory,
        'body_part': selectedBodyPart,
        'counting_method': selectedCountingMethod,
      };

      try {
        await ref.read(databaseProvider).updateExerciseType(updatedExercise);
        ref.invalidate(exerciseTypesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }

    nameController.dispose();
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운동 삭제'),
        content: Text('${exercise['name']}을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(databaseProvider).deleteExerciseType(exercise['id'] as int);
        ref.invalidate(exerciseTypesProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  String _getBodyPartName(String bodyPart) {
    switch (bodyPart) {
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
      default:
        return bodyPart;
    }
  }

  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.fitness_center;
      case 'shoulders':
        return Icons.fitness_center;
      case 'arms':
        return Icons.fitness_center;
      case 'legs':
        return Icons.directions_run;
      case 'core':
        return Icons.self_improvement;
      case 'cardio':
        return Icons.directions_bike;
      default:
        return Icons.fitness_center;
    }
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'weight':
        return '웨이트';
      case 'cardio':
        return '유산소';
      default:
        return category;
    }
  }

  String _getCountingMethodName(String method) {
    switch (method) {
      case 'reps':
        return '횟수';
      case 'time':
        return '시간';
      default:
        return method;
    }
  }
}