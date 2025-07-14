import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const baseUrl = 'https://example.com/api'; // Ganti dengan URL aslinya

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login.php'),
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json;
    } else {
      return null;
    }
  }
}
