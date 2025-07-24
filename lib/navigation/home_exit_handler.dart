import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 홈 화면에서의 앱 종료 처리를 담당하는 클래스
class HomeExitHandler {
  HomeExitHandler({
    this.exitConfirmationDuration = const Duration(seconds: 2),
    this.exitMessage = '뒤로가기 버튼을 한 번 더 누르면 앱이 종료됩니다',
  });

  /// 종료 확인 대기 시간
  final Duration exitConfirmationDuration;
  
  /// 종료 확인 메시지
  final String exitMessage;
  
  /// 마지막 뒤로가기 버튼을 누른 시간
  DateTime? _lastBackPressTime;
  
  /// 종료 확인 타이머
  Timer? _exitConfirmationTimer;
  
  /// 현재 표시된 스낵바
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _currentSnackBar;

  /// 뒤로가기 버튼 처리
  /// 
  /// Returns:
  /// - true: 앱을 종료해야 함
  /// - false: 종료 확인 메시지를 표시함
  bool handleBackPress(BuildContext context) {
    final now = DateTime.now();
    
    // 첫 번째 뒤로가기 또는 시간이 지난 경우
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > exitConfirmationDuration) {
      
      _lastBackPressTime = now;
      _showExitConfirmation(context);
      _startExitConfirmationTimer();
      
      return false; // 종료하지 않음
    }
    
    // 두 번째 뒤로가기 - 앱 종료
    _clearExitConfirmation();
    return true;
  }

  /// 종료 확인 스낵바 표시
  void _showExitConfirmation(BuildContext context) {
    // 기존 스낵바가 있다면 제거
    _currentSnackBar?.close();
    
    _currentSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                exitMessage,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        duration: exitConfirmationDuration,
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: '취소',
          textColor: Colors.white,
          onPressed: () {
            _clearExitConfirmation();
          },
        ),
      ),
    );
  }

  /// 종료 확인 타이머 시작
  void _startExitConfirmationTimer() {
    _exitConfirmationTimer?.cancel();
    _exitConfirmationTimer = Timer(exitConfirmationDuration, () {
      _clearExitConfirmation();
    });
  }

  /// 종료 확인 상태 초기화
  void _clearExitConfirmation() {
    _lastBackPressTime = null;
    _exitConfirmationTimer?.cancel();
    _exitConfirmationTimer = null;
    _currentSnackBar?.close();
    _currentSnackBar = null;
  }

  /// 앱 종료 실행
  void exitApp() {
    _clearExitConfirmation();
    SystemNavigator.pop();
  }

  /// 종료 확인 상태 여부
  bool get isInExitConfirmationState {
    if (_lastBackPressTime == null) return false;
    
    final now = DateTime.now();
    return now.difference(_lastBackPressTime!) <= exitConfirmationDuration;
  }

  /// 리소스 정리
  void dispose() {
    _exitConfirmationTimer?.cancel();
    _currentSnackBar?.close();
  }
}

/// HomeExitHandler를 위한 믹스인
mixin HomeExitMixin<T extends StatefulWidget> on State<T> {
  late HomeExitHandler _exitHandler;

  @override
  void initState() {
    super.initState();
    _exitHandler = HomeExitHandler();
  }

  @override
  void dispose() {
    _exitHandler.dispose();
    super.dispose();
  }

  /// 홈 화면에서의 뒤로가기 처리
  /// 
  /// PopScope의 onPopInvokedWithResult에서 호출
  void handleHomeBackPress(bool didPop, Object? result) {
    if (didPop) return;

    final shouldExit = _exitHandler.handleBackPress(context);
    if (shouldExit) {
      _exitHandler.exitApp();
    }
  }

  /// 직접 뒤로가기 처리 (버튼 등에서 호출)
  void handleDirectBackPress() {
    final shouldExit = _exitHandler.handleBackPress(context);
    if (shouldExit) {
      _exitHandler.exitApp();
    }
  }

  /// PopScope 위젯 빌드 헬퍼
  Widget buildHomePopScope({required Widget child}) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: handleHomeBackPress,
      child: child,
    );
  }

  /// 종료 확인 상태 getter
  bool get isInExitConfirmationState => _exitHandler.isInExitConfirmationState;
}