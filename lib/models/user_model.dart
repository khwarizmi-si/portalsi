// lib/models/user_model.dart

class User {
  final int? id; // Dibuat opsional karena tidak semua response API memilikinya
  final String username;
  final String? email;
  final String? fullName;
  final String? bio;
  final String? profilePictureUrl;
  final bool isVerified;

  User({
    this.id,
    required this.username,
    this.email,
    this.fullName,
    this.bio,
    this.profilePictureUrl,
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Menangani kasus di mana data user ada di dalam sub-key 'user'
    final userData =
        json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;

    return User(
      id: userData['user_id'] as int?,
      username: userData['username'] ?? 'User tidak dikenal',
      email: userData['email'] as String?,
      fullName: userData['full_name'] as String?,
      bio: userData['bio'] as String?,
      profilePictureUrl: userData['profile_picture_url'] as String?,
      isVerified: userData['is_verified'] as bool? ?? false,
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
    };
  }
}
