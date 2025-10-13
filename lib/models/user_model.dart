// lib/models/user_model.dart

import 'dart:developer';

class SimplePost {
  final int postId;
  final String? caption;
  final String mediaUrl;
  final DateTime createdAt;
  final bool isVideo;
  final bool isLikedByUser;   // TAMBAHKAN BARIS INI
  final bool isBookmarked;
  // <-- TAMBAHKAN PROPERTI INI

  SimplePost({
    required this.postId,
    this.caption,
    required this.mediaUrl,
    required this.createdAt,
    required this.isVideo,
    required this.isLikedByUser, // TAMBAHKAN BARIS INI
    required this.isBookmarked,// <-- TAMBAHKAN DI KONSTRUKTOR
  });

  factory SimplePost.fromJson(Map<String, dynamic> json) {
    // --- Log untuk Debugging ---
    final rawIsVideo = json['is_video'];
    final bool parsedIsVideo = rawIsVideo == 1;

    log('--- 🕵️‍♂️ Debugging Post #${json['post_id']} ---');
    log('Nilai mentah "is_video" dari API: $rawIsVideo (Tipe Data: ${rawIsVideo.runtimeType})');
    log('Hasil parsing menjadi "isVideo": $parsedIsVideo');
    log('----------------------------------------');
    // --- Batas Log ---

    return SimplePost(
      postId: json['post_id'],
      caption: json['caption'],
      mediaUrl: json['media_url'],
      createdAt: DateTime.parse(json['created_at']),
      // Gunakan hasil parsing yang sudah kita buat
      isVideo: parsedIsVideo,
      isLikedByUser: json['is_liked_by_user'] ?? false,
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'caption': caption,
      'media_url': mediaUrl,
      'created_at': createdAt.toIso8601String(),
      'is_video': isVideo, // <-- TAMBAHKAN KE JSON
    };
  }

  SimplePost copyWith({
    bool? isLikedByUser,
    bool? isBookmarked,
  }) {
    return SimplePost(
      postId: this.postId,
      caption: this.caption,
      mediaUrl: this.mediaUrl,
      createdAt: this.createdAt,
      isVideo: this.isVideo,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

// lib/models/user_model.dart

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
  final bool isOnline;
  final DateTime? lastSeen;
  final String? bannerUrl;
  final bool hasStory;
  final bool storyViewed;
  final String? role; // <-- TAMBAHKAN PROPERTI INI

  User({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.bio,
    this.profilePictureUrl,
    this.isVerified = false,
    this.isPrivate = false,
    this.followersCount = 0,
    this.bannerUrl,
    this.followingCount = 0,
    this.postsCount = 0,
    this.recentPosts = const [],
    this.isOnline = false,
    this.lastSeen,
    this.hasStory = false,
    this.storyViewed = false,
    this.role, // <-- TAMBAHKAN DI KONSTRUKTOR
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var postsFromJson = json['recent_posts'] as List? ?? [];
    List<SimplePost> recentPostsList = postsFromJson.map((i) => SimplePost.fromJson(i)).toList();

    return User(
      id: json['id'] ?? json['user_id'],
      username: json['username'],
      email: json['email'],
      fullName: json['full_name'] ?? json['name'],
      bio: json['bio'],
      bannerUrl: json['banner_url'],
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false,
      isPrivate: json['is_private'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      postsCount: json['posts_count'] ?? 0,
      recentPosts: recentPostsList,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      hasStory: json['has_story'] ?? false,
      storyViewed: json['story_viewed'] ?? false,
      role: json['role'], // <-- TAMBAHKAN LOGIKA PARSING
    );
  }

  // Method toJson() dan copyWith() tetap sama
  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'banner_url': bannerUrl,
      'bio': bio,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count': postsCount,
      'recent_posts': recentPosts.map((post) => post.toJson()).toList(),
      'role': role, // <-- TAMBAHKAN KE JSON
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
    String? bannerUrl,
    int? followingCount,
    int? postsCount,
    List<SimplePost>? recentPosts,
    String? role,
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
      bannerUrl: bannerUrl ?? this.bannerUrl,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      recentPosts: recentPosts ?? this.recentPosts,
      role: role ?? this.role,
    );
  }
}