import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/statistics/body_part_analysis_tab.dart';
import '../screens/statistics/dashboard_tab.dart';
import '../screens/statistics/period_analysis_tab.dart';
import '../screens/statistics/weight_chart_tab.dart';



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