// lib/models/user_model.dart

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
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'caption': caption,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class User {
  final int? id;
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

  User({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.bio,
    this.profilePictureUrl,
    // --- PERUBAHAN 1: Tambahkan nilai default untuk membuatnya opsional ---
    this.isVerified = false,
    this.isPrivate = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.recentPosts = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var postsFromJson = json['recent_posts'] as List? ?? [];
    List<SimplePost> recentPostsList = postsFromJson.map((i) => SimplePost.fromJson(i)).toList();

    return User(
      id: json['id'] ?? json['user_id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'],
      bio: json['bio'],
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false,
      isPrivate: json['is_private'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      recentPosts: recentPostsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'recent_posts': recentPosts.map((post) => post.toJson()).toList(),
    };
  }

  // --- ✨ PERUBAHAN 2: Tambahkan kembali method copyWith ---
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? profilePictureUrl,
    bool? isVerified,
    bool? isPrivate,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    List<SimplePost>? recentPosts,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      recentPosts: recentPosts ?? this.recentPosts,
    );
  }
}