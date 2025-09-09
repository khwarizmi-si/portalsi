import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<String> _statusController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatListController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get chatListStream => _chatListController.stream;

  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  Timer? _heartbeatTimer;
  String? _socketId;

  /// Connect ke Laravel Reverb (Pusher protocol)
  Future<void> connect(String wsUrl) async {
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

      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        send({"event": "pusher:ping", "data": {}});
      });
    } catch (e) {
      debugPrint("❌ Failed to connect: $e");
      _statusController.add("error");
    }
  }

  /// Subscribe ke channel (auto request auth ke Laravel)
  /// Subscribe ke channel (sudah termasuk proses otentikasi)
  Future<void> subscribeToChannel(
    String channelBase,
    String authToken,
    String apiBaseUrl, {
    bool isPresence = false,
  }) async {
    final prefix = isPresence ? "presence-" : "private-";
    final channelName = "$prefix$channelBase";
    if (_channel == null || _socketId == null) {
      debugPrint(
          "⚠️ Cannot subscribe: WebSocket not connected or socket_id is null.");
      return;
    }

    // Pindahkan logika otentikasi ke sini, ini adalah tempat yang tepat.
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
        send(payload); // Gunakan fungsi send yang sudah ada
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

  /// Handler pesan masuk
  void _handleMessage(String message) {
    try {
      final Map<String, dynamic> decoded = jsonDecode(message);

      final event = decoded["event"];
      final data = decoded["data"];

      switch (event) {
        case "pusher:connection_established":
          final parsed = jsonDecode(data);
          _socketId = parsed["socket_id"];
          debugPrint("✅ Connected with socket_id: $_socketId");
          _statusController.add("connected:$_socketId");
          break;

        case "pusher:error":
          debugPrint("⚠️ Pusher error: $data");
          break;

        case "pusher:ping":
          send({"event": "pusher:pong", "data": {}});
          break;

        case "notification.new":
          _notificationController.add(decoded);
          break;

        case "message.sent":
          _messageController.add(decoded);
          break;

        case "chat.updated":
          _chatListController.add(decoded);
          break;

        default:
          _eventController.add(decoded);
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing message: $e");
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
    _subscription?.cancel();
    _channel?.sink.close();
    _statusController.add("disconnected");
  }
}
