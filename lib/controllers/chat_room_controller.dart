// lib/controllers/chat_room_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gal/gal.dart'; // DIUBAH: Menggunakan gal
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../utils/secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class ChatRoomController extends ChangeNotifier {
  final User recipient;
  final ChatService _chatService = ChatService();

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = true;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  StreamSubscription? _messageSubscription;

  bool _isRecipientOnline = false;
  bool get isRecipientOnline => _isRecipientOnline;
  Timer? _statusTimer;

  ChatRoomController({required this.recipient}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
      // Alur fetchMessages sekarang sudah termasuk logika cache
      await fetchMessages();
      _markMessagesAsRead();
      _startRealtimeListeners();
      _checkOnlineStatus();
      _statusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        _checkOnlineStatus();
      });
    } else {
      _errorMessage = "Tidak bisa memuat data pengguna saat ini.";
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkOnlineStatus() async {
    if (recipient.id == null) return;

    try {
      final token = await SecureStorage.getToken();
      if (token == null) return;

      final url = Uri.parse(
          'https://api-new.portalsi.com/api/websocket/online-status/${recipient.id}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isOnline = data['is_online'] ?? false;

        // Hanya update jika statusnya berubah
        if (_isRecipientOnline != isOnline) {
          _isRecipientOnline = isOnline;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Gagal memeriksa status online: $e");
      // Jika error, anggap offline
      if (_isRecipientOnline) {
        _isRecipientOnline = false;
        notifyListeners();
      }
    }
  }

  // [BARU] Helper untuk mendapatkan kunci cache yang unik
  String _getCacheKey() {
    return 'chat_history_${_currentUser!.id}_${recipient.id}';
  }

  // [BARU] Menyimpan list pesan ke cache
  Future<void> _saveMessagesToCache(List<ChatMessage> messagesToSave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey();

      // Pastikan list diurutkan dari terlama ke terbaru sebelum disimpan.
      messagesToSave.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final List<Map<String, dynamic>> messagesJson =
      messagesToSave.map((m) => m.toJson()).toList();

      await prefs.setString(key, jsonEncode(messagesJson));
    } catch (e) {
      debugPrint("Gagal menyimpan cache: $e");
    }
  }

  // [TAMBAHAN] Metode baru untuk menjalankan API PATCH
  Future<void> _markMessagesAsRead() async {
    // Pastikan ID penerima tidak null
    if (recipient.id == null) {
      debugPrint("Mark as read failed: Recipient ID is null.");
      return;
    }

    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception("Authentication token not found.");
      }

      // Ganti dengan base URL API Anda
      final url = Uri.parse(
          'https://api-new.portalsi.com/api/messages/user/${recipient.id}/read');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint(
            "Successfully marked messages from user ${recipient.id} as read.");
      } else {
        debugPrint(
            "Failed to mark messages as read. Status: ${response.statusCode}, Body: ${response.body}");
      }
    } catch (e) {
      debugPrint("An error occurred while marking messages as read: $e");
    }
  }

  @override
  void dispose() {
    debugPrint("ChatRoomController disposed. Unsubscribing from channels.");

    // <-- PERUBAIKAN 2: Panggil unsubscribe dan batalkan listener
    if (_currentUser != null) {
      final ids = [_currentUser!.id, recipient.id]..sort();
      final roomId = ids.join('-');
      final channelName = 'private-dm.$roomId';
      AuthService.webSocketService?.unsubscribeFromChannel(channelName);
    }
    _messageSubscription?.cancel();
    _statusTimer?.cancel();

    super.dispose();
  }

  // <-- PERUBAIKAN 1: Ganti nama dan logika method ini
  void _startRealtimeListeners() {
    if (_currentUser == null) return;
    if (AuthService.webSocketService == null) {
      debugPrint("WebSocketService belum siap.");
      return;
    }

    // Bangun nama channel yang akan didengarkan
    final ids = [_currentUser!.id, recipient.id]..sort();
    final roomId = ids.join('-');
    final channelName = 'private-dm.$roomId';

    // 1. Subscribe ke channel spesifik untuk room ini
    AuthService.webSocketService!.subscribeToChannel(channelName);

    // 2. Dengarkan stream event global dari WebSocketService
    _messageSubscription = AuthService.webSocketService!.eventStream.listen(
          (AppEvent appEvent) async { // <-- Jadikan callback ini async
        if (appEvent.channel == channelName && appEvent.event == 'dm.new') {
          try {
            final messageData = appEvent.data['message'];
            final newMessage = ChatMessage.fromJson(messageData, _currentUser!, recipient);

            final isMessageExist = _messages.any((m) => m.id == newMessage.id);
            if (!isMessageExist && newMessage.sender.id != _currentUser!.id) {

              // [PERUBAHAN UTAMA] Panggil handler baru dengan alur "Cache-First".
              await _handleIncomingMessage(newMessage);

              // Jalankan langkah lain setelah cache dan UI diperbarui.
              _chatService.updateConversationCacheWithNewMessage(newMessage);
              _markMessagesAsRead();
            }
          } catch (e, s) {
            debugPrint("Error parsing pesan dari event 'dm.new': $e");
            debugPrint("Stack trace: $s");
          }
        }
      },
      onError: (error) {
        debugPrint("Error on event stream: $error");
      },
    );
  }

  // [PERBAIKAN] Menggunakan metode yang benar untuk 'gal'
  Future<void> _downloadAndSaveMedia(ChatMessage message) async {
    if (message.mediaUrl == null) return;
    try {
      debugPrint("Mengunduh media dari: ${message.mediaUrl}");
      final response = await http.get(Uri.parse(message.mediaUrl!));
      if (response.statusCode != 200) throw Exception("Gagal mengunduh file.");

      final tempDir = await getTemporaryDirectory();
      final fileName = message.mediaUrl!.split('/').last;
      final tempPath = '${tempDir.path}/$fileName';
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);

      final isVideo = fileName.toLowerCase().endsWith('.mp4');

      if (isVideo) {
        await Gal.putVideo(tempPath, album: 'Portal SI Pictures');
      } else {
        await Gal.putImage(tempPath, album: 'Portal SI Pictures');
      }

      message.localMediaPath = tempPath;
      await _saveMessagesToCache;
      debugPrint("Media berhasil disimpan di album 'Portal SI Pictures'.");
    } catch (e) {
      debugPrint("Gagal mengunduh atau menyimpan media: $e");
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await SecureStorage.getUserId();
      if (userId == null) throw Exception("User ID not found in storage");
      _currentUser = User(
        id: userId,
        username: await SecureStorage.getUsername() ?? 'Saya',
        profilePictureUrl: await SecureStorage.getProfilePicture(),
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
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey();
      final String? cachedData = prefs.getString(key);

      if (cachedData != null) {
        // --- Scenario 1: Cache Ditemukan ---
        debugPrint(
            "Cache ditemukan untuk user ${recipient.id}. Memuat dari cache.");
        final List<dynamic> messagesJson = jsonDecode(cachedData);
        _messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList()
            .reversed
            .toList();
        _isLoading = false;
        notifyListeners(); // Tampilkan data cache ke UI secepatnya

        // Ambil data baru/belum terbaca dari server
        await _fetchUnreadMessages();
        _processMediaMessages();
      } else {
        // --- Scenario 2: Cache Tidak Ditemukan ---
        debugPrint("Cache tidak ditemukan. Mengambil data lengkap dari API.");
        _messages =
        await _chatService.getConversation(_currentUser!, recipient);
        _messages = _messages.reversed.toList();
        await _saveMessagesToCache; // Simpan ke cache setelah fetch berhasil
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      debugPrint("Error terdeteksi: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchUnreadMessages() async {
    debugPrint("Mencari pesan baru dari API conversation-from...");
    try {
      final token = await SecureStorage.getToken();
      if (token == null) throw Exception("Token tidak ditemukan.");

      final url = Uri.parse(
          'https://api-new.portalsi.com/api/messages/conversation-from/${recipient.id}');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final List<dynamic> newMessagesJson = jsonDecode(response.body);
        final List<ChatMessage> fetchedMessages = newMessagesJson
            .map((json) => ChatMessage.fromJson(json, _currentUser!, recipient))
            .toList();

        // Filter hanya pesan yang belum ada di cache (berdasarkan ID)
        // dan yang 'is_read' nya false sesuai permintaan
        final existingMessageIds = _messages.map((m) => m.id).toSet();
        final List<ChatMessage> newUnreadMessages =
        fetchedMessages.where((newMessage) {
          return !existingMessageIds.contains(newMessage.id) &&
              newMessage.status != MessageStatus.read;
        }).toList();

        if (newUnreadMessages.isNotEmpty) {
          debugPrint(
              "${newUnreadMessages.length} pesan baru ditemukan dan ditambahkan.");
          _messages.insertAll(
              0, newUnreadMessages); // Tambahkan ke paling atas (terbaru)
          await _saveMessagesToCache; // Update cache dengan data gabungan
          notifyListeners();
          _processMediaMessages();
        } else {
          debugPrint("Tidak ada pesan baru yang belum dibaca.");
        }
      } else {
        throw Exception("Gagal mengambil pesan baru: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error saat fetch unread messages: $e");
    }
  }

  void _processMediaMessages() {
    // Jalankan di latar belakang tanpa menunggu selesai
    for (var message in _messages) {
      if (message.mediaUrl != null && message.localMediaPath == null) {
        _downloadAndSaveMedia(message);
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _currentUser == null) return;

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

    // UI update sementara untuk feedback instan
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 1. Kirim pesan ke server seperti biasa.
      final sentMessage = await _chatService.sendMessage(
        receiverId: recipient.id!,
        content: text.trim(),
        currentUser: _currentUser!,
        recipient: recipient,
      );

      // 2. [ALUR BARU] Mulai manipulasi cache.
      //    Baca kondisi terakhir dari cache di disk.
      List<ChatMessage> messagesFromCache = await _loadMessagesFromCache();

      // 3. Cari pesan temporer di dalam daftar yang dimuat dari cache.
      final index = messagesFromCache.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        // Ganti pesan temporer dengan data pesan asli dari server.
        messagesFromCache[index] = sentMessage;
      } else {
        // Jika karena suatu hal pesan temporer tidak ada, tambahkan saja.
        messagesFromCache.add(sentMessage);
      }

      // 4. Simpan kembali daftar yang sudah diperbarui ke cache di disk.
      await _saveMessagesToCache(messagesFromCache);

      // 5. Muat ulang state dari cache untuk ditampilkan di UI.
      //    Daftar dari cache diurutkan terlama->terbaru, kita balik untuk UI.
      _messages = messagesFromCache.reversed.toList();

    } catch (e) {
      // Jika gagal, update status pesan temporer menjadi 'failed'.
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
      }
      debugPrint("Gagal mengirim pesan: $e");
    } finally {
      // Selalu update UI di akhir, baik berhasil maupun gagal.
      notifyListeners();
    }
  }

  // Fungsi ini dipanggil untuk mengirim gambar dari galeri
  Future<void> sendMediaMessage(List<AssetEntity> assets) async {
    // Karena API hanya menerima satu media per request, kita kirim satu per satu
    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) {
        // Panggil fungsi pengiriman file tunggal yang sudah kita buat
        await sendMediaFile(file);
      }
    }
  }

  // Fungsi terpusat untuk mengirim satu file media (dari kamera atau galeri)
  Future<void> sendMediaFile(File mediaFile) async {
    if (_currentUser == null) return;

    final progressNotifier = ValueNotifier(0.0);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      type: MessageType.image, // Bisa disesuaikan jika mendukung video
      sender: _currentUser!,
      recipient: recipient,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      localFile: mediaFile,
      uploadProgress: progressNotifier,
    );

    // UI update sementara
    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // 1. Kirim file ke server.
      //    (Logika request multipart tetap sama...)
      final finalMessage = await _uploadMediaAndGetResponse(mediaFile, progressNotifier);

      // 2. [ALUR BARU] Mulai manipulasi cache.
      //    Baca kondisi terakhir dari cache di disk.
      List<ChatMessage> messagesFromCache = await _loadMessagesFromCache();

      // 3. Cari pesan media temporer di dalam daftar cache.
      final index = messagesFromCache.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        // Ganti dengan data pesan asli dari server.
        messagesFromCache[index] = finalMessage;
      } else {
        messagesFromCache.add(finalMessage);
      }

      // 4. Simpan kembali daftar yang sudah diperbarui ke cache.
      await _saveMessagesToCache(messagesFromCache);

      // 5. Muat ulang state dari cache untuk ditampilkan di UI.
      _messages = messagesFromCache.reversed.toList();

    } catch (e) {
      debugPrint("Gagal mengirim media: $e");
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
      }
    } finally {
      notifyListeners();
    }
  }

