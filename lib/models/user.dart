// Menggunakan ProfileModel sebagai model dasar untuk pengguna.
// Ini memastikan konsistensi data di seluruh aplikasi.
import 'package:portal_si/services/user_service.dart';

class User extends ProfileModel {
  // Konstruktor mewarisi dari ProfileModel
  User({
    required super.username,
    required super.email,
    required super.fullName,
    required super.bio,
    required super.profilePictureUrl,
    required super.isVerified,
  });
}
