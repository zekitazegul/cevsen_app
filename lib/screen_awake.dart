import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> setScreenAwake(bool enabled) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  await const MethodChannel('com.zek.cevsen_app/screen')
      .invokeMethod<void>('setKeepScreenOn', {'enabled': enabled});
}
