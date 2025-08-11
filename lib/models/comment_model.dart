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

  factory Comment.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};

    return Comment(
      id: json['comment_id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(
          json['updated_at'] as String), // <-- LOGIKA PARSING DITAMBAHKAN
      username: userJson['username'] ?? 'User tidak dikenal',
      profilePictureUrl: userJson['profile_picture_url'] as String?,
      likes: json['likes'] as int? ?? 0,
      liked: json['liked'] as bool? ?? false,
    );
  }
}
