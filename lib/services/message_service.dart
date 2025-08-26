// lib/services/chat_service.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:portal_si/models/user_model.dart';
// Ganti import lama dengan yang baru
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../models/chat.dart'; // Sesuaikan path model Anda
import 'api_service.dart';

class ChatService extends ApiService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  // Gunakan IO.Socket dari pustaka socket_io_client
  IO.Socket? _socket;

  // StreamController tetap berguna untuk UI
  final StreamController<ChatMessage> _privateMessageController =
      StreamController.broadcast();
  // final StreamController<GroupChatMessage> _groupMessageController = StreamController.broadcast();

  Stream<ChatMessage> get privateMessages => _privateMessageController.stream;
  // Stream<GroupChatMessage> get groupMessages => _groupMessageController.stream;

  /// Menghubungkan ke server Socket.IO dan mendaftarkan user.
  void connect(String userId) {
    if (_socket?.connected ?? false) {
      if (kDebugMode) print('🔌 Socket sudah terhubung.');
      return;
    }

    try {
      // Ganti dengan URL server Anda. 'autoConnect: false' agar kita bisa menambahkan listener dulu.
      _socket = IO.io('http://10.0.2.2:8080', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      // === MENDAFTARKAN LISTENER EVENT DARI SERVER ===

      // Listener saat koneksi berhasil
      _socket!.onConnect((_) {
        if (kDebugMode) print('✅ Berhasil terhubung ke WebSocket server');
        // KIRIM EVENT 'register' SETELAH TERHUBUNG
        _socket!.emit('register', userId);
      });

      // Listener untuk pesan pribadi baru
      _socket!.on('new_private_message', (data) {
        if (kDebugMode) print('📥 Pesan pribadi diterima: $data');
        // Di sini Anda perlu mengonversi `data` menjadi objek ChatMessage
        // final message = ChatMessage.fromJson(data, ...);
        // _privateMessageController.add(message);
      });

      // Listener untuk pesan grup baru
      _socket!.on('new_group_message', (data) {
        if (kDebugMode) print('📥 Pesan grup diterima: $data');
        // Logika serupa untuk pesan grup
        // final message = GroupChatMessage.fromJson(data);
        // _groupMessageController.add(message);
      });

      _socket!.onDisconnect((_) => print('❌ Koneksi WebSocket terputus'));
      _socket!.onError((error) => print('⚠️ Error pada WebSocket: $error'));

      // Mulai koneksi
      _socket!.connect();
    } catch (e) {
      if (kDebugMode) print('❌ Gagal terhubung ke WebSocket: $e');
    }
  }

  /// Mengirim pesan pribadi melalui WebSocket.
  void sendPrivateMessage({
    required String senderId,
    required String receiverId,
    required String content,
    String? mediaUrl,
  }) {
    _socket?.emit('private_message', {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'media_url': mediaUrl,
    });
  }

  // === FUNGSI UNTUK GROUP CHAT ===

  void joinGroup(String groupId) {
    _socket?.emit('join_group', groupId);
  }

  void sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    String? mediaUrl,
    List<String>? mentions,
  }) {
    _socket?.emit('group_message', {
      'group_id': groupId,
      'sender_id': senderId,
      'content': content,
      'media_url': mediaUrl,
      'mentions': mentions,
    });
  }

  /// Memutuskan koneksi WebSocket.
  void disconnect() {
    _socket?.disconnect();
    if (kDebugMode) print('🔌 Koneksi WebSocket diputus.');
  }

  void dispose() {
    _privateMessageController.close();
    // _groupMessageController.close();
    disconnect();
  }

  /// Mengambil riwayat percakapan dengan user tertentu.
  /// GET /api/messages/conversation/{user_id}
  Future<List<ChatMessage>> getConversation(
      User currentUser, User recipient) async {
    try {
      final List<dynamic> data =
          await get('messages/conversation/${recipient.id}');

      return data
          .map((item) => ChatMessage.fromJson(
                item,
                currentUser: currentUser,
                recipient: recipient,
              ))
          .toList();
    } catch (e) {
      print("Error fetching conversation: $e");
      rethrow;
    }
  }

  /// Mengambil semua percakapan user
  /// GET /api/messages/chat-list
  Future<List<Conversation>> getAllConversations() async {
    try {
      final List<dynamic> data = await get('messages/chat-list');
      // Tidak ada perubahan di sini, karena logika parsing sudah dipindah ke model
      return data.map((item) => Conversation.fromJson(item)).toList();
    } catch (e) {
      print("Error fetching all conversations: $e");
      rethrow;
    }
  }

  /// Mengirim pesan ke user lain
  /// POST /api/messages/send
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

      // Setelah mengirim via API, pesan akan kembali via WebSocket.
      // Kita tetap return respons API untuk konfirmasi pengiriman awal.
      return ChatMessage.fromJson(
        response['data'], // Sesuaikan dengan struktur respons API Anda
        currentUser: currentUser,
        recipient: recipient,
      );
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

  // ... (Metode deleteMessage dan markAsRead tetap sama) ...

  /// Menghapus pesan tertentu
  /// DELETE /api/messages/{id}
  Future<void> deleteMessage(int messageId) async {
    try {
      await delete('messages/$messageId');
    } catch (e) {
      print("Error deleting message: $e");
      rethrow;
    }
  }

  /// Menandai pesan sebagai sudah dibaca
  /// PATCH /api/messages/{id}/read
  Future<void> markAsRead(int messageId) async {
    try {
      await patch('messages/$messageId/read');
    } catch (e) {
      print("Error marking message as read: $e");
      rethrow;
    }
  }
  // Fungsi API untuk mengambil riwayat chat bisa tetap di sini
  // Future<List<ChatMessage>> getConversation(...) { ... }
}
