import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semester_project/app.dart';

void main() {
  testWidgets('Home scans a message and shows a high-risk result',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SafeScanApp());
    await tester.enterText(
      find.byType(TextField),
      'URGENT! Verify your OTP at http://bit.ly/x within 24 hours',
    );
    await tester.tap(find.text('Check message'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('HIGH RISK'), findsOneWidget);
  });

  testWidgets('Home opens Login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SafeScanApp());
    await tester.tap(find.text('Log in').first);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
