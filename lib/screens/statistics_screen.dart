import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/weight_provider.dart';
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
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            DashboardTab(),
            WeightChartTab(),
            ExerciseAnalysisTab(),
          ],
        ),
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
    final oneRMEstimatesAsync = ref.watch(oneRMEstimatesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 요약',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          weeklyStatsAsync.when(
            data: (weeklyStats) {
              final totalVolume = weeklyStats['totalVolume'] as double;
              final workoutDays = weeklyStats['workoutDays'] as int;
              final totalDuration = weeklyStats['totalDuration'] as int; // 초 단위
              final durationHours = totalDuration ~/ 3600;
              final durationMinutes = (totalDuration % 3600) ~/ 60;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          '총 운동 시간',
                          '${durationHours}시간 ${durationMinutes}분',
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
                            avgWeight != null
                                ? '${avgWeight.toStringAsFixed(1)}kg'
                                : '기록 없음',
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('주간 요약 오류: $error'),
          ),

          const SizedBox(height: 32),

          // 1RM 추정치
          oneRMEstimatesAsync.when(
            data: (estimates) {
              if (estimates.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '개인 최고 기록 (1RM 추정)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: estimates.entries.map((entry) {
                          return Column(
                            children: [
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${entry.value.toStringAsFixed(1)} kg'),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
            loading: () => const SizedBox.shrink(), // 로딩 중에는 표시 안함
            error: (e, s) => const SizedBox.shrink(), // 오류 시 표시 안함
          ),

          const Text(
            '이번 달 목표',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          monthlyStatsAsync.when(
            data: (monthlyStats) {
              final totalVolume = monthlyStats['totalVolume'] as double;
              final workoutDays = monthlyStats['workoutDays'] as int;

              const targetWorkoutDays = 20;
              const targetVolume = 10000.0;

              final workoutProgress = workoutDays / targetWorkoutDays;
              final volumeProgress = totalVolume / targetVolume;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProgressRow('운동 일수', '$workoutDays / $targetWorkoutDays일', workoutProgress, Colors.orange),
                      const SizedBox(height: 16),
                      _buildProgressRow('총 볼륨', '${totalVolume.toStringAsFixed(0)} / ${targetVolume.toStringAsFixed(0)}kg', volumeProgress, Colors.blue),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('월간 목표 오류: $error'),
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
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String title, String value, double progress, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(title), Text(value)],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? Colors.green : color,
          ),
        ),
      ],
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

        final chartData = records.map((record) {
          final date = DateTime.parse(record['date'] as String);
          final weight = record['weight'] as double;
          return FlSpot(date.millisecondsSinceEpoch.toDouble(), weight);
        }).toList();
        chartData.sort((a, b) => a.x.compareTo(b.x));

        final weights = records.map((r) => r['weight'] as double).toList();
        final latestWeight = weights.first;
        final maxWeight = weights.reduce((a, b) => a > b ? a : b);
        final minWeight = weights.reduce((a, b) => a < b ? a : b);
        final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
        final minY = (avgWeight - 20).clamp(0, double.infinity).toDouble();
        final maxY = (avgWeight + 20).toDouble();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('몸무게 변화 추이', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text('${v.toInt()}kg', style: const TextStyle(fontSize: 12)))),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text(DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(v.toInt())), style: const TextStyle(fontSize: 10)))),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        minY: minY, maxY: maxY,
                        lineTouchData: LineTouchData(enabled: true, handleBuiltInTouches: true),
                        clipData: FlClipData.all(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: chartData,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow('최근 몸무게', '${latestWeight.toStringAsFixed(1)}kg'),
                      const Divider(),
                      _buildInfoRow('최고 몸무게', '${maxWeight.toStringAsFixed(1)}kg'),
                      const Divider(),
                      _buildInfoRow('최저 몸무게', '${minWeight.toStringAsFixed(1)}kg'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title), Text(value)],
    );
  }
}

class ExerciseAnalysisTab extends ConsumerWidget {
  const ExerciseAnalysisTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStatsAsync = ref.watch(monthlyStatsProvider);
    final monthlyVolumeTrendAsync = ref.watch(monthlyVolumeTrendProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('월간 운동 분석', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // 월간 부위별 볼륨 (파이차트)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('부위별 볼륨 비율', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  monthlyStatsAsync.when(
                    data: (stats) {
                      final bodyPartVolume = stats['bodyPartVolume'] as Map<String, double>;
                      if (bodyPartVolume.isEmpty) return const Text('이번 달 운동 기록이 없습니다.');

                      final totalVolume = bodyPartVolume.values.reduce((a, b) => a + b);
                      final pieChartSections = bodyPartVolume.entries.map((entry) {
                        final percentage = (entry.value / totalVolume) * 100;
                        return PieChartSectionData(
                          color: _getBodyPartColor(entry.key),
                          value: entry.value,
                          title: '${percentage.toStringAsFixed(1)}%',
                          radius: 80,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList();

                      return SizedBox(
                        height: 200,
                        child: PieChart(PieChartData(sections: pieChartSections, centerSpaceRadius: 40)),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('오류: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 월간 볼륨 추이 (라인차트)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('주간 총 볼륨 추이', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  monthlyVolumeTrendAsync.when(
                    data: (trendData) {
                      if (trendData.isEmpty) return const Text('볼륨 추이 데이터가 없습니다.');

                      final spots = trendData.asMap().entries.map((entry) {
                        final index = entry.key.toDouble();
                        final volume = (entry.value['total_volume'] as num).toDouble();
                        return FlSpot(index, volume);
                      }).toList();

                      return SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final week = trendData[value.toInt()]['week'] as String;
                                    return Text(week.substring(5), style: const TextStyle(fontSize: 10)); // 'YYYY-WW' -> 'WW'
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.teal, barWidth: 3)],
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('오류: $e'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 가장 많이 한 운동 Top 5
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('가장 많이 한 운동 Top 5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  monthlyStatsAsync.when(
                    data: (stats) {
                      final topExercises = stats['top5Exercises'] as List<Map<String, dynamic>>;
                      if (topExercises.isEmpty) return const Text('운동 기록이 없습니다.');

                      return Column(
                        children: topExercises.map((exercise) {
                          return ListTile(
                            title: Text(exercise['name'] as String),
                            trailing: Text('${exercise['count']} 회'),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text('오류: $e'),
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
      case 'chest': return '가슴';
      case 'back': return '등';
      case 'shoulders': return '어깨';
      case 'arms': return '팔';
      case 'legs': return '다리';
      case 'core': return '코어';
      case 'cardio': return '유산소';
      default: return bodyPart;
    }
  }

  Color _getBodyPartColor(String bodyPart) {
    switch (bodyPart) {
      case 'chest': return Colors.red;
      case 'back': return Colors.blue;
      case 'shoulders': return Colors.orange;
      case 'arms': return Colors.green;
      case 'legs': return Colors.purple;
      case 'core': return Colors.teal;
      case 'cardio': return Colors.pink;
      default: return Colors.grey;
    }
  }
}
