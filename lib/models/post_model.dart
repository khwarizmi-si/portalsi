// lib/models/post_model.dart
import 'user_model.dart';

class Post {
  final int id;
  final String? caption;
  final String? mediaUrl;
  final bool isVideo;
  final DateTime createdAt;
  final User user;
  // --- 1. TAMBAHKAN PROPERTI DIMENSI ---
  final int? mediaWidth;
  final int? mediaHeight;

  int likesCount;
  int commentsCount;
  bool isLikedByUser;
  bool isBookmarked;

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
    this.mediaWidth, // Tambahkan di konstruktor
    this.mediaHeight, // Tambahkan di konstruktor
    required this.isBookmarked,
  });

  // --- 2. BUAT GETTER UNTUK ASPECT RATIO ---
  double get aspectRatio {
    // Memberikan rasio aspek default 1.0 (persegi) jika data tidak ada
    if (mediaWidth != null && mediaHeight != null && mediaWidth! > 0 && mediaHeight! > 0) {
      return mediaWidth! / mediaHeight!;
    }
    return 1.0;
  }

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
      isBookmarked: json['is_bookmarked'] ?? false,
      user: User.fromJson(json['user']),
      // --- 3. PARSING DATA DIMENSI DARI JSON ---
      // Pastikan backend Anda mengirimkan 'media_width' dan 'media_height'
      mediaWidth: json['media_width'],
      mediaHeight: json['media_height'],
    );
  }

  // ... sisa kode lainnya tidak berubah ...
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
      'media_width': mediaWidth,
      'media_height': mediaHeight,
    };
  }
  Post copyWith({
    int? id,
    String? caption,
    String? mediaUrl,
    bool? isVideo,
    bool? isBookmarked,
    DateTime? createdAt,
    User? user,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByUser,
    int? mediaWidth,
    int? mediaHeight,
  }) {
    return Post(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isVideo: isVideo ?? this.isVideo,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
    );
  }
}