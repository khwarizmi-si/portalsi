// lib/services/message_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../utils/secure_storage.dart';

class MessageService {
  static const String _baseUrl = 'https://api.portalsi.com/api';

  Future<Map<String, String>> _getHeaders() async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token not found');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<List<MessageModel>> getConversation(int userId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/messages/conversation/$userId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['messages'];
      return data.map((json) => MessageModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load messages');
    }
  }

  Future<MessageModel> sendMessage(int receiverId, String message) async {
    final headers = await _getHeaders();
    final body = json.encode({
      'receiver_id': receiverId,
      'message': message,
    });
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 201) {
      return MessageModel.fromJson(json.decode(response.body)['message']);
    } else {
      throw Exception('Failed to send message');
    }
  }

  Future<void> deleteMessage(int messageId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$_baseUrl/messages/$messageId'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete message');
    }
  }

  Future<void> markMessageAsRead(int messageId) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$_baseUrl/messages/$messageId/read'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      // Tidak melempar exception agar tidak mengganggu UI jika gagal
      print('Failed to mark message as read');
    }
  }
}
