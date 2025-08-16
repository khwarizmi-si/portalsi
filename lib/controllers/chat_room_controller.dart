import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../utils/secure_storage.dart';

class ChatRoomController extends ChangeNotifier {
  final User recipient; // User penerima pesan
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  ChatRoomController({required this.recipient}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
      await fetchMessages();
    } else {
      _errorMessage = "Tidak bisa memuat data pengguna saat ini.";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final username = await SecureStorage.getUsername();
      final userId = await SecureStorage.getUserId();
      final profilePic = await SecureStorage.getProfilePicture();

      _currentUser = User(
        id: userId!,
        username: username ?? 'Saya',
        profilePictureUrl: profilePic,
      );
    } catch (e) {
      debugPrint("Gagal memuat current user dari storage: $e");
    }
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (recipient.id == null) throw Exception("Recipient ID is null");

      // Teruskan currentUser dan recipient ke service
      _messages = await _chatService.getConversation(_currentUser!, recipient);
    } catch (e) {
      _errorMessage = "Gagal memuat percakapan: $e";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _currentUser == null || recipient.id == null)
      return;

    // 1. Optimistic UI: Buat pesan sementara
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      text: text.trim(),
      type: MessageType.text,
      sender: _currentUser!,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    // Langsung tambahkan ke daftar pesan dan update UI
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 2. Kirim ke server
      if (currentUser == null) {
        throw Exception("User belum login atau data currentUser belum di-load");
      }

      final sentMessage = await _chatService.sendMessage(
        receiverId: recipient.id!,
        content: text.trim(),
        currentUser: currentUser!, // pakai ! karena sudah dicek di atas
        recipient: recipient,
      );

      // 3. Ganti pesan sementara dengan data asli dari server
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index] = sentMessage;
      }
    } catch (e) {
      // 4. Jika gagal, tandai pesan sebagai 'failed'
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
      }
      debugPrint("Gagal mengirim pesan: $e");
    } finally {
      // Update UI dengan status akhir pesan
      notifyListeners();
    }
  }
}
