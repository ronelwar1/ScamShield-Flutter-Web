import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/status_style.dart';
import '../data/scam_knowledge.dart';
import '../models/analysis_models.dart';
import 'common_widgets.dart';
import 'highlighted_text.dart';
import 'link_report_card.dart';
import 'risk_gauge.dart';

String _severityWord(String severity) {
  switch (severity) {
    case 'high':
      return 'Strong sign';
    case 'medium':
      return 'Warning sign';
    case 'low':
      return 'Minor';
    default:
      return 'Note';
  }
}

/// The full, friendly breakdown of one scan.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.originalText,
    this.onReport,
    this.onShowGuide,
  });

  final ScamAnalysisResult result;
  final String originalText;
  final void Function(String text)? onReport;
  final void Function(String scamTypeId)? onShowGuide;

  @override
  Widget build(BuildContext context) {
    final style = statusForLabel(result.label);
    final guide = result.scamType == null ? null : guideForId(result.scamType!.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: style.accent.withValues(alpha: 0.45), width: 1.5),
        boxShadow: [BoxShadow(color: style.accent.withValues(alpha: 0.10), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(result: result, style: style),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (result.highlights.isNotEmpty) ...[
                  const SectionTitle(icon: Icons.highlight_alt_rounded, title: 'Your message, warning signs highlighted'),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                    child: HighlightedText(text: originalText, highlights: result.highlights),
                  ),
                  const SizedBox(height: 18),
                ],
                const SectionTitle(icon: Icons.search_rounded, title: 'What I noticed'),
                for (final s in result.signals) _SignalTile(signal: s),
                if (result.links.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SectionTitle(
                    icon: Icons.link_rounded,
                    title: result.links.length == 1 ? 'The link in this message' : 'Links in this message',
                  ),
                  for (final l in result.links)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LinkReportCard(report: l),
                    ),
                ],
                if (result.topTerms.isNotEmpty && !result.isClear) ...[
                  const SizedBox(height: 8),
                  const SectionTitle(icon: Icons.psychology_alt_rounded, title: 'Words the model found suspicious'),
                  TermChips(terms: result.topTerms),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 10),
                const SectionTitle(icon: Icons.checklist_rounded, title: 'What you can do'),
                for (final a in result.advice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(Icons.check_circle_rounded, size: 19, color: AppColors.safe),
                        ),
                        const SizedBox(width: 9),
                        Expanded(child: Text(a, style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.text))),
                      ],
                    ),
                  ),
                for (final n in result.notes)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Note: $n', style: const TextStyle(fontSize: 13, color: AppColors.sunshineDeep, height: 1.4)),
                  ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: result.toReadableText()));
                        if (context.mounted) showSnack(context, 'Result copied');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy result'),
                    ),
                    if (onReport != null && !result.isClear)
                      FilledButton.icon(
                        onPressed: () => onReport!(originalText),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.coralDeep, foregroundColor: Colors.white),
                        icon: const Icon(Icons.flag_rounded, size: 18),
                        label: const Text('Report this'),
                      ),
                    if (onShowGuide != null && guide != null)
                      TextButton.icon(
                        onPressed: () => onShowGuide!(guide.id),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('How this scam works'),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  result.limitations,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result, required this.style});
  final ScamAnalysisResult result;
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        final gauge = RiskGauge(score: result.riskScore, color: style.accent, size: narrow ? 96 : 118);
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${style.emoji}  ${result.labelText}',
                style: TextStyle(fontSize: narrow ? 18 : 21, fontWeight: FontWeight.w900, color: style.onSoft, height: 1.2)),
            if (result.scamType != null) ...[
              const SizedBox(height: 8),
              StatusPill(style: style, text: result.scamType!.name, icon: Icons.category_rounded),
              const SizedBox(height: 6),
              Text(result.scamType!.summary, style: TextStyle(fontSize: 13.5, height: 1.4, color: style.onSoft)),
            ],
            const SizedBox(height: 8),
            Text(
              'Experimental risk indicator. Not a probability, and a low score never proves a message is safe.',
              style: TextStyle(fontSize: 12, height: 1.35, color: style.onSoft.withValues(alpha: 0.85)),
            ),
          ],
        );
        return Container(
          color: style.soft,
          padding: const EdgeInsets.all(16),
          child: narrow
              ? Column(crossAxisAlignment: CrossAxisAlignment.center, children: [gauge, const SizedBox(height: 12), info])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [gauge, const SizedBox(width: 18), Expanded(child: info)],
                ),
        );
      },
    );
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.signal});
  final ScamSignal signal;

  @override
  Widget build(BuildContext context) {
    final s = statusForSeverity(signal.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: s.soft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, color: s.accent, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(signal.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.text)),
                    StatusPill(style: s, text: _severityWord(signal.severity)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(signal.explanation, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
