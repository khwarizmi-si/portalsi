// lib/services/like_service.dart

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/api_service.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart'; // Tambahkan untuk debugPrint

import '../models/like_model.dart';

/// Model untuk data update dari WebSocket
class LikeUpdate {
  final int postId;
  final int likesCount;
  final bool isLiked;

  LikeUpdate(
      {required this.postId, required this.likesCount, required this.isLiked});
}

class LikeService extends ApiService {
  // ✅ 1. Gunakan Singleton Pattern
  static final LikeService _instance = LikeService._internal();
  factory LikeService() => _instance;

  // ✅ 2. Gunakan BehaviorSubject untuk stream yang lebih fleksibel
  final BehaviorSubject<LikeUpdate> _streamController =
      BehaviorSubject<LikeUpdate>();
  Stream<LikeUpdate> get likeUpdates => _streamController.stream;

  // ✅ 3. Constructor private untuk inisialisasi listener
  LikeService._internal() {
    // ⚡️ Mendengarkan stream dari WebSocket yang diinisialisasi oleh AuthService
    AuthService.webSocketService?.eventStream.listen((appEvent) {
      try {
        if (appEvent.event == 'like.created' ||
            appEvent.event == 'like.deleted') {
          final updateData = appEvent.data as Map<String, dynamic>;
          debugPrint(
              "👍 Real-time like update received for post ${updateData['post_id']}");
          _streamController.add(LikeUpdate(
            postId: updateData['post_id'] as int,
            likesCount: updateData['likes_count'] as int,
            isLiked: updateData['is_liked_by_user'] as bool,
          ));
        }
      } catch (e, s) {
        debugPrint("❌ Gagal memproses like event: $e");
        debugPrint("Stack trace: $s");
      }
    });
  }

  // --- FUNGSI LAMA (HTTP) UNTUK KOMPATIBILITAS ---
  Future<List<Like>> getLikes(int postId) async {
    final response = await get('posts/$postId/likes');
    if (response is List) {
      return response.map((like) => Like.fromJson(like)).toList();
    }
    return [];
  }

  // ✅ 4. Gunakan API HTTP untuk aksi
  Future<bool> toggleLike(int postId) async {
    try {
      final response = await post('posts/$postId/like');
      debugPrint("✅ Like Toggled for Post #$postId");
      return response != null;
    } catch (e) {
      debugPrint("❌ Gagal Toggle Like untuk Post #$postId: $e");
      rethrow;
    }
  }

  // ❌ Hapus semua fungsi koneksi WebSocket yang duplikat
  // (misalnya connect(), disconnect(), toggleLikeSocket())
  // karena sudah ditangani secara global oleh AuthService
}
