import 'package:cevsen_app/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final size in [const Size(360, 640), const Size(800, 360)]) {
    testWidgets('Support stays above navigation buttons at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const channel = MethodChannel('com.zek.cevsen_app/update');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => {'available': false});
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      SharedPreferences.setMockInitialValues({
        'arSize': 128.0,
        'trSize': 128.0,
        'mealSize': 128.0,
      });
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              viewPadding: const EdgeInsets.only(bottom: 48),
            ),
            child: SettingsScreen(prefs: await SharedPreferences.getInstance()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      final support = find.widgetWithText(ExpansionTile, 'Destek ve iletişim');
      expect(
        tester.getBottomRight(support).dy,
        lessThanOrEqualTo(size.height - 48),
      );
      await tester.tap(find.text('Destek ve iletişim'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
