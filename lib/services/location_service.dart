import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<String?> getCurrentPlace() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan lokasi tidak aktif di perangkat Anda.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi ditolak secara permanen. Silakan aktifkan melalui pengaturan aplikasi.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return 'Lokasi tidak ditemukan';
      }

      Placemark place = placemarks[0];

      // --- LOGIKA FALLBACK YANG LEBIH BAIK ---
      String mainPlace = place.street ?? place.locality ?? '';
      String subPlace = place.subAdministrativeArea ?? place.administrativeArea ?? '';

      if (mainPlace.isNotEmpty && subPlace.isNotEmpty) {
        // Contoh: "Jl. Sudirman, Jakarta Selatan" atau "Menteng, Jakarta Pusat"
        return '$mainPlace, $subPlace';
      } else if (mainPlace.isNotEmpty) {
        // Contoh: "Jl. Sudirman"
        return mainPlace;
      } else if (subPlace.isNotEmpty) {
        // Contoh: "Jakarta Selatan"
        return subPlace;
      } else {
        // Fallback terakhir jika semua kosong
        return place.country ?? 'Lokasi tidak dikenal';
      }

    } catch (e) {
      print("Error saat reverse geocoding: $e");
      throw Exception('Gagal mendapatkan nama lokasi.');
    }
  }
}