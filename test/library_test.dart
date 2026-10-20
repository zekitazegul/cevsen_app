import 'dart:convert';
import 'dart:io';

import 'package:cevsen_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final chapters =
      jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
  test('100 audio clips cover each downloaded track without gaps', () {
    final clips = jsonDecode(
      File('assets/audio/chapters.json').readAsStringSync(),
    ) as List;
    final tracks =
        jsonDecode(File('assets/audio/index.json').readAsStringSync()) as List;
    expect(clips.length, 101);
    expect(clips.last['file'], 'dua.mp3');
    expect(File('assets/audio/dua.mp3').lengthSync(), greaterThan(1000000));
    for (var i = 0; i < 100; i++) {
      final c = clips[i];
      expect(c['bab'], i + 1);
      expect(c['endMs'] - c['startMs'], greaterThan(25000));
      expect(
        File('assets/audio/${c['file']}').lengthSync(),
        greaterThan(1000000),
      );
      if (i % 10 == 0) {
        expect(c['startMs'], 0);
      } else {
        expect(c['startMs'], clips[i - 1]['endMs']);
      }
      if (i % 10 == 9) {
        expect(c['endMs'], tracks[i ~/ 10]['durationMs']);
      }
    }
  });
  test(
    'All 100 bab contain paired Arabic and pronunciation, including refrain',
    () {
      expect(chapters.length, 101);
      expect(chapters.last['title'], 'Cevşen Duası');
      expect(chapters.last['rows'].length, 5);
      for (var i = 0; i < 100; i++) {
        expect(chapters[i]['number'], i + 1);
        final rows = chapters[i]['rows'] as List;
        expect(rows.length, greaterThanOrEqualTo(10));
        for (final row in rows) {
          expect(row['ar'], matches(RegExp(r'[\u0600-\u06ff]')));
          expect(row['tr'], isNotEmpty);
          expect(row['tr'], isNot(startsWith('Ey ')));
          expect(row['meal'], isNotEmpty);
        }
        expect(rows.last['tr'], contains('Subhâneke'));
      }
    },
  );
  for (final size in [
    const Size(360, 640),
    const Size(800, 360),
    const Size(1024, 1366),
  ]) {
    testWidgets('Compact bab list without input at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({'last': 72});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MaterialApp(
          home: Library(prefs: prefs, chapters: chapters, audio: const []),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsNothing);
      await tester.scrollUntilVisible(
        find.text('100. Bab'),
        600,
        maxScrolls: 100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('100. Bab'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '100'),
        findsNothing,
      );
      expect(find.text(chapterTitle(chapters[99])), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
