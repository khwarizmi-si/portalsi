// lib/services/chat_service.dart
import 'dart:io';
import '../models/chat.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ChatService extends ApiService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

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
  /// GET /api/messages/conversations
  Future<List<Conversation>> getAllConversations() async {
    try {
      final List<dynamic> data = await get('messages/conversations');

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
    required User currentUser, // tambahkan
    required User recipient, // tambahkan
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

      return ChatMessage.fromJson(
        response,
        currentUser: currentUser, // wajib isi
        recipient: recipient, // wajib isi
      );
    } catch (e) {
      print("Error sending message: $e");
      rethrow;
    }
  }

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
