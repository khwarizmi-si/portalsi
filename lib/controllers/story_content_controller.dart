// Letakkan kode ini di file yang sama dengan StoryContentView
// atau buat file baru seperti lib/controllers/story_content_controller.dart

import 'package:flutter/foundation.dart';

/// Controller sederhana untuk menjembatani perintah pause/resume
/// dari parent widget (StoryViewPage) ke child widget (StoryContentView).
class StoryContentController {
  VoidCallback? _onPause;
  VoidCallback? _onResume;

  /// Digunakan oleh StoryContentView untuk mendaftarkan fungsi
  /// yang akan dijalankan saat pause atau resume dipanggil.
  void addListeners({
    VoidCallback? onPause,
    VoidCallback? onResume,
  }) {
    _onPause = onPause;
    _onResume = onResume;
  }

  /// Dipanggil oleh parent (StoryViewPage) untuk menjeda konten.
  void pause() {
    _onPause?.call();
  }

  /// Dipanggil oleh parent (StoryViewPage) untuk melanjutkan konten.
  void resume() {
    _onResume?.call();
  }

  /// Membersihkan listener untuk mencegah memory leak.
  void dispose() {
    _onPause = null;
    _onResume = null;
  }
}

// di bawahnya adalah class StoryContentView yang sudah Anda miliki...
// class StoryContentView extends StatefulWidget { ... }