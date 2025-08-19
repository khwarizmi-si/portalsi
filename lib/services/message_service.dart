// lib/services/chat_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; // BARU: Import WebSocket

import '../models/chat.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ChatService extends ApiService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  // ===============================================================
  // BARU: Properti untuk WebSocket
  // ===============================================================
  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController =
      StreamController.broadcast();

  /// Stream ini akan didengarkan oleh UI (halaman chat) untuk pesan realtime.
  Stream<ChatMessage> get messages => _messageController.stream;
  // ===============================================================

  /// BARU: Menghubungkan ke server WebSocket.
  void connect(String userId,
      {required User currentUser, required User recipient}) {
    if (_channel != null && _channel!.closeCode == null) {
      if (kDebugMode) print('🔌 WebSocket sudah terhubung untuk user $userId.');
      return;
    }

    try {
      // GANTI ALAMAT IP SESUAI KONDISI ANDA (Emulator: 10.0.2.2, Device Fisik: IP Lokal)
      final uri = Uri.parse('ws://10.0.2.2:8080?userId=$userId');
      _channel = WebSocketChannel.connect(uri);

      if (kDebugMode)
        print('✅ Berhasil terhubung ke WebSocket sebagai user $userId');

      _channel!.stream.listen(
        (data) {
          if (kDebugMode) print('📥 Pesan realtime diterima: $data');
          try {
            final Map<String, dynamic> messageData = jsonDecode(data);

            // Konversi data JSON dari WebSocket menjadi objek ChatMessage
            final chatMessage = ChatMessage.fromJson(
              messageData,
              currentUser: currentUser,
              recipient: recipient,
            );

            // Tambahkan pesan baru ke stream controller agar UI bisa menerimanya
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

  /// BARU: Memutuskan koneksi WebSocket.
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    if (kDebugMode) print('🔌 Koneksi WebSocket diputus.');
  }

  /// BARU: Membersihkan StreamController (panggil saat user logout).
  void dispose() {
    _messageController.close();
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
}
