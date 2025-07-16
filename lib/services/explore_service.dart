import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/secure_storage.dart';

class ExploreService {
  final baseUrl = 'https://your-api.com';

  Future<List<dynamic>> getExplorePosts() async {
    final token = await SecureStorage.getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/explore'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('Gagal memuat postingan eksplorasi');
    }
  }
}
