// lib/controllers/chat_room_controller.dart (SUDAH DIPERBAIKI TOTAL)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:gal/gal.dart';
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

// --- TAMBAHKAN IMPORT INI ---
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data'; // Untuk Uint8List

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

  // ... (Fungsi-fungsi lain dari _initialize hingga sebelum sendMediaMessage tidak perlu diubah)
  // ... (Silakan salin-tempel sisa fungsi Anda di sini)
  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
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
        if (_isRecipientOnline != isOnline) {
          _isRecipientOnline = isOnline;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Gagal memeriksa status online: $e");
      if (_isRecipientOnline) {
        _isRecipientOnline = false;
        notifyListeners();
      }
    }
  }

  String _getCacheKey() {
    return 'chat_history_${_currentUser!.id}_${recipient.id}';
  }

  Future<void> _saveMessagesToCache(List<ChatMessage> messagesToSave) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey();
      messagesToSave.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final List<Map<String, dynamic>> messagesJson =
      messagesToSave.map((m) => m.toJson()).toList();
      await prefs.setString(key, jsonEncode(messagesJson));
    } catch (e) {
      debugPrint("Gagal menyimpan cache: $e");
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (recipient.id == null) {
      debugPrint("Mark as read failed: Recipient ID is null.");
      return;
    }
    try {
      final token = await SecureStorage.getToken();
      if (token == null) {
        throw Exception("Authentication token not found.");
      }
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
    if (_currentUser != null) {
      final ids = [_currentUser!.id, recipient.id]..sort();
      final roomId = ids.join('-');
      // final channelName = 'private-dm.$roomId';
      // AuthService.webSocketService?.unsubscribeFromChannel(channelName);
    }
    _messageSubscription?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }


  Future<void> reloadConversation() async {
    debugPrint("🔄 Memuat ulang percakapan dari AppBar...");

    // Cukup panggil kembali fungsi fetchMessages yang sudah ada.
    // Fungsi ini sudah menangani state loading dan akan memperbarui UI.
    await loadMessagesAgain();
  }


  void _startRealtimeListeners() {
    if (_currentUser == null) return;
    if (AuthService.webSocketService == null) {
      debugPrint("WebSocketService belum siap.");
      return;
    }
    final ids = [_currentUser!.id, recipient.id]..sort();
    final roomId = ids.join('-');
    final channelName = 'private-dm.$roomId';
    AuthService.webSocketService!.subscribeToChannel(channelName);
    _messageSubscription = AuthService.webSocketService!.eventStream.listen(
          (AppEvent appEvent) async {
        if (appEvent.channel == channelName && appEvent.event == 'dm.new') {
          try {
            final messageData = appEvent.data['message'];
            final newMessage = ChatMessage.fromJson(messageData, _currentUser!, recipient);
            final isMessageExist = _messages.any((m) => m.id == newMessage.id);
            if (!isMessageExist && newMessage.sender.id != _currentUser!.id) {
              await _handleIncomingMessage(newMessage);
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
      await _saveMessagesToCache(_messages);
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
        debugPrint(
            "Cache ditemukan untuk user ${recipient.id}. Memuat dari cache.");
        final List<dynamic> messagesJson = jsonDecode(cachedData);
        _messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList()
            .reversed
            .toList();
        _isLoading = false;
        notifyListeners();
        await _fetchUnreadMessages();
        _processMediaMessages();
      } else {
        debugPrint("Cache tidak ditemukan. Mengambil data lengkap dari API.");
        _messages =
        await _chatService.getConversation(_currentUser!, recipient);
        _messages = _messages.reversed.toList();
        await _saveMessagesToCache(_messages);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      debugPrint("Error terdeteksi: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessagesAgain() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      debugPrint("Mengambil Ulang dari API.");
      _messages =
      await _chatService.getConversation(_currentUser!, recipient);
      _messages = _messages.reversed.toList();
      await _saveMessagesToCache(_messages);
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
              0, newUnreadMessages);
          await _saveMessagesToCache(_messages);
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
    _messages.insert(0, tempMessage);
    notifyListeners();
    try {
      final sentMessage = await _chatService.sendMessage(
        receiverId: recipient.id!,
        content: text.trim(),
        currentUser: _currentUser!,
        recipient: recipient,
      );
      List<ChatMessage> messagesFromCache = await _loadMessagesFromCache();
      final index = messagesFromCache.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messagesFromCache[index] = sentMessage;
      } else {
        messagesFromCache.add(sentMessage);
      }
      await _saveMessagesToCache(messagesFromCache);
      _messages = messagesFromCache.reversed.toList();
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

  // ======================================================================
  // --- PERUBAHAN UTAMA DIMULAI DARI SINI ---
  // ======================================================================

  /// [MODIFIKASI] Fungsi ini sekarang menjadi adaptif terhadap platform.
  Future<void> sendMediaMessage(List<AssetEntity> assets) async {
    for (final asset in assets) {
      if (kIsWeb) {
        // --- LOGIKA UNTUK WEB ---
        final bytes = await asset.originBytes;
        final filename = await asset.titleAsync;
        if (bytes != null) {
          await _sendMediaBytes(bytes, filename);
        }
      } else {
        // --- LOGIKA UNTUK MOBILE (YANG SUDAH ADA) ---
        final file = await asset.file;
        if (file != null) {
          await sendMediaFile(file);
        }
      }
    }
  }

  /// [BARU] Fungsi terpusat untuk mengirim media dari data BYTES (untuk web).
  Future<void> _sendMediaBytes(Uint8List mediaBytes, String filename) async {
    if (_currentUser == null) return;

    final progressNotifier = ValueNotifier(0.0);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      type: MessageType.image,
      sender: _currentUser!,
      recipient: recipient,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      // PERBAIKAN: Ganti 'localByte' menjadi 'localBytes'
      localBytes: mediaBytes,
      uploadProgress: progressNotifier,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      // Panggil helper upload yang menggunakan bytes
      final finalMessage = await _uploadMediaBytesAndGetResponse(mediaBytes, filename, progressNotifier);

      List<ChatMessage> messagesFromCache = await _loadMessagesFromCache();
      final index = messagesFromCache.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messagesFromCache[index] = finalMessage;
      } else {
        messagesFromCache.add(finalMessage);
      }
      await _saveMessagesToCache(messagesFromCache);
      _messages = messagesFromCache.reversed.toList();

    } catch (e) {
      debugPrint("Gagal mengirim media dari bytes: $e");
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        _messages[index].status = MessageStatus.failed;
      }
    } finally {
      notifyListeners();
    }
  }

  /// [BARU] Fungsi helper untuk mengunggah BYTES dan mendapatkan response (untuk web).
  Future<ChatMessage> _uploadMediaBytesAndGetResponse(Uint8List mediaBytes, String filename, ValueNotifier<double> progressNotifier) async {
    final bearerToken = await SecureStorage.getToken();
    if (bearerToken == null) throw Exception('Bearer token not found.');

    final uri = Uri.parse('https://api-new.portalsi.com/api/messages/send');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $bearerToken'
      ..headers['Accept'] = 'application/json'
      ..fields['receiver_id'] = recipient.id.toString()
      ..fields['content'] = '';

    // Perbedaan utama ada di sini: menggunakan MultipartFile.fromBytes
    request.files.add(http.MultipartFile.fromBytes(
      'media', // Sesuaikan dengan nama field di API
      mediaBytes,
      filename: filename,
    ));

    // Catatan: Progress tracking untuk fromBytes tidak sesederhana fromPath.
    // Untuk saat ini, kita akan update progress menjadi selesai saat response diterima.
    final response = await request.send();
    progressNotifier.value = 1.0; // Anggap selesai setelah request dikirim.

    final responseBody = await response.stream.bytesToString();
    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(responseBody);
      final realMessageData = jsonResponse['data'];
      return ChatMessage.fromJson(realMessageData, _currentUser!, recipient);
    } else {
      throw Exception('Gagal mengirim media: Error ${response.statusCode}');
    }
  }


  /// Fungsi ini (untuk mobile) tidak diubah.
  Future<void> sendMediaFile(File mediaFile) async {
    if (_currentUser == null) return;

    final progressNotifier = ValueNotifier(0.0);
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempMessage = ChatMessage(
      id: tempId,
      type: MessageType.image,
      sender: _currentUser!,
      recipient: recipient,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      localFile: mediaFile,
      uploadProgress: progressNotifier,
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final finalMessage = await _uploadMediaAndGetResponse(mediaFile, progressNotifier);

      List<ChatMessage> messagesFromCache = await _loadMessagesFromCache();
      final index = messagesFromCache.indexWhere((m) => m.id == tempId);
      if (index != -1) {
        messagesFromCache[index] = finalMessage;
      } else {
        messagesFromCache.add(finalMessage);
      }
      await _saveMessagesToCache(messagesFromCache);
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

  /// Fungsi ini (untuk mobile) tidak diubah.
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
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("Gagal memuat cache: $e");
    }
    return [];
  }

  Future<void> _handleIncomingMessage(ChatMessage newMessage) async {
    List<ChatMessage> currentMessages = await _loadMessagesFromCache();
    currentMessages.add(newMessage);
    await _saveMessagesToCache(currentMessages);
    _messages = currentMessages.reversed.toList();
    notifyListeners();
  }
}