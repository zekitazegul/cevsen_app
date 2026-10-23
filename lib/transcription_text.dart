import 'package:flutter/material.dart';

import 'prayer_emphasis.dart';

/// Places the three dots above the Latin s independently of font mark support.
class TranscriptionText extends StatelessWidget {
  const TranscriptionText(
    this.text, {
    super.key,
    required this.style,
    required this.textAlign,
  });
  final String text;
  final TextStyle style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final plain = text.replaceAll('\u20db', '');
    final positions = <int>[];
    var removed = 0;
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x20db) {
        positions.add(i - removed - 1);
        removed++;
      }
    }
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: CustomPaint(
          foregroundPainter: _DotsPainter(
            plain,
            positions,
            effectiveStyle,
            textAlign,
            MediaQuery.textScalerOf(context),
          ),
          child: Text.rich(
            prayerSpan(plain, style),
            style: style,
            textAlign: textAlign,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(
    this.text,
    this.positions,
    this.style,
    this.alignment,
    this.scaler,
  );
  final String text;
  final List<int> positions;
  final TextStyle style;
  final TextAlign alignment;
  final TextScaler scaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.isEmpty) return;
    final painter = TextPainter(
      text: prayerSpan(text, style),
      textDirection: TextDirection.ltr,
      textAlign: alignment,
      textScaler: scaler,
    )..layout(minWidth: size.width, maxWidth: size.width);
    final lines = painter.computeLineMetrics();
    final fontSize = scaler.scale(style.fontSize ?? 14);
    final ink = Paint()..color = style.color ?? Colors.black;
    for (final index in positions) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      );
      if (boxes.isEmpty) continue;
      final box = boxes.first;
      final line = lines
          .where(
            (line) => line.baseline >= box.top && line.baseline <= box.bottom,
          )
          .firstOrNull;
      if (line == null) continue;
      final center = (box.left + box.right) / 2;
      final y = line.baseline - fontSize * .68;
      for (final shift in [-1, 0, 1]) {
        canvas.drawCircle(
          Offset(center + shift * fontSize * .13, y),
          fontSize * .035,
          ink,
        );
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => true;
}
