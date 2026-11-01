// Data classes for the ScamShield API. Parsing is defensive: a missing field never crashes the UI.

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

class SpanRange {
  const SpanRange(this.start, this.end);
  final int start;
  final int end;

  factory SpanRange.fromJson(Map<String, dynamic> json) =>
      SpanRange((json['start'] as num?)?.toInt() ?? 0, (json['end'] as num?)?.toInt() ?? 0);

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}

class ScamSignal {
  const ScamSignal({
    required this.id,
    required this.name,
    required this.explanation,
    this.severity = 'low',
    this.spans = const [],
  });

  final String id;
  final String name;
  final String explanation;
  final String severity; // high | medium | low | info
  final List<SpanRange> spans;

  factory ScamSignal.fromJson(Map<String, dynamic> json) => ScamSignal(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Warning sign',
        explanation: json['explanation'] as String? ?? '',
        severity: json['severity'] as String? ?? 'low',
        spans: _maps(json['spans']).map(SpanRange.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'explanation': explanation,
        'severity': severity,
        'spans': spans.map((s) => s.toJson()).toList(),
      };
}

class Highlight {
  const Highlight({required this.start, required this.end, this.signals = const []});
  final int start;
  final int end;
  final List<String> signals;

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
        start: (json['start'] as num?)?.toInt() ?? 0,
        end: (json['end'] as num?)?.toInt() ?? 0,
        signals: _strings(json['signals']),
      );

  Map<String, dynamic> toJson() => {'start': start, 'end': end, 'signals': signals};
}

class LinkFinding {
  const LinkFinding({required this.name, required this.explanation, required this.severity});
  final String name;
  final String explanation;
  final String severity; // high | medium | low

  factory LinkFinding.fromJson(Map<String, dynamic> json) => LinkFinding(
        name: json['name'] as String? ?? 'Finding',
        explanation: json['explanation'] as String? ?? '',
        severity: json['severity'] as String? ?? 'low',
      );

  Map<String, dynamic> toJson() => {'name': name, 'explanation': explanation, 'severity': severity};
}

class LinkReport {
  const LinkReport({
    required this.url,
    required this.host,
    required this.registeredDomain,
    required this.verdict,
    required this.verdictText,
    required this.findings,
  });

  final String url;
  final String host;
  final String registeredDomain;
  final String verdict; // high_risk | suspicious | no_obvious_issues
  final String verdictText;
  final List<LinkFinding> findings;

  factory LinkReport.fromJson(Map<String, dynamic> json) => LinkReport(
        url: json['url'] as String? ?? '',
        host: json['host'] as String? ?? '',
        registeredDomain: json['registered_domain'] as String? ?? '',
        verdict: json['verdict'] as String? ?? 'suspicious',
        verdictText: json['verdict_text'] as String? ?? 'Verify before opening.',
        findings: _maps(json['findings']).map(LinkFinding.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'host': host,
        'registered_domain': registeredDomain,
        'verdict': verdict,
        'verdict_text': verdictText,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

class ScamType {
  const ScamType({required this.id, required this.name, required this.summary});
  final String id;
  final String name;
  final String summary;

  factory ScamType.fromJson(Map<String, dynamic> json) => ScamType(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'summary': summary};
}

class ScamAnalysisResult {
  const ScamAnalysisResult({
    required this.label,
    required this.labelText,
    required this.riskScore,
    required this.modelProbability,
    required this.ruleScore,
    required this.signals,
    required this.highlights,
    required this.links,
    required this.scamType,
    required this.topTerms,
    required this.advice,
    required this.notes,
    required this.model,
    required this.limitations,
  });

  final String label; // likely_scam | suspicious | no_obvious_scam_indicators
  final String labelText;
  final int riskScore;
  final double modelProbability;
  final double ruleScore;
  final List<ScamSignal> signals;
  final List<Highlight> highlights;
  final List<LinkReport> links;
  final ScamType? scamType;
  final List<String> topTerms;
  final List<String> advice;
  final List<String> notes;
  final String model;
  final String limitations;

  bool get isLikelyScam => label == 'likely_scam';
  bool get isSuspicious => label == 'suspicious';
  bool get isClear => !isLikelyScam && !isSuspicious;

  factory ScamAnalysisResult.fromJson(Map<String, dynamic> json) {
    final type = json['scam_type'];
    return ScamAnalysisResult(
      label: json['label'] as String? ?? 'suspicious',
      labelText: json['label_text'] as String? ?? 'Needs careful checking',
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      modelProbability: (json['model_scam_probability'] as num?)?.toDouble() ?? 0,
      ruleScore: (json['rule_score'] as num?)?.toDouble() ?? 0,
      signals: _maps(json['signals']).map(ScamSignal.fromJson).toList(),
      highlights: _maps(json['highlights']).map(Highlight.fromJson).toList(),
      links: _maps(json['links']).map(LinkReport.fromJson).toList(),
      scamType: type is Map ? ScamType.fromJson(Map<String, dynamic>.from(type)) : null,
      topTerms: _strings(json['top_terms']),
      advice: _strings(json['advice']),
      notes: _strings(json['notes']),
      model: json['model'] as String? ?? 'Experimental NLP baseline',
      limitations: json['limitations'] as String? ?? 'Automated screening can make mistakes.',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'label_text': labelText,
        'risk_score': riskScore,
        'model_scam_probability': modelProbability,
        'rule_score': ruleScore,
        'signals': signals.map((s) => s.toJson()).toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'links': links.map((l) => l.toJson()).toList(),
        'scam_type': scamType?.toJson(),
        'top_terms': topTerms,
        'advice': advice,
        'notes': notes,
        'model': model,
        'limitations': limitations,
      };

  /// Plain-text version for copy / share.
  String toReadableText() {
    final out = StringBuffer()
      ..writeln('ScamShield result: $labelText')
      ..writeln('Experimental risk indicator: $riskScore/100');
    if (scamType != null) out.writeln('Looks like: ${scamType!.name}');
    out
      ..writeln()
      ..writeln('What I noticed:');
    for (final s in signals) {
      out.writeln('- ${s.name}: ${s.explanation}');
    }
    out
      ..writeln()
      ..writeln('What you can do:');
    for (final a in advice) {
      out.writeln('- $a');
    }
    out
      ..writeln()
      ..writeln('Important: $limitations');
    return out.toString().trim();
  }
}

class ReportReceipt {
  const ReportReceipt({required this.id, required this.label, required this.riskScore, required this.storedText, required this.note});
  final int id;
  final String label;
  final int riskScore;
  final String storedText;
  final String note;

  factory ReportReceipt.fromJson(Map<String, dynamic> json) => ReportReceipt(
        id: (json['id'] as num?)?.toInt() ?? 0,
        label: json['label'] as String? ?? '',
        riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
        storedText: json['stored_text'] as String? ?? '',
        note: json['note'] as String? ?? 'Report received.',
      );
}
