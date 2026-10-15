import '../models/scan_result.dart';

/// TEMPORARY stand-in for the future REST API / NLP model.
/// Uses simple keyword rules so the interface can be demonstrated.
/// It is NOT real scam detection; replace with an API call later.
class MockAnalysisService {
  const MockAnalysisService();

  Future<ScanResult> analyze(String message) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final String text = message.toLowerCase();
    int score = 0;
    final List<String> reasons = <String>[];

    void check(bool found, int points, String reason) {
      if (found) {
        score += points;
        reasons.add(reason);
      }
    }

    check(RegExp(r'https?://|www\.|bit\.ly|tinyurl').hasMatch(text), 2,
        'Contains a link. Scam messages often hide fake websites behind links.');
    check(
        RegExp(r'urgent|immediately|act now|within 24|last chance|expires')
            .hasMatch(text),
        2,
        'Creates pressure or urgency to make you act without thinking.');
    check(
        RegExp(r'otp|password|\bpin\b|cvv|verify your|account.{0,15}(suspend|lock|block)')
            .hasMatch(text),
        3,
        'Asks for, or threatens your account over, sensitive details like OTP, PIN or password.');
    check(RegExp(r'won|winner|prize|reward|free gift|claim').hasMatch(text), 2,
        'Promises a prize or reward you did not sign up for.');
    check(
        RegExp(r'gcash|maya|paypal|bank|send money|gift card|crypto')
            .hasMatch(text),
        1,
        'Mentions money transfer or payment services.');

    final RiskLevel level = score >= 5
        ? RiskLevel.high
        : score >= 2
            ? RiskLevel.medium
            : RiskLevel.low;
    final String label = level == RiskLevel.high
        ? 'Likely a scam'
        : level == RiskLevel.medium
            ? 'Suspicious message'
            : 'Looks safe';
    if (reasons.isEmpty) {
      reasons.add('No common scam warning signs were found in this message.');
    }
    final double confidence = (0.60 + (score > 8 ? 8 : score) * 0.045);
    return ScanResult(
      classification: label,
      riskLevel: level,
      confidence: confidence,
      reasons: reasons,
    );
  }
}
