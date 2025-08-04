import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'back_button_mixin.dart';

/// 앱 전체 네비게이션을 관리하는 래퍼 위젯
class NavigationWrapper extends ConsumerStatefulWidget {
  const NavigationWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends ConsumerState<NavigationWrapper> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 네비게이션 매니저 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final navigationManager = ref.read(navigationManagerProvider);
          final currentRoute = GoRouterState.of(context).uri.toString();
          navigationManager.updateNavigationHistory(currentRoute);
        } catch (e) {
          // GoRouter가 아직 초기화되지 않은 경우 기본값으로 설정
          debugPrint('NavigationWrapper init error: $e');
          final navigationManager = ref.read(navigationManagerProvider);
          navigationManager.updateNavigationHistory('/');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (!mounted || !context.mounted) return;
        
        try {
          final navigationManager = ref.read(navigationManagerProvider);
          
          // 현재 라우트 가져오기 (안전하게)
          String currentRoute = '/';
          try {
            currentRoute = GoRouterState.of(context).uri.toString();
          } catch (e) {
            debugPrint('Could not get current route: $e');
          }
          
          // 현재 라우트 업데이트
          navigationManager.updateNavigationHistory(currentRoute);
          
          // 뒤로가기 처리
          final navigationResult = await navigationManager.handleBackNavigation(context);
          
          if (mounted && context.mounted) {
            await navigationManager.executeNavigation(context, navigationResult);
          }
        } catch (e) {
          debugPrint('NavigationWrapper error: $e');
          // 오류 발생 시 안전하게 홈으로 이동
          if (mounted && context.mounted) {
            context.go('/');
          }
        }
      },
      child: widget.child,
    );
  }
}

