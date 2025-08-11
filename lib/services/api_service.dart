// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart'; // Asumsi file ini ada untuk mengambil token

/// Kelas dasar abstrak untuk semua service yang berinteraksi dengan API.
/// Mengelola URL, headers, dan error handling secara terpusat.
abstract class ApiService {
  final String _scheme = 'https';
  final String _host = 'api.portalsi.com';
  final String _unencodedPath = '/api';
  final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 15);

  /// Helper untuk menambahkan header otentikasi secara otomatis.
  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token otentikasi tidak ditemukan.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Helper terpusat untuk request GET.
  /// Mendukung query parameters opsional.
  Future<dynamic> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final uri = Uri(
      scheme: _scheme,
      host: _host,
      path: '$_unencodedPath/$endpoint',
      queryParameters: queryParams,
    );
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

  /// Helper terpusat untuk request POST.
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.https(_host, '$_unencodedPath/$endpoint');
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

  /// Helper terpusat untuk request PUT.
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.https(_host, '$_unencodedPath/$endpoint');
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

  /// Helper terpusat untuk request DELETE.
  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.https(_host, '$_unencodedPath/$endpoint');
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
    final uri = Uri.https(_host, '$_unencodedPath/$endpoint');
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

  /// Helper terpusat untuk request POST Multipart (upload file).
  Future<dynamic> postMultipart(
    String endpoint, {
    required Map<String, String> body,
    Map<String, File>? files,
  }) async {
    final uri = Uri.https(_host, '$_unencodedPath/$endpoint');
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

  /// Handler terpusat untuk memproses respons HTTP.
  dynamic _handleResponse(http.Response response) {
    // 204 No Content juga dianggap sukses
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty)
        return null; // Untuk response sukses tanpa body
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
