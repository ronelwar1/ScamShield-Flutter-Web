import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/status_style.dart';

/// White rounded card used across screens.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.color = Colors.white, this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Small coloured pill with an icon and text.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.style, required this.text, this.icon});

  final StatusStyle style;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: style.soft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? style.icon, size: 15, color: style.onSoft),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: style.onSoft, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page heading with an emoji badge, used at the top of each screen.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.emoji, required this.title, required this.subtitle, this.trailing});

  final String emoji;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.sunshineSoft, borderRadius: BorderRadius.circular(16)),
          child: Text(emoji, style: const TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: -0.4),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 14.5, color: AppColors.mutedText, height: 1.45)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Centers [child] and limits its width so lines stay readable on large screens.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 860, this.padding});

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width < 600 ? 14.0 : 24.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.fromLTRB(horizontal, 20, horizontal, 24),
          child: child,
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}
