import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/utils/secure_storage.dart';

class AuthService {
  static const String baseUrl = 'https://api.portalsi.com/api';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: {'email': email, 'password': password},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await SecureStorage.saveToken(data['token']);
        await SecureStorage.saveUserId(data['user']['user_id'].toString());
        return {
          'success': true,
          'message': 'Login berhasil',
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        final data = json.decode(response.body);
        String message = 'Login gagal';

        if (data is Map<String, dynamic>) {
          final errors = data.map(
            (key, value) => MapEntry(
              key,
              (value is List && value.isNotEmpty) ? value.first : '',
            ),
          );
          final allErrors = errors.values.where((e) => e != '').toList();
          if (allErrors.isNotEmpty) message = allErrors.first;
        }

        return {'success': false, 'message': message};
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  Future<Map<String, dynamic>> register(
    String username,
    String fullName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {
        'username': username,
        'full_name': fullName,
        'email': email,
        'password': password,
      },
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201) {
      return {'success': true};
    } else {
      return {'success': false, 'errors': data};
    }
  }

  Future<void> logout() async {
    final token = await SecureStorage.getToken();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await SecureStorage.deleteToken();
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final token = await SecureStorage.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Bisa log error atau handle unauthorized (misalnya 401)
        return null;
      }
    } catch (e) {
      // Tangani error seperti timeout, koneksi, atau parsing
      return null;
    }
  }
}
