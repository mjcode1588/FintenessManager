import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/exercise_list_screen.dart';
import 'screens/add_exercise_screen.dart';
import 'screens/exercise_record_screen.dart';
import 'screens/weight_record_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/export_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChannels.platform.invokeMethod('SystemNavigator.routeInformationUpdated');

  // 웹에서 sqflite를 사용하기 위한 초기화
  if (kIsWeb) {
    // 웹에서는 sqflite_common_ffi를 사용
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Excercise App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_lastPressedAt == null || 
            DateTime.now().difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = DateTime.now();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: const HomeScreen(),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeWrapper(),
    ),
    GoRoute(
      path: '/exercises',
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          context.go('/');
          return false;
        },
        child: const ExerciseListScreen(),
      ),
    ),
    GoRoute(
      path: '/add-exercise',
      builder: (context, state) => const AddExerciseScreen(),
    ),
    GoRoute(
      path: '/exercise-record',
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          context.go('/');
          return false;
        },
        child: const ExerciseRecordScreen(),
      ),
    ),
    GoRoute(
      path: '/weight-record',
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          context.go('/');
          return false;
        },
        child: const WeightRecordScreen(),
      ),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          context.go('/');
          return false;
        },
        child: const StatisticsScreen(),
      ),
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          context.go('/');
          return false;
        },
        child: ExportScreen(),
      ),
    ),
  ],
);