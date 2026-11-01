import 'package:flutter/material.dart';

<<<<<<< HEAD
const Color _defaultButtonMaroon = Color(0xFF0B7A74); // brand teal (name kept to limit churn)

=======
/// Reusable primary/secondary button with optional icon and loading state.
>>>>>>> 8870631c9aba6d3b1d268658e4c130a73b83d07e
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
<<<<<<< HEAD
    this.isLoading = false,
    this.expand = true,
    this.compact = false,
    this.backgroundColor,
    this.foregroundColor,
=======
    this.secondary = false,
    this.loading = false,
>>>>>>> 8870631c9aba6d3b1d268658e4c130a73b83d07e
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
<<<<<<< HEAD
  final bool isLoading;
  final bool expand;
  final bool compact;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final background = backgroundColor ?? _defaultButtonMaroon;
    final foreground = foregroundColor ?? Colors.white;

    final Widget content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
=======
  final bool secondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? action = loading ? null : onPressed;
    final Widget child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
>>>>>>> 8870631c9aba6d3b1d268658e4c130a73b83d07e
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
<<<<<<< HEAD
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );

    final button = SizedBox(
      height: compact ? 40 : 48,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
        ),
        child: content,
      ),
    );

    if (!expand) return button;

    return SizedBox(width: double.infinity, child: button);
=======
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label)),
            ],
          );
    return secondary
        ? OutlinedButton(onPressed: action, child: child)
        : FilledButton(onPressed: action, child: child);
>>>>>>> 8870631c9aba6d3b1d268658e4c130a73b83d07e
  }
}
