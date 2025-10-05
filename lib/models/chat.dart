// lib/models/chat.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:portal_si/models/group_model.dart';
import 'user_model.dart'; // Pastikan import model User sudah ada

// Enum untuk tipe pesan
enum MessageType { text, image, video, file }

// Enum untuk status pengiriman pesan
enum MessageStatus { sending, sent, read, failed }

//================================================================
// MODEL UNTUK PESAN INDIVIDUAL (TIDAK PERLU DIUBAH)
//================================================================
class ChatMessage {
  final int id;
  final String? text;
  final MessageType type;
  final User sender;
  final User recipient;
  final DateTime timestamp;
  MessageStatus status;
  final String? mediaUrl;
  String? localMediaPath;
  final String? mediaType;
  final File? localFile;
  final ValueNotifier<double>? uploadProgress;
  final Uint8List? localBytes; // <-- TAMBAHKAN PROPERTI BARU INI

  ChatMessage({
    required this.id,
    this.text,
    required this.type,
    required this.sender,
    required this.recipient,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.mediaUrl,
    this.mediaType,
    this.localFile,
    this.uploadProgress,
    this.localMediaPath,
    this.localBytes, // <-- TAMBAHKAN DI CONSTRUCTOR JUGA
  });

  // Sisa dari class ChatMessage (toJson, fromJson) tidak perlu diubah.
  // Cukup salin-tempel dari kode Anda yang sudah ada.
  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'content': text,
      'media_url': mediaUrl,
      'local_media_path': localMediaPath,
      'sender_id': sender.id,
      'receiver_id': recipient.id,
      'sent_at': timestamp.toIso8601String(),
      'is_read': status == MessageStatus.read,
      'sender_data': sender.toJson(),
      'recipient_data': recipient.toJson(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      [User? currentUser, User? recipientUser]) {
    User sender, recipient;
    if (json.containsKey('sender_data') && json.containsKey('recipient_data')) {
      sender = User.fromJson(json['sender_data']);
      recipient = User.fromJson(json['recipient_data']);
    }
    else if (currentUser != null && recipientUser != null) {
      final bool isFromCurrentUser = json['sender_id'] == currentUser.id;
      sender = isFromCurrentUser ? currentUser : recipientUser;
      recipient = isFromCurrentUser ? recipientUser : currentUser;
    } else {
      throw ArgumentError(
          'fromJson requires either full sender/recipient data or currentUser/recipientUser context.');
    }

    final bool hasMedia = json['media_url'] != null;
    final MessageType type = hasMedia ? MessageType.image : MessageType.text;

    return ChatMessage(
      id: json['message_id'],
      sender: sender,
      recipient: recipient,
      text: json['content'],
      mediaUrl: json['media_url'],
      localMediaPath: json['local_media_path'],
      timestamp: DateTime.parse(json['sent_at']),
      status:
      (json['is_read'] ?? false) ? MessageStatus.read : MessageStatus.sent,
      type: type,
    );
  }
}

//================================================================
// MODEL BARU UNTUK HALAMAN DAFTAR PERCAKAPAN (FLEKSIBEL)
//================================================================

/// Abstract class sebagai blueprint untuk semua jenis percakapan.
/// Ini memungkinkan UI (seperti _ConversationTile) untuk menampilkan data
/// tanpa perlu tahu apakah itu percakapan user atau grup.
abstract class Conversation {
  final int id;
  final String lastMessage;
  final DateTime? timestamp; // Dijadikan nullable untuk grup tanpa pesan
  final int unreadCount;
  final String? lastMediaUrl;

  Conversation({
    required this.id,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    this.lastMediaUrl,
  });

  // Getter abstrak yang harus diimplementasikan oleh subclass.
  // Ini menyediakan cara yang konsisten untuk mendapatkan nama dan URL gambar.
  String get displayName;
  String? get displayImageUrl;
}

/// Model spesifik untuk percakapan antar pengguna (type: "user").
class UserConversation extends Conversation {
  final User partner;
  final bool isPartnerVerified; // <-- 1. TAMBAHKAN PROPERTI INI

