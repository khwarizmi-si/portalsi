// lib/utils/global_audio_state.dart

import 'package:flutter/foundation.dart';

// Ubah dari class statis menjadi class biasa dengan Singleton pattern
// dan implementasikan ChangeNotifier.
class GlobalAudioState with ChangeNotifier {
  // Singleton pattern setup
  GlobalAudioState._();
  static final GlobalAudioState instance = GlobalAudioState._();

  bool _isMuted = false;

  bool get isMuted => _isMuted;

  // Buat setter yang akan memberi tahu semua listener saat nilainya berubah.
  set isMuted(bool value) {
    if (_isMuted != value) {
      _isMuted = value;
      // Ini adalah bagian terpenting: memberitahu semua widget yang
      // mendengarkan bahwa ada perubahan state.
      notifyListeners();
    }
  }
}