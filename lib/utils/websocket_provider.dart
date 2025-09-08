import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/config/api_endpoint.dart';

import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/models/notification_model.dart';
import 'package:portal_si/utils/secure_storage.dart'; // Asumsi Anda punya ini

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  String? _authToken;
  int? _userId;

  // State
  bool _isConnected = false;
  int _unreadNotifications = 0;
  List<NotificationModel> _notifications = [];

  // Getters
  bool get isConnected => _isConnected;
  int get unreadNotifications => _unreadNotifications;
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  /// Initializes the provider, service, and connects to WebSocket.
  /// Call this after user logs in or on app start if token exists.
  Future<void> initializeAndConnect() async {
    _authToken = await SecureStorage.getToken();
    _userId = await SecureStorage.getUserId();

    if (_authToken == null || _userId == null) {
      debugPrint(
          '❌ Cannot initialize WebSocketProvider: Token or UserID is missing.');
      return;
    }

    _webSocketService.initialize(ApiEndpoints.baseUrl, _authToken!);
    _setupListeners();
    await _webSocketService.connect();
  }

  void _setupListeners() {
    _webSocketService.connectionStatusStream.listen((connected) {
      if (_isConnected == connected) return; // Hindari update berlebihan

      _isConnected = connected;
      debugPrint('WebSocket connection status changed: $_isConnected');

      if (connected) {
        // Otomatis subscribe ke channel personal saat koneksi berhasil/pulih
        subscribeToUserChannel();
      }
      notifyListeners();
    });

    _webSocketService.notificationStream.listen(_handleNotification);
  }

  void _handleNotification(Map<String, dynamic> data) {
    try {
      final notification = NotificationModel.fromJson(data);
      _notifications.insert(0, notification);
      if (!notification.isRead) {
        _unreadNotifications++;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error parsing notification model: $e');
    }
  }

  /// Fetches auth signature for a private channel from the server.
  Future<String?> _getChannelSignature(String channelName) async {
    final socketId = _webSocketService.socketId;
    if (_authToken == null || socketId == null) {
      debugPrint('❌ Cannot get signature: Missing auth token or socket ID.');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.broadcastAuth}'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'socket_id': socketId,
          'channel_name': channelName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['auth'];
      } else {
        debugPrint(
            '❌ Signature auth failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Exception fetching channel signature: $e');
      return null;
    }
  }

  /// Subscribes to the logged-in user's private notification channel.
  Future<void> subscribeToUserChannel() async {
    if (_userId == null) return;

    final channelName = 'private-user.$_userId';
    final signature = await _getChannelSignature(channelName);

    if (signature != null) {
      _webSocketService.subscribeToChannel(channelName,
          authSignature: signature);
    }
  }

  void markNotificationsAsRead() {
    if (_unreadNotifications == 0) return;
    _unreadNotifications = 0;
    // Tandai juga objek notifikasi sebagai sudah dibaca
    for (var notif in _notifications) {
      notif.isRead = true;
    }
    notifyListeners();
  }

  /// Disconnects and cleans up resources.
  Future<void> disconnect() async {
    await _webSocketService.disconnect();
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