  UserConversation({
    required super.id,
    required super.lastMessage,
    required super.timestamp,
    required super.unreadCount,
    super.lastMediaUrl,
    required this.partner,
    this.isPartnerVerified = false, // <-- 2. TAMBAHKAN DI KONSTRUKTOR
  });

  @override
  String get displayName => partner.fullName ?? partner.username;

  @override
  String? get displayImageUrl => partner.profilePictureUrl;

  factory UserConversation.fromJson(Map<String, dynamic> json) {
    final conversationData = json['conversation'] as Map<String, dynamic>;
    final lastChatData = json['last_chat'] as Map<String, dynamic>?;

    final partnerUser = User.fromJson(conversationData); // Gunakan User.fromJson

    String displayMessage = 'Mulai percakapan';
    DateTime timestamp = DateTime.now();
    bool isRead = true;
    String? lastMedia;

    if (lastChatData != null) {
      displayMessage = lastChatData['content'] ?? '';
      lastMedia = lastChatData['media'] as String?;

      if (displayMessage.isEmpty && lastMedia != null) {
        displayMessage = '📎 Media';
      }

      final sentAtString = lastChatData['sent_at'] as String?;
      if (sentAtString != null) {
        timestamp = DateTime.parse(sentAtString.replaceFirst(' ', 'T'));
      }

      final isReadValue = lastChatData['is_read'];
      if (isReadValue is bool) {
        isRead = isReadValue;
      } else if (isReadValue is int) {
        isRead = isReadValue == 1;
      }
    }

    return UserConversation(
      id: partnerUser.id ?? 0,
      partner: partnerUser,
      lastMessage: displayMessage,
      timestamp: timestamp,
      unreadCount: isRead ? 0 : 1,
      lastMediaUrl: lastMedia,
      // -- 👇 3. PARSING is_verified DARI JSON 👇 --
      isPartnerVerified: conversationData['is_verified'] ?? false,
    );
  }
}

/// Model spesifik untuk percakapan grup (type: "group").
class GroupConversation extends Conversation {
  final Group group;
  final String groupName;
  final String? avatarUrl;
  final String? description;

  GroupConversation({
    required this.group,
    required super.id,
    required super.lastMessage,
    required super.timestamp,
    required super.unreadCount,
    super.lastMediaUrl,
    required this.groupName,
    this.avatarUrl,
    this.description,
  });

  // Mengimplementasikan getter dari abstract class
  @override
  String get displayName => groupName;

  @override
  String? get displayImageUrl => avatarUrl;

  factory GroupConversation.fromJson(Map<String, dynamic> json) {
    // Tangani kasus di mana 'sent_at' mungkin kosong atau null untuk grup baru
    DateTime? timestamp;
    if (json['sent_at'] != null && json['sent_at'].isNotEmpty) {
      // Perhatikan: JSON API untuk Grup menggunakan format ISO 8601 (ada 'T' dan 'Z')
      timestamp = DateTime.parse(json['sent_at']); // [PERBAIKAN: Gunakan parse standar]
    }

    // Ambil pesan terakhir. Jika kosong, gunakan teks default.
    final String lastMsg = json['last_message'] as String? ?? '';
    final String? lastMedia = json['last_media'] as String?;

    String displayMessage = lastMsg.isNotEmpty ? lastMsg : (lastMedia != null && lastMedia.isNotEmpty ? '📎 Media' : 'Mulai percakapan');

    return GroupConversation(
      group: Group.fromJson(json),
      id: json['id'],
      groupName: json['name'],
      avatarUrl: json['avatar_url'],
      description: json['description'],
      // vvv [PASTIKAN MENGGUNAKAN LOGIKA DISPLAY MESSAGE] vvv
      lastMessage: displayMessage,
      // ^^^ [BATAS PERBAIKAN] ^^^
      timestamp: timestamp,
      // Logika unreadCount untuk grup mungkin berbeda, sesuaikan jika perlu
      unreadCount: 0, // Contoh sederhana, API Anda mungkin punya field lain
      lastMediaUrl: lastMedia,
    );
  }
}
