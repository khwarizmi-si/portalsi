// lib/models/comment_model.dart
import 'user_model.dart';

class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt; // <-- PROPERTI YANG DITAMBAHKAN

  // Data 'user' yang di-flatten
  final String username;
  final String? profilePictureUrl;

  // Properti untuk state di UI
  bool liked;
  int likes;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt, // <-- PARAMETER YANG DITAMBAHKAN
    required this.username,
    this.profilePictureUrl,
    this.liked = false,
    this.likes = 0,
  });

// lib/models/comment_model.dart

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Ambil data user dari sub-key 'user' jika ada, jika tidak, gunakan json utama
    final userJson = json['user'] as Map<String, dynamic>? ?? json;

    return Comment(
      // [DIUBAH] Gunakan int.parse untuk semua ID agar aman dari tipe data String
      id: int.parse(json['comment_id'].toString()),
      postId: int.parse(json['post_id'].toString()),
      userId: int.parse(json['user_id'].toString()),

      // Properti lainnya tetap sama
      content:
          json['content'] as String? ?? '', // Tambahkan ?? '' untuk keamanan
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      username: userJson['username'] ?? 'User tidak dikenal',
      profilePictureUrl: userJson['profile_picture_url'] as String?,
      likes: json['likes_count'] as int? ?? 0, // Sesuaikan jika nama key beda
      liked: json['is_liked'] as bool? ?? false, // Sesuaikan jika nama key beda
    );
  }
}
