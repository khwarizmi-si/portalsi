// lib/models/post_model.dart
import 'user_model.dart';

class Post {
  final int id;
  final User user;
  final String? caption;
  final String? mediaUrl;
  final DateTime createdAt;

  // --- FIELD BARU DARI JSON ---
  final String? location;
  final bool isArchived;
  final bool isVideo;
  final DateTime updatedAt;
  final List<dynamic> tags;
  final List<dynamic> mentions;
  // -----------------------------

  // Properti ini akan diisi oleh Controller secara terpisah
  int likesCount = 0;
  int commentsCount = 0;
  bool isLikedByUser = false;

  Post({
    required this.id,
    required this.user,
    this.caption,
    this.mediaUrl,
    required this.createdAt,
    // --- TAMBAHKAN DI KONSTRUKTOR ---
    this.location,
    required this.isArchived,
    required this.isVideo,
    required this.updatedAt,
    required this.tags,
    required this.mentions,
    // ---------------------------------
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['post_id'] ?? 0,
      caption: json['caption'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      user: User.fromJson(json['user'] ?? {}),
      location: json['location'] as String?,
      isArchived: (json['is_archived'] ?? 0) == 1,
      isVideo: (json['is_video'] ?? 0) == 1,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      tags: (json['tags'] as List?) ?? [],
      mentions: (json['mentions'] as List?) ?? [],
    );
  }
}
