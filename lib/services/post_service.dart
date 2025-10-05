// lib/services/post_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/liker_model.dart';
import '../models/paginated_response.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';

import '../models/post_model.dart';

// --- PERBAIKAN: Tambahkan kembali "extends ApiService" ---
class PostService extends ApiService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  // --- SEMUA KODE CACHE LAMA DIHAPUS DARI SINI ---

  Future<Post?> createPost(Map<String, String> fields, {File? mediaFile}) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    if (mediaFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'media',
          mediaFile.path,
          filename: path.basename(mediaFile.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      // --- PERUBAHAN: Tambahkan log untuk respons body ---
      log("✅ Respons Sukses dari Endpoint /posts:\n${response.body}");
      // --- AKHIR PERUBAHAN ---

      final responseData = jsonDecode(response.body);
      // Pastikan 'post' adalah Map sebelum dioper ke Post.fromJson
      if (responseData['post'] is Map<String, dynamic>) {
        return Post.fromJson(responseData['post'] as Map<String, dynamic>);
      } else {
        // Tambahkan penanganan jika 'post' tidak ada atau bukan Map
        throw Exception('Format data post tidak valid dalam respons.');
      }
    } else {
      throw Exception(
          'Gagal membuat postingan. Status: ${response.statusCode}, Body: ${response.body}'
      );
    }
  }

  Future<Post?> fetchPinnedPost() async {
    // Implementasi placeholder Anda dipertahankan
    return null;
  }

  Future<PaginatedFeedResponse> fetchPosts({int page = 1}) async {
    final dynamic responseData = await get('posts', queryParams: {
      'page': page.toString(),
    });

    if (responseData is Map<String, dynamic> && responseData['feed'] is List) {
      // Ambil list feed seperti sebelumnya
      final items = responseData['feed'] as List<dynamic>;

      // --- 👇 CEK APAKAH ADA HALAMAN BERIKUTNYA 👇 ---
      final bool hasNext = responseData['next_page_url'] != null;

      // Kembalikan objek PaginatedFeedResponse
      return PaginatedFeedResponse(feedItems: items, hasNextPage: hasNext);
    } else {
      // Jika format tidak sesuai, kembalikan data kosong dan anggap tidak ada halaman lagi
      print('⚠️ Peringatan: Format respons /posts tidak sesuai.');
      return PaginatedFeedResponse(feedItems: [], hasNextPage: false);
    }
  }

  Future<List<Post>> fetchExplorePosts({int page = 1}) async {
    final token = await SecureStorage.getToken();
    final url = Uri.parse('$baseUrl/explore?page=$page');

    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      // 1. Decode respons sebagai Map
      final Map<String, dynamic> body = json.decode(response.body);
      // 2. Ambil list dari key 'data'
      final List<dynamic> postsJson = body['data'];
      // 3. Ubah setiap item JSON menjadi objek Post
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat postingan explore dari API');
    }
  }

  Future<Post> getPostDetail(int id) async {
    final dynamic data = await get('posts/$id');
    print('=============================================');
    print('🔍 DEBUG: DATA MENTAH DARI API UNTUK POST ID #$id');
    // Gunakan jsonEncode untuk format yang rapi (pretty print)
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyprint = encoder.convert(data);
    log(prettyprint); // log() lebih baik untuk string panjang
    print('=============================================');
    if (data is Map<String, dynamic>) {
      return Post.fromJson(data);
    } else {
      throw Exception('Format data untuk post #$id tidak valid.');
    }
  }

  Future<List<Liker>> getPostLikers(int postId) async {
    try {
      final currentUserId = await SecureStorage.getUserId(); // Ambil ID pengguna saat ini
      final responseData = await get('posts/$postId/likes');

      if (responseData is List) {
        return responseData
            .map((likeData) => Liker.fromJson(likeData, currentUserId ?? 0))
            .toList();
      }
      return [];

    } catch (e) {
      log('❌ Gagal mengambil data likers untuk post $postId: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getClipsFeed({int? startingPostId, String? nextUrl}) async {
    assert(startingPostId != null || nextUrl != null, 'Harus menyediakan startingPostId atau nextUrl');

    try {
      dynamic responseData;

      // Jika ada nextUrl (untuk pagination), panggil dengan http.get langsung
      if (nextUrl != null) {
        log("🚀 Mencoba mengambil clips dari URL LENGKAP: $nextUrl");
        final token = await SecureStorage.getToken();
        final response = await http.get(
          Uri.parse(nextUrl),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          responseData = jsonDecode(response.body);
        } else {
          throw Exception('Endpoint tidak ditemukan (${response.statusCode}). URL: $nextUrl');
        }
      }
      // Jika tidak ada nextUrl (panggilan pertama), gunakan ApiService.get
      else {
        final String endpoint = 'clips/$startingPostId';
        log("🚀 Mencoba mengambil clips dari ENDPOINT: $endpoint");
        responseData = await get(endpoint);
      }

      log("✅ SUKSES: Respons diterima.");

      if (responseData is Map<String, dynamic>) {
        final List<dynamic> clipsJson = responseData['next_clips'] as List? ?? [];
        final List<Post> clips = clipsJson.map((json) => Post.fromJson(json)).toList();

        return {
          'clips': clips,
          'next_page_url': responseData['next_page_url'],
        };
      }
      return {'clips': [], 'next_page_url': null};
    } catch (e) {
      log('❌ Gagal mengambil clips feed: $e');
      rethrow;
    }
  }

  Future<bool> deletePost(int id) async {
    await delete('posts/$id');
    return true;
  }
}