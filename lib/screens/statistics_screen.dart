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
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                      _buildProgressRow(
                        '운동 일수',
                        '$workoutDays / $targetWorkoutDays일',
                        workoutProgress,
                        Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      _buildProgressRow(
                        '총 볼륨',
                        '${totalVolume.toStringAsFixed(0)} / ${targetVolume.toStringAsFixed(0)}kg',
                        volumeProgress,
                        Colors.blue,
                      ),
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(
    String title,
    String value,
    double progress,
    Color color,
  ) {
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

        final weights = filteredRecords.map((r) => r['weight'] as double).toList();
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
                      weightChange >= 0 ? Icons.trending_up : Icons.trending_down,
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
                            reservedSize: 35,
                            interval: _getBottomInterval(chartData),
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('MM/dd').format(date),
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
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
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
                          Icon(Icons.analytics_outlined, color: Colors.grey.shade600),
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

  List<Map<String, dynamic>> _filterRecordsByPeriod(List<Map<String, dynamic>> records) {
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
    return timeRange / 5; // 5개 정도의 레이블
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfoRow(String title, String value, IconData icon, Color color) {
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


}

class ExerciseAnalysisTab extends ConsumerStatefulWidget {
  const ExerciseAnalysisTab({super.key});

  @override
  ConsumerState<ExerciseAnalysisTab> createState() =>
      _ExerciseAnalysisTabState();
}

class _ExerciseAnalysisTabState extends ConsumerState<ExerciseAnalysisTab> {
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
                '운동 분석',
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

          // 볼륨 추이 차트
          _buildVolumeTrendChart(),
          const SizedBox(height: 16),

          // 운동 강도 분석
          _buildIntensityAnalysis(),
          const SizedBox(height: 16),

          // 상위 운동 목록
          _buildTopExercisesList(),
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
    final statsProvider = _selectedPeriod == 'week'
        ? weeklyStatsProvider
        : monthlyStatsProvider;

    return Consumer(
      builder: (context, ref, child) {
        final statsAsync = ref.watch(statsProvider);
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
                        _buildSummaryItem(
                          '총 시간',
                          '${(totalDuration / 60).toStringAsFixed(0)}분',
                          Icons.timer,
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
    final statsProvider = _selectedPeriod == 'week'
        ? weeklyStatsProvider
        : monthlyStatsProvider;

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
                final statsAsync = ref.watch(statsProvider);
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
    final statsProvider = _selectedPeriod == 'week'
        ? weeklyStatsProvider
        : monthlyStatsProvider;

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
                final statsAsync = ref.watch(statsProvider);
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
                final trendAsync = ref.watch(monthlyVolumeTrendProvider);
                return trendAsync.when(
                  data: (trendData) {
                    if (trendData.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('볼륨 추이 데이터가 없습니다.'),
                        ),
                      );
                    }

                    final spots = trendData.asMap().entries.map((entry) {
                      final index = entry.key.toDouble();
                      final volume = (entry.value['total_volume'] as num)
                          .toDouble();
                      return FlSpot(index, volume);
                    }).toList();

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
                                  if (value.toInt() < trendData.length) {
                                    final week =
                                        trendData[value.toInt()]['week']
                                            as String;
                                    return Text(
                                      week.substring(5),
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
                                  final week =
                                      trendData[spot.x.toInt()]['week']
                                          as String;
                                  return LineTooltipItem(
                                    '$week\n${spot.y.toStringAsFixed(0)}kg',
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
    final statsProvider = _selectedPeriod == 'week'
        ? weeklyStatsProvider
        : monthlyStatsProvider;

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
                final statsAsync = ref.watch(statsProvider);
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildIntensityCard(
                            '일평균 운동시간',
                            '${avgDurationPerDay.toStringAsFixed(0)}분',
                            Icons.timer,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildIntensityCard(
                            '분당 볼륨',
                            '${volumePerMinute.toStringAsFixed(1)}kg',
                            Icons.speed,
                            Colors.red,
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
    final statsProvider = _selectedPeriod == 'week'
        ? weeklyStatsProvider
        : monthlyStatsProvider;

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
                final statsAsync = ref.watch(statsProvider);
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
}
