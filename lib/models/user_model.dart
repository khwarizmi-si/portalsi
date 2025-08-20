// lib/models/user_model.dart

// Model sederhana untuk menampung data di 'recent_posts'
class SimplePost {
  final int postId;
  final String? caption;
  final String mediaUrl;
  final DateTime createdAt;

  SimplePost({
    required this.postId,
    this.caption,
    required this.mediaUrl,
    required this.createdAt,
  });

  factory SimplePost.fromJson(Map<String, dynamic> json) {
    return SimplePost(
      postId: json['post_id'],
      caption: json['caption'],
      mediaUrl: json['media_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class User {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final String? bio;
  final String? profilePictureUrl;
  final bool isVerified;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final List<SimplePost> recentPosts;
  final String? role;

  User({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.bio,
    this.profilePictureUrl,
    this.isVerified = false,
    this.isPrivate = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.recentPosts = const [],
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userData = json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    var postsList = <SimplePost>[];
    if (userData['recent_posts'] != null && userData['recent_posts'] is List) {
      postsList = (userData['recent_posts'] as List)
          .map((postJson) => SimplePost.fromJson(postJson))
          .toList();
    }

    return User(
      id: userData['user_id'] ?? 0,
      username: userData['username'] ?? 'User tidak dikenal',
      email: userData['email'],
      fullName: userData['full_name'],
      bio: userData['bio'],
      profilePictureUrl: userData['profile_picture_url'],
      isVerified: userData['is_verified'] ?? false,
      isPrivate: userData['is_private'] ?? false,
      role: userData['role'],
      followersCount: userData['followers_count'] ?? 0,
      followingCount: userData['following_count'] ?? 0,
      postsCount: userData['posts_count'] ?? 0,
      recentPosts: postsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'role': role,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
    };
  }

  // --- PERBAIKAN DI SINI ---
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profilePictureUrl,
    bool? isVerified,
    bool? isPrivate,
    String? role,
    // Tambahkan parameter untuk field baru
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<SimplePost>? recentPosts,
  }) {
    return User(
      // Salin nilai lama atau gunakan nilai baru jika ada
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      role: role ?? this.role,
      // Gunakan nilai baru atau salin nilai lama dari 'this'
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      recentPosts: recentPosts ?? this.recentPosts,
    );
  }
}