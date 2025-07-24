import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../navigation/back_button_mixin.dart';

/// 기존 화면들을 간단한 뒤로가기 처리로 감싸는 래퍼
class ScreenWrapper extends ConsumerWidget {
  const ScreenWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false, // NavigationManager를 통해 처리
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (!context.mounted) return;
        
        final navigationManager = ref.read(navigationManagerProvider);
        final navigationResult = await navigationManager.handleBackNavigation(context);
        
        if (context.mounted) {
          await navigationManager.executeNavigation(context, navigationResult);
        }
      },
      child: child,
    );
  }
}