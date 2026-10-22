
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield/main.dart';

void main() {
  testWidgets('ScamShield app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ScamShieldHome());

    expect(find.byType(ScamShieldHome), findsOneWidget);
  });
}
