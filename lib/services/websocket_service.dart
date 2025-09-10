import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:portal_si/utils/secure_storage.dart'; // [BARU] Import untuk ambil token
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

final WebSocketService webSocketService = WebSocketService();

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<String> _statusController =
  StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
  StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
  StreamController.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Timer? _heartbeatTimer;
  Timer? _activityTimer; // [BARU] Timer untuk update aktivitas
  String? _socketId;

  Completer<void>? _connectionCompleter;

  /// Connect ke Laravel Reverb (Pusher protocol)
  Future<void> connect(String wsUrl) async {
    if (_channel != null && _channel!.closeCode == null) {
      // Jika sudah terhubung, langsung selesaikan completer
      if (!_connectionCompleter!.isCompleted) _connectionCompleter!.complete();
      return;
    }
    _connectionCompleter = Completer<void>();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _statusController.add("connecting");

      _subscription = _channel!.stream.listen(
            (message) {
          debugPrint("📩 WebSocket received: $message");
          _handleMessage(message);
        },
        onDone: () {
          _statusController.add("disconnected");
          _reconnect(wsUrl);
        },
        onError: (error) {
          debugPrint("❌ WebSocket error: $error");
          _statusController.add("error");
          _reconnect(wsUrl);
        },
      );

      _statusController.add("connected");

      // Setup heartbeat (ping/pong)
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        send({"event": "pusher:ping", "data": {}});
      });

      // [BARU] Setup timer untuk update aktivitas setiap 2 menit
      _activityTimer?.cancel();
      _activityTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        updateActivity();
      });

    } catch (e) {
      debugPrint("❌ Failed to connect: $e");

      _connectionCompleter!.completeError(e);
      _statusController.add("error");
    }
  }

  // [BARU] Fungsi untuk memanggil endpoint update-activity
  Future<void> updateActivity() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        debugPrint("⚠️ Tidak bisa update aktivitas: Token tidak ditemukan.");
        return;
      }

      // Ganti dengan base URL API Anda dari ApiEndpoints
      const String apiBaseUrl = 'https://api-new.portalsi.com/api';

      final response = await http.post(
        Uri.parse("$apiBaseUrl/websocket/update-activity"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        debugPrint("🏃‍♂️ Aktivitas pengguna berhasil diperbarui.");
      } else {
        debugPrint("❌ Gagal memperbarui aktivitas: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error saat update aktivitas: $e");
    }
  }

  /// Subscribe ke channel (sudah termasuk proses otentikasi)
  Future<void> subscribeToChannel(String channelName, String authToken, String apiBaseUrl) async {
    await _connectionCompleter?.future;

    if (_channel == null || _socketId == null) {
      debugPrint("⚠️ Cannot subscribe: WebSocket not connected or socket_id is null.");
      return;
    }
    if (_channel == null || _socketId == null) {
      debugPrint(
          "⚠️ Cannot subscribe: WebSocket not connected or socket_id is null.");
      return;
    }

    // ... (sisa kode subscribeToChannel tidak berubah)
    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/broadcasting/auth"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "channel_name": channelName,
          "socket_id": _socketId,
        }),
      );

      if (response.statusCode == 200) {
        final authData = jsonDecode(response.body);
        final authSignature = authData["auth"];

        final payload = {
          "event": "pusher:subscribe",
          "data": {
            "channel": channelName,
            "auth": authSignature,
          }
        };
        send(payload);
        debugPrint("📡 Subscribing to $channelName...");
      } else {
        debugPrint(
            "❌ Failed to authenticate channel subscription: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error during channel subscription: $e");
    }
  }

  /// Kirim data ke server
  void send(Map<String, dynamic> data) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  // [MODIFIKASI UTAMA] Logika parsing pesan yang disempurnakan
  void _handleMessage(String message) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(message);
      final String eventName = decoded["event"];

      // Tangani event internal dari Pusher/Reverb
      if (eventName.startsWith('pusher:')) {
        _handlePusherEvent(eventName, decoded["data"]);
        return;
      }

      // Tangani event dari channel aplikasi kita (misalnya: private-chat.1)
      if (decoded.containsKey("channel")) {
        // Data dari Pusher seringkali berupa string JSON, perlu di-decode lagi
        final dynamic dataPayload = jsonDecode(decoded["data"]);

        // Buat format event yang konsisten untuk aplikasi
        final Map<String, dynamic> appEvent = {
          'type': eventName, // Contoh: "message.new" atau "message.read"
          'data': dataPayload,
        };

        debugPrint("✅ App event received: Type=${appEvent['type']}");
        _eventController.add(appEvent);
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing message: $e");
    }
  }

  // [BARU] Fungsi terpisah untuk menangani event internal Pusher
  void _handlePusherEvent(String event, dynamic data) {
    switch (event) {
      case "pusher:connection_established":
        final parsed = jsonDecode(data);
        _socketId = parsed["socket_id"];
        debugPrint("✅ Connected with socket_id: $_socketId");

        if (!_connectionCompleter!.isCompleted) {
          _connectionCompleter!.complete();
        }

        break;

      case "pusher:error":
        debugPrint("⚠️ Pusher error: $data");
        break;

      case "pusher:ping":
        send({"event": "pusher:pong", "data": {}});
        break;

    // Anda bisa menambahkan case lain jika perlu, misal: pusher_internal:subscription_succeeded
      case "pusher_internal:subscription_succeeded":
        debugPrint("✅ Successfully subscribed to channel: ${jsonDecode(data)['channel']}");
        break;
    }
  }

  /// Reconnect otomatis
  void _reconnect(String wsUrl) {
    Future.delayed(const Duration(seconds: 5), () {
      connect(wsUrl);
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _activityTimer?.cancel(); // [BARU] Hentikan timer aktivitas saat disconnect
    _subscription?.cancel();
    _channel?.sink.close();
    _statusController.add("disconnected");
  }
}