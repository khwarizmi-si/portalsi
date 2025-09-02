// lib/services/message_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/chat.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

class ChatService extends ApiService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  static const String _cacheKey = 'conversations_cache';

  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController =
  StreamController.broadcast();

  Stream<ChatMessage> get messages => _messageController.stream;

  void connect(String userId,
      {required User currentUser, required User recipient}) {
    if (_channel != null && _channel!.closeCode == null) {
      if (kDebugMode) print('🔌 WebSocket sudah terhubung untuk user $userId.');
      return;
    }

    try {
      final uri = Uri.parse('ws://10.0.2.2:8080?userId=$userId');
      _channel = WebSocketChannel.connect(uri);

      if (kDebugMode)
        print('✅ Berhasil terhubung ke WebSocket sebagai user $userId');

      _channel!.stream.listen(
            (data) {
          if (kDebugMode) print('📥 Pesan realtime diterima: $data');
          try {
            final Map<String, dynamic> messageData = jsonDecode(data);

            // [PERBAIKAN 1 DI SINI]
            // Tambahkan argumen currentUser dan recipient yang sudah ada
            final chatMessage = ChatMessage.fromJson(
              messageData,
              currentUser, // <-- Argumen kedua ditambahkan
              recipient,   // <-- Argumen ketiga ditambahkan
            );

            _messageController.add(chatMessage);
          } catch (e) {
            if (kDebugMode) print('⚠️ Gagal parsing pesan realtime: $e');
          }
        },
        onDone: () => print('❌ Koneksi WebSocket ditutup.'),
        onError: (error) => print('⚠️ Error pada WebSocket: $error'),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Gagal terhubung ke WebSocket: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    if (kDebugMode) print('🔌 Koneksi WebSocket diputus.');
  }

  void dispose() {
    _messageController.close();
    disconnect();
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

  Future<List<ChatMessage>> getConversation(User currentUser, User recipientUser) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final response = await http.get(
      Uri.parse('https://api-new.portalsi.com/api/messages/conversation/${recipientUser.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // Panggilan di sini sudah benar, tidak perlu diubah
      return data.map((json) => ChatMessage.fromJson(json, currentUser, recipientUser)).toList();
    } else {
      throw Exception('Gagal memuat percakapan dari API: ${response.statusCode}');
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
      return data.map((item) {
        if (item is Map<String, dynamic> && item.containsKey('type')) {
          if (item['type'] == 'group') {
            return GroupConversation.fromJson(item);
          } else if (item['type'] == 'user') {
            return UserConversation.fromJson(item);
          }
        }
        return null;
      }).whereType<Conversation>().toList();

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
        currentUser,     // <-- Argumen kedua ditambahkan
        recipient,       // <-- Argumen ketiga ditambahkan
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
        return data.map((item) {
          if (item is Map<String, dynamic> && item.containsKey('type')) {
            if (item['type'] == 'group') {
              return GroupConversation.fromJson(item);
            } else if (item['type'] == 'user') {
              return UserConversation.fromJson(item);
            }
          }
          return null;
        }).whereType<Conversation>().toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Gagal memuat cache: $e');
      }
    }
    return null;
  }
}