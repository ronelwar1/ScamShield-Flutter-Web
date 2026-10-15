/// Risk levels (later returned by the planned analyze endpoint).
enum RiskLevel { low, medium, high }

/// Client-side model of one analysis result.
class ScanResult {
  const ScanResult({
    required this.classification,
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
  });

  final String classification;
  final RiskLevel riskLevel;
  final double confidence; // 0.0 - 1.0
  final List<String> reasons;

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        classification: json['classification'] as String,
        riskLevel: RiskLevel.values.byName(
          (json['risk_level'] as String).toLowerCase(),
        ),
        confidence: (json['confidence'] as num).toDouble(),
        reasons: List<String>.from(json['reasons'] as List<dynamic>),
      );
}
