// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_endpoint.dart';
import '../utils/secure_storage.dart';

abstract class ApiService {
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  /// Single source of truth — switchable via --dart-define API_BASE_URL.
  /// Works for both https prod and http://127.0.0.1:8000 local.
  String get baseUrl => ApiEndpoints.apiUrl;

  /// Builds the full request URI from [baseUrl], preserving scheme/host/port.
  Uri _buildUri(String endpoint, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl/$endpoint');
    return queryParams == null
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
  }

  // --- ✨ PERUBAHAN 2: Tambahkan metode publik untuk mendapatkan token ---
  Future<String> getToken() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token otentikasi tidak ditemukan.');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken(); // Sekarang memanggil metode publik di atas
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams: queryParams);
    try {
      final response = await _client
          .get(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    try {
      final response = await _client
          .post(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    try {
      final response = await _client
          .put(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = _buildUri(endpoint);
    try {
      final response = await _client
          .delete(uri, headers: await _getHeaders())
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = _buildUri(endpoint);
    try {
      final response = await _client
          .patch(
        uri,
        headers: await _getHeaders(),
        body: body != null ? jsonEncode(body) : null,
      )
          .timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> postMultipart(
      String endpoint, {
        required Map<String, String> body,
        Map<String, File>? files,
      }) async {
    final uri = _buildUri(endpoint);
    try {
      final request = http.MultipartRequest('POST', uri);
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      request.fields.addAll(body);

      if (files != null) {
        for (var entry in files.entries) {
          request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value.path));
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } on SocketException {
      throw Exception('Koneksi jaringan gagal. Mohon periksa internet Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Silakan coba lagi.');
    } catch (e) {
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty)
        return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Otentikasi gagal. Sesi Anda mungkin telah berakhir.');
    } else if (response.statusCode == 404) {
      throw Exception('Endpoint tidak ditemukan (404).');
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['message'] ?? 'Terjadi kesalahan tidak diketahui.';
        throw Exception('Error: $errorMessage (Status ${response.statusCode})');
      } catch (e) {
        throw Exception('Terjadi kesalahan (Status ${response.statusCode})');
      }
    }
  }
}