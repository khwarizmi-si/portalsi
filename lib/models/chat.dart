// lib/models/chat_models.dart
import 'dart:io';

import 'user_model.dart';

// Enum untuk status pesan, berguna untuk optimistic UI
enum MessageStatus { sending, sent, failed, read }

// Enum untuk tipe pesan
enum MessageType { text, image, video, file, voice }

// ... (Kelas Conversation tetap sama seperti sebelumnya) ...
class Conversation {
  final User user;
  final String lastMessage;
  final String lastMessageTime;
  final bool isRead;
  final int unreadCount;

  Conversation({
    required this.user,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isRead = true,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      user: User.fromJson(json['user']),
      lastMessage: json['last_message']?['content'] ?? '',
      lastMessageTime: json['last_message']?['time_ago'] ?? '',
      isRead: json['is_read'] ?? true,
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

/// Model untuk satu bubble pesan di dalam ChatRoomPage
class ChatMessage {
  final int id;
  final String? text;
  final MessageType type;
  final User sender; // Siapa pengirimnya (objek User lengkap)
  final DateTime timestamp;
  MessageStatus status;

  final String? remoteUrl;
  final String? fileName;
  final File? localFile;

  ChatMessage({
    required this.id,
    this.text,
    required this.type,
    required this.sender,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.remoteUrl,
    this.fileName,
    this.localFile,
  });

  // ✅ FACTORY FROMJSON YANG DIPERBARUI
  // Sekarang ia menerima currentUser dan recipient untuk menentukan objek sender
  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required User currentUser, required User recipient}) {
    // Tentukan siapa pengirimnya berdasarkan sender_id
    final sender =
        (json['sender_id'] == currentUser.id) ? currentUser : recipient;

    MessageType messageType = MessageType.text;
    if (json['media_url'] != null) {
      // Anda bisa menambahkan logika lebih canggih di sini
      messageType = MessageType.image;
    }

    return ChatMessage(
      id: json['message_id'],
      sender: sender, // Masukkan objek User yang sudah ditentukan
      text: json['content'],
      type: messageType,
      timestamp: DateTime.parse(json['sent_at']),
      remoteUrl: json['media_url'],
      status:
          (json['is_read'] ?? false) ? MessageStatus.read : MessageStatus.sent,
    );
  }
}
