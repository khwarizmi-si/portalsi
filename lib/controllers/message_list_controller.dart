// lib/controllers/message_list_controller.dart

import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/message_service.dart'; // Pastikan path ini benar ke ChatService

class MessageListController extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];
  List<Conversation> get filteredConversations => _filteredConversations;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MessageListController() {
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _allConversations = await _chatService.getAllConversations();
      _filteredConversations = _allConversations;
    } catch (e) {
      _errorMessage = "Gagal memuat pesan: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterConversations(String query) {
    if (query.isEmpty) {
      _filteredConversations = _allConversations;
    } else {
      _filteredConversations = _allConversations
          .where((convo) =>
              // ==== PERUBAHAN DI SINI ====
              // Mengganti convo.user menjadi convo.partner
              (convo.partner.fullName ?? '')
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              convo.partner.username
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }
}
