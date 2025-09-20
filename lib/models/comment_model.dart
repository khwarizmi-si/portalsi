// lib/models/comment_model.dart
class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.updatedAt,
    required this.username,
    this.profilePictureUrl,
    this.liked = false,
    this.likes = 0,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Ambil data user dari sub-key 'user' jika ada, jika tidak, gunakan json utama
    final userJson = json['user'] as Map<String, dynamic>? ?? json;

    return Comment(
      // Gunakan int.tryParse untuk keamanan tipe data
      id: int.tryParse(json['comment_id'].toString()) ?? 0,
      postId: int.tryParse(json['post_id'].toString()) ?? 0,
      userId: int.tryParse(userJson['user_id'].toString()) ?? int.tryParse(userJson['id'].toString()) ?? 0,

      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      // Tambahkan updatedAt dengan fallback ke createdAt jika null
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),

      username: userJson['username'] ?? 'User tidak dikenal',
      profilePictureUrl: userJson['profile_picture_url'] as String?,
      likes: json['likes_count'] as int? ?? 0,
      liked: json['is_liked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'likes_count': likes,
      'is_liked': liked,
    };
  }
}