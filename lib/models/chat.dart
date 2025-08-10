// lib/models.dart

import 'dart:io';

// Enum untuk mendefinisikan tipe pesan
enum MessageType { text, image, video, file, voice }

class ChatUser {
  // ... (tetap sama seperti sebelumnya)
  final String id;
  final String name;
  final String username;
  final String? imageUrl;

  const ChatUser({
    required this.id,
    required this.name,
    required this.username,
    this.imageUrl,
  });
}

class ChatMessage {
  final String? text; // Sekarang bisa null jika pesannya bukan teks
  final MessageType type;
  final bool isMe;
  final DateTime timestamp;

  // Path file lokal untuk pesan non-teks
  // Dalam aplikasi nyata, ini akan menjadi URL dari backend
  final File? file;
  final String? fileName;

  const ChatMessage({
    this.text,
    required this.type,
    required this.isMe,
    required this.timestamp,
    this.file,
    this.fileName,
  });
}
