import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sends the app to the background (Android), replacing the unmaintained
/// `move_to_background` plugin which used Flutter's removed v1 embedding API.
/// Backed by a MethodChannel handled in MainActivity (`moveTaskToBack(true)`).
class AppBackground {
  static const MethodChannel _channel =
      MethodChannel('app/move_to_background');

  static Future<void> moveTaskToBack() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod('moveTaskToBack');
    } on PlatformException {
      // No-op: nothing else to do if the platform can't background the task.
    }
  }
}
