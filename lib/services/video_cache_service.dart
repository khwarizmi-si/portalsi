// lib/services/video_cache_service.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VideoCacheService {
  static const key = 'customVideoCache';

  // Singleton pattern
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() => _instance;
  VideoCacheService._internal();

  // Konfigurasi Cache Manager
  static CacheManager? _cacheManager;

  CacheManager get cacheManager {
    _cacheManager ??= CacheManager(
      Config(
        key,
        // Video akan dianggap usang setelah 1.5 menit (90 detik) di cache
        // Cache manager akan membersihkannya secara berkala.
        stalePeriod: const Duration(minutes: 1, seconds: 30),
        // Jumlah maksimum objek di dalam cache
        maxNrOfCacheObjects: 100,
        // Opsi untuk custom path, jika dibutuhkan
        // fileSystem: IOFileSystem(key),
      ),
    );
    return _cacheManager!;
  }

  // Fungsi untuk mendapatkan file dari cache atau men-download jika belum ada
  Future<FileInfo> getSingleFile(String url) async {
    return await cacheManager.downloadFile(url);
  }

  // Fungsi untuk membersihkan seluruh cache video
  Future<void> emptyCache() async {
    await cacheManager.emptyCache();
    print("===== Cache Video Telah Dibersihkan =====");
  }
}