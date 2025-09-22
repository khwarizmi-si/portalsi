// lib/services/group_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:portal_si/models/user_model.dart'; // Pastikan import User model
import '../utils/secure_storage.dart';

class GroupService {
  final String _baseUrl = 'https://api-new.portalsi.com/api';

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
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Grup berhasil dibuat!');
        return responseData['group'] as Map<String, dynamic>?;
      } else {
        throw Exception(
            'Gagal membuat grup: ${responseData['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error saat membuat grup: $e');
    }
  }

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
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map<String, dynamic> && decodedBody.containsKey('group')) {
          return decodedBody['group'] as Map<String, dynamic>;
        } else {
          throw Exception("Respons API untuk getGroupDetails tidak memiliki key 'group'.");
        }
      } else {
        throw Exception('Gagal memuat detail grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat detail grup: $e');
    }
  }

  /// Mengambil daftar anggota dari sebuah grup.
  Future<List<User>> getGroupMembers(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/members');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat anggota grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat anggota grup: $e');
    }
  }

  Future<bool> addMemberByIdentifier({
    required int groupId,
    required String identifier,
    String role = 'member',
  }) async {
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
        body: jsonEncode({
          'identifier': identifier,
          'role': role,
        }),
      );

      // API yang sukses biasanya mengembalikan 200 (OK) atau 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Anggota $identifier berhasil ditambahkan ke grup $groupId');
        return true;
      } else {
        debugPrint('Gagal menambah anggota: ${response.body}');
        return false;
      }
    } catch (e) {
      throw Exception('Error saat menambah anggota: $e');
    }
  }

  /// Mengambil history percakapan dari sebuah grup.
  Future<Map<String, dynamic>> getGroupMessages(int groupId, {int? page}) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // Jika page null, jangan tambahkan parameter query
    final url = Uri.parse('$_baseUrl/groups/$groupId/messages${page != null ? '?page=$page' : ''}');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // Kembalikan seluruh body yang sudah di-decode
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal memuat pesan grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat pesan grup: $e');
    }
  }

  /// Mengirim pesan baru ke sebuah grup menggunakan form-data.
  Future<Map<String, dynamic>> sendGroupMessage({
    required int groupId,
    required String content,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages');
    var request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['content'] = content;

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['data'] as Map<String, dynamic>;
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
      debugPrint('✅ Anggota berhasil ditambahkan ke grup $groupId');
    } catch (e) {
      throw Exception('Error saat menambah anggota: $e');
    }
  }

  /// Menghapus seorang anggota dari grup.
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
      debugPrint('✅ Anggota $userId berhasil dihapus dari grup $groupId');
    } catch (e) {
      throw Exception('Error saat menghapus anggota: $e');
    }
  }


  Future<List<Map<String, dynamic>>> getUnreadGroupMessages(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages/unread');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['messages'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Gagal memuat pesan belum dibaca: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat pesan belum dibaca: $e');
    }
  }

  /// [BARU] Menandai satu pesan sebagai sudah dibaca.
  Future<bool> markMessageAsRead(int groupId, int messageId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages/$messageId/read');
    try {
      final response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error markMessageAsRead: $e');
      return false;
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
      debugPrint('✅ Berhasil keluar dari grup $groupId');
    } catch (e) {
      throw Exception('Error saat keluar dari grup: $e');
    }
  }

  /// Menghapus grup secara permanen.
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
      debugPrint('✅ Grup $groupId berhasil dihapus');
    } catch (e) {
      throw Exception('Error saat menghapus grup: $e');
    }
  }
}