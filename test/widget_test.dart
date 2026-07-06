import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manifest_fellowship_tracker/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Manifest Fellowship Tracker'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  });
}
