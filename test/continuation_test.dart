import 'package:cevsen_app/scroll_continuation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Reading follows audio smoothly and reveals the final lines', (
    tester,
  ) async {
    final progress = ValueNotifier<double?>(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<double?>(
            valueListenable: progress,
            builder: (context, value, child) => ScrollContinuation(
              readingProgress: value,
              builder: (controller) => SingleChildScrollView(
                controller: controller,
                child: const SizedBox(height: 1800, child: Text('Uzun bab')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(scroll.pixels, 0);
    progress.value = .6;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final midway = scroll.pixels;
    expect(midway, greaterThan(0));
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(midway));
    progress.value = 1;
    await tester.pumpAndSettle();
    expect(scroll.pixels, scroll.maxScrollExtent);
    expect(find.byKey(const ValueKey('continuation-mist')), findsNothing);
    progress.value = null;
    await tester.pumpAndSettle();
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    expect(scroll.pixels, 0);
    await tester.pumpWidget(const SizedBox());
    progress.dispose();
  });

  testWidgets('Continuation hint disappears when the last line is reached', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollContinuation(
            builder: (controller) => SingleChildScrollView(
              controller: controller,
              child: const SizedBox(height: 1800, child: Text('Uzun bab')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continuation-mist')), findsOneWidget);
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    scroll.jumpTo(scroll.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('continuation-mist')), findsNothing);
  });
}
