// lib/providers/feed_provider.dart
import 'package:portal_si/config/api_endpoint.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../utils/secure_storage.dart';

class FeedProvider with ChangeNotifier {
  // Pindahkan semua state dari FeedPage ke sini
  List<Post> _posts = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoading = true;
  bool _isFetchingMore = false;

  // Variabel cache juga dipindahkan ke sini
  List<Post>? _cachedPosts;
  DateTime? _cacheTimestamp;

  // Buat getter agar UI bisa mengakses data
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;

  // Pindahkan logika fetch ke sini
  Future<void> fetchPosts({bool isRefresh = false}) async {
    // 💡 Gunakan logika cache yang sudah ada
    if (_currentPage == 1 && !isRefresh && _cachedPosts != null && _cacheTimestamp != null) {
      final cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < const Duration(minutes: 3)) {
        _posts = _cachedPosts!;
        _isLoading = false;
        log('✅ Provider: Menggunakan data dari cache.');
        notifyListeners(); // Beri tahu UI bahwa ada data baru
        return;
      }
    }

    if (isRefresh) {
      _posts = [];
      _currentPage = 1;
      _hasNextPage = true;
      _isLoading = true;
      notifyListeners();
    }

    _isFetchingMore = true;

    // Logika HTTP request Anda (copy-paste dari _fetchPosts di page)
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final url = Uri.parse('${ApiEndpoints.apiUrl}/explore?page=$_currentPage');
      final response = await http.get(url, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List postsJson = data['data'];
        final newPosts = postsJson.map((p) => Post.fromJson(p)).toList();

        if (isRefresh || _currentPage == 1) {
          _posts = newPosts;
          _cachedPosts = newPosts; // Simpan ke cache
          _cacheTimestamp = DateTime.now(); // Simpan waktu
        } else {
          _posts.addAll(newPosts);
        }

        _hasNextPage = data['next_page_url'] != null;
        if (_hasNextPage) _currentPage++;
      }
    } catch (e) {
      log('🚨 EXCEPTION DI PROVIDER: $e');
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners(); // Update UI setelah selesai
    }
  }

  // Method untuk pagination
  void fetchMorePosts() {
    if (_hasNextPage && !_isFetchingMore) {
      fetchPosts();
    }
  }
}