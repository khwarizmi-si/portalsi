// lib/models/user_model.dart

class User {
  final int id;
  final String username;
  final String fullName; // Nama lengkap atau bio singkat
  final String profilePictureUrl;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.profilePictureUrl,
  });
}