// lib/services/like_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'api_service.dart';
import '../models/like_model.dart'; // Pastikan model ini ada

// Model untuk data update dari WebSocket
class LikeUpdate {
  final int postId;
  final int likesCount;
  final bool isLiked;

  LikeUpdate(
      {required this.postId, required this.likesCount, required this.isLiked});
}

class LikeService extends ApiService {
  WebSocketChannel? _channel;
  final StreamController<LikeUpdate> _streamController =
      StreamController.broadcast();

  Stream<LikeUpdate> get likeUpdates => _streamController.stream;

  // --- FUNGSI LAMA (HTTP) UNTUK KOMPATIBILITAS ---
  Future<List<Like>> getLikes(int postId) async {
    final response = await get('posts/$postId/likes');
    if (response is List) {
      return response.map((like) => Like.fromJson(like)).toList();
    }
    return [];
  }

  Future<bool> toggleLikeHttp(int postId) async {
    try {
      final response = await post(
          'posts/$postId/like'); // Memanggil metode post dari ApiService

      // --- 👇 PERUBAHAN DI SINI ---
      // Mencetak status dan isi respons ke console untuk debugging
      print("✅ Like Toggled for Post #$postId: Status OK");
      print("   Response Body: $response");
      // -----------------------------

      return response != null; // Mengembalikan true jika request berhasil
    } catch (e) {
      // Menangkap dan mencetak error jika request gagal
      print("❌ Gagal Toggle Like untuk Post #$postId: $e");
      rethrow; // Melemparkan kembali error agar bisa ditangani oleh controller
    }
  }

  // --- FUNGSI BARU (WEBSOCKET) UNTUK REAL-TIME ---
  Future<void> connect() async {
    if (_channel != null) return;
    final token = await getToken();
    final wsUrl = Uri.parse('wss://api-new.portalsi.com/ws/likes?token=$token');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      print("✅ Terhubung ke WebSocket Likes Server.");

      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        if (data['event'] == 'like_update') {
          final updateData = data['data'];
          _streamController.add(LikeUpdate(
            postId: updateData['post_id'],
            likesCount: updateData['likes_count'],
            isLiked: updateData['is_liked_by_user'],
          ));
        }
      }, onError: (error) {
        // print("❌ WebSocket Error: $error");
        disconnect();
      }, onDone: () {
        print("🔌 Koneksi WebSocket ditutup.");
        disconnect();
      });
    } catch (e) {
      print("❌ Gagal terhubung ke WebSocket: $e");
    }
  }

  void toggleLikeSocket(int postId) {
    if (_channel == null) return;
    final message = jsonEncode({"action": "toggle_like", "post_id": postId});
    _channel!.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
