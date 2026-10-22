import 'package:cevsen_app/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.zek.cevsen_app/external');
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'Sharing requests only the installer and recovers after failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final calls = <String>[];
      var fail = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call.method);
            if (fail) {
              throw PlatformException(
                code: 'share',
                message: 'Paylaşım açılamadı.',
              );
            }
            return null;
          });
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(prefs: await SharedPreferences.getInstance()),
        ),
      );
      expect(find.text('Cevsen Installer’ı paylaş'), findsNothing);
      expect(
        tester.getTopLeft(find.text('Okuma ve görünüm')).dy,
        lessThan(tester.getTopLeft(find.text('Güncelle')).dy),
      );
      await tester.tap(find.text('Uygulamayı paylaş'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Cevsen Installer’ı paylaş'));
      await tester.tap(find.text('Cevsen Installer’ı paylaş'));
      await tester.pumpAndSettle();
      expect(calls, ['shareInstaller']);
      expect(find.text('Paylaşım açılamadı.'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Cevsen Installer’ı paylaş'));
      await tester.pumpAndSettle();
      expect(calls, ['shareInstaller', 'shareInstaller']);
      expect(find.text('Kurulum dosyası hazırlanıyor…'), findsNothing);
    },
  );
}
