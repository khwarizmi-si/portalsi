// lib/providers/chat_room_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:portal_si/models/chat.dart'; // Sesuaikan path
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/services/websocket_service.dart';

class ChatRoomProvider with ChangeNotifier {
  final WebSocketService? _wsService = AuthService.webSocketService;
  StreamSubscription? _eventSubscription;

  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  String? _currentChannelName;

  /// Panggil ini dari initState() di halaman chat Anda
  void startListening(int currentUserId, int otherUserId) {
    // Bangun nama channel
    final ids = [currentUserId, otherUserId]..sort();
    final roomId = ids.join('-');
    _currentChannelName = 'private-chat.direct.$roomId';

    // 1. Subscribe ke channel
    _wsService!.subscribeToChannel(_currentChannelName!);

    // 2. Dengarkan stream event
    _eventSubscription = _wsService.eventStream.listen((AppEvent appEvent) {
      // 3. Filter event yang relevan untuk room ini
      if (appEvent.channel == _currentChannelName &&
          appEvent.event == 'NewDirectMessage') {
        try {
          // Buat objek ChatMessage dari data event
          // PERHATIAN: Anda mungkin perlu menyesuaikan ChatMessage.fromJson
          // untuk bisa menerima data mentah dari event.
          final newMessage = ChatMessage.fromJson(appEvent.data['message']);

          // Tambahkan pesan baru ke daftar dan beri tahu UI
          _messages.add(newMessage);
          notifyListeners();
        } catch (e) {
          debugPrint("Error parsing pesan realtime di provider: $e");
        }
      }
    });
  }

  /// Panggil ini dari dispose() di halaman chat Anda
  void stopListening() {
    if (_currentChannelName != null) {
      _wsService!.unsubscribeFromChannel(_currentChannelName!);
    }
    _eventSubscription?.cancel();
    _messages = []; // Kosongkan pesan saat keluar dari room
  }

  // Anda juga bisa menambahkan method untuk fetch history chat di sini
  // Future<void> fetchInitialMessages(...) { ... }
}
