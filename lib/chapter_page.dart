import 'package:flutter/material.dart';

import 'scroll_continuation.dart';
import 'transcription_text.dart';
import 'prayer_emphasis.dart';

/// One bab, in one script. Enlarged or long chapters remain scrollable.
class ChapterPage extends StatelessWidget {
  const ChapterPage({
    super.key,
    required this.number,
    required this.rows,
    required this.transcript,
    required this.fontSize,
    required this.fitPage,
    this.arabicLineStarts = false,
    this.transcriptLeftAligned = false,
    this.meaning = false,
    this.heading,
    this.readingProgress,
  });
  final int number;
  final List rows;
  final bool transcript, fitPage;
  final bool arabicLineStarts;
  final bool transcriptLeftAligned;
  final bool meaning;
  final String? heading;
  final double fontSize;
  final double? readingProgress;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffd8d2c3),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final latin = transcript || meaning;
          final lineLayout = !latin && arabicLineStarts;
          final text = rows
              .map(
                (r) =>
                    '${lineLayout ? '\u200f۞ ' : ''}${r[meaning
                        ? 'meal'
                        : transcript
                        ? 'tr'
                        : 'ar']}',
              )
              .join(latin || lineLayout ? '\n' : '  ۞  ');
          final alignment = latin
              ? (meaning || transcriptLeftAligned
                    ? TextAlign.left
                    : TextAlign.center)
              : (lineLayout ? TextAlign.right : TextAlign.center);
          final direction = latin ? TextDirection.ltr : TextDirection.rtl;
          final scaler = MediaQuery.textScalerOf(context);
          TextStyle style(double size) => TextStyle(
            fontSize: size,
            fontFamily: latin ? null : 'Amiri',
            height: latin ? 1.55 : 1.9,
            color: latin ? const Color(0xff65563f) : const Color(0xff123f35),
          );
          var size = fontSize;
          final available = (constraints.maxHeight - 64).clamp(
            1.0,
            double.infinity,
          );
          if (fitPage) {
            final minimum = latin ? 14.0 : 20.0;
            while (size > minimum) {
              final painter =
                  TextPainter(
                    text: prayerSpan(
                      transcript ? text.replaceAll('\u20db', '') : text,
                      style(size),
                    ),
                    textDirection: direction,
                    textAlign: alignment,
                    textScaler: scaler,
                  )..layout(
                    maxWidth: (constraints.maxWidth - 16).clamp(
                      1.0,
                      double.infinity,
                    ),
                  );
              final fits = painter.height <= available;
              painter.dispose();
              if (fits) break;
              size = (size - .5).clamp(minimum, fontSize);
            }
          }
          return ScrollContinuation(
            readingProgress: readingProgress,
            builder: (controller) => SingleChildScrollView(
              controller: controller,
              key: PageStorageKey(
                'bab-$number-$transcript-$meaning-$lineLayout-$transcriptLeftAligned',
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xfffffbf0), Color(0xfff3e8d1)],
                  ),
                  border: Border.all(color: const Color(0xffc5ad7d)),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 26).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          heading ?? '✧  $number. BAB  ✧',
                          style: const TextStyle(
                            color: Color(0xffb8914b),
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: transcript && text.contains('\u20db')
                            ? TranscriptionText(
                                text,
                                style: style(size),
                                textAlign: alignment,
                              )
                            : Text.rich(
                                prayerSpan(text, style(size)),
                                textDirection: direction,
                                textAlign: alignment,
                                style: style(size),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
