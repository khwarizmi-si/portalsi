// lib/controllers/group_chat_controller.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/notification_system_service.dart';
import '../services/websocket_service.dart';
import '../utils/app_lifecycle_manager.dart';
import '../utils/secure_storage.dart';

class GroupChatRoomController with ChangeNotifier {
  final Group group;
  final GroupService _groupService = GroupService();

  User? _currentUser;
  StreamSubscription? _eventSubscription;

  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;

  // --- [FIX UNTUK ERROR 2 & 3] Deklarasikan variabel yang hilang ---
  bool _isReloading = false;
  int? _currentPage;
  int? _lastPage;
  bool _hasMorePagesToLoad = true;
  bool _isLoadingMore = false;
  // -----------------------------------------------------------------

  // --- [FIX UNTUK ERROR 4] Tambahkan getter yang hilang ---
  bool get isReloading => _isReloading;
  // -----------------------------------------------------

  List<User> _members = [];
  Map<int, User> get membersMap => { for (var member in _members) member.id! : member };
  List<User> get appBarMembers => _members.take(2).toList();
  List<GroupMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMorePagesToLoad => (_currentPage ?? 1) < (_lastPage ?? 1);

  GroupChatRoomController({required this.group}) {
    _initialize();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // --- [FIX UNTUK ERROR 1] Tambahkan fungsi _saveMessagesToCache ---
  String _getCacheKey() => 'group_chat_history_${group.id}';

  Future<void> _saveMessagesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((m) => m.toJson()).toList();
      await prefs.setString(_getCacheKey(), jsonEncode(messagesJson));
      debugPrint("💾 Cache pesan grup untuk ID ${group.id} berhasil diperbarui.");
    } catch (e) {
      debugPrint("⚠️ Gagal menyimpan cache pesan grup: $e");
    }
  }
  // -------------------------------------------------------------

  Future<void> _initialize() async {
    await _loadCurrentUser();
    await Future.wait([
      fetchMessages(),
      fetchGroupMembers(),
    ]);
    _startRealtimeListeners();
  }

  Future<void> _loadCurrentUser() async {
    final userId = await SecureStorage.getUserId();
    final username = await SecureStorage.getUsername();
    _currentUser = User(id: userId, username: username ?? 'Anda');
  }

  Future<void> fetchMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final bool hasCache = await _loadMessagesFromCache();
    // Jika cache sudah dimuat, matikan loading utama
    if (hasCache) {
      _isLoading = false;
      notifyListeners();
    }

    try {
      List<GroupMessage> newMessages;

      if (hasCache) {
        // **ALUR 1: JIKA ADA CACHE**
        debugPrint("Memuat dari cache, lalu mengambil pesan belum dibaca...");
        // 1. Ambil pesan yang belum dibaca dari API
        final unreadMessagesJson = await _groupService.getUnreadGroupMessages(group.id);
        newMessages = unreadMessagesJson.map((json) => GroupMessage.fromJson(json)).toList();

        if (newMessages.isNotEmpty) {
          // 2. Gabungkan pesan lama (dari cache) dengan pesan baru (dari API)
          // Hapus duplikat jika ada
          final existingIds = _messages.map((m) => m.id).toSet();
          newMessages.removeWhere((m) => existingIds.contains(m.id));
          _messages.insertAll(0, newMessages);
        }

      } else {
        // **ALUR 2: JIKA TIDAK ADA CACHE**
        debugPrint("Cache kosong, mengambil riwayat lengkap dari API...");
        // 1. Ambil semua riwayat pesan dari API
        final responseData = await _groupService.getGroupMessages(group.id);
        final List<dynamic> messageList = responseData['messages'] ?? [];
        newMessages = messageList.map((json) => GroupMessage.fromJson(json)).toList();
        _messages = newMessages; // Ganti seluruh daftar dengan data dari API
      }

      // Urutkan ulang semua pesan untuk memastikan urutan kronologis
      _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // 3. Simpan daftar pesan yang sudah digabung/baru ke cache
      await _saveMessagesToCache();

      // 4. Tandai semua pesan yang didapat sebagai sudah dibaca
      if (newMessages.isNotEmpty) {
        await _markMessagesAsRead(newMessages.map((m) => m.id).toList());
      }

    } catch (e) {
      debugPrint("Gagal memuat pesan: $e");
      if (!hasCache) {
        _errorMessage = "Gagal memuat percakapan.";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- [FUNGSI BARU] Untuk menandai pesan sudah dibaca ---
  Future<void> _markMessagesAsRead(List<int> messageIds) async {
    debugPrint("Menandai ${messageIds.length} pesan sebagai sudah dibaca...");
    // Panggil API untuk setiap ID pesan
    await Future.wait(
        messageIds.map((id) => _groupService.markMessageAsRead(group.id, id))
    );
    debugPrint("✅ Semua pesan baru telah ditandai sebagai sudah dibaca.");
  }

  // [MODIFIKASI] _loadMessagesFromCache sekarang mengembalikan boolean
  Future<bool> _loadMessagesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_getCacheKey());
      if (cachedData != null) {
        final List<dynamic> messagesJson = jsonDecode(cachedData);
        _messages = messagesJson.map((json) => GroupMessage.fromJson(json)).toList();
        notifyListeners();
        return true; // Berhasil memuat cache
      }
    } catch (e) {
      debugPrint("⚠️ Gagal memuat cache pesan grup: $e");
    }
    return false; // Gagal atau tidak ada cache
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !hasMorePagesToLoad || _currentPage == null || _currentPage! <= 1) return;

    _isLoadingMore = true;
    notifyListeners();

    final int pageToFetch = _currentPage! - 1;

    try {
      final responseData = await _groupService.getGroupMessages(group.id, page: pageToFetch);
      final List<dynamic> olderMessagesJson = responseData['messages'] ?? [];
      final olderMessages = olderMessagesJson.map((json) => GroupMessage.fromJson(json)).toList();

      _messages.addAll(olderMessages);

      _currentPage = responseData['pagination']['current_page'];

      await _saveMessagesToCache();

    } catch (e) {
      debugPrint("Gagal memuat halaman pesan sebelumnya: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupMembers() async {
    try {
      _members = await _groupService.getGroupMembers(group.id);
      _members.sort((a, b) {
        if (a.isOnline == b.isOnline) {
          return (b.lastSeen ?? DateTime(0)).compareTo(a.lastSeen ?? DateTime(0));
        }
        return a.isOnline ? -1 : 1;
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal mengambil anggota grup: $e");
    }
  }

  void _startRealtimeListeners() {
    final wsService = AuthService.webSocketService;
    if (wsService == null || _currentUser == null) return;
    final channelName = 'private-group.${group.id}';
    wsService.subscribeToChannel(channelName);
    _eventSubscription?.cancel();
    _eventSubscription = wsService.eventStream.listen((AppEvent appEvent) {
      if (appEvent.channel == channelName && appEvent.event == 'group.new') {
        _handleIncomingMessage(appEvent.data);
      }
    });
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _currentUser == null) return;

    final tempMessage = GroupMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      content: text.trim(),
      sender: _currentUser!,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    // 1. Tambahkan pesan temporary dan update UI
    _messages.insert(0, tempMessage);
    await _saveMessagesToCache();
    notifyListeners();

    try {
      // 2. Kirim ke server
      final sentMessageData = await _groupService.sendGroupMessage(
        groupId: group.id,
        content: text.trim(),
      );
      final sentMessage = GroupMessage.fromJson(sentMessageData);

      // 3. Cari dan Ganti pesan temporary DENGAN CARA YANG LEBIH ANDAL
      // Kita buat list baru daripada memodifikasi yang lama untuk memicu update
      final updatedMessages = List<GroupMessage>.from(_messages);
      final index = updatedMessages.indexWhere((m) => m.id == tempMessage.id);

      if (index != -1) {
        updatedMessages[index] = sentMessage;
        _messages = updatedMessages; // Ganti list lama dengan yang baru
      }

      // Simpan ke cache dan update UI
      await _saveMessagesToCache();
      notifyListeners();

    } catch (e) {
      debugPrint("Gagal mengirim pesan grup: $e");
      // Penanganan error tetap sama, tapi pastikan juga mengganti list
      final updatedMessages = List<GroupMessage>.from(_messages);
      final index = updatedMessages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        updatedMessages[index].status = MessageStatus.failed;
        _messages = updatedMessages;
      }
      await _saveMessagesToCache();
      notifyListeners();
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] as Map<String, dynamic>;
      final newMessage = GroupMessage.fromJson(messageData);

      if (!_messages.any((m) => m.id == newMessage.id)) {
        if (newMessage.sender.id != _currentUser!.id) {
          _messages.insert(0, newMessage);
          _saveMessagesToCache();
          notifyListeners();

          if (!AppLifecycleManager.isAppInForeground) {
            NotificationSystemService.instance.showGroupedNotification(
              id: newMessage.id,
              title: group.name,
              body: '${newMessage.sender.username}: ${newMessage.content}',
              groupKey: 'group_${group.id}',
              groupChannelId: 'group_channel',
              groupChannelName: 'Pesan Grup',
              largeIconUrl: group.avatarUrl,
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error parsing pesan grup realtime: $e");
    }
  }

  Future<void> reloadMessages() async {
    _isReloading = true;
    notifyListeners();

    // --- [TAMBAHAN] Kosongkan daftar pesan saat ini ---
    _messages.clear();
    // ----------------------------------------------------

    _currentPage = null;
    _lastPage = null;
    _hasMorePagesToLoad = true;

    // Panggil fetchMessages untuk memulai ulang dari awal
    await fetchMessages();

    // fetchMessages sudah mengatur _isReloading, tapi kita atur lagi di sini untuk kepastian
    _isReloading = false;
    notifyListeners();
  }
}