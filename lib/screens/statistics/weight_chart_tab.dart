import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '/../providers/weight_provider.dart';


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
