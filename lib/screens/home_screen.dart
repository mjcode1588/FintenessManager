import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('운동 기록 앱'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMenuCard(
              context,
              '운동 종류 관리',
              Icons.fitness_center,
              Colors.blue,
              () => context.go('/exercises'),
            ),
            _buildMenuCard(
              context,
              '운동 기록',
              Icons.assignment,
              Colors.green,
              () => context.go('/exercise-record'),
            ),
            _buildMenuCard(
              context,
              '몸무게 기록',
              Icons.monitor_weight,
              Colors.orange,
              () => context.go('/weight-record'),
            ),
            _buildMenuCard(
              context,
              '통계 & 차트',
              Icons.analytics,
              Colors.purple,
              () => context.go('/statistics'),
            ),
            _buildMenuCard(
              context,
              '데이터 내보내기',
              Icons.upload_file,
              Colors.teal,
              () => context.go('/export'),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}