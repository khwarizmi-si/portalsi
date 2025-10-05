// lib/providers/shake_provider.dart

import 'package:flutter/material.dart';

class ShakeProvider with ChangeNotifier {
  /// Memanggil method ini akan memberitahu listener (MainScaffold)
  /// untuk memulai animasi getar.
  void shake() {
    notifyListeners();
  }
}