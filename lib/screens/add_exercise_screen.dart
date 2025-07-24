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

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ExerciseCategory _selectedCategory = ExerciseCategory.weight;
  BodyPart _selectedBodyPart = BodyPart.chest;
  CountingMethod _selectedCountingMethod = CountingMethod.reps;
  WeightType _selectedWeightType = WeightType.weighted;

  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeDefaultExercises();
    
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  Future<void> _initializeDefaultExercises() async {
    // 기본 운동들은 데이터베이스 초기화 시 자동으로 추가됩니다.
    // 여기서는 별도 작업이 필요하지 않습니다.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.blue.shade50,
              Colors.indigo.shade50,
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
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
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
                colors: [Colors.green.shade400, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.go('/exercises'),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '운동 종류 추가',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '새로운 운동을 추가해보세요',
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

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.blue.shade400],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '새 운동 정보',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildTextField(),
                const SizedBox(height: 20),

                _buildCategoryDropdown(),
                const SizedBox(height: 20),

                if (_selectedCategory == ExerciseCategory.weight) ...[
                  _buildWeightTypeDropdown(),
                  const SizedBox(height: 20),
                ],

                _buildBodyPartDropdown(),
                const SizedBox(height: 20),

                _buildCountingMethodDropdown(),
                const SizedBox(height: 32),

                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 이름',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '예: 벤치프레스, 스쿼트',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.fitness_center, color: Colors.grey.shade400),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '운동 이름을 입력해주세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<ExerciseCategory>(
            value: _selectedCategory,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(
                _selectedCategory == ExerciseCategory.weight 
                  ? Icons.fitness_center 
                  : Icons.directions_run,
                color: Colors.grey.shade400,
              ),
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
        ),
      ],
    );
  }

  Widget _buildWeightTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '무게 타입',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<WeightType>(
            value: _selectedWeightType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(
                _selectedWeightType == WeightType.weighted 
                  ? Icons.fitness_center 
                  : Icons.accessibility,
                color: Colors.grey.shade400,
              ),
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
        ),
      ],
    );
  }

  Widget _buildBodyPartDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운동 부위',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<BodyPart>(
            value: _selectedBodyPart,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(
                _getBodyPartIcon(_selectedBodyPart),
                color: _getBodyPartColor(_selectedBodyPart),
              ),
            ),
            items: BodyPart.values.map((bodyPart) {
              return DropdownMenuItem(
                value: bodyPart,
                child: Row(
                  children: [
                    Icon(
                      _getBodyPartIcon(bodyPart),
                      color: _getBodyPartColor(bodyPart),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_getBodyPartName(bodyPart)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBodyPart = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountingMethodDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카운팅 방법',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonFormField<CountingMethod>(
            value: _selectedCountingMethod,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: Icon(
                _selectedCountingMethod == CountingMethod.reps 
                  ? Icons.numbers 
                  : Icons.timer,
                color: Colors.grey.shade400,
              ),
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
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.blue.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade200,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _addExercise,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '운동 추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
      final existingExercise = await database.getExerciseTypeByName(
        exerciseName,
      );

      if (existingExercise != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미 추가된 운동입니다.')));
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('운동이 추가되었습니다')));
          context.go('/exercises');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getBodyPartColor(BodyPart bodyPart) {
    switch (bodyPart) {
      case BodyPart.chest:
        return Colors.red.shade400;
      case BodyPart.back:
        return Colors.blue.shade400;
      case BodyPart.shoulders:
        return Colors.orange.shade400;
      case BodyPart.arms:
        return Colors.green.shade400;
      case BodyPart.legs:
        return Colors.purple.shade400;
      case BodyPart.core:
        return Colors.teal.shade400;
      case BodyPart.cardio:
        return Colors.pink.shade400;
    }
  }

  IconData _getBodyPartIcon(BodyPart bodyPart) {
    switch (bodyPart) {
      case BodyPart.chest:
        return Icons.favorite;
      case BodyPart.back:
        return Icons.accessibility_new;
      case BodyPart.shoulders:
        return Icons.sports_gymnastics;
      case BodyPart.arms:
        return Icons.sports_martial_arts;
      case BodyPart.legs:
        return Icons.directions_run;
      case BodyPart.core:
        return Icons.center_focus_strong;
      case BodyPart.cardio:
        return Icons.favorite_border;
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
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}