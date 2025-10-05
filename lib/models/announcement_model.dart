// lib/models/announcement_model.dart

class Announcement {
  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final bool pinned;
  final DateTime createdAt;
  final Creator creator;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.pinned,
    required this.createdAt,
    required this.creator,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['image_url'],
      pinned: json['pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      creator: Creator.fromJson(json['creator']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'pinned': pinned,
      'created_at': createdAt.toIso8601String(),
      'creator': creator.toJson(),
    };
  }
}

class Creator {
  final int userId;
  final String fullName;
  final String username;
  final String? profilePictureUrl;
  final bool isVerified; // <-- 1. TAMBAHKAN PROPERTI INI

  Creator({
    required this.userId,
    required this.fullName,
    required this.username,
    this.profilePictureUrl,
    this.isVerified = false, // <-- 2. TAMBAHKAN DI KONSTRUKTOR
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      userId: json['user_id'],
      fullName: json['full_name'],
      username: json['username'],
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false, // <-- 3. TAMBAHKAN PARSING DARI JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'is_verified': isVerified, // Jangan lupa tambahkan juga di sini
    };
  }
}