// lib/services/group_service.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:portal_si/models/user_model.dart'; // Pastikan import User model
import '../models/group_member_model.dart';
import '../models/group_model.dart';
import '../utils/secure_storage.dart';

class GroupService {
  final String _baseUrl = 'https://api-new.portalsi.com/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, dynamic>> getMutuals({int page = 1}) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$_baseUrl/mutuals?page=$page');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal memuat daftar mutuals: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // --- 👇 PERBAIKAN: Kembalikan fungsi ini agar me-return Map ---
  /// Mencari pengguna berdasarkan query dengan paginasi.
  Future<Map<String, dynamic>> searchUsers({int page = 1, required String query}) async {
    if (query.trim().isEmpty) {
      // Jika query kosong, kita panggil getMutuals saja
      return getMutuals(page: page);
    }
    try {
      final headers = await _getHeaders();
      // Asumsi endpoint search Anda adalah /users/search
      final uri = Uri.parse('$_baseUrl/users/search?page=$page&username=$query&fullname=$query');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        // Mengembalikan seluruh Map, karena formatnya sama dengan /mutuals
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal mencari pengguna: ${response.body}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan saat mencari pengguna: $e');
    }
  }

  Future<bool> updateGroup({
    required int groupId,
    required String name,
    String? description,
    File? avatarFile,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan.');
    }

    // Gunakan MultipartRequest karena ada kemungkinan upload file (avatar)
    final request = http.MultipartRequest(
      'POST', // Sesuai dokumentasi, gunakan POST
      Uri.parse('$_baseUrl/groups/$groupId'),
    );

    // Set header
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // Tambahkan fields ke form-data
    request.fields['name'] = name;
    if (description != null) {
      request.fields['description'] = description;
    }
    // Catatan: API Anda mungkin memerlukan '_method' = 'PUT' atau 'PATCH'
    // jika backend framework (spt. Laravel) menggunakannya untuk meniru method tsb.
    // request.fields['_method'] = 'PATCH'; // Contoh jika diperlukan

    // Tambahkan file avatar jika ada
    if (avatarFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatar', // 'name' dari field file di API
          avatarFile.path,
          contentType: MediaType('image', 'jpeg'), // Sesuaikan tipe konten jika perlu
        ),
      );
    }

    try {
      final response = await request.send();

      // Anda bisa membaca respons jika perlu
      // final responseBody = await response.stream.bytesToString();
      // print('Status Code: ${response.statusCode}');
      // print('Response Body: $responseBody');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Tangani error jaringan atau lainnya
      print('Error saat update grup: $e');
      return false;
    }
  }

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

  Future<List<Group>> getParentGroups() async {
    final token = await SecureStorage.getToken();
    final url = Uri.parse('$_baseUrl/special-groups');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Cetak status code dan body respons, baik sukses maupun gagal
    print('URL: $url');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Group.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load parent groups');
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

  Future<String> getUserRoleInGroup(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/groups/$groupId/role');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // --- [TAMBAHKAN BARIS INI UNTUK MELAKUKAN LOGGING] ---
      debugPrint("Respons dari API getUserRoleInGroup: ${response.body}");
      // --- BATAS TAMBAHAN ---

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);
        return decodedBody['role'] ?? 'member';
      } else {
        return 'member';
      }
    } catch (e) {
      debugPrint("Error getting user role: $e");
      return 'member';
    }
  }

  Future<bool> addMember(int groupId, int userId) async {
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
        // Body API Anda kemungkinan mengharapkan sebuah List,
        // jadi kita kirim satu ID di dalam list.
        body: jsonEncode({'user_ids': [userId]}),
      );

      // Sukses jika status code 200 (OK) atau 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Anggota dengan ID $userId berhasil ditambahkan ke grup $groupId');
        return true;
      } else {
        // Coba decode error message dari API jika ada
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Gagal menambah anggota.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Tangkap dan lempar kembali error agar bisa ditampilkan di UI
      throw Exception('Error saat menambah anggota: $e');
    }
  }

  /// Mengambil daftar anggota dari sebuah grup.
  // Future<List<User>> getGroupMembers(int groupId) async {
  //   final token = await SecureStorage.getToken();
  //   if (token == null) throw Exception('Token tidak ditemukan');
  //
  //   final url = Uri.parse('$_baseUrl/groups/$groupId/members');
  //   try {
  //     final response = await http.get(url, headers: {
  //       'Authorization': 'Bearer $token',
  //       'Accept': 'application/json',
  //     });
  //
  //     if (response.statusCode == 200) {
  //       final List<dynamic> data = jsonDecode(response.body)['data'];
  //       return data.map((json) => User.fromJson(json)).toList();
  //     } else {
  //       throw Exception('Gagal memuat anggota grup: ${response.body}');
  //     }
  //   } catch (e) {
  //     throw Exception('Error saat memuat anggota grup: $e');
  //   }
  // }

  Future<bool> _performPostAction(String endpoint) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    // Mengembalikan true jika request berhasil (status code 2xx)
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  /// Mengeluarkan anggota dari grup (DELETE)
  Future<bool> removeMember(int groupId, int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/groups/$groupId/members/$userId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  /// Menjadikan anggota sebagai admin
  Future<bool> promoteMember(int groupId, int userId) {
    return _performPostAction('/groups/$groupId/members/$userId/promote');
  }

  /// Menurunkan admin menjadi anggota biasa
  Future<bool> demoteMember(int groupId, int userId) {
    return _performPostAction('/groups/$groupId/members/$userId/demote');
  }

  /// Membisukan anggota
  Future<bool> muteMember(int groupId, int userId) {
    return _performPostAction('/groups/$groupId/members/$userId/mute');
  }

  /// Membatalkan bisu anggota
  Future<bool> unmuteMember(int groupId, int userId) {
    return _performPostAction('/groups/$groupId/members/$userId/unmute');
  }

  Future<Map<String, List<GroupMember>>> getGroupMembers(int groupId) async {
    final token = await SecureStorage.getToken();
    final url = Uri.parse('$_baseUrl/groups/$groupId/members');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Helper untuk mengubah list of JSON menjadi list of GroupMember
        List<GroupMember> parseMemberList(List<dynamic> jsonList) {
          return jsonList
              .map((item) => GroupMember.fromJson(item as Map<String, dynamic>))
              .toList();
        }

        // Parsing setiap kategori dari API
        final meList = parseMemberList(responseData['me'] ?? []);
        final followingList = parseMemberList(responseData['following'] ?? []);
        final notFollowingList = parseMemberList(responseData['not_following'] ?? []);

        // Kembalikan dalam bentuk Map agar mudah diakses di UI
        return {
          'me': meList,
          'following': followingList,
          'not_following': notFollowingList,
        };
      } else {
        throw Exception('Gagal memuat anggota grup: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<bool> addMemberByIdentifier({required int groupId, required String identifier}) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Autentikasi gagal: Token tidak ditemukan.');
    }

    final url = Uri.parse('$_baseUrl/groups/$groupId/members');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Body ini sudah sesuai dengan format yang Anda inginkan
        body: jsonEncode({
          'identifier': identifier, // Akan berisi username, misal: "faisal"
          'role': 'member'
        }),
      );

      debugPrint("Respons dari API addMember (identifier: $identifier): ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;

    } catch (e) {
      debugPrint("Error saat menambahkan anggota '$identifier': $e");
      return false;
    }
  }

  /// Mengambil history percakapan dari sebuah grup.
  Future<Map<String, dynamic>> getGroupMessages(int groupId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // [MODIFIKASI] URL disederhanakan, tidak ada lagi query parameter '?page='
    final url = Uri.parse('$_baseUrl/groups/$groupId/messages');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // Kembalikan seluruh body yang sudah di-decode, ini sudah sesuai
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Gagal memuat pesan grup: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saat memuat pesan grup: $e');
    }
  }

  /// Mengirim pesan baru ke sebuah grup menggunakan form-data.
  Future<Map<String, dynamic>?> sendMessage({
    required int groupId,
    required String content,
    int? replyToId,
  }) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$_baseUrl/groups/$groupId/messages');

    final body = {
      'content': content,
      // Menggunakan kunci 'reply_to' sesuai konfirmasi
      if (replyToId != null) 'reply_to': replyToId,
    };

    // Logging Payload
    log('API Request: POST $url');
    log('Payload Sent: ${jsonEncode(body)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      // Logging Response Code dan Body
      log('API Response Status: ${response.statusCode}');
      log('API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>; // Pastikan ini Map
      } else {
        // Jika terjadi error (misalnya 4xx atau 5xx), throw exception dengan body.
        final responseBody = response.body.isNotEmpty ? response.body : 'No response body.';
        log('API Error: $responseBody');
        throw Exception('Gagal mengirim pesan. Status: ${response.statusCode}');
      }
    } catch (e) {
      log('Error saat mengirim pesan: $e');
      throw Exception('Error koneksi saat mengirim pesan: $e');
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
        final decodedBody = jsonDecode(response.body);
        // ✨ PERBAIKAN: Gunakan ?? [] untuk menjamin nilai tidak null.
        final List<dynamic> data = decodedBody['messages'] ?? [];
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