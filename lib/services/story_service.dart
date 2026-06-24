// lib/services/story_service.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import '../models/paginated_story_feed.dart';
import '../models/story_model.dart';
import '../models/story_viewer_model.dart';
import '../config/api_endpoint.dart';
import '../utils/secure_storage.dart';

// Fungsi helper yang sama dari PostService untuk stream dengan progress
Stream<List<int>> _createUploadStream(
    File file, void Function(int, int) onProgress) {
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

Future<http.Response> _sendMultipartWithProgress(
  http.MultipartRequest request,
  Function(int sent, int total)? onProgress,
) async {
  final client = http.Client();
  try {
    final total = request.contentLength;
    var sent = 0;
    final stream = request.finalize();
    final streamedRequest = http.StreamedRequest(request.method, request.url)
      ..headers.addAll(request.headers)
      ..contentLength = total
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection;

    stream.listen(
      (chunk) {
        sent += chunk.length;
        onProgress?.call(sent, total);
        streamedRequest.sink.add(chunk);
      },
      onError: streamedRequest.sink.addError,
      onDone: streamedRequest.sink.close,
      cancelOnError: true,
    );

    final streamedResponse = await client.send(streamedRequest);
    return http.Response.fromStream(streamedResponse);
  } finally {
    client.close();
  }
}

class StoryService {
  final baseUrl = ApiEndpoints.apiUrl;

  MediaType? _mediaTypeFor(String? filename, Uint8List bytes) {
    final mime = lookupMimeType(filename ?? '', headerBytes: bytes);
    final parts = mime?.split('/');
    if (parts == null || parts.length != 2) return null;
    return MediaType(parts[0], parts[1]);
  }

  /// --- FUNGSI BARU UNTUK MENGUNGGAH STORY DENGAN PROGRESS ---
  Future<void> createStory(Map<String, String> fields,
      {File? mediaFile,
      Uint8List? mediaBytes,
      String? mediaFilename,
      Function(int sent, int total)? onProgress}) async {
    final token = await SecureStorage.getToken();
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/stories'));

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    // Web has no file paths — upload raw bytes.
    if (mediaBytes != null) {
      request.files.add(http.MultipartFile.fromBytes('media', mediaBytes,
          filename: mediaFilename ?? 'story.png',
          contentType: _mediaTypeFor(mediaFilename, mediaBytes)));
    } else if (mediaFile != null) {
      if (onProgress != null) {
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
      final response = await _sendMultipartWithProgress(request, onProgress);

      if (response.statusCode == 201 || response.statusCode == 200) {
        log("✅ Story berhasil diunggah:\n${response.body}");
      } else {
        throw Exception(
            'Gagal membuat story. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } on http.ClientException catch (e) {
      log("Upload Story dibatalkan: $e");
      throw Exception('Upload Story dibatalkan oleh pengguna.');
    }
  }

  Future<bool> viewStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories/$id/view'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<UserWithStories> getStoriesForUser(int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/stories/user/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      log('✅ SUCCESS: Respons API untuk getStoriesForUser (userId: $userId)');
      log(res.body);
      return UserWithStories.fromJson(jsonDecode(res.body));
    } else {
      log('❌ FAILED: Gagal memuat story (userId: $userId)');
      log('Status Code: ${res.statusCode}');
      log('Response Body: ${res.body}');
      throw Exception('Gagal memuat story untuk pengguna ID: $userId');
    }
  }

  Future<bool> uploadStory(String mediaUrl) async {
    final token = await SecureStorage.getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/stories'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'media_url': mediaUrl}),
    );
    return res.statusCode == 201;
  }

  Future<bool> deleteStory(int id) async {
    final token = await SecureStorage.getToken();
    final res = await http.delete(
      Uri.parse('$baseUrl/stories/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return res.statusCode == 200;
  }

  Future<List<dynamic>> getStoryFeed() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/stories/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // ponytail: API returns {stories:[...], suggestions:[...]}; the home feed
      // expects just the list. Casting the Map as List was what broke home.
      return data is List ? data : (data['stories'] as List? ?? []);
    } else {
      throw Exception('Gagal memuat story feed');
    }
  }

  Future<PaginatedStoryFeed> getPaginatedStoryFeedForUser(int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final uri = Uri.parse('$baseUrl/stories/feed/user/$userId');
    log('Fetching paginated story feed from: $uri');

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      log('✅ SUCCESS: Respons API untuk getPaginatedStoryFeed (userId: $userId)');
      log(res.body);
      return PaginatedStoryFeed.fromJson(jsonDecode(res.body));
    } else {
      log('❌ FAILED: Gagal memuat paginated story feed (userId: $userId)');
      log('Status Code: ${res.statusCode}, Body: ${res.body}');
      throw Exception('Gagal memuat story feed untuk user ID: $userId');
    }
  }

  Future<StoryViewersInfo> getStoryViewers(int storyId) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }

    final res = await http.get(
      Uri.parse('$baseUrl/stories/$storyId/viewers'), // Sesuai endpoint Anda
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      log('✅ SUCCESS: Respons API untuk getStoryViewers (storyId: $storyId)');
      log(res.body);
      return StoryViewersInfo.fromJson(jsonDecode(res.body));
    } else {
      log('❌ FAILED: Gagal memuat viewers (storyId: $storyId)');
      log('Status Code: ${res.statusCode}');
      log('Response Body: ${res.body}');
      throw Exception('Gagal memuat daftar penonton untuk story ID: $storyId');
    }
  }
}
