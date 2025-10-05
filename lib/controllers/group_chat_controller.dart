import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_member_model.dart';
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

  bool _isCurrentUserAdmin = false;
  bool get isCurrentUserAdmin => _isCurrentUserAdmin;

  int? get currentUserId => _currentUser?.id;

  List<GroupMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isReloading = false;

  GroupMessage? _repliedToMessage;
  GroupMessage? get repliedToMessage => _repliedToMessage;

  // --- [DIHAPUS] Semua variabel state untuk paginasi dihapus ---
  // int? _currentPage;
  // int? _lastPage;
  // bool _isLoadingMore = false;

  bool get isReloading => _isReloading;
  List<User> _members = [];
  Map<int, User> get membersMap => { for (var member in _members) member.id! : member };
  List<User> get appBarMembers => _members.take(2).toList();
  List<GroupMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- [DIHAPUS] Getter yang berhubungan dengan paginasi dihapus ---
  // bool get isLoadingMore => _isLoadingMore;
  // bool get hasMorePagesToLoad => (_currentPage ?? 1) < (_lastPage ?? 1);

  GroupChatRoomController({required this.group}) {
    _initialize();
    _checkUserRole();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  String _getCacheKey() => 'group_chat_history_${group.id}';

  Future<void> _checkUserRole() async {
    try {
      final role = await _groupService.getUserRoleInGroup(group.id);
      _isCurrentUserAdmin = (role.toLowerCase() == 'admin');
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal memeriksa peran pengguna: $e");
    }
  }

  void setRepliedToMessage(GroupMessage? message) {
    _repliedToMessage = message;
    notifyListeners();
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = _messages.map((m) => m.toJson()).toList();

      // --- [TAMBAHAN UNTUK DEBUGGING] ---
      // Kita akan mencetak (print) isi dari messagesJson ke konsol debug
      // agar bisa melihat data mentah yang akan disimpan.
      // Kita gunakan JsonEncoder.withIndent agar hasilnya rapi dan mudah dibaca.
      final jsonEncoder = JsonEncoder.withIndent('  '); // '  ' untuk 2 spasi indentasi
      final prettyJsonString = jsonEncoder.convert(messagesJson);

      debugPrint("--- [DEBUG] Data yang Akan Disimpan ke Cache (messagesJson) ---");
      debugPrint(prettyJsonString);
      debugPrint("--- [DEBUG] Akhir dari Data Cache ---");
      // --- BATAS TAMBAHAN ---

      // Baris ini tetap untuk menyimpan data ke cache
      await prefs.setString(_getCacheKey(), jsonEncode(messagesJson));

      debugPrint("💾 Cache untuk grup ID ${group.id} berhasil disimpan/diperbarui.");
    } catch (e) {
      debugPrint("⚠️ Gagal menyimpan cache pesan grup: $e");
    }
  }

  Future<void> clearCacheAndReload() async {
    try {
      // 1. Hapus cache dari SharedPreferences menggunakan key yang ada
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getCacheKey());
      debugPrint("✅ Cache untuk grup ID ${group.id} berhasil dihapus.");

      // 2. Kosongkan daftar pesan saat ini agar UI menampilkan state loading
      _messages.clear();

      // 3. Panggil fetchMessages untuk memuat ulang seluruhnya dari API
      //    (fetchMessages sudah memanggil notifyListeners() di dalamnya)
      await fetchMessages();

    } catch (e) {
      debugPrint("⚠️ Gagal menghapus cache: $e");
    }
  }

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
    if (hasCache) {
      _isLoading = false;
      notifyListeners();
    }

    try {
      List<GroupMessage> newMessages;

      if (hasCache) {
        debugPrint("Memuat dari cache, lalu mengambil pesan belum dibaca...");
        final unreadMessagesJson = await _groupService.getUnreadGroupMessages(group.id);
        newMessages = unreadMessagesJson.map((json) => GroupMessage.fromJson(json)).toList();

        if (newMessages.isNotEmpty) {
          final existingIds = _messages.map((m) => m.id).toSet();
          newMessages.removeWhere((m) => existingIds.contains(m.id));
          _messages.insertAll(0, newMessages);
        }
      } else {
        debugPrint("Cache kosong, mengambil riwayat lengkap dari API...");
        // [MODIFIKASI] Memanggil service tanpa parameter 'page'
        final responseData = await _groupService.getGroupMessages(group.id);
        // [MODIFIKASI] Mengambil list pesan dari key 'messages'
        final List<dynamic> messageList = responseData['messages'] ?? [];
        newMessages = messageList.map((json) => GroupMessage.fromJson(json)).toList();
        _messages = newMessages;

        // [DIHAPUS] Logika untuk set _currentPage dan _lastPage dihapus
      }

      _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // [PENTING] Menyimpan data yang baru diambil dari API ke cache
      await _saveMessagesToCache();

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

  Future<void> _markMessagesAsRead(List<int> messageIds) async {
    debugPrint("Menandai ${messageIds.length} pesan sebagai sudah dibaca...");
    await Future.wait(
        messageIds.map((id) => _groupService.markMessageAsRead(group.id, id))
    );
    debugPrint("✅ Semua pesan baru telah ditandai sebagai sudah dibaca.");
  }

  Future<bool> _loadMessagesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_getCacheKey());
      if (cachedData != null) {
        final List<dynamic> messagesJson = jsonDecode(cachedData);
        _messages = messagesJson.map((json) => GroupMessage.fromJson(json)).toList();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ Gagal memuat cache pesan grup: $e");
    }
    return false;
  }

  Future<void> fetchGroupMembers() async {
    try {
      // 1. Ambil data dari service sebagai List<GroupMember>
      final List<GroupMember> groupMembers = await _groupService.getGroupMembers(group.id);

      // 2. Konversi setiap item dari GroupMember menjadi User
      _members = groupMembers.map((member) {
        return User(
          id: member.userId,
          username: member.username,
          fullName: member.fullName,
          profilePictureUrl: member.profilePictureUrl,
          isOnline: member.isOnline,
          lastSeen: member.lastSeen,
          // Properti lain dari model User akan menggunakan nilai default
        );
      }).toList(); // Jangan lupa .toList() untuk mengubahnya kembali menjadi List

      // 3. Lakukan sorting pada List<User> yang sudah dikonversi
      _members.sort((a, b) {
        if (a.isOnline == b.isOnline) {
          // Gunakan ?? untuk memberikan nilai default jika lastSeen null
          return (b.lastSeen ?? DateTime(0)).compareTo(a.lastSeen ?? DateTime(0));
        }
        return a.isOnline ? -1 : 1; // Anggota online akan berada di atas
      });

      notifyListeners(); // Beri tahu UI bahwa data sudah diperbarui
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
      if (appEvent.channel == channelName) {
        // [MODIFIKASI] Panggil _handleIncomingMessage untuk semua event
        _handleIncomingMessage(appEvent as Map<String, dynamic>);
      }
    });
  }

  void sendMessage(String content) async {
    // Jika konten kosong dan tidak ada reply, batalkan pengiriman
    if (content.trim().isEmpty && _repliedToMessage == null) return;
    if (_currentUser == null) return;

    final int? replyToId = _repliedToMessage?.id;

    // Simpan referensi pesan yang dibalas sebelum menghapusnya
    final repliedMessageReference = _repliedToMessage;
    setRepliedToMessage(null); // Menghapus UI reply segera

    // Buat pesan dummy (lokal) segera
    final tempMessageId = DateTime.now().millisecondsSinceEpoch;
    final tempMessage = GroupMessage(
      id: tempMessageId,
      content: content,
      sender: _currentUser!,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
      // Gunakan referensi yang tersimpan
      repliedTo: repliedMessageReference != null
          ? ReplyInfo(
        id: repliedMessageReference.id,
        content: repliedMessageReference.content,
        sender: repliedMessageReference.sender,
      )
          : null,
    );

    _messages.insert(0, tempMessage);
    _saveMessagesToCache();
    notifyListeners();

    try {
      final responseData = await _groupService.sendMessage(
        groupId: group.id,
        content: content,
        replyToId: replyToId, // Kirim ID pesan ke Service
      );

      // ✨ PERBAIKAN: Ambil objek pesan dari key 'data' dari respons API yang sukses.
      if (responseData == null || !responseData.containsKey('data')) {
        throw Exception("Successful response but missing 'data' key.");
      }

      final dataWrapper = responseData['data'] as Map<String, dynamic>;

      // Asumsi objek pesan yang sebenarnya adalah isi dari dataWrapper (atau di bawah kunci 'message' di dalamnya)
      // Berdasarkan log Anda, kita asumsikan data yang dibutuhkan ada di responseData['data']
      final newMessage = GroupMessage.fromJson(dataWrapper);

      // Ganti pesan dummy dengan pesan nyata dari server
      final index = _messages.indexWhere((m) => m.id == tempMessageId);
      if (index != -1) {
        _messages[index] = newMessage;
      }
      _saveMessagesToCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal mengirim pesan: $e');
      final index = _messages.indexWhere((m) => m.id == tempMessageId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
        notifyListeners();
      }
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
    _messages.clear();

    // [DIHAPUS] Logika reset _currentPage dan _lastPage tidak diperlukan lagi

    await fetchMessages();

    _isReloading = false;
    notifyListeners();
  }
}
