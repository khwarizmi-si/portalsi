// lib/services/like_service.dart

import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:portal_si/services/api_service.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/foundation.dart';

import '../models/like_model.dart';

/// Model untuk data update dari WebSocket
class LikeUpdate {
  final int postId;
  // --- 👇 PERUBAHAN 1: Buat agar bisa null (nullable) 👇 ---
  final int? likesCount;
  // --- 👆 AKHIR PERUBAHAN 👆 ---
  final bool isLiked;

  LikeUpdate(
      {required this.postId, this.likesCount, required this.isLiked});
}

class LikeService extends ApiService {
  static final LikeService _instance = LikeService._internal();
  factory LikeService() => _instance;

  final BehaviorSubject<LikeUpdate> _streamController =
  BehaviorSubject<LikeUpdate>();
  Stream<LikeUpdate> get likeUpdates => _streamController.stream;

  LikeService._internal() {
    AuthService.webSocketService?.eventStream.listen((appEvent) {
      try {
        if (appEvent.event == 'like.created' ||
            appEvent.event == 'like.deleted') {
          final updateData = appEvent.data as Map<String, dynamic>;
          debugPrint(
              "👍 Real-time like update received for post ${updateData['post_id']}");
          _streamController.add(LikeUpdate(
            postId: updateData['post_id'] as int,
            likesCount: updateData['likes_count'] as int?,
            isLiked: updateData['is_liked_by_user'] as bool? ?? false,
          ));
        }
      } catch (e, s) {
        debugPrint("❌ Gagal memproses like event: $e");
        debugPrint("Stack trace: $s");
      }
    });
  }

  // --- (getLikes tidak berubah) ---
  Future<List<Like>> getLikes(int postId) async {
    final response = await get('posts/$postId/likes');
    if (response is List) {
      return response.map((like) => Like.fromJson(like)).toList();
    }
    return [];
  }

  // --- 👇 PERUBAHAN 2: Ubah total fungsi ini 👇 ---
  /// Toggle like via HTTP dan siarkan status baru secara manual.
  /// Membutuhkan status saat ini untuk menghitung status baru.
  Future<bool> toggleLikeHttp(
      int postId, {
        required bool isCurrentlyLiked,
        int? currentLikesCount, // Dibuat nullable
      }) async {
    try {
      // 1. Panggil API. Kita tidak peduli lagi dengan responsnya.
      await post('posts/$postId/like');
      debugPrint("✅ Like Toggled for Post #$postId via HTTP");

      // 2. Hitung status baru secara manual
      final bool newLikeStatus = !isCurrentlyLiked;
      final int? newLikesCount = (currentLikesCount != null)
          ? (isCurrentlyLiked ? currentLikesCount - 1 : currentLikesCount + 1)
          : null; // Biarkan null jika kita tidak tahu

      // 3. Siarkan status baru secara manual (INI KUNCINYA)
      debugPrint("👍 Manually pushing like update from HTTP toggle for post $postId");
      _streamController.add(LikeUpdate(
        postId: postId,
        likesCount: newLikesCount, // Kirim null jika tidak ada
        isLiked: newLikeStatus,
      ));

      return true;

    } catch (e) {
      debugPrint("❌ Gagal Toggle Like untuk Post #$postId: $e");
      rethrow; // Biarkan UI yang menangani error
    }
  }
// --- 👆 AKHIR PERUBAHAN 👆 ---
}