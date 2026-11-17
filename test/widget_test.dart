import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kindoverse/main.dart';

void main() {
  testWidgets('Kindoverse app renders home discovery shell with logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: KindoverseApp(enableIntroSplash: false)),
    );
    await tester.pump();

    expect(find.byType(Image), findsWidgets);
  });
}
