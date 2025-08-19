// lib/models/chat.dart

import 'user_model.dart'; // Pastikan import model User sudah ada

// Enum untuk tipe pesan
enum MessageType { text, image, video, file }

// Enum untuk status pengiriman pesan
enum MessageStatus { sending, sent, read, failed }

class ChatMessage {
  final int id;
  final String? text;
  final MessageType type;
  final User sender; // BARU: Tipe data diubah menjadi User
  final User recipient; // BARU: Properti ini ditambahkan
  final DateTime timestamp;
  MessageStatus status;

  ChatMessage({
    required this.id,
    this.text,
    required this.type,
    required this.sender, // BARU
    required this.recipient, // BARU
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    // BARU: Kita butuh objek User lengkap saat parsing
    required User currentUser,
    required User recipient,
  }) {
    // Tentukan siapa pengirim berdasarkan sender_id dari JSON
    final isMe = json['sender_id'] == currentUser.id;

    return ChatMessage(
      id: json['message_id'] ?? json['id'] ?? 0,
      text: json['content'],
      type: json['media_url'] != null
          ? MessageType.image
          : MessageType.text, // Logika sederhana

      // BARU: Isi properti sender dan recipient dengan objek User
      sender: isMe ? currentUser : recipient,
      recipient: isMe ? recipient : currentUser,

      timestamp: DateTime.parse(json['sent_at'] ?? json['timestamp']),
      status:
          (json['is_read'] ?? false) ? MessageStatus.read : MessageStatus.sent,
    );
  }
}

// Model untuk halaman daftar percakapan
class Conversation {
  final User partner;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  // BARU: Tambahkan properti ini agar sesuai dengan data dari API
  final String? lastMediaUrl;

  Conversation({
    required this.partner,
    required this.lastMessage,
    required this.timestamp,
    this.unreadCount = 0, // Beri nilai default
    this.lastMediaUrl, // Tambahkan di konstruktor
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // API hanya memberikan 'user_id', bukan objek User lengkap.
    // Kita buat objek User sederhana dari data yang ada.
    // Detail user (seperti nama lengkap & foto profil) perlu diambil terpisah
    // atau dimuat saat halaman chat dibuka.
    final partnerUser = User(
      id: json['user_id'],
      // Kita belum punya nama dari API ini, jadi gunakan placeholder
      username: 'User ${json['user_id']}',
      // Anda bisa menambahkan properti lain jika ada di JSON
    );

    String displayMessage = json['last_message'] ?? '';
    // Jika tidak ada teks pesan tapi ada media, tampilkan 'Media'
    if (displayMessage.isEmpty && json['last_media'] != null) {
      displayMessage = '📎 Media';
    }

    return Conversation(
      partner: partnerUser,
      lastMessage: displayMessage,
      timestamp: DateTime.parse(json['sent_at']),
      // API Anda mengembalikan is_read (boolean). Kita ubah jadi unreadCount.
      // Jika is_read=false, berarti ada 1 pesan belum dibaca (minimal).
      unreadCount: (json['is_read'] == false) ? 1 : 0,
      lastMediaUrl: json['last_media'],
    );
  }
}
