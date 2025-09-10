// lib/services/session_manager.dart

import 'package:portal_si/config/api_endpoint.dart';
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  bool _isWebSocketConnected = false;

  // Panggil ini setelah login berhasil atau saat aplikasi dimulai jika ada token
  Future<void> startSession() async {
    final token = await SecureStorage.getToken();
    if (token != null && !_isWebSocketConnected) {
      print("🔌 Sesi aktif ditemukan. Menghubungkan ke WebSocket...");
      // Ambil App Key dari environment atau konstanta Anda
      const String reverbAppKey = 'your_reverb_app_key'; // Ganti dengan App Key Anda
      final wsUrl = ApiEndpoints.getWebSocketUrl(reverbAppKey);
      await webSocketService.connect(wsUrl);
      _isWebSocketConnected = true;
    }
  }

  // Panggil ini saat logout
  void endSession() {
    print("🔌 Sesi diakhiri. Memutus koneksi WebSocket...");
    webSocketService.disconnect();
    _isWebSocketConnected = false;
  }
}