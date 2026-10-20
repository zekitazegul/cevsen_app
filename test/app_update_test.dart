import 'package:cevsen_app/app_update.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('com.zek.cevsen_app/update');
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets('Checks once while busy and displays installed version', (
    tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls++;
          expect(call.arguments['manifestUrl'], contains('cevsen_app'));
          return 'Uygulamanız zaten en son sürüm olan 1.1.1 sürümünde.';
        });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppUpdateTile())),
    );
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.textContaining('1.1.1 sürümünde'), findsOneWidget);
  });

  testWidgets('Network failure remains retryable', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: 'network',
            message: 'Bağlantı yok.',
          ),
        );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppUpdateTile())),
    );
    await tester.tap(find.text('Güncelle'));
    await tester.pumpAndSettle();
    expect(find.text('Bağlantı yok.'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNotNull);
  });
}
