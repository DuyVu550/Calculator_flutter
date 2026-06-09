import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:test_flutter/main.dart';

void main() {
  testWidgets('Calculator UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: CalculatorApp()));

    // Verify that the initial display shows '0'.
    // Note: There's a '0' on the button and a '0' on the display.
    expect(find.text('0'), findsNWidgets(2));

    // Tap the '5' button
    await tester.tap(find.text('5'));
    await tester.pump();

    // Tap the '+' button
    await tester.tap(find.text('+'));
    await tester.pump();

    // Tap the '3' button
    await tester.tap(find.text('3'));
    await tester.pump();

    // Verify pending expression shows '5+3'
    expect(find.text('5+3'), findsOneWidget);

    // Tap the '=' button
    await tester.tap(find.text('='));
    await tester.pump();

    // Verify result is '8'
    expect(find.text('8'), findsWidgets); // '8' on display and '8' on button
  });
}
