// lib/services/token_refresh_service.dart
import 'dart:async';
import 'package:dio/dio.dart'; // Gunakan http client Anda, contoh ini menggunakan Dio
import '../utils/secure_storage.dart';

class TokenRefreshService {
  Timer? _timer;

  // Menggunakan pola Singleton agar hanya ada satu instance dari service ini di seluruh aplikasi
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() {
    return _instance;
  }
  TokenRefreshService._internal();

  /// Memulai timer periodik untuk merefresh token.
  void start() {
    // Hentikan timer yang mungkin sudah berjalan untuk mencegah duplikasi
    stop();

    print("✅ Memulai refresh token periodik (setiap 3 menit)...");
    // Jalankan _performTokenRefresh segera saat pertama kali dimulai
    _performTokenRefresh();
    // Kemudian, atur timer untuk berjalan setiap 3 menit
    _timer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _performTokenRefresh();
    });
  }

  /// Menghentikan timer (dipanggil saat logout).
  void stop() {
    if (_timer?.isActive ?? false) {
      print("🛑 Menghentikan refresh token periodik.");
      _timer?.cancel();
    }
  }

  /// Fungsi yang melakukan panggilan API untuk merefresh token.
  Future<void> _performTokenRefresh() async {
    print("🔄 Mencoba merefresh token dari API...");
    try {
      // Pastikan Anda sudah menyimpan refresh token di SecureStorage saat login
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) {
        print("⚠️ Refresh token tidak ditemukan. Tidak dapat merefresh.");
        stop(); // Hentikan proses jika tidak ada refresh token
        return;
      }

      final dio = Dio();
      // Ganti '/auth/refresh' dengan endpoint API Anda yang sebenarnya
      final response = await dio.post(
          'https://api-new.portalsi.com/api/login',
          data: {
            'refresh_token': refreshToken,
          }
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final newAccessToken = response.data['token'];
        // Simpan token akses dan refresh token yang baru
        await SecureStorage.saveToken(newAccessToken);
        if (response.data['token'] != null) {
          await SecureStorage.saveRefreshToken(response.data['token']);
        }
        print("✅ Token berhasil diperbarui dan disimpan ke cache.");
      } else {
        print("❌ Gagal merefresh token. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error saat merefresh token: $e");
      // Anda bisa menambahkan logika di sini untuk logout pengguna jika refresh token gagal
    }
  }
}