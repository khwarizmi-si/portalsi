// lib/controllers/group_chat_room_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/group_model.dart'; // Ganti dengan path model Group Anda
import '../models/group_message_model.dart'; // Ganti dengan path model GroupMessage Anda
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/websocket_service.dart';
import '../utils/secure_storage.dart';

class GroupChatRoomController with ChangeNotifier {
  final Group group;
  final GroupService _groupService = GroupService();

  User? _currentUser;
  StreamSubscription? _eventSubscription;

  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<GroupMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GroupChatRoomController({required this.group}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await fetchMessages();
    _startRealtimeListeners();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await SecureStorage.getUserId();
    final username = await SecureStorage.getUsername();

    // Anda mungkin perlu mengambil detail user lengkap jika dibutuhkan
    _currentUser = User(id: userId, username: username!);
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final messagesData = await _groupService.getGroupMessages(group.id);
      _messages = messagesData
          .map((json) => GroupMessage.fromJson(json))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startRealtimeListeners() {
    final wsService = AuthService.webSocketService;
    if (wsService == null || _currentUser == null) return;

    final channelName = 'private-group.${group.id}';

    wsService.subscribeToChannel(channelName);

    _eventSubscription = wsService.eventStream.listen((AppEvent appEvent) {
      if (appEvent.channel == channelName && appEvent.event == 'group.new') {
        try {
          final newMessage = GroupMessage.fromJson(appEvent.data);

          // Tambahkan pesan hanya jika belum ada dan bukan dari kita sendiri
          if (!_messages.any((m) => m.id == newMessage.id) &&
              newMessage.sender.id != _currentUser!.id) {
            _messages.insert(0, newMessage);
            notifyListeners();
          }
        } catch (e) {
          debugPrint("Error parsing pesan grup realtime: $e");
        }
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Optimistic UI: tampilkan pesan langsung dengan status 'sending'
    final tempMessage = GroupMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      content: text.trim(),
      sender: _currentUser!, // Asumsi sender adalah currentUser
      sentAt: DateTime.now(),
      // status: MessageStatus.sending, // Anda bisa menambahkan status jika perlu
    );
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final sentMessageData = await _groupService.sendGroupMessage(
        groupId: group.id,
        content: text.trim(),
      );

      // Ganti pesan temporary dengan pesan asli dari server
      final sentMessage = GroupMessage.fromJson(sentMessageData);
      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _messages[index] = sentMessage;
        notifyListeners();
      }
    } catch (e) {
      // Handle error, misalnya ubah status pesan temporary menjadi 'failed'
      debugPrint("Gagal mengirim pesan grup: $e");
      final index = _messages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        // _messages[index].status = MessageStatus.failed;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    final wsService = AuthService.webSocketService;
    if (wsService != null) {
      wsService.unsubscribeFromChannel('private-group.${group.id}');
    }
    _eventSubscription?.cancel();
    super.dispose();
  }
}
