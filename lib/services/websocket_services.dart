// lib/services/websocket_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// [PENTING] Kita buat satu instance global (Singleton) agar mudah diakses
// dari mana saja tanpa perlu Provider.of berkali-kali.
final WebSocketService webSocketService = WebSocketService();

class WebSocketService {
  WebSocketChannel? _channel;
  String? _socketId;
  String? _token; // Simpan token untuk re-autentikasi jika perlu

  final StreamController<String> _statusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventController = StreamController.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  // [MODIFIKASI] Method ini sekarang kita sebut 'initialize'
  void initialize({required String token}) {
    if (_channel != null && _channel?.closeCode == null) {
      debugPrint("WebSocket already initialized and connected.");
      return;
    }
    _token = token;
    final uri = Uri.parse('wss://api-new.portalsi.com:443/app/fiouy3umnruqcwdsoxni');

    try {
      _statusController.add('connecting');
      debugPrint('🔄 WebSocket Connecting to Reverb...');
      _channel = IOWebSocketChannel.connect(uri);
      _channel!.stream.listen(
        _handleMessage,
        onDone: () {
          _statusController.add('disconnected');
          debugPrint('🔌 WebSocket Disconnected from Reverb');
        },
        onError: (error) {
          _statusController.add('error');
          debugPrint('❌ WebSocket Error: $error');
        },
      );
    } catch (e) {
      debugPrint('‼️ GAGAL TOTAL SAAT INISIALISASI WEBSOCKETSERVICE: $e');
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    debugPrint("RECV: $message");
    final data = jsonDecode(message as String);
    final event = data['event'] as String;

    if (event.contains('NewDirectMessage')) {
      _messageController.add({'event': event, 'data': jsonDecode(data['data'])});
    } else {
      _eventController.add({'event': event, 'data': data['data']});
    }

    if (event == 'pusher:connection_established') {
      final eventData = jsonDecode(data['data'] as String);
      _socketId = eventData['socket_id'];
      _statusController.add('connected');
      debugPrint('✅ WebSocket Connected. Socket ID: $_socketId');
    }
  }

  Future<void> _subscribeToPrivateChannel(String channelName) async {
    if (_socketId == null || _token == null) return;
    try {
      final authResponse = await http.post(
        Uri.parse('https://api-new.portalsi.com/api/broadcasting/auth'),
        headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'},
        body: jsonEncode({'socket_id': _socketId, 'channel_name': channelName}),
      );
      if (authResponse.statusCode != 200) return;

      final authToken = jsonDecode(authResponse.body)['auth'];
      _sendMessage({'event': 'pusher:subscribe', 'data': {'channel': channelName, 'auth': authToken}});
      debugPrint("📡 Sending subscription request for: $channelName");
    } catch (e) {
      debugPrint("❌ Error subscribing to private channel $channelName: $e");
    }
  }

  // [MODIFIKASI] Nama method disesuaikan agar konsisten
  void listenToDirectMessages(int currentUserId, int otherUserId) {
    final ids = [currentUserId, otherUserId]..sort();
    final channelName = 'private-chat.direct.${ids.join('-')}';
    _subscribeToPrivateChannel(channelName);
  }

  void listenToUserChannel(int userId) {
    final channelName = 'private-user.$userId';
    _subscribeToPrivateChannel(channelName);
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel?.closeCode != null) return;
    _channel?.sink.add(jsonEncode(message));
  }

  void leaveChannel(String channelName) {
    _sendMessage({'event': 'pusher:unsubscribe', 'data': {'channel': channelName}});
    debugPrint("🛑 Left channel: $channelName");
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    debugPrint("🔌 WebSocket connection terminated.");
  }
}