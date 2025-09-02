// lib/services/group_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../utils/secure_storage.dart';

class GroupService {
  final String _baseUrl = 'https://api-new.portalsi.com/api';

  // Fungsi untuk membuat grup baru
  Future<Map<String, dynamic>?> createGroup({
    required String name,
    String? description,
    File? avatar,
    File? cover,
  }) async {
    final token = await SecureStorage.getToken();
    final url = Uri.parse('$_baseUrl/groups');
    var request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    request.fields['name'] = name;
    if (description != null) {
      request.fields['description'] = description;
    }
    if (avatar != null) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', avatar.path, filename: path.basename(avatar.path)),
      );
    }
    if (cover != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cover', cover.path, filename: path.basename(cover.path)),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Grup berhasil dibuat!');
        // [PERUBAHAN] Mencetak body respons ke konsol
        print('📦 Response Body: ${response.body}');

        final responseData = jsonDecode(response.body);
        // [PERUBAHAN] Mengembalikan data grup dari respons
        return responseData['group'] as Map<String, dynamic>?;
      } else {
        print('Gagal membuat grup: ${response.body}');
        return null; // Mengembalikan null jika gagal
      }
    } catch (e) {
      print('Error saat membuat grup: $e');
      return null; // Mengembalikan null jika terjadi error
    }
  }
}