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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: '기간별 분석'),
            Tab(text: '부위별 분석'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            DashboardTab(),
            WeightChartTab(),
            PeriodAnalysisTab(),
            BodyPartAnalysisTab(),
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

class WeightChartTab extends ConsumerStatefulWidget {
  const WeightChartTab({super.key});

  @override
  ConsumerState<WeightChartTab> createState() => _WeightChartTabState();
}

class _WeightChartTabState extends ConsumerState<WeightChartTab> {
  String _selectedPeriod = '3months'; // '1month', '3months', '6months', 'all'

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final weightRecordsAsync = ref.watch(weightRecordsProvider);

    return weightRecordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.monitor_weight_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '몸무게 기록이 없습니다',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '몸무게를 기록하면 변화 추이를\n아름다운 차트로 확인할 수 있습니다',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // 몸무게 기록 화면으로 이동
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('첫 기록 추가하기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 기간별 데이터 필터링
        final filteredRecords = _filterRecordsByPeriod(records);

        final chartData = filteredRecords.map((record) {
          final date = DateTime.parse(record['date'] as String);
          final weight = record['weight'] as double;
          return FlSpot(date.millisecondsSinceEpoch.toDouble(), weight);
        }).toList();
        chartData.sort((a, b) => a.x.compareTo(b.x));

        final weights = filteredRecords
            .map((r) => r['weight'] as double)
            .toList();
        final latestWeight = weights.first;
        final maxWeight = weights.reduce((a, b) => a > b ? a : b);
        final minWeight = weights.reduce((a, b) => a < b ? a : b);
        final avgWeight = weights.reduce((a, b) => a + b) / weights.length;

        // 더 스마트한 Y축 범위 계산
        final weightRange = maxWeight - minWeight;
        final padding = weightRange > 0 ? weightRange * 0.1 : 5.0;
        final minY = (minWeight - padding).clamp(0.0, double.infinity);
        final maxY = maxWeight + padding;

        // 몸무게 변화량 계산
        final weightChange = chartData.length > 1
            ? chartData.last.y - chartData.first.y
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더와 기간 선택
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '몸무게 변화 추이',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: '1month', child: Text('1개월')),
                        DropdownMenuItem(value: '3months', child: Text('3개월')),
                        DropdownMenuItem(value: '6months', child: Text('6개월')),
                        DropdownMenuItem(value: 'all', child: Text('전체')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPeriod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 요약 통계 카드들
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      '현재 몸무게',
                      '${latestWeight.toStringAsFixed(1)}kg',
                      Icons.monitor_weight,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      '변화량',
                      '${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)}kg',
                      weightChange >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      weightChange >= 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      '평균 몸무게',
                      '${avgWeight.toStringAsFixed(1)}kg',
                      Icons.analytics,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 메인 차트
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: (maxY - minY) / 5,
                        verticalInterval: _getVerticalInterval(chartData),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            interval: (maxY - minY) / 5,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toStringAsFixed(1)}kg',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _getBottomInterval(chartData),
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );

                              // 차트 데이터 범위에 따라 날짜 포맷 조정
                              final timeRange =
                                  chartData.last.x - chartData.first.x;
                              final days = timeRange / (1000 * 60 * 60 * 24);

                              String dateText;
                              if (days <= 7) {
                                dateText = DateFormat('MM/dd').format(date);
                              } else if (days <= 30) {
                                dateText = DateFormat('MM/dd').format(date);
                              } else {
                                dateText = DateFormat('MM/dd').format(date);
                              }

                              return Transform.rotate(
                                angle: -0.5, // 약간 기울여서 겹침 방지
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    dateText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                spot.x.toInt(),
                              );
                              return LineTooltipItem(
                                '${DateFormat('MM/dd').format(date)}\n${spot.y.toStringAsFixed(1)}kg',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        getTouchedSpotIndicator: (barData, spotIndexes) {
                          return spotIndexes.map((index) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: Colors.blue.withOpacity(0.5),
                                strokeWidth: 2,
                                dashArray: [5, 5],
                              ),
                              FlDotData(
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: Colors.blue,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartData,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2,
                                strokeColor: Colors.blue,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue.withOpacity(0.3),
                                Colors.blue.withOpacity(0.1),
                                Colors.blue.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 상세 통계 정보
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '상세 통계',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailedInfoRow(
                        '최고 몸무게',
                        '${maxWeight.toStringAsFixed(1)}kg',
                        Icons.keyboard_arrow_up,
                        Colors.red.shade400,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailedInfoRow(
                        '최저 몸무게',
                        '${minWeight.toStringAsFixed(1)}kg',
                        Icons.keyboard_arrow_down,
                        Colors.green.shade400,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailedInfoRow(
                        '기록 수',
                        '${filteredRecords.length}개',
                        Icons.data_usage,
                        Colors.blue.shade400,
                      ),
                      if (chartData.length > 1) ...[
                        const SizedBox(height: 12),
                        _buildDetailedInfoRow(
                          '기간',
                          '${DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(chartData.first.x.toInt()))} ~ ${DateFormat('MM/dd').format(DateTime.fromMillisecondsSinceEpoch(chartData.last.x.toInt()))}',
                          Icons.date_range,
                          Colors.orange.shade400,
                        ),
                      ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              '데이터를 불러오는 중 오류가 발생했습니다',
              style: TextStyle(fontSize: 16, color: Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterRecordsByPeriod(
    List<Map<String, dynamic>> records,
  ) {
    if (_selectedPeriod == 'all') return records;

    final now = DateTime.now();
    DateTime cutoffDate;

    switch (_selectedPeriod) {
      case '1month':
        cutoffDate = now.subtract(const Duration(days: 30));
        break;
      case '3months':
        cutoffDate = now.subtract(const Duration(days: 90));
        break;
      case '6months':
        cutoffDate = now.subtract(const Duration(days: 180));
        break;
      default:
        return records;
    }

    return records.where((record) {
      final date = DateTime.parse(record['date'] as String);
      return date.isAfter(cutoffDate);
    }).toList();
  }

  double _getVerticalInterval(List<FlSpot> chartData) {
    if (chartData.length <= 1) return 1;
    final timeRange = chartData.last.x - chartData.first.x;
    final days = timeRange / (1000 * 60 * 60 * 24);

    if (days <= 7) return 1000 * 60 * 60 * 24; // 1일
    if (days <= 30) return 1000 * 60 * 60 * 24 * 7; // 1주
    if (days <= 90) return 1000 * 60 * 60 * 24 * 14; // 2주
    return 1000 * 60 * 60 * 24 * 30; // 1개월
  }

  double _getBottomInterval(List<FlSpot> chartData) {
    if (chartData.length <= 1) return 1;
    final timeRange = chartData.last.x - chartData.first.x;
    final days = timeRange / (1000 * 60 * 60 * 24);

    // 데이터 포인트 수에 따라 적절한 간격 설정
    if (chartData.length <= 3) {
      return timeRange / chartData.length; // 모든 포인트 표시
    } else if (days <= 7) {
      return 1000 * 60 * 60 * 24; // 1일 간격
    } else if (days <= 30) {
      return 1000 * 60 * 60 * 24 * 3; // 3일 간격
    } else if (days <= 90) {
      return 1000 * 60 * 60 * 24 * 7; // 1주 간격
    } else {
      return 1000 * 60 * 60 * 24 * 14; // 2주 간격
    }
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoRow(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class PeriodAnalysisTab extends ConsumerStatefulWidget {
  const PeriodAnalysisTab({super.key});

  @override
  ConsumerState<PeriodAnalysisTab> createState() =>
      _PeriodAnalysisTabState();
}

class _PeriodAnalysisTabState extends ConsumerState<PeriodAnalysisTab> {
  String _selectedPeriod = 'month'; // 'week' or 'month'
  int _selectedWeekOffset = 0; // 0: 이번주, -1: 지난주, -2: 2주전...

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 선택 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '기간별 분석',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'week', label: Text('주별')),
                  ButtonSegment(value: 'month', label: Text('월별')),
                ],
                selected: {_selectedPeriod},
                onSelectionChanged: (Set<String> selection) {
                  setState(() {
                    _selectedPeriod = selection.first;
                    _selectedWeekOffset = 0; // 기간 변경시 현재로 리셋
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 주별 보기일 때 주 선택 컨트롤
          if (_selectedPeriod == 'week') _buildWeekSelector(),

          // 기간 정보 표시
          _buildPeriodInfo(),
          const SizedBox(height: 16),

          // 부위별 볼륨 분석
          _buildBodyPartVolumeChart(),
          const SizedBox(height: 16),

          // 운동 빈도 분석
          _buildExerciseFrequencyChart(),
          const SizedBox(height: 16),



          // 상위 운동 목록
          _buildTopExercisesList(),
          const SizedBox(height: 16),

          // 부위별 운동 상세 내용
          _buildBodyPartExerciseDetails(),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => setState(() => _selectedWeekOffset--),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              _getWeekDisplayText(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _selectedWeekOffset < 0
                  ? () => setState(() => _selectedWeekOffset++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekDisplayText() {
    final now = DateTime.now();
    final targetDate = now.add(Duration(days: _selectedWeekOffset * 7));
    final weekStart = targetDate.subtract(
      Duration(days: targetDate.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    if (_selectedWeekOffset == 0) {
      return '이번 주 (${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)})';
    } else if (_selectedWeekOffset == -1) {
      return '지난 주 (${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)})';
    } else {
      return '${(-_selectedWeekOffset)}주 전 (${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)})';
    }
  }

  Widget _buildPeriodInfo() {
    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = _selectedPeriod == 'week'
            ? ref.watch(weeklyStatsWithOffsetProvider(_selectedWeekOffset))
            : ref.watch(monthlyStatsProvider);
        return statsAsync.when(
          data: (stats) {
            final totalVolume = (stats['totalVolume'] as double?) ?? 0.0;
            final workoutDays = (stats['workoutDays'] as int?) ?? 0;
            final totalDuration = (stats['totalDuration'] as int?) ?? 0;

            return Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedPeriod == 'week' ? '주간' : '월간'} 요약',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          '운동 일수',
                          '$workoutDays일',
                          Icons.calendar_today,
                        ),
                        _buildSummaryItem(
                          '총 볼륨',
                          '${totalVolume.toStringAsFixed(0)}kg',
                          Icons.fitness_center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('오류: $e'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBodyPartVolumeChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '부위별 볼륨 분석',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '각 신체 부위별로 얼마나 많은 볼륨(무게×횟수×세트)을 수행했는지 보여줍니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        weeklyStatsWithOffsetProvider(_selectedWeekOffset),
                      )
                    : ref.watch(monthlyStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final bodyPartVolume =
                        (stats['bodyPartVolume'] as Map<String, double>?) ??
                        <String, double>{};
                    if (bodyPartVolume.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('해당 기간에 운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    final totalVolume = bodyPartVolume.values.reduce(
                      (a, b) => a + b,
                    );
                    final sortedEntries = bodyPartVolume.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: PieChart(
                                  PieChartData(
                                    sections: sortedEntries.map((entry) {
                                      final percentage =
                                          (entry.value / totalVolume) * 100;
                                      return PieChartSectionData(
                                        color: _getBodyPartColor(entry.key),
                                        value: entry.value,
                                        title:
                                            '${percentage.toStringAsFixed(1)}%',
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                    centerSpaceRadius: 30,
                                    sectionsSpace: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: sortedEntries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            color: _getBodyPartColor(entry.key),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getBodyPartName(entry.key),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${entry.value.toStringAsFixed(0)}kg',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
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
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseFrequencyChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '부위별 운동 빈도',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '각 신체 부위를 얼마나 자주 운동했는지 횟수로 보여줍니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        weeklyStatsWithOffsetProvider(_selectedWeekOffset),
                      )
                    : ref.watch(monthlyStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final bodyPartFrequency =
                        stats['bodyPartFrequency'] as Map<String, int>? ?? {};
                    if (bodyPartFrequency.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('해당 기간에 운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    final sortedEntries = bodyPartFrequency.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final maxValue = sortedEntries.first.value.toDouble();

                    return SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxValue * 1.2,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final bodyPart =
                                    sortedEntries[group.x.toInt()].key;
                                return BarTooltipItem(
                                  '${_getBodyPartName(bodyPart)}\n${rod.toY.toInt()}회',
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < sortedEntries.length) {
                                    final bodyPart =
                                        sortedEntries[value.toInt()].key;
                                    return Text(
                                      _getBodyPartName(bodyPart),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: sortedEntries.asMap().entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.value.toDouble(),
                                  color: _getBodyPartColor(entry.value.key),
                                  width: 20,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '${_selectedPeriod == 'week' ? '일별' : '주별'} 볼륨 추이',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedPeriod == 'week' ? '일별로' : '주별로'} 총 볼륨의 변화를 보여줍니다. 꾸준한 증가 추세를 유지하는 것이 좋습니다.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final trendAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        weeklyDetailedStatsWithOffsetProvider(
                          _selectedWeekOffset,
                        ),
                      )
                    : ref.watch(monthlyVolumeTrendProvider);
                return trendAsync.when(
                  data: (data) {
                    List<FlSpot> spots;
                    List<String> labels;

                    if (_selectedPeriod == 'week') {
                      // 주별 선택 시 일별 데이터 표시
                      final weekData = data as Map<String, dynamic>;
                      final dailyWorkouts = weekData['dailyWorkouts'] as List;
                      if (dailyWorkouts.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('해당 주에 운동 기록이 없습니다.'),
                          ),
                        );
                      }

                      spots = dailyWorkouts.asMap().entries.map((entry) {
                        final index = entry.key.toDouble();
                        final volume =
                            (entry.value['daily_volume'] as num?)?.toDouble() ??
                            0.0;
                        return FlSpot(index, volume);
                      }).toList();

                      labels = dailyWorkouts.map((workout) {
                        final date = DateTime.parse(workout['date'] as String);
                        return DateFormat('MM/dd').format(date);
                      }).toList();
                    } else {
                      // 월별 선택 시 주별 데이터 표시
                      final trendData = data as List;
                      if (trendData.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('볼륨 추이 데이터가 없습니다.'),
                          ),
                        );
                      }

                      spots = trendData.asMap().entries.map((entry) {
                        final index = entry.key.toDouble();
                        final volume = (entry.value['total_volume'] as num)
                            .toDouble();
                        return FlSpot(index, volume);
                      }).toList();

                      labels = trendData
                          .map((item) => (item['week'] as String).substring(5))
                          .toList();
                    }

                    final maxY =
                        spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) *
                        1.2;

                    return SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: maxY / 5,
                            verticalInterval: 1,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return FlLine(
                                color: Colors.grey.withOpacity(0.3),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}kg',
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < labels.length) {
                                    return Text(
                                      labels[value.toInt()],
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          minY: 0,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final index = spot.x.toInt();
                                  final label = index < labels.length
                                      ? labels[index]
                                      : '';
                                  return LineTooltipItem(
                                    '$label\n${spot.y.toStringAsFixed(0)}kg',
                                    const TextStyle(color: Colors.white),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.blue,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '운동 강도 분석',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '평균 세트당 볼륨과 운동 밀도를 분석합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        weeklyStatsWithOffsetProvider(_selectedWeekOffset),
                      )
                    : ref.watch(monthlyStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final totalVolume =
                        (stats['totalVolume'] as double?) ?? 0.0;
                    final totalSets = (stats['totalSets'] as int?) ?? 0;
                    final totalDuration = (stats['totalDuration'] as int?) ?? 0;
                    final workoutDays = (stats['workoutDays'] as int?) ?? 0;

                    final avgVolumePerSet = totalSets > 0
                        ? totalVolume / totalSets
                        : 0.0;
                    final avgDurationPerDay = workoutDays > 0
                        ? totalDuration / workoutDays / 60
                        : 0.0; // 분 단위
                    final volumePerMinute = totalDuration > 0
                        ? totalVolume / (totalDuration / 60)
                        : 0.0;

                    return Row(
                      children: [
                        Expanded(
                          child: _buildIntensityCard(
                            '세트당 평균 볼륨',
                            '${avgVolumePerSet.toStringAsFixed(1)}kg',
                            Icons.fitness_center,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Container()), // 빈 공간
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntensityCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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

  Widget _buildTopExercisesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '가장 많이 한 운동 Top 5',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '해당 기간에 가장 자주 수행한 운동들을 순위별로 보여줍니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        weeklyStatsWithOffsetProvider(_selectedWeekOffset),
                      )
                    : ref.watch(monthlyStatsProvider);
                return statsAsync.when(
                  data: (stats) {
                    final topExercises =
                        stats['top5Exercises'] as List<Map<String, dynamic>>? ??
                        [];
                    if (topExercises.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('해당 기간에 운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: topExercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        final rank = index + 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getRankColor(rank).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRankColor(rank).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _getRankColor(rank),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '총 ${exercise['count']}회 수행',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (exercise['total_volume'] != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(exercise['total_volume'] as num).toStringAsFixed(0)}kg',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Text(
                                      '총 볼륨',
                                      style: TextStyle(
                                        fontSize: 10,
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // 금색
      case 2:
        return Colors.grey; // 은색
      case 3:
        return Colors.brown; // 동색
      default:
        return Colors.blue;
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

  Widget _buildBodyPartExerciseDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  '부위별 운동 상세',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '각 신체 부위별로 수행한 운동들의 상세 정보를 보여줍니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final detailsAsync = _selectedPeriod == 'week'
                    ? ref.watch(
                        bodyPartExerciseDetailsProvider(_selectedWeekOffset),
                      )
                    : ref.watch(monthlyBodyPartExerciseDetailsProvider);

                return detailsAsync.when(
                  data: (bodyPartExercises) {
                    if (bodyPartExercises.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('해당 기간에 운동 기록이 없습니다.'),
                        ),
                      );
                    }

                    return Column(
                      children: bodyPartExercises.entries.map((entry) {
                        final bodyPart = entry.key;
                        final exercises = entry.value;
                        final bodyPartName = _getBodyPartName(bodyPart);
                        final bodyPartColor = _getBodyPartColor(bodyPart);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: bodyPartColor.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: bodyPartColor.withOpacity(0.05),
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bodyPartColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getBodyPartIcon(bodyPart),
                                color: bodyPartColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              bodyPartName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: bodyPartColor,
                              ),
                            ),
                            subtitle: Text(
                              '${exercises.length}개 운동',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            children: exercises.map((exercise) {
                              final exerciseName =
                                  exercise['exercise_name'] as String;
                              final frequency = exercise['frequency'] as int;
                              final totalSets = exercise['total_sets'] as int?;
                              final avgWeight =
                                  exercise['avg_weight'] as double?;
                              final avgReps = exercise['avg_reps'] as double?;
                              final totalVolume =
                                  exercise['total_volume'] as double?;

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            exerciseName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: bodyPartColor.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${frequency}회',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: bodyPartColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        if (totalSets != null)
                                          _buildExerciseDetailItem(
                                            '총 세트',
                                            '${totalSets}세트',
                                            Icons.repeat,
                                            Colors.blue,
                                          ),
                                        if (avgWeight != null && avgWeight > 0)
                                          _buildExerciseDetailItem(
                                            '평균 중량',
                                            '${avgWeight.toStringAsFixed(1)}kg',
                                            Icons.fitness_center,
                                            Colors.orange,
                                          ),
                                        if (avgReps != null && avgReps > 0)
                                          _buildExerciseDetailItem(
                                            '평균 횟수',
                                            '${avgReps.toStringAsFixed(1)}회',
                                            Icons.numbers,
                                            Colors.green,
                                          ),
                                      ],
                                    ),
                                    if (totalVolume != null &&
                                        totalVolume > 0) ...[
                                      const SizedBox(height: 8),
                                      _buildExerciseDetailItem(
                                        '총 볼륨',
                                        '${totalVolume.toStringAsFixed(0)}kg',
                                        Icons.trending_up,
                                        Colors.purple,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('오류: $e'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
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
