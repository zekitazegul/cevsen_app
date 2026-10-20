import 'dart:convert';
import 'dart:io';

import 'package:cevsen_app/chapter_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final chapters =
      jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
  testWidgets(
    'Short bab fits; enlarged text scrolls without dropping content',
    (tester) async {
      tester.view.physicalSize = const Size(380, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final transcript in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChapterPage(
                number: 1,
                rows: chapters[0]['rows'] as List,
                transcript: transcript,
                fontSize: transcript ? 20 : 32,
                fitPage: true,
              ),
            ),
          ),
        );
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .maxScrollExtent,
          0,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChapterPage(
                number: 1,
                rows: chapters[0]['rows'] as List,
                transcript: transcript,
                fontSize: transcript ? 40 : 64,
                fitPage: false,
              ),
            ),
          ),
        );
        expect(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .position
              .maxScrollExtent,
          greaterThan(0),
        );
      }
    },
  );
  for (final transcript in [false, true]) {
    for (final dimensions in [
      const Size(360, 500),
      const Size(800, 220),
      const Size(1024, 1000),
    ]) {
      testWidgets('Single script, scrollable bab: $transcript $dimensions', (
        tester,
      ) async {
        tester.view.physicalSize = dimensions;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        for (final bab in [0, 5, 73, 99]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChapterPage(
                  number: bab + 1,
                  rows: chapters[bab]['rows'] as List,
                  transcript: transcript,
                  fontSize: transcript ? 40 : 64,
                  fitPage: true,
                ),
              ),
            ),
          );
          final texts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .join();
          expect(RegExp(r'[\u0600-\u06ff]').hasMatch(texts), !transcript);
          expect(texts.contains(chapters[bab]['rows'][0]['tr']), transcript);
          expect(tester.takeException(), isNull);
          await tester.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -300),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
