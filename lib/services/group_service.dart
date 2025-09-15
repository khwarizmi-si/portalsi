// lib/services/group_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../utils/secure_storage.dart'; // Sesuaikan path jika perlu

class GroupService {
  final String _baseUrl = 'https://api-new.portalsi.com/api';

  // --- FUNGSI YANG SUDAH ANDA BUAT ---

  /// Membuat grup baru dengan nama, deskripsi, dan gambar.
  Future<Map<String, dynamic>?> createGroup({
    required String name,
    String? description,
    File? avatar,
    File? cover,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

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
        await http.MultipartFile.fromPath('avatar', avatar.path,
            filename: path.basename(avatar.path)),
      );
    }
    if (cover != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cover', cover.path,
            filename: path.basename(cover.path)),
      );
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ================================================================
      // 👇 BLOK DEBUGGING - KITA AKAN MELIHAT APA YANG SEBENARNYA DIKIRIM SERVER
      // ================================================================
      debugPrint("--- [SERVER RESPONSE RECEIVED] ---");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("----------------------------------");
      // ================================================================

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Grup berhasil dibuat!');
        return responseData['group'] as Map<String, dynamic>?;
      } else {
        throw Exception(
            'Gagal membuat grup: ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error saat membuat grup: $e');
    }
  }

  // --- FUNGSI-FUNGSI BARU ---

  /// Mengambil detail spesifik dari sebuah grup berdasarkan ID.
  Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Gagal memuat detail grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat detail grup: $e');
    }
  }

  // Di dalam class GroupService

  /// Mengambil history percakapan dari sebuah grup.
  Future<List<Map<String, dynamic>>> getGroupMessages(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // Responsnya adalah list, jadi kita cast sebagai List<dynamic>
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal memuat pesan grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat pesan grup: $e');
    }
  }

  /// Mengirim pesan baru ke sebuah grup.
  Future<Map<String, dynamic>> sendGroupMessage({
    required int groupId,
    required String content,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          // Backend Anda mungkin butuh group_id di body juga, sesuaikan jika perlu
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Gagal mengirim pesan grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat mengirim pesan grup: $e');
    }
  }

  /// Menambah satu atau lebih anggota baru ke dalam grup.
  Future<void> addMembers(int groupId, List<int> userIds) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/members');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'user_ids': userIds}),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal menambah anggota: ${response.body}');
      }
      print('✅ Anggota berhasil ditambahkan ke grup $groupId');
    } catch (e) {
      throw Exception('Error saat menambah anggota: $e');
    }
  }

  /// Menghapus seorang anggota dari grup (biasanya dilakukan oleh admin).
  Future<void> removeMember(int groupId, int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/members/$userId');
    try {
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus anggota: ${response.body}');
      }
      print('✅ Anggota $userId berhasil dihapus dari grup $groupId');
    } catch (e) {
      throw Exception('Error saat menghapus anggota: $e');
    }
  }

  /// Untuk pengguna yang sedang login keluar dari grup.
  Future<void> leaveGroup(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/leave');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200) {
        throw Exception('Gagal keluar dari grup: ${response.body}');
      }
      print('✅ Berhasil keluar dari grup $groupId');
    } catch (e) {
      throw Exception('Error saat keluar dari grup: $e');
    }
  }

  /// Menghapus grup secara permanen (biasanya dilakukan oleh admin/pembuat grup).
  Future<void> deleteGroup(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId');
    try {
      final response = await http.delete(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus grup: ${response.body}');
      }
      print('✅ Grup $groupId berhasil dihapus');
    } catch (e) {
      throw Exception('Error saat menghapus grup: $e');
    }
  }
}
