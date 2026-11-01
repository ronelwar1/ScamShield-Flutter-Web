import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/status_style.dart';
import '../models/analysis_models.dart';

/// Shows the static analysis of one link. The link is never opened by the app.
class LinkReportCard extends StatelessWidget {
  const LinkReportCard({super.key, required this.report, this.showUrl = true});

  final LinkReport report;
  final bool showUrl;

  @override
  Widget build(BuildContext context) {
    final style = statusForLabel(report.verdict);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.soft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: style.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(style.icon, color: style.accent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  report.verdictText,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: style.onSoft),
                ),
              ),
            ],
          ),
          if (showUrl) ...[
            const SizedBox(height: 8),
            // Plain, non-tappable text on purpose.
            Text(
              report.url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.text),
            ),
          ],
          if (report.registeredDomain.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Real owner of this address: ${report.registeredDomain}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
          ],
          const SizedBox(height: 10),
          for (final f in report.findings) _FindingRow(finding: f),
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});
  final LinkFinding finding;

  @override
  Widget build(BuildContext context) {
    final s = statusForSeverity(finding.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, size: 18, color: s.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(finding.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.text)),
                const SizedBox(height: 2),
                Text(finding.explanation, style: const TextStyle(fontSize: 13.5, height: 1.45, color: AppColors.mutedText)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of chips for the "why" words.
class TermChips extends StatelessWidget {
  const TermChips({super.key, required this.terms});
  final List<String> terms;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in terms)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: AppColors.grapeSoft, borderRadius: BorderRadius.circular(999)),
            child: Text(t, style: const TextStyle(color: Color(0xFF3B2FA8), fontWeight: FontWeight.w700, fontSize: 13)),
          ),
      ],
    );
  }
}

/// Convenience wrapper used by result sections.
class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppColors.primaryDark)),
          ),
        ],
      ),
    );
  }
}

