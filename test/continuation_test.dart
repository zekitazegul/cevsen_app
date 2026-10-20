import 'package:cevsen_app/scroll_continuation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
