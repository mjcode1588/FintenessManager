import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/../providers/statistics_provider.dart';
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
