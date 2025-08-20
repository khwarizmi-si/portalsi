// lib/services/santri_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/santri_model.dart';

class SantriService {
  final String _apiUrl = "https://santriboard.vercel.app/api/student/leaderboard";

  Future<List<Santri>> fetchSantriList() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // Jika request berhasil, parse JSON
        final List<dynamic> body = jsonDecode(response.body);
        final List<Santri> santriList = body
            .map((dynamic item) => Santri.fromJson(item))
            .toList();
        return santriList;
      } else {
        // Jika server mengembalikan error, lempar exception
        throw Exception('Gagal memuat daftar santri: Status code ${response.statusCode}');
      }
    } catch (e) {
      // Menangani error koneksi atau lainnya
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}