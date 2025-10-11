// lib/models/group_message_model.dart

import 'package:portal_si/models/user_model.dart';

import 'chat.dart';

enum MessageStatus { sending, sent, failed }
enum MessageType { userMessage, memberAddedNotification }


class ReplyInfo {
  final int id;
  final String content;
  final User sender;

  ReplyInfo({required this.id, required this.content, required this.sender});

  factory ReplyInfo.fromJson(Map<String, dynamic> json) {
    return ReplyInfo(
      id: json['id'],
      content: json['content'],
      // Panggil User.fromJson untuk objek sender
      sender: User.fromJson(json['sender']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toJson(), // Memanggil toJson dari objek User
    };
  }
}

class GroupMessage {
  final MessageType type;
  final User? addedByUser; // Siapa yang menambahkan
  final User? addedUser;
  final int id;
  final String content;
  final User sender;
  final DateTime sentAt;
  MessageStatus status;
  final ReplyInfo? repliedTo; // <-- TAMBAHKAN INI

  GroupMessage({
    required this.id,
    required this.sentAt,
    // Jadikan opsional untuk notifikasi
    this.content = '',
    User? sender,
    // Default-kan ke tipe pesan pengguna
    this.type = MessageType.userMessage,
    this.addedByUser,
    this.addedUser,
    this.status = MessageStatus.sent,
    this.repliedTo,
  }) : sender = sender ?? User(id: 0, username: 'system');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.toJson(),
      'sent_at': sentAt.toIso8601String(),
      // [PERBAIKAN] Pastikan key-nya adalah 'reply_to', bukan 'replied_to'
      'reply_to': repliedTo?.toJson(),
    };
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // [MODIFIKASI] Tambahkan logika untuk event 'member_added'
    if (json['event_type'] == 'member_added') {
      return GroupMessage(
        // Kita bisa gunakan timestamp atau buat ID unik dari timestamp
        id: DateTime.parse(json['timestamp']).millisecondsSinceEpoch,
        sentAt: DateTime.parse(json['timestamp']),
        type: MessageType.memberAddedNotification,
        // Isi dengan data dari event
        addedByUser: User.fromJson(json['adder']),
        addedUser: User.fromJson(json['added_user']),
      );
    }

    // Logika lama untuk pesan biasa
    return GroupMessage(
      type: MessageType.userMessage,
      id: json['id'],
      content: json['content'],
      sender: User.fromJson(json['sender']),
      sentAt: DateTime.parse(json['sent_at']),
      status: MessageStatus.sent,
      repliedTo: json['reply_to'] != null
          ? ReplyInfo.fromJson(json['reply_to'])
          : null,
    );
  }
}