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
import 'screens/screen_wrapper.dart';
import 'navigation/navigation_wrapper.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChannels.platform.invokeMethod(
    'SystemNavigator.routeInformationUpdated',
  );

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
      builder: (context, child) {
        return NavigationWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
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
      builder: (context, state) => const ScreenWrapper(child: ExerciseListScreen()),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const ScreenWrapper(child: AddExerciseScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/exercise-record',
      builder: (context, state) => const ScreenWrapper(child: ExerciseRecordScreen()),
    ),
    GoRoute(
      path: '/weight-record',
      builder: (context, state) => const ScreenWrapper(child: WeightRecordScreen()),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const ScreenWrapper(child: StatisticsScreen()),
    ),
    GoRoute(
      path: '/export',
      builder: (context, state) => ScreenWrapper(child: ExportScreen()),
    ),
    // 기존 add-exercise 라우트 호환성을 위해 유지
    GoRoute(
      path: '/add-exercise',
      redirect: (context, state) => '/exercises/add',
    ),
  ],
);
