import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintenessmanager/main.dart';

void main() {
  testWidgets('HomeScreen has a title and menu cards', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify that the AppBar title is present.
    expect(find.text('운동 기록 앱'), findsOneWidget);

    // Verify that one of the menu cards is present.
    expect(find.text('운동 종류 관리'), findsOneWidget);
    
    // Verify that another menu card is present.
    expect(find.text('운동 기록'), findsOneWidget);
  });
}