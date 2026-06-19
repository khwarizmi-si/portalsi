// lib/services/message_service.dart

import 'package:portal_si/config/api_endpoint.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class ChatService extends ApiService {

  ChatService._internal(); // Tetap sebagai Singleton

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  static const String _cacheKey = 'conversations_cache';

  // --- 👇 PENAMBAHAN UNTUK MEMPERBAIKI ERROR 'sendStoryResponse' 👇 ---
  Future<ChatMessage> sendStoryResponse({
    required int receiverId,
    required String content,
    required int storyId,
    required String? respondedMediaUrl,
    required User currentUser,
    required User recipient,
  }) async {
    // 1. LOG SAAT FUNGSI DIPANGGIL
    log(
      'Mencoba mengirim story response ke user ID: $receiverId dengan konten: "$content"',
      name: 'ChatService',
    );

    try {
      final body = {
        'receiver_id': receiverId.toString(),
        'content': content,
        'is_story_response': '1',
        'story_id': storyId.toString(),
        'responded_media_url': respondedMediaUrl ?? '',
      };

      final response = await postMultipart(
        'messages/send',
        body: body,
      );

      // 2. LOG SAAT BERHASIL (YANG SUDAH ADA SEBELUMNYA)
      log(
        '✅ SUCCESS: Respons API untuk sendStoryResponse:\n${jsonEncode(response)}',
        name: 'ChatService',
      );

      return ChatMessage.fromJson(
        response['data'],
        currentUser,
        recipient,
      );
    } catch (e, stackTrace) {
      // 3. LOG SAAT TERJADI ERROR
      log(
        '❌ ERROR: Gagal saat mengirim story response.',
        name: 'ChatService',
        error: e, // Mencetak objek error
        stackTrace: stackTrace, // Mencetak jejak error untuk debugging mendalam
      );
      rethrow; // Tetap lemparkan error agar bisa ditangani di level controller
    }
  }
  // --- 👆 AKHIR PERBAIKAN 👆 ---


  Future<List<String>> getActiveConversationChannels() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    // Ganti endpoint ini dengan endpoint API Anda yang sebenarnya
    final url = Uri.parse('${ApiEndpoints.apiUrl}/messages/channels');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Asumsi API mengembalikan list of strings ["channel_name_1", "channel_name_2"]
        return List<String>.from(data);
      } else {
        throw Exception("Gagal mengambil channel: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error getActiveConversationChannels: $e");
      return []; // Kembalikan list kosong jika gagal
    }
  }

  Future<void> _saveConversationsToCache(String jsonString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonString);
      if (kDebugMode) {
        print('💾 Cache percakapan berhasil disimpan.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Gagal menyimpan cache: $e');
      }
    }
  }

  Future<List<ChatMessage>> getConversation(
      User currentUser, User recipientUser) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final response = await http.get(
      Uri.parse(
          '${ApiEndpoints.apiUrl}/messages/conversation/${recipientUser.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Panggilan di sini sudah benar, tidak perlu diubah
      return data
          .map((json) => ChatMessage.fromJson(json, currentUser, recipientUser))
          .toList();
    } else {
      throw Exception(
          'Gagal memuat percakapan dari API: ${response.statusCode}');
    }
  }

  Future<List<Conversation>> getAllConversations() async {
    try {
      // 1. Ambil data mentah (sebagai List<dynamic>) dari API
      final List<dynamic> data = await get('messages/chat-list');

      // 2. Ubah data mentah menjadi string JSON untuk disimpan di cache
      final jsonString = jsonEncode(data);
      await _saveConversationsToCache(jsonString);

      // 3. Parse data mentah menjadi List<Conversation> untuk dikembalikan ke controller
      return data
          .map((item) {
        if (item is Map<String, dynamic> && item.containsKey('type')) {
          if (item['type'] == 'group') {
            return GroupConversation.fromJson(item);
          } else if (item['type'] == 'user') {
            return UserConversation.fromJson(item);
          }
        }
        return null;
      })
          .whereType<Conversation>()
          .toList();
    } catch (e) {
      print("Error fetching all conversations from API: $e");
      rethrow; // Lemparkan lagi error agar controller bisa menanganinya
    }
  }

  Future<ChatMessage> sendMessage({
    required int receiverId,
    required String content,
    required User currentUser,
    required User recipient,
    File? media,
  }) async {
    try {
      final body = {
        'receiver_id': receiverId.toString(),
        'content': content,
      };

      final response = await postMultipart(
        'messages/send',
        body: body,
        files: media != null ? {'media': media} : null,
      );

      // [PERBAIKAN 2 DI SINI]
      // Tambahkan argumen currentUser dan recipient yang sudah ada
      return ChatMessage.fromJson(
        response['data'], // Sesuaikan dengan struktur respons API Anda
        currentUser, // <-- Argumen kedua ditambahkan
        recipient, // <-- Argumen ketiga ditambahkan
      );
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await delete('messages/$messageId');
    } catch (e) {
      print("Error deleting message: $e");
      rethrow;
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      await patch('messages/$messageId/read');
    } catch (e) {
      print("Error marking message as read: $e");
      rethrow;
    }
  }

  Future<void> updateConversationCacheWithNewMessage(ChatMessage newMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      // Jika cache belum ada sama sekali, buat cache baru dengan satu percakapan ini.
      if (jsonString == null) {
        final newConversation = {
          "type": "user",
          "user": newMessage.sender.toJson(), // Asumsi ada method toJson() di model User
          "last_message": newMessage.toJson(),
          "unread_count": 0,
        };
        await _saveConversationsToCache(jsonEncode([newConversation]));
        debugPrint("✅ Cache baru dibuat dengan pesan pertama dari user ID: ${newMessage.sender.id}");
        return;
      }

      // Jika cache sudah ada, lanjutkan logika update/tambah.
      List<dynamic> conversationsJson = jsonDecode(jsonString);
      final otherUserId = newMessage.sender.id;
      final int conversationIndex = conversationsJson.indexWhere((conv) =>
      conv['type'] == 'user' &&
          conv['user'] != null &&
          conv['user']['id'] == otherUserId);

      if (conversationIndex != -1) {
        // [Logika Lama] Jika percakapan DITEMUKAN (update).
        var conversationToUpdate = conversationsJson.removeAt(conversationIndex);
        conversationToUpdate['last_message'] = newMessage.toJson();
        conversationToUpdate['unread_count'] = 0;
        conversationsJson.insert(0, conversationToUpdate);
        debugPrint("✅ Cache percakapan berhasil diupdate dengan pesan baru dari user ID: $otherUserId");

      } else {
        // [BARU] Logika jika percakapan TIDAK ditemukan (chat baru).
        debugPrint("Percakapan dengan user ID $otherUserId tidak ditemukan di cache. Membuat entri baru...");
        final newConversation = {
          "type": "user",
          "user": newMessage.sender.toJson(),
          "last_message": newMessage.toJson(),
          "unread_count": 0,
        };
        // Tambahkan percakapan baru ini ke paling atas daftar.
        conversationsJson.insert(0, newConversation);
        debugPrint("✅ Entri percakapan baru untuk user ID $otherUserId berhasil ditambahkan ke cache.");
      }

      // Simpan kembali cache yang sudah diperbarui.
      await _saveConversationsToCache(jsonEncode(conversationsJson));

    } catch (e) {
      debugPrint("⚠️ Gagal mengupdate cache percakapan dengan pesan baru: $e");
    }
  }

  /// [BARU] Mengambil daftar percakapan dari cache lokal.
  /// Mengembalikan null jika tidak ada cache atau terjadi error.
  Future<List<Conversation>?> getConversationsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);

      if (jsonString != null) {
        final List<dynamic> data = jsonDecode(jsonString);
        if (kDebugMode) {
          print('📦 Cache percakapan berhasil dimuat.');
        }
        // Logika parsing yang sama seperti sebelumnya
        return data
            .map((item) {
          if (item is Map<String, dynamic> && item.containsKey('type')) {
            if (item['type'] == 'group') {
              return GroupConversation.fromJson(item);
            } else if (item['type'] == 'user') {
              return UserConversation.fromJson(item);
            }
          }
          return null;
        })
            .whereType<Conversation>()
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Gagal memuat cache: $e');
      }
    }
    return null;
  }
}