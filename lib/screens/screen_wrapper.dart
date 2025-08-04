import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/back_button_mixin.dart';

/// 기존 화면들을 간단한 뒤로가기 처리로 감싸는 래퍼
class ScreenWrapper extends ConsumerStatefulWidget {
  const ScreenWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<ScreenWrapper> createState() => _ScreenWrapperState();
}

class _ScreenWrapperState extends ConsumerState<ScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 네비게이션 히스토리 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentRoute = GoRouterState.of(context).uri.toString();
        final navigationManager = ref.read(navigationManagerProvider);
        navigationManager.updateNavigationHistory(currentRoute);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // NavigationWrapper에서 전역적으로 뒤로가기를 처리하므로 
    // 여기서는 단순히 child만 반환
    return widget.child;
  }
}