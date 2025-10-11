// lib/services/music_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/song_model.dart';

class MusicService {
  final Dio _dio = Dio();

  // URL yang benar didefinisikan di sini
  final String _baseUrl = 'https://itunes.apple.com/search';

  Future<List<Song>> getTrendingSongs() async {
    final trendingQueries = ['top hits', 'viral songs', 'pop chart', 'new music'];
    final randomQuery = trendingQueries[Random().nextInt(trendingQueries.length)];

    try {
      final response = await _dio.get(
        _baseUrl, // Menggunakan URL yang benar
        queryParameters: {
          'term': randomQuery,
          'entity': 'song',
          'limit': 20,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.data as String);
        final List results = data['results'];
        if (results.isEmpty) return [];

        List<Song> songs = results.map((json) => Song.fromJson(json)).toList();
        songs.shuffle();
        return songs.take(10).toList();
      } else {
        throw Exception('Failed to load trending songs');
      }
    } catch (e) {
      print('Error fetching trending songs: $e');
      return [];
    }
  }

  Future<List<Song>> searchSongs(String term) async {
    if (term.isEmpty) return [];

    try {
      final response = await _dio.get(
        _baseUrl, // Menggunakan URL yang benar
        queryParameters: {
          'term': term,
          'entity': 'song',
          'limit': 25,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.data as String);
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