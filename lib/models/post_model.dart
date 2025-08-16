// lib/models/post_model.dart
import 'user_model.dart';

class Post {
  final int id;
  final User user;
  final String? caption;
  final String? mediaUrl;
  final DateTime createdAt;
  final String? location;
  final bool isArchived;
  final bool isVideo;
  final DateTime updatedAt;
  final List<dynamic> tags;
  final List<dynamic> mentions;

  // Properti ini sekarang diinisialisasi dari JSON
  int likesCount;
  int commentsCount;
  bool isLikedByUser;

  Post({
    required this.id,
    required this.user,
    this.caption,
    this.mediaUrl,
    required this.createdAt,
    this.location,
    required this.isArchived,
    required this.isVideo,
    required this.updatedAt,
    required this.tags,
    required this.mentions,
    // --- TAMBAHKAN DI KONSTRUKTOR ---
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
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

      // --- TAMBAHKAN LOGIKA PARSING INI ---
      // Ini akan mengambil data dari JSON
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByUser: json['is_liked'] ?? false,
    );
  }
}
