import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';

// Service class untuk mengelola semua logika WebSocket
class WebSocketService {
  final String token;
  Echo? echo;

  // StreamControllers untuk menyiarkan data yang diterima ke seluruh aplikasi
  final StreamController<String> _statusController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();

  // Getters agar bagian lain dari aplikasi bisa mendengarkan stream ini
  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  WebSocketService({required this.token});

  // ========== 1. INISIALISASI ==========
  void init() {
    if (echo != null) {
      print('Echo sudah diinisialisasi.');
      return;
    }

    // Konfigurasi PusherClient untuk terhubung ke Laravel Reverb Anda
    PusherClient pusherClient = PusherClient(
      'fiouy3umnruqcwdsoxni', // ✅ Diambil dari REVERB_APP_KEY
      PusherOptions(
        // ❗️ Cluster Dihapus! Ini hanya untuk cloud Pusher.

        // ✅ Tambahkan konfigurasi ini untuk Reverb (self-hosted)
        host: 'api-new.portalsi.com', // ✅ Diambil dari REVERB_HOST
        wssPort: 443, // ✅ Diambil dari REVERB_PORT
        encrypted: true, // ✅ true karena REVERB_SCHEME adalah https

        // Konfigurasi otentikasi tetap sama
        auth: PusherAuth(
          'https://api-new.portalsi.com/api/broadcasting/auth',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      ),
      enableLogging: kDebugMode, // Tampilkan log hanya saat debug
    );

    echo = Echo(
      broadcaster: EchoBroadcasterType.Pusher,
      client: pusherClient,
    );

    // Dengarkan perubahan status koneksi (sisanya tetap sama)
    echo?.connector.onConnect((_) {
      _statusController.add('connected');
      debugPrint('✅ WebSocket Connected to Reverb: ${echo?.socketId()}');
    });

    echo?.connector.onDisconnect((_) {
      _statusController.add('disconnected');
      debugPrint('🔌 WebSocket Disconnected from Reverb');
    });

    echo?.connector.onError((error) {
      _statusController.add('error');
      debugPrint('❌ WebSocket Error: ${error.toString()}');
    });

    // Mulai koneksi
    pusherClient.connect();
  }

  // ========== 2. METHOD UNTUK MENDENGARKAN CHANNEL ==========

  /// Mendengarkan pesan baru dalam sebuah percakapan direct message.
  void listenToDirectMessages(int currentUserId, int otherUserId) {
    if (echo == null) return;

    // Pastikan Room ID konsisten
    final ids = [currentUserId, otherUserId]..sort();
    final roomId = ids.join('-');

    echo?.private('chat.direct.$roomId').listen('.NewDirectMessage', (e) {
      if (e is PusherEvent && e.data != null) {
        try {
          final data = jsonDecode(e.data!);
          final message = data['message'];

          // Cek untuk menghindari duplikasi pesan dari pengirim
          if (message['sender_id'] != currentUserId) {
            // Kirim pesan ke stream agar bisa ditangkap oleh UI
            _messageController.add(message);
          }
        } catch (err) {
          debugPrint('⚠️ Gagal parsing pesan DM: $err');
        }
      }
    });
    debugPrint("📡 Listening for DMs on: chat.direct.$roomId");
  }

  /// Mendengarkan update untuk daftar obrolan (chat list).
  void listenToChatListUpdates(int currentUserId) {
    if (echo == null) return;

    echo?.private('user.$currentUserId').listen('.ChatListUpdated', (e) {
      if (e is PusherEvent && e.data != null) {
        try {
          final data = jsonDecode(e.data!);
          // Kirim data ke stream event
          _eventController.add({
            'event': 'ChatListUpdated',
            'data': data['data'],
          });
        } catch (err) {
          debugPrint('⚠️ Gagal parsing update chat list: $err');
        }
      }
    });
    debugPrint("📡 Listening for chat list updates on: user.$currentUserId");
  }

  /// Berhenti mendengarkan channel tertentu
  void leaveChannel(String channelName) {
    echo?.leave(channelName);
    debugPrint("🛑 Left channel: $channelName");
  }

  // ========== 3. DISCONNECT ==========
  void disconnect() {
    echo?.disconnect();
    _statusController.close();
    _messageController.close();
    _eventController.close();
  }
}
