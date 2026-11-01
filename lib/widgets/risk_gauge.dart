import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Animated three-quarter ring showing the 0-100 experimental risk indicator.
class RiskGauge extends StatelessWidget {
  const RiskGauge({super.key, required this.score, required this.color, this.size = 120});

  final int score;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final target = (score.clamp(0, 100)) / 100.0;
    return Semantics(
      label: 'Experimental risk indicator: $score out of 100',
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(size: Size.square(size), painter: _GaugePainter(value, color)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(value * 100).round()}',
                        style: TextStyle(
                          fontSize: size * 0.3,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: size * 0.02),
                      Text(
                        'out of 100',
                        style: TextStyle(fontSize: size * 0.1, color: AppColors.mutedText, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress, this.color);

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, start, sweep, false, track);
    if (progress > 0) {
      canvas.drawArc(rect, start, sweep * progress, false, fill);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress || old.color != color;
}
