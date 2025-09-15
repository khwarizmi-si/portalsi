// import 'package:flutter/foundation.dart';
// import 'package:portal_si/services/websocket_service.dart';
// import 'package:portal_si/utils/secure_storage.dart';
// import 'package:portal_si/config/api_endpoint.dart';

// class WebSocketProvider with ChangeNotifier {
//   // Menggunakan instance singleton yang sudah kita buat sebelumnya
//   final WebSocketService _service = webSocketService;
//   String? _authToken;
//   int? _userId;

//   bool _isConnected = false;
//   final Map<int, bool> _onlineUsers = {};
//   final Map<int, dynamic> _latestMessages = {};
//   final Map<int, int> _likeCounts = {};
//   final Map<int, int> _commentCounts = {};

//   // [BARU] State untuk notifikasi dan stories
//   int _unreadNotifications = 0;
//   final List<Map<String, dynamic>> _recentStories = [];


//   bool get isConnected => _isConnected;
//   bool isUserOnline(int userId) => _onlineUsers[userId] ?? false;
//   Map<String, dynamic>? getLatestMessage(int roomId) => _latestMessages[roomId];
//   int getLikeCount(int postId, int defaultCount) =>
//       _likeCounts[postId] ?? defaultCount;
//   int getCommentCount(int postId, int defaultCount) =>
//       _commentCounts[postId] ?? defaultCount;

//   // [BARU] Getter untuk notifikasi dan stories agar bisa diakses oleh UI
//   int get unreadNotifications => _unreadNotifications;
//   List<Map<String, dynamic>> get recentStories => _recentStories;

//   Future<void> initializeAndConnect() async {
//     _authToken = await SecureStorage.getToken();
//     final userIdStr = await SecureStorage.getUserId();
//     if (_authToken == null || userIdStr == null) return;

//     // Perbaikan: Parsing userId dari String ke int
//     _userId = userIdStr;
//     if (_userId == null) return;

//     _setupListeners();
//     final wsUrl = ApiEndpoints.getWebSocketUrl('wss://api-new.portalsi.com/app/fiouy3umnruqcwdsoxni?protocol=7&client=js&version=7.0');
//     // Tidak perlu `await _service.connect(wsUrl);` di sini jika service sudah di-manage di tempat lain (misal: SessionManager)
//     // Namun jika ini adalah entry point utama, biarkan saja.
//     await _service.connect(wsUrl);
//   }

//   void _setupListeners() {
//     _service.statusStream.listen((status) {
//       final newState = status.startsWith("connected");
//       if (_isConnected == newState) return;
//       _isConnected = newState;

//       if (_isConnected) subscribeToUserChannel();
//       notifyListeners();
//     });

//     _service.messageStream.listen((msg) {
//       final channel = msg["channel"];
//       final data = msg["data"];

//       // Pastikan room_id ada dan merupakan integer
//       if (data != null && data['room_id'] is int) {
//         final int roomId = data["room_id"];
//         _latestMessages[roomId] = data;
//         notifyListeners();
//       }
//     });

//     _service.eventStream.listen((event) {
//       final eventName = event["event"];
//       final data = event["data"];
//       if (data == null) return; // Pengaman jika data null

//       // [MODIFIKASI] Menambahkan case baru untuk notifikasi dan stories
//       switch (eventName) {
//         case "pusher_internal:member_added":
//           _onlineUsers[data["user_id"]] = true;
//           notifyListeners();
//           break;
//         case "pusher_internal:member_removed":
//           _onlineUsers[data["user_id"]] = false;
//           notifyListeners();
//           break;
//         case "post.liked":
//           _likeCounts[data["post_id"]] =
//               (_likeCounts[data["post_id"]] ?? 0) + 1;
//           notifyListeners();
//           break;
//         case "post.commented":
//           _commentCounts[data["post_id"]] =
//               (_commentCounts[data["post_id"]] ?? 0) + 1;
//           notifyListeners();
//           break;

//       // [BARU] Menangani event notifikasi baru
//         case "notification.new":
//           _unreadNotifications++;
//           notifyListeners();
//           break;

//       // [BARU] Menangani event story baru
//         case "story.new":
//         // Menambahkan story baru ke awal list
//           _recentStories.insert(0, data as Map<String, dynamic>);
//           // Opsional: Batasi jumlah story agar tidak terlalu banyak
//           if (_recentStories.length > 20) {
//             _recentStories.removeLast();
//           }
//           notifyListeners();
//           break;

//         default:
//           debugPrint("ℹ️ Unhandled event: $eventName");
//       }
//     });
//   }

//   // [BARU] Fungsi bantuan untuk mereset data saat dibutuhkan
//   void clearUnreadNotifications() {
//     _unreadNotifications = 0;
//     notifyListeners();
//   }

//   void clearRecentStories() {
//     _recentStories.clear();
//     notifyListeners();
//   }

//   Future<void> subscribeToUserChannel() async {
//     if (_userId == null || _authToken == null) return;
//     await _service.subscribeToChannel(
//         "user.$_userId", _authToken!, ApiEndpoints.baseUrl);
//   }

//   Future<void> subscribeToChatRoom(int roomId) async {
//     if (_authToken == null) return;
//     await _service.subscribeToChannel(
//         "chat.$roomId", _authToken!, ApiEndpoints.baseUrl);
//   }

//   void disconnect() => _service.disconnect();
//   Future<void> reconnect() async {
//     final wsUrl = ApiEndpoints.getWebSocketUrl('wss://api-new.portalsi.com/app/fiouy3umnruqcwdsoxni?protocol=7&client=js&version=7.0');
//     await _service.connect(wsUrl);
//   }
// }