// lib/models/group_message_model.dart

import 'package:portal_si/models/user_model.dart';

enum MessageStatus { sending, sent, failed }

class GroupMessage {
  final int id;
  final String content;
  final User sender;
  final DateTime sentAt;
  MessageStatus status;

  GroupMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });

  // --- [TAMBAHAN BARU] Metode toJson untuk Caching ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      // Penting: Simpan data sender sebagai Map juga
      'sender': sender.toJson(),
      'sent_at': sentAt.toIso8601String(),
      // Status tidak perlu disimpan, karena saat di-load dari cache,
      // kita akan anggap statusnya 'sent'
    };
  }
  // --- BATAS TAMBAHAN ---

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      content: json['content'],
      sender: User.fromJson(json['sender']),
      sentAt: DateTime.parse(json['sent_at']),
      // Saat di-load dari API atau cache, statusnya pasti 'sent'
      status: MessageStatus.sent,
    );
  }
}