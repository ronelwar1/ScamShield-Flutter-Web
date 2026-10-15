import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/scan_result.dart';
import 'app_button.dart';
import 'risk_badge.dart';

/// Shows classification, risk level, confidence and explanation.
class ResultCard extends StatelessWidget {
  const ResultCard({
    super.key,
    required this.result,
    required this.onScanAnother,
  });

  final ScanResult result;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    final Color color = AppColors.risk(result.riskLevel);
    final int percent = (result.confidence * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.riskTint(result.riskLevel),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              RiskBadge(level: result.riskLevel),
              Text(
                result.classification,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Confidence'),
              Text('$percent%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: result.confidence,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text('Why this result',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final String reason in result.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.chevron_right_rounded, size: 20, color: color),
                  const SizedBox(width: 4),
                  Expanded(child: Text(reason)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Scan another message',
            icon: Icons.refresh_rounded,
            secondary: true,
            onPressed: onScanAnother,
          ),
        ],
      ),
    );
  }
}
