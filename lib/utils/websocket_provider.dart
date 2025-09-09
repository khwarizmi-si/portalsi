import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/config/api_endpoint.dart';
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/models/notification_model.dart';
import 'package:portal_si/utils/secure_storage.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();
  String? _authToken;
  int? _userId;

  // ================= State =================
  bool _isConnected = false;
  int _unreadNotifications = 0;
  final List<NotificationModel> _notifications = [];

  // Chat & Social features
  final Map<int, bool> _onlineUsers = {};
  final List<Map<String, dynamic>> _recentStories = [];
  final Map<int, int> _likeCounts = {};
  final Map<int, int> _commentCounts = {};
  final Map<int, Map<String, dynamic>> _latestMessages = {};

  // ================= Getters =================
  bool get isConnected => _isConnected;
  int get unreadNotifications => _unreadNotifications;
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool isUserOnline(int userId) => _onlineUsers[userId] ?? false;
  List<Map<String, dynamic>> get recentStories =>
      List.unmodifiable(_recentStories);
  int getLikeCount(int postId, int initialCount) =>
      _likeCounts[postId] ?? initialCount;
  int getCommentCount(int postId, int initialCount) =>
      _commentCounts[postId] ?? initialCount;
  Map<String, dynamic>? getLatestMessage(int roomId) => _latestMessages[roomId];

  // ================= Initialization =================
  Future<void> initializeAndConnect() async {
    _authToken = await SecureStorage.getToken();
    final userIdStr = await SecureStorage.getUserId();
    _userId = userIdStr != null ? int.tryParse(userIdStr as String) : null;

    if (_authToken == null || _userId == null) {
      debugPrint('❌ Cannot init WebSocket: Token or UserID missing.');
      return;
    }

    _setupListeners();
    // PERBAIKAN 1: Buat URL WebSocket yang benar sebelum memanggil connect
    final wsUrl = ApiEndpoints.getWebSocketUrl(
        'YOUR_REVERB_APP_KEY'); // Ganti dengan App Key Anda
    await _webSocketService.connect(wsUrl);
  }

  void _setupListeners() {
    // PERBAIKAN: Gunakan stream yang benar dari service
    _webSocketService.statusStream.listen((status) {
      final newConnectionState = status.startsWith("connected");
      if (_isConnected == newConnectionState) return;

      _isConnected = newConnectionState;
      debugPrint('🔌 WebSocket connection status: $status');

      if (_isConnected) {
        // Otomatis subscribe setelah koneksi berhasil
        subscribeToUserChannel();
      }
      notifyListeners();
    });

    _webSocketService.notificationStream.listen(_handleNotification);
    _webSocketService.eventStream.listen(_handleCustomEvent);
  }

  // ================= Handlers =================
  void _handleNotification(Map<String, dynamic> data) {
    try {
      final notification = NotificationModel.fromJson(data);
      _notifications.insert(0, notification);

      if (!notification.isRead) {
        _unreadNotifications++;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error parsing notification: $e');
    }
  }

  void _handleCustomEvent(Map<String, dynamic> event) {
    final channel = event['channel'];
    final eventName = event['event'];
    final data = event['data'];

    debugPrint("📩 Event received: $channel | $eventName | $data");

    switch (eventName) {
      case "message.new":
        final roomId = data['room_id'];
        _latestMessages[roomId] = data;
        notifyListeners();
        break;

      case "user.online":
        final uid = data['user_id'];
        _onlineUsers[uid] = true;
        notifyListeners();
        break;

      case "user.offline":
        final uid = data['user_id'];
        _onlineUsers[uid] = false;
        notifyListeners();
        break;

      case "post.liked":
        final postId = data['post_id'];
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
        notifyListeners();
        break;

      case "post.commented":
        final postId = data['post_id'];
        _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;
        notifyListeners();
        break;

      case "story.new":
        _recentStories.add(data);
        notifyListeners();
        break;

      default:
        debugPrint("ℹ️ Unhandled event: $eventName");
    }
  }

  // ================= Channels =================

  Future<void> subscribeToUserChannel() async {
    if (_userId == null || _authToken == null) return;

    final channelName = 'private-user.$_userId';

    // PERBAIKAN 3: Panggil metode service yang sudah benar
    // Provider tidak perlu tahu tentang 'signature', serahkan pada service
    await _webSocketService.subscribeToChannel(
      channelName,
      _authToken!,
      ApiEndpoints.baseUrl,
    );
  }

  // ================= Utils =================
  void markNotificationsAsRead() {
    if (_unreadNotifications == 0) return;

    _unreadNotifications = 0;
    for (var notif in _notifications) {
      notif.isRead = true;
    }
    notifyListeners();
  }

  Future<void> reconnect() async {
    // PERBAIKAN 4: Gunakan cara yang sama seperti inisialisasi
    if (_authToken != null) {
      final wsUrl = ApiEndpoints.getWebSocketUrl(
          'YOUR_REVERB_APP_KEY'); // Ganti dengan App Key Anda
      await _webSocketService.connect(wsUrl);
    }
  }

  void disconnect() {
    // PERBAIKAN 5: Panggil nama fungsi yang benar
    _webSocketService.disconnect();
  }

  @override
  void dispose() {
    disconnect(); // Panggil fungsi disconnect yang sudah benar
    super.dispose();
  }
}
