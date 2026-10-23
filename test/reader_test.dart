import 'dart:convert';
import 'dart:io';

import 'package:cevsen_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final dimensions in [const Size(400, 800), const Size(800, 400)]) {
    testWidgets('Pinch resizes text without changing bab at $dimensions', (
      tester,
    ) async {
      tester.view.physicalSize = dimensions;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final chapters =
          jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
      await tester.pumpWidget(
        MaterialApp(
          home: Reader(
            prefs: prefs,
            chapters: chapters,
            audio: const [],
            initial: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      double size() => tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((text) => text.textSpan != null)
          .style!
          .fontSize!;
      final original = size();
      final center = tester.getCenter(find.byType(PageView));
      final first = await tester.startGesture(
        center - const Offset(60, 0),
        pointer: 1,
      );
      final second = await tester.startGesture(
        center + const Offset(60, 0),
        pointer: 2,
      );
      await first.moveTo(center - const Offset(120, 0));
      await second.moveTo(center + const Offset(120, 0));
      await tester.pump();
      expect(size(), greaterThan(original));
      final enlarged = size();
      await first.moveTo(center - const Offset(50, 0));
      await second.moveTo(center + const Offset(50, 0));
      await tester.pump();
      expect(size(), lessThan(enlarged));
      await first.up();
      await second.up();
      await tester.pumpAndSettle();
      expect(prefs.getInt('last'), 0);
      expect(prefs.getDouble('arSize'), size());
      expect(prefs.getBool('fitPage'), false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('Rotation enters fullscreen and restores reader controls', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final chapters =
        jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
    await tester.pumpWidget(
      MaterialApp(
        home: Reader(
          prefs: prefs,
          chapters: chapters,
          audio: const [],
          initial: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    tester.view.physicalSize = const Size(800, 400);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final pageEffect in [true, false]) {
    testWidgets(
      'Bab 10 reopens with its heading visible (effect: $pageEffect)',
      (tester) async {
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'pageEffect': pageEffect,
          'fitPage': false,
          'arSize': 48.0,
        });
        final prefs = await SharedPreferences.getInstance();
        final chapters =
            jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
        await tester.pumpWidget(
          MaterialApp(
            home: Reader(
              prefs: prefs,
              chapters: chapters,
              audio: const [],
              initial: 9,
            ),
          ),
        );
        await tester.pumpAndSettle();

        ScrollPosition currentPosition() => tester
            .state<ScrollableState>(
              find.descendant(
                of: find.byType(SingleChildScrollView).hitTestable(),
                matching: find.byType(Scrollable),
              ),
            )
            .position;

        Future<void> turn(double direction) async {
          await tester.drag(find.byType(PageView), Offset(direction * 600, 0));
          await tester.pumpAndSettle();
          expect(currentPosition().pixels, 0);
        }

        currentPosition().jumpTo(currentPosition().maxScrollExtent);
        await tester.pumpAndSettle();
        expect(currentPosition().pixels, greaterThan(0));
        await turn(-1);
        currentPosition().jumpTo(currentPosition().maxScrollExtent);
        await tester.pumpAndSettle();
        await turn(1);
        expect(find.textContaining('10. BAB').hitTestable(), findsOneWidget);
        await turn(-1);
        expect(find.textContaining('11. BAB').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets(
    'Reader follows finger and keeps scripts separate without audio card',
    (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final chapters =
          jsonDecode(File('assets/cevsen.json').readAsStringSync()) as List;
      await tester.pumpWidget(
        MaterialApp(
          home: Reader(
            prefs: prefs,
            chapters: chapters,
            audio: const [],
            initial: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Enes Sakallı'), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      await tester.tap(find.byTooltip('Dinle'));
      await tester.pumpAndSettle();
      expect(find.text('Bu babı dinle'), findsOneWidget);
      expect(find.text('Bu babdan sonuna kadar dinle'), findsOneWidget);
      expect(find.text('Cevşen’in tamamını dinle'), findsOneWidget);
      expect(find.text('1. babdan başlar'), findsOneWidget);
      await tester.tapAt(const Offset(10, 100));
      await tester.pumpAndSettle();
      expect(find.text('Bu babı dinle'), findsNothing);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      expect(pageView.controller!.page, greaterThan(0));
      expect(pageView.controller!.page, lessThan(1));
      await gesture.moveBy(const Offset(-300, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('✧  2. BAB  ✧'), findsOneWidget);
      await tester.tap(find.text('Türkçe okunuş'));
      await tester.pumpAndSettle();
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .join();
      expect(RegExp(r'[\u0600-\u06ff]').hasMatch(texts), false);
      expect(texts, contains(chapters[1]['rows'][0]['tr']));
      expect(find.byIcon(Icons.fullscreen), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit), findsNothing);
      for (final fullScreen in [true, false]) {
        await tester.tapAt(tester.getCenter(find.byType(PageView)));
        await tester.pump(const Duration(milliseconds: 80));
        await tester.tapAt(tester.getCenter(find.byType(PageView)));
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), fullScreen ? findsNothing : findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
