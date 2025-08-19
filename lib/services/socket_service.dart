// lib/services/websocket_service.dart

import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  Stream? get stream => _channel?.stream;

  final String _userId;

  WebSocketService(this._userId);

  void connect() {
    try {
      // ===== PERHATIAN PENTING =====
      // Ganti alamat IP ini sesuai dengan kondisi Anda:
      //
      // 1. Jika testing di Emulator Android: gunakan '10.0.2.2'
      // 2. Jika testing di device fisik (HP asli): gunakan IP Address lokal komputer Anda
      //    (misalnya '192.168.1.10'). Anda bisa cek IP dengan 'ipconfig' di CMD Windows
      //    atau 'ifconfig' di terminal Mac/Linux.
      //
      // Pastikan HP dan komputer Anda terhubung ke jaringan WiFi yang sama.
      final uri = Uri.parse('ws://10.90.90.153:8080?userId=$_userId');

      _channel = WebSocketChannel.connect(uri);
      print('✅ Berhasil terhubung ke WebSocket sebagai userId: $_userId');
    } catch (e) {
      print('❌ Gagal terhubung ke WebSocket: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    print('🔌 Koneksi WebSocket ditutup.');
  }

  // Fungsi untuk mengubah data JSON string dari server menjadi objek Map
  Map<String, dynamic> parseMessage(String data) {
    try {
      final message = jsonDecode(data);
      return message as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing message: $e');
      return {}; // Kembalikan map kosong jika ada error
    }
  }
}
