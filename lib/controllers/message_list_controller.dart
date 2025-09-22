// lib/controllers/message_list_controller.dart

import 'dart:async';

import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/websocket_service.dart';

class MessageListController extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];
  List<Conversation> get filteredConversations => _filteredConversations;

  bool _isLoading = false; // Awalnya false untuk menghindari loading yang tidak perlu
  bool get isLoading => _isLoading;
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  StreamSubscription? _eventSubscription;

  MessageListController() {
    fetchConversations();
    _initializeWebSocketListener();
  }

  // [TAMBAHAN] Jangan lupa untuk membatalkan subscription saat controller hancur
  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// Menerapkan strategi cache-then-network.
  /// 1. Muat data dari cache untuk tampilan instan.
  /// 2. Ambil data baru dari API di latar belakang dan perbarui UI.
  Future<void> fetchConversations() async {
    // Hanya tampilkan loading indicator jika daftar benar-benar kosong di awal.
    if (_allConversations.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    // 1. Muat dari cache terlebih dahulu untuk tampilan instan
    try {
      final cachedData = await _chatService.getConversationsFromCache();
      if (cachedData != null && cachedData.isNotEmpty) {
        _allConversations = cachedData;
        _sortAndFilterConversations();
        // Hentikan loading jika data cache berhasil dimuat
        if (_isLoading) {
          _isLoading = false;
        }
        notifyListeners();
      }
    } catch (e) {
      print("Gagal memuat cache, akan melanjutkan dengan panggilan API. Error: $e");
    }

    // 2. Selalu coba ambil data terbaru dari API di latar belakang
    try {
      final networkData = await _chatService.getAllConversations();
      _allConversations = networkData;
      _errorMessage = null; // Hapus pesan error jika panggilan API berhasil
      _sortAndFilterConversations();
    } catch (e) {
      print("Gagal mengambil data dari API: $e");
      // Hanya tampilkan pesan error di UI jika tidak ada data sama sekali
      // (baik dari cache maupun API).
      if (_allConversations.isEmpty) {
        _errorMessage = "Gagal memuat pesan: ${e.toString()}";
      }
    } finally {
      // Pastikan loading indicator selalu berhenti pada akhirnya
      if (_isLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _initializeWebSocketListener() {
    // Ambil instance WebSocketService yang sudah ada
    final wsService = AuthService.webSocketService;
    if (wsService == null) return; // Hentikan jika service tidak aktif

    // Batalkan listener lama sebelum membuat yang baru
    _eventSubscription?.cancel();

    _eventSubscription = wsService.eventStream.listen((AppEvent appEvent) {
      // Kita hanya peduli dengan event yang mengupdate daftar percakapan
      if (appEvent.event == 'conversation.updated') {
        debugPrint("🔄 Menerima update percakapan via WebSocket!");
        // Panggil handler untuk memproses data
        _handleConversationUpdate(appEvent.data);
      }
    });
  }

  /// Memproses data dari WebSocket dan memperbarui state.
  void _handleConversationUpdate(Map<String, dynamic> data) {
    try {
      Conversation newOrUpdatedConversation;

      // Tentukan jenis percakapan dan parse JSON-nya
      if (data['type'] == 'user') {
        newOrUpdatedConversation = UserConversation.fromJson(data['conversation']);
      } else if (data['type'] == 'group') {
        newOrUpdatedConversation = GroupConversation.fromJson(data['conversation']);
      } else {
        return; // Jenis tidak dikenal, abaikan.
      }

      // Hapus percakapan lama jika sudah ada di daftar
      _allConversations.removeWhere((c) => c.id == newOrUpdatedConversation.id);

      // Tambahkan percakapan yang baru/diperbarui ke daftar
      _allConversations.add(newOrUpdatedConversation);

      // Urutkan ulang daftar dan terapkan filter
      _sortAndFilterConversations();

      // Beri tahu UI untuk refresh!
      notifyListeners();

    } catch (e) {
      debugPrint("❌ Gagal memproses update percakapan dari WebSocket: $e");
    }
  }

  /// Helper method untuk mengurutkan dan menerapkan filter pada daftar percakapan.
  /// Ini untuk menghindari duplikasi kode.
  void _sortAndFilterConversations() {
    // Urutkan berdasarkan timestamp, yang terbaru di atas
    _allConversations.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return 1; // Anggap null lebih lama
      if (b.timestamp == null) return -1;
      return b.timestamp!.compareTo(a.timestamp!);
    });

    // Terapkan filter yang sedang aktif (jika ada)
    // Untuk saat ini, kita asumsikan filter kosong saat pertama kali memuat
    _filteredConversations = _allConversations;
  }

  /// Memfilter daftar percakapan berdasarkan query dari search bar.
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