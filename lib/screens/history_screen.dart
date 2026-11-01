import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/status_style.dart';
import '../services/history_store.dart';
import '../widgets/common_widgets.dart';
import '../widgets/result_card.dart';

const List<String> _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatWhen(DateTime t) {
  final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  final suffix = t.hour >= 12 ? 'PM' : 'AM';
  return '${_months[t.month - 1]} ${t.day} · $hour12:$minute $suffix';
}

/// On-device history of previous checks. Nothing here is uploaded.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.history,
    required this.onScanAgain,
    required this.onReport,
    required this.onShowGuide,
  });

  final HistoryStore history;
  final void Function(String text) onScanAgain;
  final void Function(String text) onReport;
  final void Function(String scamTypeId) onShowGuide;

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This removes every saved check from this device. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.coralDeep),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await history.clear();
  }

  void _open(BuildContext context, ScanRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 820),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.97,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(formatWhen(record.time), style: const TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ResultCard(
                    result: record.result,
                    originalText: record.text,
                    onReport: (t) {
                      Navigator.of(sheetContext).pop();
                      onReport(t);
                    },
                    onShowGuide: (id) {
                      Navigator.of(sheetContext).pop();
                      onShowGuide(id);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onScanAgain(record.text);
                    },
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Check this message again'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final items = history.items;
        return SingleChildScrollView(
          child: PageBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeading(
                  emoji: '🕘',
                  title: 'Your checks',
                  subtitle: 'Saved only on this device. Nothing here is uploaded.',
                ),
                const SizedBox(height: 18),
                SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Save my checks on this device', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.text)),
                      ),
                      Switch(value: history.enabled, onChanged: (v) => history.setEnabled(v)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isNotEmpty) ...[
                  _Stats(history: history),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmClear(context),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                      label: const Text('Clear all'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.coralDeep),
                    ),
                  ),
                  for (final r in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(
                        record: r,
                        onTap: () => _open(context, r),
                        onDelete: () => history.remove(r.id),
                      ),
                    ),
                ] else
                  SoftCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        const Text('🗂️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        const Text('Nothing here yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                        const SizedBox(height: 6),
                        Text(
                          history.enabled
                              ? 'Messages you check will show up here so you can review them later.'
                              : 'History is switched off, so new checks are not being saved.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.mutedText),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.history});
  final HistoryStore history;

  @override
  Widget build(BuildContext context) {
    final likely = history.countWhere((r) => r.result.isLikelyScam);
    final suspicious = history.countWhere((r) => r.result.isSuspicious);
    final clear = history.countWhere((r) => r.result.isClear);
    Widget stat(String label, int value, StatusStyle s) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: s.soft, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, color: s.accent, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: s.onSoft)),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.onSoft)),
              ],
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        stat('Likely scams', likely, statusForLabel('likely_scam')),
        stat('Be careful', suspicious, statusForLabel('suspicious')),
        stat('No obvious signs', clear, statusForLabel('none')),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record, required this.onTap, required this.onDelete});
  final ScanRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final s = statusForLabel(record.result.label);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: s.soft, borderRadius: BorderRadius.circular(14)),
                child: Text('${record.result.riskScore}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: s.onSoft)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(style: s, text: record.result.labelText),
                        Text(formatWhen(record.time), style: const TextStyle(fontSize: 12.5, color: AppColors.mutedText)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(record.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.text)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete this check',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
