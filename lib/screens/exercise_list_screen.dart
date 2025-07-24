import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/exercise_provider.dart';
import '../providers/database_provider.dart';
import '../navigation/back_button_mixin.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> 
    with TickerProviderStateMixin, BackButtonMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseTypesAsync = ref.watch(exerciseTypesProvider);

    return buildWithBackButton(
      child: Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.indigo.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: exerciseTypesAsync.when(
                      data: (exerciseTypes) => _buildExerciseList(exerciseTypes),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => _buildErrorState(error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.indigo.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Consumer(
              builder: (context, ref, _) {
                return IconButton(
                  onPressed: () async {
                    if (!context.mounted) return;
                    
                    final navigationManager = ref.read(navigationManagerProvider);
                    final result = await navigationManager.handleBackNavigation(context);
                    
                    if (context.mounted) {
                      await navigationManager.executeNavigation(context, result);
                    }
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운동 종류 관리',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '운동 종류를 추가하고 관리하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.indigo.shade500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => context.go('/exercises/add'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
  Widget _buildExerciseList(List<Map<String, dynamic>> exerciseTypes) {
    if (exerciseTypes.isEmpty) {
      return _buildEmptyState();
    }

    // 부위별로 그룹화
    final groupedExercises = <String, List<Map<String, dynamic>>>{};
    for (final exercise in exerciseTypes) {
      final bodyPart = exercise['body_part'] as String;
      groupedExercises.putIfAbsent(bodyPart, () => []).add(exercise);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: groupedExercises.length,
      itemBuilder: (context, index) {
        final bodyPart = groupedExercises.keys.elementAt(index);
        final exercises = groupedExercises[bodyPart]!;
        
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 400 + (index * 100)),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: _buildBodyPartCard(bodyPart, exercises),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade200, Colors.grey.shade100],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '등록된 운동이 없습니다',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '새로운 운동을 추가해보세요!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.indigo.shade500],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => context.go('/exercises/add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                '운동 추가하기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '오류가 발생했습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBodyPartCard(String bodyPart, List<Map<String, dynamic>> exercises) {
    final bodyPartColor = _getBodyPartColor(bodyPart);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bodyPartColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [bodyPartColor, bodyPartColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getBodyPartIcon(bodyPart),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getBodyPartName(bodyPart),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bodyPartColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${exercises.length}개',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bodyPartColor,
                  ),
                ),
              ),
            ],
          ),
          children: exercises.map((exercise) => _buildExerciseItem(exercise, bodyPartColor)).toList(),
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Map<String, dynamic> exercise, Color bodyPartColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bodyPartColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bodyPartColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['name'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bodyPartColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryName(exercise['category'] as String),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: bodyPartColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCountingMethodName(exercise['counting_method'] as String),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showEditExerciseDialog(context, ref, exercise),
                  icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _showDeleteConfirmDialog(context, ref, exercise),
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 20),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

  Color _getBodyPartColor(String bodyPart) {
    switch (bodyPart) {
      case 'chest':
        return Colors.red.shade400;
      case 'back':
        return Colors.blue.shade400;
      case 'shoulders':
        return Colors.orange.shade400;
      case 'arms':
        return Colors.green.shade400;
      case 'legs':
        return Colors.purple.shade400;
      case 'core':
        return Colors.teal.shade400;
      case 'cardio':
        return Colors.pink.shade400;
      default:
        return Colors.grey.shade400;
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
        return Icons.favorite;
      case 'back':
        return Icons.accessibility_new;
      case 'shoulders':
        return Icons.sports_gymnastics;
      case 'arms':
        return Icons.sports_martial_arts;
      case 'legs':
        return Icons.directions_run;
      case 'core':
        return Icons.center_focus_strong;
      case 'cardio':
        return Icons.favorite_border;
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