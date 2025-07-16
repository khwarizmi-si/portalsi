import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/secure_storage.dart';
import 'package:mime/mime.dart';

class UploadService {
  final baseUrl = 'https://your-api.com';

  Future<String> uploadMedia(File file) async {
    final token = await SecureStorage.getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));

    final mimeType = lookupMimeType(file.path)?.split('/');
    if (mimeType == null || mimeType.length != 2) {
      throw Exception('Tipe file tidak dikenali');
    }

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType(mimeType[0], mimeType[1]),
      ),
    );

    final streamedResponse = await request.send();
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['url']; // pastikan API mengembalikan key ini
    } else {
      throw Exception('Gagal mengunggah media');
    }
  }
}
