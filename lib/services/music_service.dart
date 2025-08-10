// lib/services/music_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/song_model.dart';

class MusicService {
  final Dio _dio = Dio();

  Future<List<Song>> searchSongs(String term) async {
    if (term.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://itunes.apple.com/search',
        queryParameters: {
          'term': term,
          'entity': 'song',
          'limit': 25,
        },
      );

      if (response.statusCode == 200) {
        // --- 2. PERUBAHAN UTAMA DI SINI ---
        // Decode response secara manual untuk memastikan formatnya adalah Map
        final data = jsonDecode(response.data as String);

        // Gunakan data yang sudah di-decode
        final List results = data['results'];

        return results.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load songs');
      }
    } catch (e) {
      print('Error searching songs: $e');
      throw Exception('Failed to load songs');
    }
  }
}