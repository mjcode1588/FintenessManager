import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'navigation_manager.dart';
import 'navigation_models.dart';

/// 뒤로가기 버튼 처리를 표준화하는 믹스인
mixin BackButtonMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  
  /// 커스텀 뒤로가기 처리가 필요한 경우 오버라이드
  Future<BackNavigationResult?> onCustomBackPressed() async {
    return null; // 기본적으로는 표준 처리 사용
  }

  /// 뒤로가기 처리 완료 후 호출되는 콜백
  void onBackNavigationCompleted(BackNavigationResult result) {
    // 기본적으로는 아무것도 하지 않음
    // 필요한 경우 화면별로 오버라이드
  }

  /// 표준화된 PopScope 위젯 생성
  Widget buildWithBackButton({
    required Widget child,
    bool? canPop,
  }) {
    return Consumer(
      builder: (context, ref, _) {
        final navigationManager = ref.watch(navigationManagerProvider);
        
        return PopScope(
          canPop: canPop ?? _shouldAllowPop(navigationManager),
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            
            await _handleBackPressed(context, navigationManager);
          },
          child: child,
        );
      },
    );
  }

  /// PopScope의 canPop 값 결정
  bool _shouldAllowPop(NavigationManager navigationManager) {
    // 홈 화면이 아니고 히스토리가 있으면 기본 pop 허용
    return !navigationManager.isAtHome && navigationManager.canNavigateBack;
  }

  /// 뒤로가기 버튼 처리 로직
  Future<void> _handleBackPressed(BuildContext context, NavigationManager navigationManager) async {
    if (!mounted || !context.mounted) return;
    
    try {
      // 커스텀 처리가 있는지 확인
      final customResult = await onCustomBackPressed();
      if (customResult != null) {
        if (mounted && context.mounted) {
          await navigationManager.executeNavigation(context, customResult);
          onBackNavigationCompleted(customResult);
        }
        return;
      }

      // 표준 뒤로가기 처리
      final result = await navigationManager.handleBackNavigation(context);
      if (mounted && context.mounted) {
        await navigationManager.executeNavigation(context, result);
        onBackNavigationCompleted(result);
      }
      
    } catch (e) {
      debugPrint('Back button handling error: $e');
      // 오류 발생 시 안전하게 홈으로 이동
      if (mounted && context.mounted) {
        final fallbackResult = const BackNavigationResult(
          action: BackNavigationAction.goHome,
          targetRoute: '/',
        );
        await navigationManager.executeNavigation(context, fallbackResult);
        onBackNavigationCompleted(fallbackResult);
      }
    }
  }

  /// 간단한 뒤로가기 처리 (PopScope 없이 직접 호출용)
  Future<void> handleBackNavigation() async {
    final navigationManager = ref.read(navigationManagerProvider);
    if (mounted && context.mounted) {
      final result = await navigationManager.handleBackNavigation(context);
      await navigationManager.executeNavigation(context, result);
      onBackNavigationCompleted(result);
    }
  }
}

/// NavigationManager Provider
final navigationManagerProvider = ChangeNotifierProvider<NavigationManager>((ref) {
  return NavigationManager();
});

/// 뒤로가기 버튼을 위한 헬퍼 함수들
class BackButtonHelper {
  
  /// 표준 뒤로가기 AppBar 액션 생성
  static Widget buildBackButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () async {
        if (!context.mounted) return;
        
        final navigationManager = ref.read(navigationManagerProvider);
        final result = await navigationManager.handleBackNavigation(context);
        
        if (context.mounted) {
          await navigationManager.executeNavigation(context, result);
        }
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  /// 홈 버튼 생성 (현재 앱에서 사용 중인 스타일)
  static Widget buildHomeButton(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.indigo.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () async {
          if (!context.mounted) return;
          
          // NavigationManager를 통해 안전하게 홈으로 이동하면서 히스토리 초기화
          final navigationManager = ref.read(navigationManagerProvider);
          navigationManager.clearHistory();
          
          if (context.mounted) {
            context.go('/');
          }
        },
        icon: const Icon(Icons.home, color: Colors.white),
      ),
    );
  }

  /// 커스텀 뒤로가기 버튼 생성
  static Widget buildCustomBackButton({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onPressed,
    IconData icon = Icons.arrow_back,
    Color? color,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
    );
  }
}