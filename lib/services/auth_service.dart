import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:portal_si/utils/secure_storage.dart';

class AuthService {
  static const String baseUrl = 'https://yourapi.com';

  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await SecureStorage.saveToken(data['token']);
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      body: {'name': name, 'email': email, 'password': password},
    );
    return response.statusCode == 201;
  }

  Future<void> logout() async {
    final token = await SecureStorage.getToken();
    await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    await SecureStorage.clearToken();
  }

  Future<Map<String, dynamic>?> getUser() async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
