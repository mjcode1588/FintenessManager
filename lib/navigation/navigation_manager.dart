import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'navigation_models.dart';

/// 네비게이션 상태와 뒤로가기 동작을 관리하는 중앙 관리자
class NavigationManager extends ChangeNotifier {
  NavigationManager() {
    _initializeState();
  }

  /// 현재 네비게이션 상태
  NavigationState _state = const NavigationState();
  
  /// 히스토리 최대 크기 (메모리 효율성을 위해)
  static const int _maxHistorySize = 20;
  
  /// 앱 종료 확인 대기 시간 (초)
  static const int _exitConfirmationSeconds = 2;

  /// 현재 네비게이션 상태 getter
  NavigationState get state => _state;

  /// 현재 라우트 getter
  String get currentRoute => _state.currentRoute;

  /// 뒤로가기 가능 여부 확인
  bool get canNavigateBack => _state.routeHistory.isNotEmpty;

  /// 홈 화면 여부 확인
  bool get isAtHome => _state.currentRoute == '/';

  /// 초기 상태 설정
  void _initializeState() {
    _state = const NavigationState(
      routeHistory: [],
      currentRoute: '/',
    );
  }

  /// 라우트 히스토리 업데이트
  void updateNavigationHistory(String newRoute) {
    if (newRoute == _state.currentRoute) return;

    final updatedHistory = List<String>.from(_state.routeHistory);
    
    // 현재 라우트를 히스토리에 추가 (홈이 아닌 경우)
    if (_state.currentRoute != '/') {
      updatedHistory.add(_state.currentRoute);
    }

    // 히스토리 크기 제한
    if (updatedHistory.length > _maxHistorySize) {
      updatedHistory.removeAt(0);
    }

    _state = _state.copyWith(
      routeHistory: updatedHistory,
      currentRoute: newRoute,
    );

    // 뒤로가기 시간 초기화 (새로운 화면으로 이동했으므로)
    _clearExitConfirmation();
    
    notifyListeners();
  }

  /// 뒤로가기 동작 처리
  Future<BackNavigationResult> handleBackNavigation(BuildContext context) async {
    // 홈 화면에서의 뒤로가기 처리
    if (isAtHome) {
      return _handleHomeBackNavigation(context);
    }

    // 일반 화면에서의 뒤로가기 처리
    return _handleStandardBackNavigation(context);
  }

  /// 홈 화면에서의 뒤로가기 처리
  BackNavigationResult _handleHomeBackNavigation(BuildContext context) {
    final now = DateTime.now();
    
    // 첫 번째 뒤로가기 또는 시간이 지난 경우
    if (_state.lastBackPressTime == null ||
        now.difference(_state.lastBackPressTime!).inSeconds > _exitConfirmationSeconds) {
      
      _state = _state.copyWith(
        lastBackPressTime: now,
        canExit: true,
      );
      notifyListeners();
      
      return const BackNavigationResult(action: BackNavigationAction.showExitDialog);
    }
    
    // 두 번째 뒤로가기 (종료)
    return const BackNavigationResult(action: BackNavigationAction.exit);
  }

  /// 일반 화면에서의 뒤로가기 처리
  BackNavigationResult _handleStandardBackNavigation(BuildContext context) {
    // 히스토리가 있는 경우 이전 화면으로 이동
    if (canNavigateBack) {
      final previousRoute = _state.routeHistory.last;
      
      // 히스토리에서 마지막 항목 제거
      final updatedHistory = List<String>.from(_state.routeHistory)..removeLast();
      
      _state = _state.copyWith(
        routeHistory: updatedHistory,
        currentRoute: previousRoute,
      );
      notifyListeners();
      
      return BackNavigationResult(
        action: BackNavigationAction.pop,
        targetRoute: previousRoute,
      );
    }
    
    // 히스토리가 없는 경우 홈으로 이동
    _state = _state.copyWith(
      routeHistory: [],
      currentRoute: '/',
    );
    notifyListeners();
    
    return const BackNavigationResult(
      action: BackNavigationAction.goHome,
      targetRoute: '/',
    );
  }

  /// 앱 종료 확인 상태 초기화
  void _clearExitConfirmation() {
    if (_state.lastBackPressTime != null || _state.canExit) {
      _state = _state.clearLastBackPressTime();
      notifyListeners();
    }
  }

  /// 앱 종료 실행
  void exitApp() {
    SystemNavigator.pop();
  }

  /// 종료 확인 스낵바 표시
  void showExitConfirmationSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다'),
        duration: Duration(seconds: _exitConfirmationSeconds),
      ),
    );
  }

  /// 네비게이션 실행 (안전한 컨텍스트 확인 포함)
  Future<bool> executeNavigation(BuildContext context, BackNavigationResult result) async {
    if (!context.mounted) return false;

    try {
      switch (result.action) {
        case BackNavigationAction.pop:
          if (result.targetRoute != null) {
            context.go(result.targetRoute!);
          } else {
            context.pop();
          }
          break;
          
        case BackNavigationAction.goHome:
          context.go('/');
          break;
          
        case BackNavigationAction.showExitDialog:
          showExitConfirmationSnackBar(context);
          break;
          
        case BackNavigationAction.exit:
          exitApp();
          break;
      }
      return true;
    } catch (e) {
      // 네비게이션 오류 시 홈으로 폴백
      debugPrint('Navigation error: $e');
      if (context.mounted) {
        context.go('/');
      }
      return false;
    }
  }

  /// 히스토리 초기화 (필요한 경우)
  void clearHistory() {
    _state = _state.copyWith(routeHistory: []);
    notifyListeners();
  }

  /// 특정 라우트까지 히스토리 정리
  void clearHistoryUntil(String route) {
    final updatedHistory = <String>[];
    bool found = false;
    
    for (int i = _state.routeHistory.length - 1; i >= 0; i--) {
      if (_state.routeHistory[i] == route) {
        found = true;
        break;
      }
      updatedHistory.insert(0, _state.routeHistory[i]);
    }
    
    if (found) {
      _state = _state.copyWith(routeHistory: updatedHistory);
      notifyListeners();
    }
  }

  /// 디버그용 히스토리 출력
  void debugPrintHistory() {
    debugPrint('Navigation History: ${_state.routeHistory}');
    debugPrint('Current Route: ${_state.currentRoute}');
  }


}