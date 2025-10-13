// lib/models/liker_model.dart

class Liker {
  final int userId;
  final String username;
  final String? fullName;
  final String? profilePictureUrl;
  bool isFollowing; // Status follow dari pengguna saat ini
  final bool isCurrentUser; // Apakah liker ini adalah pengguna yang sedang login

  Liker({
    required this.userId,
    required this.username,
    this.fullName,
    this.profilePictureUrl,
    required this.isFollowing,
    required this.isCurrentUser,
  });

  // --- PERUBAHAN: Jadikan currentUserId opsional (nullable) ---
  factory Liker.fromJson(Map<String, dynamic> json, [int? currentUserId]) {
    final userJson = json['user'] as Map<String, dynamic>? ?? json;

    return Liker(
      userId: userJson['user_id'],
      username: userJson['username'] ?? 'Unknown',
      fullName: userJson['full_name'],
      profilePictureUrl: userJson['profile_picture_url'],
      isFollowing: json['is_following_status'] ?? false,
      // Logika ini tetap aman, jika currentUserId null, hasilnya akan selalu false
      isCurrentUser: userJson['user_id'] == currentUserId,
    );
  }
}