import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../data/scam_knowledge.dart';
import '../widgets/common_widgets.dart';

/// Calm, step-by-step "I think I got scammed" checklist.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  String? _selectedId;
  final Set<String> _done = <String>{};

  RecoveryScenario? get _selected {
    for (final s in recoveryScenarios) {
      if (s.id == _selectedId) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return SingleChildScrollView(
      child: PageBody(
        maxWidth: 780,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeading(
              emoji: '🆘',
              title: 'I think I got scammed',
              subtitle: 'Take a breath. It happens to smart people, and acting quickly really helps.',
            ),
            const SizedBox(height: 18),
            const SoftCard(
              color: AppColors.sunshineSoft,
              borderColor: AppColors.sunshine,
              child: Text(
                'What happened? Pick the closest option and follow the checklist from the top. '
                'Use official contact details from your bank\'s app, card or website, never numbers sent in a message.',
                style: TextStyle(fontSize: 14.5, height: 1.55, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 16),
            for (final s in recoveryScenarios)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScenarioButton(
                  scenario: s,
                  selected: s.id == _selectedId,
                  onTap: () => setState(() => _selectedId = s.id),
                ),
              ),
            if (selected != null) ...[
              const SizedBox(height: 8),
              _Checklist(
                scenario: selected,
                done: _done,
                onToggle: (key, value) => setState(() {
                  if (value) {
                    _done.add(key);
                  } else {
                    _done.remove(key);
                  }
                }),
              ),
            ],
            const SizedBox(height: 18),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📣 Where to report', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primaryDark)),
                  const SizedBox(height: 8),
                  for (final r in whereToReport)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.circle, size: 8, color: AppColors.teal)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(r, style: const TextStyle(fontSize: 14.5, height: 1.45, color: AppColors.text))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SoftCard(
              color: AppColors.coralSoft,
              borderColor: AppColors.coral,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('🚫 Please don\'t', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF8E1F10))),
                  SizedBox(height: 8),
                  Text('• Pay anyone who offers to "recover" your money. That is usually a second scam.', style: TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF8E1F10))),
                  SizedBox(height: 4),
                  Text('• Keep chatting with the scammer or click more of their links.', style: TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF8E1F10))),
                  SizedBox(height: 4),
                  Text('• Delete the evidence. Screenshot it first.', style: TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF8E1F10))),
                  SizedBox(height: 4),
                  Text('• Blame yourself. Scammers are professionals, and reporting helps others.', style: TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF8E1F10))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'This is general guidance, not legal or financial advice. Your bank and local authorities can give advice for your situation.',
              style: TextStyle(fontSize: 12.5, color: AppColors.mutedText, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioButton extends StatelessWidget {
  const _ScenarioButton({required this.scenario, required this.selected, required this.onTap});
  final RecoveryScenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Text(scenario.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(scenario.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AppColors.text)),
              ),
              Icon(selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded, color: selected ? AppColors.primary : AppColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist({required this.scenario, required this.done, required this.onToggle});
  final RecoveryScenario scenario;
  final Set<String> done;
  final void Function(String key, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    final total = scenario.steps.length;
    var completed = 0;
    for (var i = 0; i < total; i++) {
      if (done.contains('${scenario.id}:$i')) completed++;
    }
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your checklist: ${scenario.title}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5, color: AppColors.primaryDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completed / total,
                          minHeight: 10,
                          backgroundColor: AppColors.mint,
                          color: AppColors.safe,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$completed/$total', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mutedText)),
                  ],
                ),
                if (completed == total && total > 0) ...[
                  const SizedBox(height: 8),
                  const Text('🎉 All steps done. Well done for acting fast!', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.safe)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < total; i++)
            CheckboxListTile(
              value: done.contains('${scenario.id}:$i'),
              onChanged: (v) => onToggle('${scenario.id}:$i', v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              activeColor: AppColors.safe,
              title: Text(scenario.steps[i], style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.text)),
            ),
        ],
      ),
    );
  }
}
