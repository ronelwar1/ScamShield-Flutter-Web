import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../data/scam_knowledge.dart';
import '../services/prefill.dart';
import '../widgets/common_widgets.dart';

/// Offline reference: how scams work. No quiz, no scoring. Just explanations.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key, required this.prefill});

  /// Carries a scam-type id to expand (e.g. from "How this scam works" on a result).
  final Prefill prefill;

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    widget.prefill.addListener(_onPrefill);
  }

  @override
  void dispose() {
    widget.prefill.removeListener(_onPrefill);
    super.dispose();
  }

  void _onPrefill() {
    final id = widget.prefill.take();
    if (id == null || !mounted) return;
    setState(() => _expandedId = id);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeading(
              emoji: '📖',
              title: 'How scams work',
              subtitle: 'Plain explanations of how common scams operate and why people fall for them.',
            ),
            const SizedBox(height: 22),
            const _SectionTitle('The pattern behind most scams'),
            const SizedBox(height: 10),
            const _Playbook(),
            const SizedBox(height: 24),
            const _SectionTitle('Why they work, even on careful people'),
            const SizedBox(height: 10),
            const _Levers(),
            const SizedBox(height: 24),
            const _SectionTitle('Common scams, explained'),
            const SizedBox(height: 4),
            const Text(
              'Tap a scam to see how it unfolds. The examples are made up to illustrate the pattern.',
              style: TextStyle(fontSize: 13.5, height: 1.4, color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 700;
                final cardWidth = twoColumns ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    for (final g in scamGuides)
                      SizedBox(
                        width: cardWidth,
                        child: _GuideCard(
                          key: ValueKey('${g.id}-${_expandedId == g.id}'),
                          guide: g,
                          initiallyExpanded: _expandedId == g.id,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark));
}

class _Playbook extends StatelessWidget {
  const _Playbook();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          for (var i = 0; i < scamPlaybook.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scamPlaybook[i].$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppColors.text)),
                        const SizedBox(height: 2),
                        Text(scamPlaybook[i].$2, style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.text)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Levers extends StatelessWidget {
  const _Levers();

  @override
  Widget build(BuildContext context) {
    const tints = [AppColors.coralSoft, AppColors.sunshineSoft, AppColors.grapeSoft, AppColors.mint, AppColors.softAccent];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 3 : (constraints.maxWidth >= 560 ? 2 : 1);
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < scamLevers.length; i++)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: tints[i % tints.length], borderRadius: BorderRadius.circular(18)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scamLevers[i].$1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: AppColors.text)),
                      const SizedBox(height: 3),
                      Text(scamLevers[i].$2, style: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.text)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({super.key, required this.guide, required this.initiallyExpanded});
  final ScamGuide guide;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: initiallyExpanded ? AppColors.teal : AppColors.border, width: initiallyExpanded ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
          child: Text(guide.emoji, style: const TextStyle(fontSize: 24)),
        ),
        title: Text(guide.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: AppColors.text)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(guide.tagline, style: const TextStyle(fontSize: 13.5, height: 1.35, color: AppColors.mutedText)),
        ),
        children: [
          Text(guide.howItWorks, style: const TextStyle(fontSize: 14.5, height: 1.55, color: AppColors.text)),
          const SizedBox(height: 14),
          const _Label('How it usually unfolds', AppColors.primaryDark),
          const SizedBox(height: 6),
          for (var i = 0; i < guide.steps.length; i++) _Step(number: i + 1, text: guide.steps[i]),
          const SizedBox(height: 10),
          const _Label('Why it works', AppColors.primaryDark),
          const SizedBox(height: 4),
          Text(guide.whyItWorks, style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.text)),
          const SizedBox(height: 14),
          const _Label('Warning signs', AppColors.coralDeep),
          const SizedBox(height: 6),
          for (final f in guide.redFlags) _Bullet(text: f, icon: Icons.flag_rounded, color: AppColors.coralDeep),
          const SizedBox(height: 10),
          const _Label('Worth knowing', AppColors.safe),
          const SizedBox(height: 6),
          for (final t in guide.whatToDo) _Bullet(text: t, icon: Icons.check_circle_rounded, color: AppColors.safe),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Example (made up)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.mutedText)),
                const SizedBox(height: 4),
                Text('“${guide.example}”', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, height: 1.45, color: AppColors.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 14.5));
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
            child: Text('$number', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.text))),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text, required this.icon, required this.color});
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.text))),
        ],
      ),
    );
  }
}
