// lib/services/history_service.dart

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';
import '../models/login_history_model.dart';

class HistoryService {
  final String _baseUrl = 'https://api.portalsi.com/api';

  // Fungsi untuk mengambil daftar riwayat login
  Future<List<LoginHistory>> fetchLoginHistories() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$_baseUrl/login-histories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // 1. Decode respons JSON
      final dynamic decodedData = json.decode(response.body);

      // 2. Cek apakah hasilnya adalah sebuah List (sesuai format baru)
      if (decodedData is List) {

        // (Opsional) Print log untuk debugging
        print('✅ Menerima respons dari /login-histories (Format List Langsung)');
        log(response.body);

        // 3. Langsung map dari list tersebut ke List<LoginHistory>
        return decodedData
            .map((jsonItem) => LoginHistory.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        // Fallback jika format kembali berubah
        throw Exception('Format respons API tidak terduga. Diharapkan List.');
      }
    } else {
      throw Exception('Gagal memuat riwayat login. Status: ${response.statusCode}');
    }
  }

  // Fungsi untuk logout dari sesi yang dipilih
  Future<bool> logoutSessions(List<int> sessionIds) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // 1. Buat daftar Future untuk setiap permintaan DELETE
    final List<Future<http.Response>> deleteFutures = sessionIds.map((id) {
      final uri = Uri.parse('$_baseUrl/login-histories/$id');
      print('🚀 Menjalankan DELETE untuk sesi ID: $id');

      // 2. Gunakan http.delete untuk setiap ID
      return http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    }).toList();

    // 3. Jalankan semua permintaan secara paralel dan tunggu hasilnya
    final responses = await Future.wait(deleteFutures);

    // 4. Cek apakah SEMUA permintaan berhasil.
    //    DELETE yang sukses biasanya mengembalikan status code 200 (OK) atau 204 (No Content).
    final bool allSucceeded = responses.every(
            (response) => response.statusCode == 200 || response.statusCode == 204
    );

    if (!allSucceeded) {
      print('❌ Beberapa sesi gagal dihapus.');
    }

    return allSucceeded;
  }
}