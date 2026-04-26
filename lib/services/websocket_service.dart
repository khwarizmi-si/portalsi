// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/notification_system_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/app_lifecycle_manager.dart';

class AppEvent {
  final String channel;
  final String event;
  final dynamic data;

  AppEvent({required this.channel, required this.event, this.data});
}

class WebSocketService {
  final String _wsBaseUrl = "wss://ws.portalsi.com:443/app/fiouy3umnruqcwdsoxni";
  final String _authBaseUrl = "https://api.portalsi.com/api";
  final String _token;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  String? _socketId;
  String? get socketId => _socketId;
  Completer<void>? _connectionCompleter;

  final Set<String> _subscribedChannels = {};

  final StreamController<String> _statusController = StreamController.broadcast();
  final StreamController<AppEvent> _eventController = StreamController.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<AppEvent> get eventStream => _eventController.stream;

  WebSocketService({required String token}) : _token = token;

  Future<void> connect() {
    if (_channel != null && _channel?.closeCode == null) {
      debugPrint("WebSocket sudah terkoneksi.");
      return Future.value();
    }

    _connectionCompleter = Completer<void>();
    _statusController.add("connecting");
    _channel = WebSocketChannel.connect(Uri.parse(_wsBaseUrl));

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onDone: () {
        debugPrint("🚨 WebSocket DONE. Koneksi ditutup. Kode: ${_channel?.closeCode}, Alasan: ${_channel?.closeReason}");
        _statusController.add("disconnected");
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError("WebSocket disconnected before connection was established.");
        }
        _cleanup();
        _reconnect();
      },
      onError: (error) {
        debugPrint("🔥 WebSocket ERROR: $error");
        _statusController.add("error");
        if (_connectionCompleter != null && !_connectionCompleter!.isCompleted) {
          _connectionCompleter!.completeError(error);
        }
        _cleanup();
        _reconnect();
      },
    );
    return _connectionCompleter!.future;
  }

  void disconnect() {
    debugPrint("🔌 Disconnecting WebSocket secara manual...");
    _cleanup();
    _channel?.sink.close();
  }

  // --- 👇 FUNGSI BARU DITAMBAHKAN DI SINI 👇 ---
  Future<void> reconnect() async {
    debugPrint("🔄 Meminta koneksi ulang WebSocket secara manual...");
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
  // --- 👆 BATAS FUNGSI BARU 👆 ---

  void _reconnect() {
    debugPrint("🔁 Mencoba menyambung ulang dalam 5 detik...");
    Future.delayed(const Duration(seconds: 5), () => connect());
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _socketId = null;
    _subscribedChannels.clear();
  }

  void _handleMessage(dynamic message) {
    final decoded = jsonDecode(message as String);
    final eventName = decoded["event"] as String;
    debugPrint("===[ RAW WEBSOCKET MESSAGE RECEIVED ]===\n$message\n========================================");

    switch (eventName) {
      case "pusher:connection_established":
        _socketId = jsonDecode(decoded["data"])["socket_id"];
        _statusController.add("connected");
        debugPrint("✅ WebSocket Connected with socket_id: $_socketId");
        _startHeartbeat();
        return;
      case "pusher:ping":
        _send({"event": "pusher:pong", "data": {}});
        return;
      case "pusher_internal:subscription_succeeded":
        final String? channel = decoded['channel'];
        if (channel != null) {
          _subscribedChannels.add(channel);
          debugPrint("✅ Berhasil subscribe dan TERCATAT ke channel: $channel. Total: ${_subscribedChannels.length}");
        }
        return;
    }

    String? channelName = decoded['channel'];
    dynamic eventData;
    if (decoded['data'] is String) {
      eventData = jsonDecode(decoded['data']);
    } else {
      eventData = decoded['data'];
    }

    if (channelName == null && eventName == 'dm.new') {
      final messageContent = eventData['message'];
      if (messageContent != null) {
        final senderId = messageContent['sender_id'];
        final receiverId = messageContent['receiver_id'];
        if (senderId != null && receiverId != null) {
          final ids = [senderId, receiverId]..sort();
          channelName = 'private-dm.${ids.join('-')}';
          debugPrint("🔧 Channel name reconstructed for dm.new: $channelName");
        }
      }
    }

    if (channelName == null) {
      debugPrint("⚠️ Event '$eventName' diabaikan karena tidak memiliki channel.");
      return;
    }

    if (eventName == 'dm.new') {
      if (!AppLifecycleManager.isAppInForeground) {
        final messageData = eventData['message'];
        final senderData = eventData['sender'];
        if (messageData != null && senderData != null) {
          final int messageId = messageData['message_id'];
          final int senderId = senderData['user_id'];
          final String senderName = senderData['full_name'] ?? 'Pesan Baru';
          final String? profilePicUrl = senderData['profile_picture_url'];
          final String content = messageData['content'] ?? 'Mengirim media';
          final String payload = jsonEncode(senderData);
          NotificationSystemService.instance.showGroupedNotification(
            id: messageId,
            title: senderName,
            body: content,
            groupKey: 'dm_$senderId',
            groupChannelId: 'dm_channel',
            groupChannelName: 'Pesan Langsung',
            largeIconUrl: profilePicUrl,
            payload: payload,
          );
        }
      }
    }
    _eventController.add(AppEvent(
      channel: channelName,
      event: eventName,
      data: eventData,
    ));
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

  Future<void> subscribeToChannel(String channelName) async {
    if (_subscribedChannels.contains(channelName)) {
      debugPrint("✅ Sudah subscribe ke channel $channelName, tidak melakukan subscribe ulang.");
      return;
    }
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
        debugPrint("❌ Gagal otentikasi channel ${channelName}: ${response.body}");
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
  bool get isConnected => _channel != null && _channel?.closeCode == null;
}