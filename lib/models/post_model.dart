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
      id: json['post_id'] as int,
      caption: json['caption'] as String?,
      mediaUrl: json['media_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),

      // --- PARSING DATA BARU ---
      location: json['location'] as String?,
      // Konversi nilai integer (0 atau 1) menjadi boolean (false atau true)
      isArchived: (json['is_archived'] as int) == 1,
      isVideo: (json['is_video'] as int) == 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tags: json['tags'] as List<dynamic>,
      mentions: json['mentions'] as List<dynamic>,
      // --------------------------
    );
  }
}
