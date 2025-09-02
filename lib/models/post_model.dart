// lib/models/post_model.dart
import 'user_model.dart';

class Post {
  final int id;
  final String? caption;
  final String? mediaUrl;
  final bool isVideo;
  final DateTime createdAt;
  final User user;

  int likesCount;
  int commentsCount;
  bool isLikedByUser;

  Post({
    required this.id,
    this.caption,
    this.mediaUrl,
    required this.isVideo,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    required this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['post_id'],
      caption: json['caption'],
      mediaUrl: json['media_url'],
      isVideo: json['is_video'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLikedByUser: json['is_liked'] ?? false,
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': id,
      'caption': caption,
      'media_url': mediaUrl,
      'is_video': isVideo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLikedByUser,
      'user': user.toJson(),
    };
  }
  Post copyWith({
    int? id,
    String? caption,
    String? mediaUrl,
    bool? isVideo,
    DateTime? createdAt,
    User? user,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByUser,
  }) {
    return Post(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isVideo: isVideo ?? this.isVideo,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
    );
  }
}