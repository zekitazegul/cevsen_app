import 'package:flutter/material.dart';

/// Styles the closing pleas while retaining the original spelling and marks.
TextSpan prayerSpan(String text, TextStyle style) {
  final words = RegExp(r'[^\s]+');
  final marks = RegExp(r'[\u064b-\u065f\u0670]');
  final children = <TextSpan>[];
  var end = 0;
  for (final match in words.allMatches(text)) {
    final word = match.group(0)!;
    final normalized = word.replaceAll(marks, '').toLowerCase();
    if (!const {
      'neccinâ',
      'ecirnâ',
      'ḣallisnâ',
      'hallisnâ',
      'نجنا',
      'اجرنا',
      'أجرنا',
      'خلصنا',
    }.contains(normalized))
      continue;
    children.add(TextSpan(text: text.substring(end, match.start)));
    children.add(
      TextSpan(
        text: word,
        style: const TextStyle(
          color: Color(0xffc62828),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    end = match.end;
  }
  children.add(TextSpan(text: text.substring(end)));
  return TextSpan(style: style, children: children);
}
