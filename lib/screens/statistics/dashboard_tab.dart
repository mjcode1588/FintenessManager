import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/../providers/statistics_provider.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final weeklyDetailedAsync = ref.watch(weeklyDetailedStatsProvider);
    final recentWeightAsync = ref.watch(recentWeightAverageProvider);
    final oneRMEstimatesAsync = ref.watch(oneRMEstimatesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이번 주 요약 헤더
          Row(
            children: [
              Icon(Icons.insights, color: Colors.blue.shade600, size: 28),
              const SizedBox(width: 8),
              const Text(
                '이번 주 운동 요약',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 메인 통계 카드들
          weeklyStatsAsync.when(
            data: (weeklyStats) {
              final totalVolume = weeklyStats['totalVolume'] as double;
              final workoutDays = weeklyStats['workoutDays'] as int;
              final totalSets = weeklyStats['totalSets'] as int;
              final totalDuration = weeklyStats['totalDuration'] as int;
              final durationHours = totalDuration ~/ 3600;
              final durationMinutes = (totalDuration % 3600) ~/ 60;

              return Column(
                children: [
                  // 첫 번째 줄: 운동 일수와 총 세트
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          '운동 일수',
                          '${workoutDays}일',
                          '이번 주',
                          Icons.calendar_today,
                          Colors.blue,
                          workoutDays > 0 ? '활발함' : '시작해보세요',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildEnhancedStatCard(
                          '총 세트',
                          '${totalSets}세트',
                          '완료',
                          Icons.fitness_center,
                          Colors.green,
                          totalSets > 50
                              ? '훌륭함'
                              : totalSets > 20
                              ? '좋음'
                              : '더 화이팅',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 두 번째 줄: 총 볼륨
                  Row(
                    children: [
                      Expanded(
                        child: _buildEnhancedStatCard(
                          '총 볼륨',
                          '${totalVolume.toStringAsFixed(0)}kg',
                          '누적',
                          Icons.trending_up,
                          Colors.orange,
                          totalVolume > 5000
                              ? '강력함'
                              : totalVolume > 2000
                              ? '견고함'
                              : '성장중',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Container()), // 빈 공간
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('주간 요약 오류: $error'),
          ),

          const SizedBox(height: 32),

          // 이번 주 상세 분석
          weeklyDetailedAsync.when(
            data: (detailedStats) {
              final topExercises = detailedStats['topExercises'] as List;
              final bodyPartDistribution =
                  detailedStats['bodyPartDistribution'] as List;
              final personalRecords = detailedStats['personalRecords'] as List;
              final dailyWorkouts = detailedStats['dailyWorkouts'] as List;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 개인 기록 갱신 (있을 경우에만)
                  if (personalRecords.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '이번 주 개인 기록 갱신! 🎉',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade50, Colors.orange.shade50],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        children: personalRecords.take(3).map<Widget>((record) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${record['name']} - ${record['weight']}kg × ${record['reps']}회',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 가장 많이 한 운동
                  if (topExercises.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '이번 주 주력 운동',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: topExercises.take(3).map<Widget>((
                            exercise,
                          ) {
                            final volume = exercise['total_volume'] as double?;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade400,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          exercise['name'] as String,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '${exercise['count']}회 수행 • ${exercise['total_sets'] ?? 0}세트' +
                                              (volume != null
                                                  ? ' • ${volume.toStringAsFixed(0)}kg'
                                                  : ''),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 부위별 운동 분포
                  if (bodyPartDistribution.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.accessibility_new,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '운동 부위 분포',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: bodyPartDistribution.map<Widget>((
                            bodyPart,
                          ) {
                            final bodyPartName = _getBodyPartDisplayName(
                              bodyPart['body_part'] as String,
                            );
                            final count = bodyPart['count'] as int;
                            final maxCount =
                                bodyPartDistribution.first['count'] as int;
                            final percentage = count / maxCount;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      bodyPartName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.green.shade400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${count}회',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),

          // 1RM 추정치 (간소화)
          oneRMEstimatesAsync.when(
            data: (estimates) {
              if (estimates.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.military_tech,
                        color: Colors.indigo.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '개인 최고 기록',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: estimates.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.indigo.shade200),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.value.toStringAsFixed(1)}kg',
                                  style: TextStyle(
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String status,
  ) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 24, color: Colors.white),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
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
}
