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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '부위별 분석 (전체 기간)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 부위 선택
          _buildBodyPartSelector(),
          const SizedBox(height: 16),

          // 부위별 운동 강도 분석 (전체 기간)
          _buildBodyPartIntensityAnalysis(),
          const SizedBox(height: 16),

          // 부위별 운동 분포 (전체 기간)
          _buildBodyPartExerciseDistribution(),
          const SizedBox(height: 16),

          // 부위별 개인 기록 (전체 기간)
          _buildBodyPartPersonalRecords(),
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



  Widget _buildBodyPartIntensityAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Text(
                  '${_getBodyPartDisplayName(_selectedBodyPart)} 운동 강도',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getBodyPartDisplayName(_selectedBodyPart)} 부위의 전체 기간 평균 세트당 볼륨과 운동 빈도를 분석합니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(allTimeBodyPartStatsProvider(_selectedBodyPart));
                
                return statsAsync.when(
                  data: (stats) {
                    final totalVolume = (stats['total_volume'] as double?) ?? 0.0;
                    final totalSets = (stats['total_sets'] as int?) ?? 0;
                    final exerciseCount = (stats['exercise_count'] as int?) ?? 0;
                    final avgVolumePerSet = totalSets > 0 ? totalVolume / totalSets : 0.0;
                    
                    if (totalVolume == 0) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildIntensityCard(
                                '총 볼륨',
                                '${totalVolume.toStringAsFixed(0)}kg',
                                Icons.fitness_center,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildIntensityCard(
                                '총 세트',
                                '${totalSets}세트',
                                Icons.repeat,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildIntensityCard(
                                '세트당 볼륨',
                                '${avgVolumePerSet.toStringAsFixed(1)}kg',
                                Icons.trending_up,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildIntensityCard(
                                '운동 종류',
                                '${exerciseCount}개',
                                Icons.list,
                                _getBodyPartColor(_selectedBodyPart),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildBodyPartExerciseDistribution() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Text(
                  '${_getBodyPartDisplayName(_selectedBodyPart)} 운동 분포',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getBodyPartDisplayName(_selectedBodyPart)} 부위에서 수행한 각 운동의 비중을 보여줍니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final detailsAsync = ref.watch(allTimeBodyPartExerciseDetailsProvider);
                
                return detailsAsync.when(
                  data: (bodyPartExercises) {
                    final exercises = bodyPartExercises[_selectedBodyPart] ?? [];
                    
                    if (exercises.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('해당 기간에 운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: exercises.map<Widget>((exercise) {
                        final exerciseName = exercise['exercise_name'] as String;
                        final frequency = exercise['frequency'] as int;
                        final totalVolume = (exercise['total_volume'] as double?) ?? 0.0;
                        final maxFrequency = exercises.fold<int>(
                          0, 
                          (max, e) => (e['frequency'] as int) > max ? (e['frequency'] as int) : max,
                        );
                        final percentage = maxFrequency > 0 ? frequency / maxFrequency : 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getBodyPartColor(_selectedBodyPart).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getBodyPartColor(_selectedBodyPart).withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  Text(
                                    '${frequency}회',
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
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '총 볼륨: ${totalVolume.toStringAsFixed(0)}kg',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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

  Widget _buildBodyPartPersonalRecords() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: _getBodyPartColor(_selectedBodyPart)),
                const SizedBox(width: 8),
                Text(
                  '${_getBodyPartDisplayName(_selectedBodyPart)} 개인 기록',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_getBodyPartDisplayName(_selectedBodyPart)} 부위의 최고 기록들을 보여줍니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final recordsAsync = ref.watch(bodyPartPersonalRecordsProvider(_selectedBodyPart));
                
                return recordsAsync.when(
                  data: (records) {
                    if (records.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('개인 기록이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: records.map<Widget>((record) {
                        final exerciseName = record['exercise_name'] as String;
                        final maxWeight = (record['max_weight'] as double?) ?? 0.0;
                        final maxReps = record['max_reps'] as int?;
                        final estimated1RM = (record['estimated_1rm'] as double?) ?? 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
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
                                exerciseName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  if (maxWeight > 0) 
                                    _buildRecordItem(
                                      '최고 중량',
                                      '${maxWeight.toStringAsFixed(1)}kg',
                                      Icons.fitness_center,
                                    ),
                                  if (maxReps != null && maxReps > 0) 
                                    _buildRecordItem(
                                      '최고 횟수',
                                      '${maxReps}회',
                                      Icons.numbers,
                                    ),
                                  if (estimated1RM > 0) 
                                    _buildRecordItem(
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

  Widget _buildRecordItem(String label, String value, IconData icon) {
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

  Widget _buildIntensityCard(String title, String value, IconData icon, Color color) {
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
