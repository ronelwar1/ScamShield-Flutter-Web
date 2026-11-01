import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield/app.dart';
import 'package:scamshield/data/scam_knowledge.dart';
import 'package:scamshield/models/analysis_models.dart';
import 'package:scamshield/services/scam_analysis_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, dynamic> _sample = {
  'label': 'likely_scam',
  'label_text': 'Likely scam indicators',
  'risk_score': 78,
  'model_scam_probability': 0.91,
  'rule_score': 0.7,
  'signals': [
    {
      'id': 'credential_request',
      'name': 'Asks for a code or password',
      'explanation': 'x',
      'severity': 'high',
      'spans': [
        {'start': 5, 'end': 10}
      ],
    }
  ],
  'highlights': [
    {'start': 5, 'end': 10, 'signals': ['credential_request']}
  ],
  'links': [],
  'scam_type': {'id': 'phishing', 'name': 'Phishing', 'summary': 's'},
  'top_terms': ['otp'],
  'advice': ['Do not share'],
  'notes': [],
  'model': 'm',
  'limitations': 'does not prove',
};

/// Fake server: always answers 503, so no real network is touched and no timers are left pending.
ScamAnalysisService _offlineService() =>
    ScamAnalysisService(client: MockClient((request) async => http.Response('{}', 503)));

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ScamShield app loads on a phone-sized screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ScamShieldApp(service: _offlineService()));
    await tester.pumpAndSettle();
    expect(find.text('ScamShield'), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('desktop width shows the side bar instead of the bottom bar', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ScamShieldApp(service: _offlineService()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Check a message'), findsWidgets);
  });

  test('analysis result parses and round-trips through JSON', () {
    final r = ScamAnalysisResult.fromJson(_sample);
    expect(r.isLikelyScam, isTrue);
    expect(r.riskScore, 78);
    expect(r.scamType?.id, 'phishing');
    expect(r.highlights.single.start, 5);
    final again = ScamAnalysisResult.fromJson(r.toJson());
    expect(again.signals.single.spans.single.end, 10);
    expect(again.toReadableText(), contains('Likely scam indicators'));
  });

  test('parsing tolerates an empty response', () {
    final r = ScamAnalysisResult.fromJson(const {});
    expect(r.signals, isEmpty);
    expect(r.scamType, isNull);
  });

  test('every scam type the API can return has a "how it works" guide', () {
    for (final id in ['phishing', 'prize', 'advance_fee', 'investment', 'job_task', 'tech_support', 'emergency', 'authority']) {
      final g = guideForId(id);
      expect(g, isNotNull, reason: id);
      expect(g!.steps.length, greaterThanOrEqualTo(3), reason: id);
      expect(g.whyItWorks, isNotEmpty, reason: id);
      expect(g.redFlags, isNotEmpty, reason: id);
    }
  });

  testWidgets('phone bar has five destinations, a "How scams work" guide and no quiz', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(ScamShieldApp(service: _offlineService()));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination)), findsNWidgets(5));
    expect(find.text('Quiz'), findsNothing);
    expect(find.textContaining('Spot the Scam'), findsNothing);
    expect(find.textContaining('tricks'), findsNothing);

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Guide')));
    await tester.pumpAndSettle();
    expect(find.text('How scams work'), findsWidgets);
    expect(find.text('The pattern behind most scams'), findsOneWidget);
  });
}
