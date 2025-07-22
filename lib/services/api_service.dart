import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const baseUrl =
      'https://api.portalsi.com/api'; // ganti sesuai API kamu

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
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
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }
}
