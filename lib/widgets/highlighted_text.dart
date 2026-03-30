// widgets/highlighted_text.dart
// Renders [text] with any occurrences of [highlight] styled differently.
// Used in task cards to show which part of the title matched the search query.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? baseStyle;

  const HighlightedText({
    super.key,
    required this.text,
    required this.highlight,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    // No highlight needed — just render normally
    if (highlight.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = highlight.toLowerCase();
    final spans = <TextSpan>[];
    int cursor = 0;

    // Walk through the string finding every occurrence of the query
    while (cursor < text.length) {
      final matchIndex = lowerText.indexOf(lowerQuery, cursor);

      if (matchIndex == -1) {
        // No more matches — append the rest as plain text
        spans.add(TextSpan(
          text: text.substring(cursor),
          style: baseStyle,
        ));
        break;
      }

      // Text before the match
      if (matchIndex > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, matchIndex),
          style: baseStyle,
        ));
      }

      // The matched portion — amber text on dark amber background
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + highlight.length),
        style: (baseStyle ?? const TextStyle()).copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.accentDim,
        ),
      ));

      cursor = matchIndex + highlight.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
    );
  }
}
