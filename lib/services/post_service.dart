// lib/services/post_service.dart
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/liker_model.dart';
import '../models/paginated_response.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';

import '../models/post_model.dart';

// Fungsi helper untuk membuat stream yang melaporkan progres unggahan
Stream<List<int>> _createUploadStream(File file, void Function(int, int) onProgress) {
  final fileStream = file.openRead();
  final totalBytes = file.lengthSync();
  int bytesSent = 0;

  return fileStream.transform(
    StreamTransformer.fromHandlers(
      handleData: (data, sink) {
        bytesSent += data.length;
        onProgress(bytesSent, totalBytes);
        sink.add(data);
      },
      handleError: (error, stack, sink) {
        sink.addError(error, stack);
      },
      handleDone: (sink) {
        sink.close();
      },
    ),
  );
}


class PostService extends ApiService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  Future<Post?> createPost(
      Map<String, String> fields,
      {File? mediaFile,
      Uint8List? mediaBytes,
      String? mediaFilename,
      Function(int sent, int total)? onProgress}
      ) async {
    final token = await getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    // Web has no file paths — upload raw bytes (e.g. from image_picker XFile).
    if (mediaBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'media',
          mediaBytes,
          filename: mediaFilename ?? 'upload.bin',
        ),
      );
    } else if (mediaFile != null) {
      if (onProgress != null) {
        // Menggunakan stream kustom untuk melaporkan progres
        final stream = _createUploadStream(mediaFile, onProgress);
        request.files.add(
          http.MultipartFile(
            'media',
            stream,
            mediaFile.lengthSync(),
            filename: path.basename(mediaFile.path),
          ),
        );
      } else {
        // Fallback jika tidak ada callback progress
        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            mediaFile.path,
            filename: path.basename(mediaFile.path),
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ Respons Sukses dari Endpoint /posts:\n${response.body}");
        final responseData = jsonDecode(response.body);
        if (responseData['post'] is Map<String, dynamic>) {
          return Post.fromJson(responseData['post'] as Map<String, dynamic>);
        } else {
          throw Exception('Format data post tidak valid dalam respons.');
        }
      } else {
        // Jika koneksi ditutup (biasanya karena pembatalan), lempar error spesifik
        if (streamedResponse.request == null) {
          throw Exception('Upload dibatalkan oleh pengguna.');
        }
        throw Exception(
            'Gagal membuat postingan. Status: ${response.statusCode}, Body: ${response.body}'
        );
      }
    } on http.ClientException catch (e) {
      // Menangkap error ketika stream dibatalkan secara paksa
      log("Upload dibatalkan: $e");
      throw Exception('Upload dibatalkan oleh pengguna.');
    }
  }

  Future<Post?> fetchPinnedPost() async {
    return null;
  }

  Future<PaginatedFeedResponse> fetchPosts({int page = 1}) async {
    final dynamic responseData = await get('posts', queryParams: {
      'page': page.toString(),
    });

    if (responseData is Map<String, dynamic> && responseData['feed'] is List) {
      final items = responseData['feed'] as List<dynamic>;
      final bool hasNext = responseData['next_page_url'] != null;
      return PaginatedFeedResponse(feedItems: items, hasNextPage: hasNext);
    } else {
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
      final Map<String, dynamic> body = json.decode(response.body);
      final List<dynamic> postsJson = body['data'];
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat postingan explore dari API');
    }
  }

  Future<Post> getPostDetail(int id) async {
    final dynamic data = await get('posts/$id');
    if (data is Map<String, dynamic>) {
      return Post.fromJson(data);
    } else {
      throw Exception('Format data untuk post #$id tidak valid.');
    }
  }

  Future<List<Liker>> getPostLikers(int postId) async {
    try {
      final currentUserId = await SecureStorage.getUserId();
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