import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../providers/statistics_provider.dart';

class BodyPartAnalysisTab extends ConsumerStatefulWidget {
  const BodyPartAnalysisTab({super.key});

  @override
  ConsumerState<BodyPartAnalysisTab> createState() => _BodyPartAnalysisTabState();
}

class _BodyPartAnalysisTabState extends ConsumerState<BodyPartAnalysisTab> {
  String _selectedBodyPart = 'chest'; // 선택된 부위
  String? _selectedExercise; // 선택된 운동

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '운동별 진행 분석',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 부위 선택
          _buildBodyPartSelector(),
          const SizedBox(height: 16),

          // 운동 선택
          _buildExerciseSelector(),
          const SizedBox(height: 16),

          // 선택된 운동이 있을 때만 분석 표시
          if (_selectedExercise != null) ...[
            // 운동 진행 상황 분석
            _buildExerciseProgressAnalysis(),
            const SizedBox(height: 16),

            // 운동 볼륨 트렌드
            _buildExerciseVolumeTrend(),
            const SizedBox(height: 16),

            // 운동 중량/횟수 진행
            _buildExerciseWeightRepsProgress(),
          ] else
            _buildSelectExercisePrompt(),
        ],
      ),
    );
  }

  Widget _buildBodyPartSelector() {
    final bodyParts = ['chest', 'back', 'shoulders', 'arms', 'legs', 'core'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석할 부위 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bodyParts.map((bodyPart) {
                final isSelected = _selectedBodyPart == bodyPart;
                final bodyPartName = _getBodyPartDisplayName(bodyPart);
                final bodyPartColor = _getBodyPartColor(bodyPart);
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedBodyPart = bodyPart),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? bodyPartColor : bodyPartColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: bodyPartColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getBodyPartIcon(bodyPart),
                          color: isSelected ? Colors.white : bodyPartColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bodyPartName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : bodyPartColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildExerciseSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '분석할 운동 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final detailsAsync = ref.watch(allTimeBodyPartExerciseDetailsProvider);
                
                return detailsAsync.when(
                  data: (bodyPartExercises) {
                    final exercises = bodyPartExercises[_selectedBodyPart] ?? [];
                    
                    if (exercises.isEmpty) {
                      return const Text(
                        '해당 부위에 운동 기록이 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: exercises.map<Widget>((exercise) {
                        final exerciseName = exercise['exercise_name'] as String;
                        final isSelected = _selectedExercise == exerciseName;
                        final bodyPartColor = _getBodyPartColor(_selectedBodyPart);
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedExercise = exerciseName),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? bodyPartColor : bodyPartColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: bodyPartColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              exerciseName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : bodyPartColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectExercisePrompt() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                '분석할 운동을 선택해주세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '위에서 부위와 운동을 선택하면\n해당 운동의 진행 상황을 분석해드립니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseProgressAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedExercise 진행 상황',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '선택한 운동의 전체적인 진행 상황과 최근 성과를 분석합니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final progressAsync = ref.watch(exerciseProgressAnalysisProvider(_selectedExercise!));
                
                return progressAsync.when(
                  data: (progress) {
                    final totalSessions = progress['total_sessions'] as int? ?? 0;
                    final totalVolume = (progress['total_volume'] as double?) ?? 0.0;
                    final avgVolume = (progress['avg_volume_per_session'] as double?) ?? 0.0;
                    final maxWeight = (progress['max_weight'] as double?) ?? 0.0;
                    final recentTrend = progress['recent_trend'] as String? ?? 'stable';
                    
                    if (totalSessions == 0) {
                      return const Center(
                        child: Text('운동 기록이 없습니다.'),
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildProgressCard(
                                '총 운동 횟수',
                                '${totalSessions}회',
                                Icons.calendar_today,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProgressCard(
                                '총 볼륨',
                                '${totalVolume.toStringAsFixed(0)}kg',
                                Icons.fitness_center,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildProgressCard(
                                '평균 볼륨',
                                '${avgVolume.toStringAsFixed(1)}kg',
                                Icons.bar_chart,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProgressCard(
                                '최고 중량',
                                '${maxWeight.toStringAsFixed(1)}kg',
                                Icons.emoji_events,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTrendIndicator(recentTrend),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseVolumeTrend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedExercise 볼륨 변화',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '시간에 따른 운동 볼륨의 변화를 보여줍니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final trendAsync = ref.watch(exerciseVolumeTrendProvider(_selectedExercise!));
                
                return trendAsync.when(
                  data: (trendData) {
                    if (trendData.isEmpty) {
                      return const Center(
                        child: Text('볼륨 데이터가 없습니다.'),
                      );
                    }

                    final maxVolume = trendData.fold<double>(
                      0.0,
                      (max, data) => (data['volume'] as double) > max ? (data['volume'] as double) : max,
                    );

                    return Column(
                      children: trendData.map<Widget>((data) {
                        final date = data['date'] as String;
                        final volume = (data['volume'] as double?) ?? 0.0;
                        final percentage = maxVolume > 0 ? volume / maxVolume : 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getBodyPartColor(_selectedBodyPart).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '${volume.toStringAsFixed(0)}kg',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getBodyPartColor(_selectedBodyPart),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getBodyPartColor(_selectedBodyPart),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseWeightRepsProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_selectedExercise 중량/횟수 진행',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '시간에 따른 중량과 횟수의 변화를 보여줍니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final progressAsync = ref.watch(exerciseWeightRepsProgressProvider(_selectedExercise!));
                
                return progressAsync.when(
                  data: (progressData) {
                    if (progressData.isEmpty) {
                      return const Center(
                        child: Text('진행 데이터가 없습니다.'),
                      );
                    }

                    return Column(
                      children: progressData.map<Widget>((data) {
                        final date = data['date'] as String;
                        final maxWeight = (data['max_weight'] as double?) ?? 0.0;
                        final maxReps = data['max_reps'] as int? ?? 0;
                        final totalSets = data['total_sets'] as int? ?? 0;
                        final estimated1RM = (data['estimated_1rm'] as double?) ?? 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getBodyPartColor(_selectedBodyPart).withOpacity(0.1),
                                _getBodyPartColor(_selectedBodyPart).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getBodyPartColor(_selectedBodyPart).withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _buildProgressItem(
                                    '최고 중량',
                                    '${maxWeight.toStringAsFixed(1)}kg',
                                    Icons.fitness_center,
                                  ),
                                  _buildProgressItem(
                                    '최고 횟수',
                                    '${maxReps}회',
                                    Icons.numbers,
                                  ),
                                  _buildProgressItem(
                                    '총 세트',
                                    '${totalSets}세트',
                                    Icons.repeat,
                                  ),
                                  if (estimated1RM > 0)
                                    _buildProgressItem(
                                      '1RM 추정',
                                      '${estimated1RM.toStringAsFixed(1)}kg',
                                      Icons.trending_up,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _getBodyPartColor(_selectedBodyPart)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _getBodyPartColor(_selectedBodyPart),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(String trend) {
    IconData icon;
    Color color;
    String message;

    switch (trend) {
      case 'increasing':
        icon = Icons.trending_up;
        color = Colors.green;
        message = '최근 성과가 향상되고 있습니다!';
        break;
      case 'decreasing':
        icon = Icons.trending_down;
        color = Colors.red;
        message = '최근 성과가 감소하고 있습니다.';
        break;
      default:
        icon = Icons.trending_flat;
        color = Colors.orange;
        message = '최근 성과가 안정적입니다.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBodyPartDisplayName(String bodyPart) {
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

  Color _getBodyPartColor(String bodyPart) {
    switch (bodyPart) {
      case 'chest':
        return Colors.red;
      case 'back':
        return Colors.blue;
      case 'shoulders':
        return Colors.orange;
      case 'arms':
        return Colors.green;
      case 'legs':
        return Colors.purple;
      case 'core':
        return Colors.teal;
      case 'cardio':
        return Colors.pink;
      default:
        return Colors.grey;
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
}
