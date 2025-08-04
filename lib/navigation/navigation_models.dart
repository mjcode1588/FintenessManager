/// 뒤로가기 동작의 종류를 정의하는 열거형
enum BackNavigationAction {
  /// 이전 화면으로 이동
  pop,
  /// 홈으로 이동
  goHome,
  /// 종료 확인 표시
  showExitDialog,
  /// 앱 종료
  exit,
}

/// 뒤로가기 처리 결과를 나타내는 클래스
class BackNavigationResult {
  const BackNavigationResult({
    required this.action,
    this.targetRoute,
    this.handled = true,
  });

  /// 수행할 동작
  final BackNavigationAction action;
  
  /// 이동할 대상 라우트 (필요한 경우)
  final String? targetRoute;
  
  /// 처리 완료 여부
  final bool handled;

  @override
  String toString() {
    return 'BackNavigationResult(action: $action, targetRoute: $targetRoute, handled: $handled)';
  }
}

/// 네비게이션 상태를 나타내는 클래스
class NavigationState {
  const NavigationState({
    this.routeHistory = const [],
    this.currentRoute = '/',
    this.lastBackPressTime,
    this.canExit = false,
  });

  /// 라우트 히스토리 스택
  final List<String> routeHistory;
  
  /// 현재 라우트
  final String currentRoute;
  
  /// 마지막 뒤로가기 버튼 누른 시간
  final DateTime? lastBackPressTime;
  
  /// 앱 종료 가능 여부
  final bool canExit;

  /// 새로운 상태를 생성하는 copyWith 메서드
  NavigationState copyWith({
    List<String>? routeHistory,
    String? currentRoute,
    DateTime? lastBackPressTime,
    bool? canExit,
  }) {
    return NavigationState(
      routeHistory: routeHistory ?? this.routeHistory,
      currentRoute: currentRoute ?? this.currentRoute,
      lastBackPressTime: lastBackPressTime ?? this.lastBackPressTime,
      canExit: canExit ?? this.canExit,
    );
  }

  /// 마지막 뒤로가기 시간을 초기화하는 메서드
  NavigationState clearLastBackPressTime() {
    return copyWith(
      lastBackPressTime: null,
      canExit: false,
    );
  }

  @override
  String toString() {
    return 'NavigationState(routeHistory: $routeHistory, currentRoute: $currentRoute, lastBackPressTime: $lastBackPressTime, canExit: $canExit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationState &&
        other.routeHistory.toString() == routeHistory.toString() &&
        other.currentRoute == currentRoute &&
        other.lastBackPressTime == lastBackPressTime &&
        other.canExit == canExit;
  }

  @override
  int get hashCode {
    return routeHistory.hashCode ^
        currentRoute.hashCode ^
        lastBackPressTime.hashCode ^
        canExit.hashCode;
  }
}