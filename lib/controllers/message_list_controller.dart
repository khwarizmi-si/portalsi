// lib/controllers/message_list_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';
import '../utils/secure_storage.dart';

class MessageListController extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];
  List<Conversation> get filteredConversations => _filteredConversations;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _eventSubscription;
  User? _currentUser;

  MessageListController() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await fetchConversations();
    _initializeWebSocketListener();
  }

  // ▼▼▼ FUNGSI YANG DIPERBAIKI ADA DI SINI ▼▼▼
  Future<void> _loadCurrentUser() async {
    try {
      final userIdStr = await SecureStorage.getUserId();
      if (userIdStr == null) {
        throw Exception("User ID not found in storage");
      }
      // userId adalah variabel angka (int)
      final userId = int.parse(userIdStr as String);

      // username adalah variabel teks (String)
      final username = await SecureStorage.getUsername();
      if (username == null) {
        throw Exception("Username not found in storage");
      }

      // Pastikan variabel dimasukkan ke parameter yang sesuai
      _currentUser = User(
        id: userId,          // BENAR: int ke parameter id
        username: username,  // BENAR: String ke parameter username
      );
    } catch (e) {
      debugPrint("Gagal memuat current user di MessageListController: $e");
    }
  }
  // ▲▲▲ BATAS PERBAIKAN ▲▲▲

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _initializeWebSocketListener() {
    final wsService = AuthService.webSocketService;
    if (wsService == null) return;

    _eventSubscription?.cancel();
    _eventSubscription = wsService.eventStream.listen((AppEvent appEvent) {
      if (appEvent.event == 'dm.new') {
        _handleNewDirectMessage(appEvent.data);
      } else if (appEvent.event == 'conversation.updated') {
        // Anda bisa menambahkan logika untuk event lain di sini jika perlu
      }
    });
  }

  void _handleNewDirectMessage(Map<String, dynamic> data) {
    if (_currentUser == null) return;

    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final newMessage = ChatMessage.fromJson(messageData);

      final partner = (newMessage.sender.id == _currentUser!.id)
          ? newMessage.recipient
          : newMessage.sender;

      _allConversations.removeWhere((c) => c is UserConversation && c.partner.id == partner.id);

      final updatedConversation = UserConversation(
        id: partner.id!,
        partner: partner,
        lastMessage: newMessage.text ?? '📎 Media',
        timestamp: newMessage.timestamp,
        unreadCount: (newMessage.sender.id != _currentUser!.id) ? 1 : 0,
        isPartnerVerified: partner.isVerified,
      );

      _allConversations.add(updatedConversation);
      _sortAndFilterConversations();
      notifyListeners();

      _chatService.updateConversationCacheWithNewMessage(newMessage);

    } catch (e, s) {
      debugPrint("Gagal memproses 'dm.new' di MessageListController: $e\n$s");
    }
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cachedData = await _chatService.getConversationsFromCache();
      if (cachedData != null && cachedData.isNotEmpty) {
        _allConversations = cachedData;
        _sortAndFilterConversations();
        _isLoading = false;
        notifyListeners();
      }

      final networkData = await _chatService.getAllConversations();
      _allConversations = networkData;
      _sortAndFilterConversations();
      _errorMessage = null;

    } catch (e) {
      if (_allConversations.isEmpty) {
        _errorMessage = "Gagal memuat pesan: ${e.toString()}";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortAndFilterConversations() {
    _allConversations.sort((a, b) {
      if (a.timestamp == null || b.timestamp == null) return 0;
      return b.timestamp!.compareTo(a.timestamp!);
    });
    _filteredConversations = _allConversations;
  }

  void filterConversations(String query) {
    if (query.isEmpty) {
      _filteredConversations = _allConversations;
    } else {
      _filteredConversations = _allConversations
          .where((convo) =>
          convo.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}