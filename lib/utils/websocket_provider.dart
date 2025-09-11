import 'package:flutter/foundation.dart';
import 'package:portal_si/services/websocket_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:portal_si/config/api_endpoint.dart';

class WebSocketProvider with ChangeNotifier {
  final WebSocketService _service = WebSocketService();
  String? _authToken;
  int? _userId;

  bool _isConnected = false;
  Map<int, bool> _onlineUsers = {};
  Map<int, dynamic> _latestMessages = {};
  Map<int, int> _likeCounts = {};
  Map<int, int> _commentCounts = {};

  bool get isConnected => _isConnected;
  bool isUserOnline(int userId) => _onlineUsers[userId] ?? false;
  Map<int, dynamic>? getLatestMessage(int roomId) => _latestMessages[roomId];
  int getLikeCount(int postId, int defaultCount) =>
      _likeCounts[postId] ?? defaultCount;
  int getCommentCount(int postId, int defaultCount) =>
      _commentCounts[postId] ?? defaultCount;

  Future<void> initializeAndConnect() async {
    _authToken = await SecureStorage.getToken();
    final userIdStr = await SecureStorage.getUserId();
    if (_authToken == null || userIdStr == null) return;
    _userId = userIdStr;

    _setupListeners();
    final wsUrl = ApiEndpoints.getWebSocketUrl('fiouy3umnruqcwdsoxni');
    await _service.connect(wsUrl);
  }

  void _setupListeners() {
    _service.statusStream.listen((status) {
      final newState = status.startsWith("connected");
      if (_isConnected == newState) return;
      _isConnected = newState;

      if (_isConnected) subscribeToUserChannel();
      notifyListeners();
    });

    _service.messageStream.listen((msg) {
      final channel = msg["channel"];
      final data = msg["data"];
      final roomId = data["room_id"];
      _latestMessages[roomId] = data;
      notifyListeners();
    });

    _service.eventStream.listen((event) {
      final channel = event["channel"];
      final eventName = event["event"];
      final data = event["data"];

      switch (eventName) {
        case "pusher_internal:member_added":
          _onlineUsers[data["user_id"]] = true;
          notifyListeners();
          break;
        case "pusher_internal:member_removed":
          _onlineUsers[data["user_id"]] = false;
          notifyListeners();
          break;
        case "post.liked":
          _likeCounts[data["post_id"]] =
              (_likeCounts[data["post_id"]] ?? 0) + 1;
          notifyListeners();
          break;
        case "post.commented":
          _commentCounts[data["post_id"]] =
              (_commentCounts[data["post_id"]] ?? 0) + 1;
          notifyListeners();
          break;
        default:
          debugPrint("ℹ️ Unhandled event: $eventName");
      }
    });
  }

  Future<void> subscribeToUserChannel() async {
    if (_userId == null || _authToken == null) return;
    await _service.subscribeToChannel(
        "user.$_userId", _authToken!, ApiEndpoints.baseUrl);
  }

  Future<void> subscribeToChatRoom(int roomId) async {
    if (_authToken == null) return;
    await _service.subscribeToChannel(
        "chat.$roomId", _authToken!, ApiEndpoints.baseUrl);
  }

  void disconnect() => _service.disconnect();
  Future<void> reconnect() async {
    final wsUrl = ApiEndpoints.getWebSocketUrl('fiouy3umnruqcwdsoxni');
    await _service.connect(wsUrl);
  }
}
