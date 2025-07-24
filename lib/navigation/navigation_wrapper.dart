import 'package:flutter/material.dart';

/// 앱 전체 네비게이션을 관리하는 래퍼 위젯
class NavigationWrapper extends StatelessWidget {
  const NavigationWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

