import 'package:cevsen_app/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.zek.cevsen_app/screen');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'Screen stays awake by default; disabling persists across visits',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      Future<void> openSettings() async {
        await tester.pumpWidget(
          MaterialApp(home: SettingsScreen(prefs: prefs)),
        );
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(SwitchListTile, 'Uygulama açıkken'),
          findsNothing,
        );
        await tester.tap(find.text('Ekranı açık tut'));
        await tester.pumpAndSettle();
      }

      await openSettings();
      final toggle = find.widgetWithText(SwitchListTile, 'Uygulama açıkken');
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      expect(
        tester.getTopLeft(find.text('Güncelle')).dy,
        lessThan(tester.getTopLeft(find.text('Uygulamayı paylaş')).dy),
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(prefs.getBool('keepScreenOn'), isFalse);
      expect(calls.single.method, 'setKeepScreenOn');
      expect(calls.single.arguments, {'enabled': false});

      await tester.pumpWidget(const SizedBox());
      await openSettings();
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(prefs.getBool('keepScreenOn'), isTrue);
      expect(calls.last.arguments, {'enabled': true});
    },
  );
}
