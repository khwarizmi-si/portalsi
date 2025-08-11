// lib/models/post_model.dart
import 'user_model.dart';

class Post {
  final int id;
  final String? caption;
  final String? mediaUrl;
  final DateTime createdAt;
  final User user;

  // Properti ini akan diisi oleh Controller
  int likesCount = 0;
  int commentsCount = 0;
  bool isLikedByUser = false;
  // bool isBookmarked; // Jika ada

  Post({
    required this.id,
    this.caption,
    this.mediaUrl,
    required this.createdAt,
    required this.user,
  });

  // Factory constructor tetap sama, tapi tidak mengisi data like/comment
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['post_id'] as int,
      caption: json['caption'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
