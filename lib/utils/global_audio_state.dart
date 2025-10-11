// lib/utils/global_audio_state.dart

class GlobalAudioState {
  /// Variabel statis yang akan menyimpan status mute di seluruh aplikasi.
  /// Kita set default-nya 'true' agar suara mati saat aplikasi pertama kali dibuka.
  static bool isMuted = true;
}