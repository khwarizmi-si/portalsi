import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/notification_system_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/app_lifecycle_manager.dart';


// Model sederhana untuk event yang masuk
class AppEvent {
  final String channel;
  final String event;
  final dynamic data;

  AppEvent({required this.channel, required this.event, this.data});
}


class WebSocketService {
  final String _wsBaseUrl =
      "wss://ws.portalsi.com:443/app/fiouy3umnruqcwdsoxni";
  final String _authBaseUrl = "https://api-new.portalsi.com/api";
  final String _token;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  String? _socketId;
  // [TAMBAHAN] Buat getter publik untuk _socketId
  String? get socketId => _socketId;
  Completer<void>? _connectionCompleter;

  final Set<String> _subscribedChannels = {};

  // Stream Controllers
  final StreamController<String> _statusController =
  StreamController.broadcast();
  final StreamController<AppEvent> _eventController =
  StreamController.broadcast();

  // Getters untuk didengarkan oleh bagian lain dari aplikasi
  Stream<String> get statusStream => _statusController.stream;
  Stream<AppEvent> get eventStream => _eventController.stream;

  WebSocketService({required String token}) : _token = token;

  // ========== KONEKSI & DISKONEKSI ==========

  Future<void> connect() {
    if (_channel != null && _channel?.closeCode == null) {
      debugPrint("WebSocket sudah terkoneksi.");
      // Jika sudah terkoneksi, langsung selesaikan Future
      return Future.value();
    }

    // Buat completer baru setiap kali mencoba koneksi
    _connectionCompleter = Completer<void>();

    _statusController.add("connecting");
    _channel = WebSocketChannel.connect(Uri.parse(_wsBaseUrl));

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onDone: () {
        _statusController.add("disconnected");
        // [MODIFIKASI] Gagalkan completer jika koneksi terputus sebelum siap
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError("WebSocket disconnected before connection was established.");
        }
        _cleanup();
        _reconnect();
      },
      onError: (error) {
        debugPrint("❌ WebSocket Error: $error");
        _statusController.add("error");
        // [MODIFIKASI] Gagalkan completer jika ada error
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError(error);
        }
        _cleanup();
        _reconnect();
      },
    );

    // Kembalikan Future dari completer
    return _connectionCompleter!.future;
  }

  void disconnect() {
    debugPrint("🔌 Disconnecting WebSocket secara manual...");
    _cleanup();
    _channel?.sink.close();
  }

  void _reconnect() {
    debugPrint("🔁 Mencoba menyambung ulang dalam 5 detik...");
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _socketId = null;
    // [TAMBAHAN] Bersihkan daftar channel saat koneksi dihentikan
    _subscribedChannels.clear();
  }

  // ========== PENGELOLAAN PESAN ==========

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message as String);
    final eventName = decoded["event"] as String;

    debugPrint(
        "===[ RAW WEBSOCKET MESSAGE RECEIVED ]===\n$message\n========================================");

    // Tangani event internal Pusher terlebih dahulu
    switch (eventName) {
      case "pusher:connection_established":
        _socketId = jsonDecode(decoded["data"])["socket_id"];
        _statusController.add("connected");
        debugPrint("✅ WebSocket Connected with socket_id: $_socketId");
        _startHeartbeat();
        return; // Keluar dari fungsi setelah menangani event ini

      case "pusher:ping":
        _send({"event": "pusher:pong", "data": {}});
        return; // Keluar dari fungsi

      case "pusher_internal:subscription_succeeded":
        final String? channel = decoded['channel'];
        if (channel != null) {
          _subscribedChannels.add(channel);
          debugPrint("✅ Berhasil subscribe dan TERCATAT ke channel: $channel. Total: ${_subscribedChannels.length}");
        }
        return;
    }

    // [LOGIKA BARU] Setelah event Pusher ditangani, proses event aplikasi
    if (decoded["channel"] != null) {

      // Cek notifikasi HANYA untuk event 'dm.new'
      if (eventName == 'dm.new') {
        if (!AppLifecycleManager.isAppInForeground) {
          final data = jsonDecode(decoded["data"]);
          final messageData = data['message'];

          // [MODIFIKASI] Ambil seluruh objek sender, bukan hanya beberapa field
          final senderData = data['sender'];

          if (messageData != null && senderData != null) {
            // [MODIFIKASI] Ambil message_id sebagai ID unik notifikasi
            final int messageId = messageData['message_id'];
            final String senderName = senderData['full_name'] ?? 'Pesan Baru';
            final String content = messageData['content'] ?? 'Mengirim media';
            final DateTime timestamp = DateTime.parse(messageData['sent_at']);

            // [MODIFIKASI] Kirim messageId dan seluruh senderData sebagai payload
            NotificationSystemService.instance.showNewMessageNotification(
              messageId: messageId, // Gunakan ID pesan yang unik
              title: senderName,
              body: content,
              timestamp: timestamp,
              payloadData: senderData, // Kirim seluruh data sender
            );
          }
        }
      }

      // Siarkan SEMUA event yang memiliki channel ke aplikasi (HANYA SEKALI)
      _eventController.add(AppEvent(
        channel: decoded["channel"],
        event: eventName,
        data: jsonDecode(decoded["data"]),
      ));
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      _send({"event": "pusher:ping", "data": {}});
    });
  }

  void _send(Map<String, dynamic> data) {
    if (_channel?.sink != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  // ========== SUBSCRIBE & UNSUBSCRIBE (PUBLIC METHOD) ==========

  Future<void> subscribeToChannel(String channelName) async {
    // [MODIFIKASI] Cek dulu apakah sudah subscribe ke channel ini
    if (_subscribedChannels.contains(channelName)) {
      debugPrint("✅ Sudah subscribe ke channel $channelName, tidak melakukan subscribe ulang.");
      return; // Hentikan fungsi di sini
    }

    // [LOGIKA LAMA TETAP BERJALAN JIKA BELUM SUBSCRIBE]
    if (_socketId == null) {
      debugPrint("⏳ Sedang menunggu _socketId terisi sebelum meminta permintaan subscribe ke $channelName...");
    }

    // Tunggu sampai socketId tersedia
    while (_socketId == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }


    try {
      final response = await http.post(
        Uri.parse("$_authBaseUrl/broadcasting/auth"),
        headers: {
          "Authorization": "Bearer $_token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"channel_name": channelName, "socket_id": _socketId}),
      );

      if (response.statusCode == 200) {
        final authData = jsonDecode(response.body);
        _send({
          "event": "pusher:subscribe",
          "data": {"channel": channelName, "auth": authData["auth"]}
        });
        debugPrint("📡 Mengirim permintaan subscribe ke $channelName...");
      } else {

        debugPrint(
            "❌ Gagal otentikasi channel ${channelName}: ${response.body}");

      }
    } catch (e) {
      debugPrint("⚠️ Error saat otentikasi channel: $e");
    }
  }

  void unsubscribeFromChannel(String channelName) {
    _send({
      "event": "pusher:unsubscribe",
      "data": {"channel": channelName}
    });
    debugPrint("🛑 Mengirim permintaan unsubscribe dari $channelName...");
  }
}

extension WebSocketStatus on WebSocketService {
  /// Memeriksa apakah channel WebSocket aktif dan belum ditutup.
  /// Mengembalikan `true` jika terhubung, `false` jika tidak.
  bool get isConnected => _channel != null && _channel?.closeCode == null;
}