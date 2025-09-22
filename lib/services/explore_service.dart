import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class ExploreService {
  // Ganti dengan URL API Anda yang sebenarnya
  final baseUrl = 'https://api-new.portalsi.com/api'; // Contoh URL yang benar

  Future<List<dynamic>> getExplorePosts() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/explore'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      // --- [PERBAIKAN DI SINI] ---
      // 1. Decode body sebagai Map (JSON Object)
      final Map<String, dynamic> responseBody = jsonDecode(res.body);

      // 2. Cek apakah Map tersebut memiliki key 'data' dan nilainya adalah List
      if (responseBody.containsKey('data') && responseBody['data'] is List) {
        // 3. Kembalikan List yang ada di dalam 'data'
        return responseBody['data'] as List<dynamic>;
      } else {
        // Jika formatnya tidak sesuai, lemparkan error
        throw Exception('Format respons tidak valid: kunci "data" tidak ditemukan atau bukan sebuah list.');
      }
    } else {
      // Tambahkan detail error untuk debugging yang lebih baik
      throw Exception('Gagal memuat postingan eksplorasi. Status: ${res.statusCode}, Body: ${res.body}');
    }
  }
}