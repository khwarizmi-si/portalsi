import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/utils/secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<String> _statusController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Timer? _heartbeatTimer;
  Timer? _activityTimer;
  String? _socketId;
  Completer<void>? _connectionCompleter;

  // ========== CONNECT ==========
  Future<void> connect(String wsUrl) async {
    if (_channel != null && _channel!.closeCode == null) return;

    _connectionCompleter = Completer<void>();
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _statusController.add("connecting");

    _subscription = _channel!.stream.listen(
      (msg) => _handleMessage(msg),
      onDone: () {
        _statusController.add("disconnected");
        _reconnect(wsUrl);
      },
      onError: (err) {
        debugPrint("❌ WebSocket error: $err");
        _statusController.add("error");
        _reconnect(wsUrl);
      },
    );

    _statusController.add("connected");

    // Heartbeat ping every 10 seconds
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      send({"event": "pusher:ping", "data": {}});
    });

    // Activity timer (update backend every 2 mins)
    _activityTimer?.cancel();
    _activityTimer =
        Timer.periodic(const Duration(minutes: 2), (_) => updateActivity());
  }

  Future<void> updateActivity() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;
      await http.post(
        Uri.parse("https://api-new.portalsi.com/api/websocket/update-activity"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json"
        },
      );
    } catch (e) {
      debugPrint("⚠️ Error updating activity: $e");
    }
  }

  // ========== SUBSCRIBE ==========
  Future<void> subscribeToChannel(
      String channelBase, String authToken, String apiBaseUrl,
      {bool isPresence = false}) async {
    if (_channel == null || _socketId == null) return;

    final prefix = isPresence ? "presence-" : "private-";
    final channelName = "$prefix$channelBase";

    try {
      final response = await http.post(
        Uri.parse("$apiBaseUrl/broadcasting/auth"),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({"channel_name": channelName, "socket_id": _socketId}),
      );

      if (response.statusCode == 200) {
        final authData = jsonDecode(response.body);
        send({
          "event": "pusher:subscribe",
          "data": {"channel": channelName, "auth": authData["auth"]}
        });
        debugPrint("📡 Subscribing to $channelName...");
      } else {
        debugPrint("❌ Auth failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("⚠️ Error during subscription: $e");
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null) _channel!.sink.add(jsonEncode(data));
  }

  // ========== MESSAGE HANDLER ==========
  void _handleMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      final event = decoded["event"];
      final channel = decoded["channel"];
      dynamic data = decoded["data"];
      if (data is String) data = jsonDecode(data);

      switch (event) {
        case "pusher:connection_established":
          _socketId = data["socket_id"];
          debugPrint("✅ Connected with socket_id: $_socketId");
          _statusController.add("connected:$_socketId");
          break;

        case "pusher:ping":
          send({"event": "pusher:pong", "data": {}});
          break;

        case "pusher_internal:subscription_succeeded":
          debugPrint("✅ Subscribed to $channel");
          break;

        case "pusher_internal:member_added":
        case "pusher_internal:member_removed":
          _eventController
              .add({"event": event, "channel": channel, "data": data});
          break;

        case "message.new":
          _messageController.add({"channel": channel, "data": data});
          break;

        default:
          _eventController
              .add({"event": event, "channel": channel, "data": data});
      }
    } catch (e) {
      debugPrint("⚠️ Error parsing WS message: $e");
    }
  }

  void _reconnect(String wsUrl) =>
      Future.delayed(const Duration(seconds: 5), () => connect(wsUrl));

  void disconnect() {
    _heartbeatTimer?.cancel();
    _activityTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _statusController.add("disconnected");
  }
}
