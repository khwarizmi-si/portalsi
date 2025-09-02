// lib/models/chat.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
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
  final String? mediaType;
  final File? localFile;
  final ValueNotifier<double>? uploadProgress;

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
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, User currentUser, User recipientUser) {
    final bool isFromCurrentUser = json['sender_id'] == currentUser.id;
    final User sender = isFromCurrentUser ? currentUser : recipientUser;
    final User recipient = isFromCurrentUser ? recipientUser : currentUser;

    final bool hasMedia = json['media_url'] != null;
    final MessageType type = hasMedia ? MessageType.image : MessageType.text;

    return ChatMessage(
      id: json['message_id'],
      sender: sender,
      recipient: recipient,
      text: json['content'],
      mediaUrl: json['media_url'],
      timestamp: DateTime.parse(json['sent_at']),
      status: json['is_read'] ? MessageStatus.read : MessageStatus.sent,
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

  UserConversation({
    required super.id,
    required super.lastMessage,
    required super.timestamp,
    required super.unreadCount,
    super.lastMediaUrl,
    required this.partner,
  });

  // Mengimplementasikan getter dari abstract class
  @override
  String get displayName => partner.fullName ?? partner.username;

  @override
  String? get displayImageUrl => partner.profilePictureUrl;


  factory UserConversation.fromJson(Map<String, dynamic> json) {
    final partnerUser = User(
      id: json['id'], // Disesuaikan dengan JSON: 'id' bukan 'user_id'
      username: json['username'] ?? 'unknown',
      fullName: json['name'], // Disesuaikan dengan JSON: 'name' bukan 'full_name'
      profilePictureUrl: json['profile_picture_url'],
    );

    String displayMessage = json['last_message'] ?? '';
    if (displayMessage.isEmpty && json['last_media'] != null) {
      displayMessage = '📎 Media';
    }

    return UserConversation(
      id: json['id'],
      partner: partnerUser,
      lastMessage: displayMessage,
      timestamp: DateTime.parse(json['sent_at']),
      unreadCount: (json['is_read'] == 0) ? 1 : 0, // Asumsi 1 pesan belum dibaca jika is_read = 0
      lastMediaUrl: json['last_media'],
    );
  }
}


/// Model spesifik untuk percakapan grup (type: "group").
class GroupConversation extends Conversation {
  final String groupName;
  final String? avatarUrl;
  final String? description;

  GroupConversation({
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
      timestamp = DateTime.parse(json['sent_at']);
    }

    return GroupConversation(
      id: json['id'],
      groupName: json['name'],
      avatarUrl: json['avatar_url'],
      description: json['description'],
      lastMessage: json['last_message'] ?? '',
      timestamp: timestamp,
      // Logika unreadCount untuk grup mungkin berbeda, sesuaikan jika perlu
      unreadCount: 0, // Contoh sederhana, API Anda mungkin punya field lain
      lastMediaUrl: json['last_media'],
    );
  }
}