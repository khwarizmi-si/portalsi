import 'dart:async'; // BARU: Diperlukan untuk StreamSubscription
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/message_service.dart'; // Pastikan ini mengarah ke ChatService Anda
import '../utils/secure_storage.dart';

class ChatRoomController extends ChangeNotifier {
  final User recipient;
  final ChatService _chatService =
      ChatService(); // Gunakan ChatService yang sudah ada

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  // BARU: Subscription untuk mendengarkan pesan realtime dari service
  StreamSubscription? _messageSubscription;

  ChatRoomController({required this.recipient}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
      await fetchMessages();
      // BARU: Setelah riwayat chat dimuat, mulai dengarkan pesan baru
      _connectAndListen();
    } else {
      _errorMessage = "Tidak bisa memuat data pengguna saat ini.";
      _isLoading = false;
      notifyListeners();
    }
  }

  // BARU: Metode untuk menghubungkan dan mendengarkan WebSocket
  void _connectAndListen() {
    if (_currentUser == null) return;

    // Panggil metode connect dari ChatService
    _chatService.connect(
      _currentUser!.id.toString(),
      currentUser: _currentUser!,
      recipient: recipient,
    );

    // Dengarkan stream 'messages' dari service
    _messageSubscription = _chatService.messages.listen((newMessage) {
      // PENTING: Cek apakah pesan yang masuk BUKAN dari kita sendiri.
      // Ini untuk menghindari duplikasi, karena pesan kita sudah ditambahkan
      // secara optimis di metode sendMessage().
      if (newMessage.sender.id != _currentUser!.id) {
        // Cek apakah pesan sudah ada di list (untuk kasus yang sangat jarang terjadi)
        final isMessageExist = _messages.any((m) => m.id == newMessage.id);
        if (!isMessageExist) {
          _messages.insert(0, newMessage);
          notifyListeners();
        }
      }
    });
  }

  // BARU: Override metode dispose untuk membersihkan resource
  @override
  void dispose() {
    _messageSubscription?.cancel(); // Hentikan listener
    _chatService.disconnect(); // Putuskan koneksi WebSocket
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final username = await SecureStorage.getUsername();
      final userId = await SecureStorage.getUserId();
      final profilePic = await SecureStorage.getProfilePicture();

      if (userId == null) throw Exception("User ID not found in storage");

      _currentUser = User(
        id: userId,
        username: username ?? 'Saya',
        profilePictureUrl: profilePic,
      );
    } catch (e) {
      debugPrint("Gagal memuat current user dari storage: $e");
      _errorMessage = "Sesi Anda tidak valid, silakan login kembali.";
    }
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (recipient.id == null) throw Exception("Recipient ID is null");
      if (_currentUser == null) throw Exception("Current user is not loaded");

      _messages = await _chatService.getConversation(_currentUser!, recipient);
      _messages = _messages.reversed.toList();
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

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      text: text.trim(),
      type: MessageType.text,
      sender: _currentUser!,
      recipient: recipient,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: recipient.id!,
        content: text.trim(),
        currentUser: _currentUser!,
        recipient: recipient,
      );

      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        // Ganti pesan sementara dengan data dari server.
        // Server akan mengirim balik pesan ini via WebSocket, TAPI karena
        // listener kita mengecek sender.id, pesan ini tidak akan diduplikasi.
        _messages[index] = sentMessage;
      }
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
      }
      debugPrint("Gagal mengirim pesan: $e");
    } finally {
      notifyListeners();
    }
  }
}
