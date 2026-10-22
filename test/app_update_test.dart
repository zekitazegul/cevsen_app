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
          if (call.method == 'checkUpdate') {
            calls++;
            return {'available': false, 'installedVersionName': '1.1.1'};
          }
          calls++;
          expect(call.arguments['manifestUrl'], contains('cevsen_app'));
          return 'Uygulamanız zaten en son sürüm olan 1.1.1 sürümünde.';
        });
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppUpdateTile())),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(find.text('Güncellemeler'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('Sürüm: 1.1.1'), findsOneWidget);
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Güncellemeler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sürüm bilgisi alınamadı'), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'Güncellemeler'))
          .onTap,
      isNotNull,
    );
  });

  testWidgets(
    'A newer version shows a badge and notes without starting an install',
    (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            return {
              'available': true,
              'versionName': '9.0',
              'releaseNotes': {'tr': 'Yeni okuma seçenekleri.'},
            };
          });
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppUpdateTile())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Yeni'), findsOneWidget);
      expect(find.text('Yeni okuma seçenekleri.'), findsNothing);
      await tester.tap(find.text('Güncellemeler'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni sürüm: 9.0'), findsOneWidget);
      expect(find.text('Yeni okuma seçenekleri.'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Güncellemeler'), findsOneWidget);
      expect(calls, ['checkUpdate', 'checkUpdate']);
      await tester.tap(find.text('Güncellemeler'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Güncelle'), findsNothing);
      expect(calls.length, 2);
      await tester.tap(find.text('Güncellemeler'));
      await tester.pumpAndSettle();
      expect(calls, ['checkUpdate', 'checkUpdate', 'checkUpdate']);
      expect(find.widgetWithText(FilledButton, 'Güncelle'), findsOneWidget);
    },
  );
}
