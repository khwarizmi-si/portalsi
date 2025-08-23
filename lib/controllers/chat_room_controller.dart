// lib/controllers/chat_room_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/message_service.dart'; // Pastikan path ini benar
import '../utils/secure_storage.dart';

class ChatRoomController extends ChangeNotifier {
  final User recipient;
  final ChatService _chatService = ChatService(); // Gunakan singleton instance

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  StreamSubscription? _messageSubscription;

  ChatRoomController({required this.recipient}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
      await fetchMessages();
      // Langsung dengarkan pesan baru. Tidak perlu 'connect' di sini.
      _listenToMessages();
    } else {
      _errorMessage = "Tidak bisa memuat data pengguna saat ini.";
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mulai mendengarkan stream pesan pribadi dari ChatService.
  void _listenToMessages() {
    _messageSubscription = _chatService.privateMessages.listen((newMessage) {
      // Cek apakah pesan ini untuk percakapan yang sedang dibuka
      if ((newMessage.sender.id == _currentUser!.id &&
              newMessage.recipient.id == recipient.id) ||
          (newMessage.sender.id == recipient.id &&
              newMessage.recipient.id == _currentUser!.id)) {
        // Pola baru: Cari pesan sementara (jika ada) dan ganti.
        final tempMessageIndex = _messages.indexWhere((m) =>
            m.status == MessageStatus.sending && m.text == newMessage.text);

        if (tempMessageIndex != -1) {
          // Jika ditemukan (ini adalah pesan kita yang baru saja dikonfirmasi server), ganti.
          _messages[tempMessageIndex] = newMessage;
        } else {
          // Jika tidak ditemukan (ini adalah pesan baru dari penerima), tambahkan.
          _messages.insert(0, newMessage);
        }
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    // HANYA batalkan subscription. JANGAN disconnect socket di sini.
    _messageSubscription?.cancel();
    super.dispose();
  }

  // Metode _loadCurrentUser() tidak perlu diubah, biarkan seperti semula.
  Future<void> _loadCurrentUser() async {/* ... kode Anda ... */}

  // Metode fetchMessages() juga tidak perlu diubah.
  Future<void> fetchMessages() async {/* ... kode Anda ... */}

  /// Mengirim pesan menggunakan metode baru dari ChatService
  void sendMessage(String text) {
    if (text.trim().isEmpty || _currentUser == null || recipient.id == null)
      return;

    // 1. Buat pesan sementara untuk "Optimistic UI"
    final tempMessage = ChatMessage(
      id: -DateTime.now().millisecondsSinceEpoch, // ID negatif sementara
      text: text.trim(),
      type: MessageType.text,
      sender: _currentUser!,
      recipient: recipient,
      timestamp: DateTime.now(),
      status: MessageStatus.sending, // Status: sedang dikirim
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    // 2. Kirim pesan melalui WebSocket (fire and forget)
    try {
      _chatService.sendPrivateMessage(
        senderId: _currentUser!.id.toString(),
        receiverId: recipient.id!.toString(),
        content: text.trim(),
      );
    } catch (e) {
      // Jika `emit` gagal, tandai pesan sebagai gagal.
      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
        notifyListeners();
      }
      debugPrint("Gagal mengirim pesan via socket: $e");
    }
  }
}
