// lib/models/comment_model.dart

import 'user_model.dart'; // Pastikan path ini benar

class Comment {
  final int id;
  final int postId;
  final String content;
  final DateTime createdAt;
  final bool isVerified;

  // Data user yang sudah di-flatten
  final int userId;
  final String username;
  final String? profilePictureUrl;

  final DateTime updatedAt;

  // Data untuk balasan (replies)u
  final int? parentId;
  final List<Comment> replies;

  // Properti untuk state di UI
  bool liked;
  int likes;
  int depth; // Untuk indentasi UI

  Comment( {
    required this.updatedAt,
    required this.id,
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.username,
    this.profilePictureUrl,
    this.parentId,
    this.replies = const [],
    this.liked = false,
    this.likes = 0,
    this.depth = 0,
    this.isVerified = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Helper untuk mengambil data user, baik dari root atau dari sub-objek 'user'
    final userJson = json['user'] as Map<String, dynamic>? ?? json;

    // --- Logika Parsing yang Tangguh (diambil dari file comment.dart Anda) ---

    // 1. Parsing ID yang fleksibel (cek 'comment_id' atau 'id')
    final int commentId = int.tryParse(json['comment_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0;

    // 2. Parsing User ID yang fleksibel
    final int userId = int.tryParse(userJson['user_id']?.toString() ?? userJson['id']?.toString() ?? '0') ?? 0;

    // 3. Parsing Username dengan berbagai kemungkinan kunci
    String username = userJson['username'] ??
        userJson['full_name'] ??
        userJson['name'] ??
        'User tidak dikenal';

    // 4. Parsing URL foto profil dengan berbagai kemungkinan kunci
    String? profilePictureUrl = userJson['profile_picture_url'];


    // 5. Proses replies secara rekursif (mengembalikan fungsionalitas balasan)
    var repliesFromJson = json['replies'] as List? ?? [];
    List<Comment> replyList = repliesFromJson.map((r) => Comment.fromJson(r)).toList();

    return Comment(
      id: commentId,
      postId: int.tryParse(json['post_id'].toString()) ?? 0,
      userId: userId,
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),

      username: username,
      profilePictureUrl: profilePictureUrl,

      likes: json['likes_count'] as int? ?? 0,
      isVerified: userJson['is_verified'] ?? false,
      liked: json['is_liked'] as bool? ?? false,

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),

      parentId: int.tryParse(json['parent_comment_id']?.toString() ?? ''),
      replies: replyList,
    );
  }
}