import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/analysis_models.dart';

int _clampInt(int value, int low, int high) => value < low ? low : (value > high ? high : value);

/// Renders [text] with the warning phrases found by the NLP service highlighted.
///
/// The API reports positions in Unicode code points (Python), while Dart strings are UTF-16, so the
/// text is sliced by runes to keep emoji and other non-BMP characters from shifting the highlights.
class HighlightedText extends StatelessWidget {
  const HighlightedText({super.key, required this.text, required this.highlights, this.style});

  final String text;
  final List<Highlight> highlights;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final runes = text.runes.toList();
    final sorted = List<Highlight>.from(highlights)..sort((a, b) => a.start.compareTo(b.start));
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final h in sorted) {
      final start = _clampInt(h.start, 0, runes.length);
      final end = _clampInt(h.end, 0, runes.length);
      if (end <= start || start < cursor) continue;
      if (start > cursor) {
        spans.add(TextSpan(text: String.fromCharCodes(runes.sublist(cursor, start))));
      }
      spans.add(TextSpan(
        text: String.fromCharCodes(runes.sublist(start, end)),
        style: TextStyle(
          backgroundColor: AppColors.sunshine.withValues(alpha: 0.65),
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
      ));
      cursor = end;
    }
    if (cursor < runes.length) {
      spans.add(TextSpan(text: String.fromCharCodes(runes.sublist(cursor))));
    }
    return Text.rich(
      TextSpan(
        style: style ?? const TextStyle(fontSize: 15, height: 1.6, color: AppColors.text),
        children: spans,
      ),
    );
  }
}
