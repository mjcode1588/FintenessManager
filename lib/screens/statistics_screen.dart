import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/weight_provider.dart';
import '../providers/database_provider.dart';
import '../providers/statistics_provider.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 & 차트'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대시보드'),
            Tab(text: '몸무게 변화'),
            Tab(text: '운동 분석'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DashboardTab(),
          WeightChartTab(),
          ExerciseAnalysisTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final recentWeightAsync = ref.watch(recentWeightAverageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 요약',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          weeklyStatsAsync.when(
            data: (weeklyStats) {
              final totalVolume = weeklyStats['totalVolume'] as double;
              final workoutDays = weeklyStats['workoutDays'] as int;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '총 운동 시간',
                          '계산 중',
                          Icons.timer,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          '총 볼륨',
                          '${totalVolume.toStringAsFixed(0)}kg',
                          Icons.fitness_center,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '운동 일수',
                          '${workoutDays}일',
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: recentWeightAsync.when(
                          data: (avgWeight) => _buildStatCard(
                            '평균 몸무게',
                            avgWeight != null ? '${avgWeight.toStringAsFixed(1)}kg' : '기록 없음',
                            Icons.monitor_weight,
                            Colors.purple,
                          ),
                          loading: () => _buildStatCard(
                            '평균 몸무게',
                            '로딩 중...',
                            Icons.monitor_weight,
                            Colors.purple,
                          ),
                          error: (_, __) => _buildStatCard(
                            '평균 몸무게',
                            '오류',
                            Icons.monitor_weight,
                            Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '총 운동 시간',
                        '로딩 중...',
                        Icons.timer,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '총 볼륨',
                        '로딩 중...',
                        Icons.fitness_center,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '운동 일수',
                        '로딩 중...',
                        Icons.calendar_today,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '평균 몸무게',
                        '로딩 중...',
                        Icons.monitor_weight,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            error: (error, stack) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '총 운동 시간',
                        '오류',
                        Icons.timer,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '총 볼륨',
                        '오류',
                        Icons.fitness_center,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '운동 일수',
                        '오류',
                        Icons.calendar_today,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        '평균 몸무게',
                        '오류',
                        Icons.monitor_weight,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            '이번 달 목표',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          monthlyStatsAsync.when(
            data: (monthlyStats) {
              final totalVolume = monthlyStats['totalVolume'] as double;
              final workoutDays = monthlyStats['workoutDays'] as int;
              
              // 목표 설정
              const targetWorkoutDays = 20;
              const targetVolume = 10000.0;
              
              final workoutProgress = workoutDays / targetWorkoutDays;
              final volumeProgress = totalVolume / targetVolume;
              
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('운동 일수'),
                          Text('$workoutDays / $targetWorkoutDays일'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: workoutProgress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          workoutProgress >= 1.0 ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('총 볼륨'),
                          Text('${totalVolume.toStringAsFixed(0)} / ${targetVolume.toStringAsFixed(0)}kg'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: volumeProgress.clamp(0.0, 1.0),
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          volumeProgress >= 1.0 ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('운동 일수'),
                        Text('로딩 중...'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.0,
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('총 볼륨'),
                        Text('로딩 중...'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.0,
                      backgroundColor: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('오류가 발생했습니다: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class WeightChartTab extends ConsumerWidget {
  const WeightChartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightRecordsAsync = ref.watch(weightRecordsProvider);

    return weightRecordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '몸무게 기록이 없습니다.\n기록을 추가하면 차트가 표시됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // 차트 데이터 준비
        final chartData = records.map((record) {
          final weight = record['weight'] as double;
          final dateStr = record['date'] as String;
          final date = DateTime.parse(dateStr);
          return FlSpot(date.millisecondsSinceEpoch.toDouble(), weight);
        }).toList();

        chartData.sort((a, b) => a.x.compareTo(b.x));

        // 통계 계산
        final weights = records.map((r) => r['weight'] as double).toList();
        final latestWeight = weights.first;
        final maxWeight = weights.reduce((a, b) => a > b ? a : b);
        final minWeight = weights.reduce((a, b) => a < b ? a : b);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '몸무게 변화 추이',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}kg',
                                  style: const TextStyle(fontSize: 12),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                return Text(
                                  DateFormat('MM/dd').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 통계 정보
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('최근 몸무게'),
                          Text('${latestWeight.toStringAsFixed(1)}kg'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('최고 몸무게'),
                          Text('${maxWeight.toStringAsFixed(1)}kg'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('최저 몸무게'),
                          Text('${minWeight.toStringAsFixed(1)}kg'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('오류가 발생했습니다: $error'),
      ),
    );
  }
}

class ExerciseAnalysisTab extends ConsumerWidget {
  const ExerciseAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatsAsync = ref.watch(weeklyStatsProvider);
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 분석',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // 이번 주 부위별 운동 빈도
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이번 주 부위별 운동 빈도',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  weeklyStatsAsync.when(
                    data: (weeklyStats) {
                      final bodyPartFrequency = weeklyStats['bodyPartFrequency'] as Map<String, int>;
                      
                      if (bodyPartFrequency.isEmpty) {
                        return const Text(
                          '이번 주 운동 기록이 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      return SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: bodyPartFrequency.values.reduce((a, b) => a > b ? a : b).toDouble() + 2,
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    final bodyParts = bodyPartFrequency.keys.toList();
                                    if (value.toInt() < bodyParts.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          _getBodyPartName(bodyParts[value.toInt()]),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (double value, TitleMeta meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: bodyPartFrequency.entries.toList().asMap().entries.map((entry) {
                              final index = entry.key;
                              final bodyPartEntry = entry.value;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: bodyPartEntry.value.toDouble(),
                                    color: _getBodyPartColor(bodyPartEntry.key),
                                    width: 20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, stack) => SizedBox(
                      height: 200,
                      child: Center(
                        child: Text('오류가 발생했습니다: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 이번 달 부위별 운동 빈도
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '이번 달 부위별 운동 빈도',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  monthlyStatsAsync.when(
                    data: (monthlyStats) {
                      final bodyPartFrequency = monthlyStats['bodyPartFrequency'] as Map<String, int>;
                      
                      if (bodyPartFrequency.isEmpty) {
                        return const Text(
                          '이번 달 운동 기록이 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        );
                      }

                      // 리스트 형태로 표시
                      return Column(
                        children: bodyPartFrequency.entries.map((entry) {
                          final bodyPart = entry.key;
                          final frequency = entry.value;
                          final maxFrequency = bodyPartFrequency.values.reduce((a, b) => a > b ? a : b);
                          final progress = frequency / maxFrequency;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_getBodyPartName(bodyPart)),
                                    Text('${frequency}회'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getBodyPartColor(bodyPart),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text('오류가 발생했습니다: $error'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}