// BUAT FUNGSI HELPER INI untuk merapikan kode `sendMediaFile`
// (Letakkan di dalam class ChatRoomController juga)
  Future<ChatMessage> _uploadMediaAndGetResponse(File mediaFile, ValueNotifier<double> progressNotifier) async {
    final bearerToken = await SecureStorage.getToken();
    if (bearerToken == null) throw Exception('Bearer token not found.');

    final uri = Uri.parse('https://api-new.portalsi.com/api/messages/send');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $bearerToken'
      ..headers['Accept'] = 'application/json'
      ..fields['receiver_id'] = recipient.id.toString()
      ..fields['content'] = '';

    final fileLength = await mediaFile.length();
    final fileStream = mediaFile.openRead();

    int bytesSent = 0;
    final Stream<List<int>> transformedStream = fileStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          bytesSent += data.length;
          progressNotifier.value = bytesSent / fileLength;
          sink.add(data);
        },
        handleDone: (sink) {
          progressNotifier.value = 1.0;
          sink.close();
        },
        handleError: (error, stack, sink) => sink.addError(error),
      ),
    );

    request.files.add(http.MultipartFile(
      'media',
      transformedStream,
      fileLength,
      filename: path.basename(mediaFile.path),
    ));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(responseBody);
      final realMessageData = jsonResponse['data'];
      return ChatMessage.fromJson(realMessageData, _currentUser!, recipient);
    } else {
      throw Exception('Gagal mengirim media: Error ${response.statusCode}');
    }
  }

  Future<List<ChatMessage>> _loadMessagesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey();
      final String? cachedData = prefs.getString(key);

      if (cachedData != null) {
        final List<dynamic> messagesJson = jsonDecode(cachedData);
        // Data di cache sudah diurutkan dari terlama ke terbaru.
        // Kita kembalikan dalam bentuk list yang bisa langsung dipakai.
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Gagal memuat cache: $e");
    }
    // Kembalikan list kosong jika cache tidak ada atau error.
    return [];
  }

  Future<void> _handleIncomingMessage(ChatMessage newMessage) async {
    // 1. Membaca kondisi terakhir dari cache di disk.
    List<ChatMessage> currentMessages = await _loadMessagesFromCache();

    // 2. Menambahkan pesan baru ke daftar yang sudah dibaca.
    currentMessages.add(newMessage);

    // 3. Simpan kembali daftar yang sudah diperbarui ke cache di disk.
    //    (Kita akan sedikit memodifikasi _saveMessagesToCache untuk ini)
    await _saveMessagesToCache(currentMessages);

    // 4. Muat ulang state dari cache untuk ditampilkan di UI.
    //    Daftar dari cache diurutkan terlama->terbaru, kita balik untuk UI.
    _messages = currentMessages.reversed.toList();

    // 5. Beri tahu UI untuk menggambar ulang.
    notifyListeners();
  }
}