// lib/controllers/chat_room_controller.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';
import '../models/chat.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../utils/secure_storage.dart';

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

  ChatRoomController({required this.recipient}) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCurrentUser();
    if (_currentUser != null) {
      await fetchMessages();
      _connectAndListen();
    } else {
      _errorMessage = "Tidak bisa memuat data pengguna saat ini.";
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint("ChatRoomController disposed. Disconnecting WebSocket.");
    _messageSubscription?.cancel();
    _chatService.disconnect();
    super.dispose();
  }

  void _connectAndListen() {
    if (_currentUser == null) return;

    _chatService.connect(
      _currentUser!.id.toString(),
      currentUser: _currentUser!,
      recipient: recipient,
    );
    _messageSubscription?.cancel();
    _messageSubscription = _chatService.messages.listen(
          (newMessage) {
        if (newMessage.sender.id != _currentUser!.id) {
          final isMessageExist = _messages.any((m) => m.id == newMessage.id);
          if (!isMessageExist) {
            _messages.insert(0, newMessage);
            notifyListeners();
          }
        }
      },
      onError: (error) {
        debugPrint("Error on message stream: $error");
      },
      onDone: () {
        debugPrint("Message stream was closed.");
      },
      cancelOnError: false,
    );
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
      final index = _messages.indexWhere((m) => m.id == tempId);
      if (index != -1) {
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

    // [PERUBAHAN 1] Buat ValueNotifier untuk pesan ini
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
      uploadProgress: progressNotifier, // <-- Masukkan notifier ke pesan
    );

    _messages.insert(0, tempMessage);
    notifyListeners();

    try {
      final bearerToken = await SecureStorage.getToken();
      if (bearerToken == null) throw Exception('Bearer token not found.');

      final uri = Uri.parse('https://api-new.portalsi.com/api/messages/send');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $bearerToken'
        ..headers['Accept'] = 'application/json'
        ..fields['receiver_id'] = recipient.id.toString()
        ..fields['content'] = '';

      // [PERUBAHAN 2] Membuat MultipartFile dari stream untuk melacak progres
      final fileLength = await mediaFile.length();
      final fileStream = mediaFile.openRead();

      // StreamTransformer untuk memantau byte yang dikirim
      int bytesSent = 0;
      final Stream<List<int>> transformedStream = fileStream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            bytesSent += data.length;
            final progress = bytesSent / fileLength;
            // Update notifier yang akan didengarkan oleh UI
            progressNotifier.value = progress;
            sink.add(data);
          },
          handleDone: (sink) {
            progressNotifier.value = 1.0; // Pastikan selesai di 100%
            sink.close();
          },
          handleError: (error, stack, sink) {
            debugPrint("Error reading file stream: $error");
            sink.addError(error);
          },
        ),
      );

      final multipartFile = http.MultipartFile(
        'media',
        transformedStream,
        fileLength,
        filename: path.basename(mediaFile.path),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseBody);
        final realMessageData = jsonResponse['data'];
        final finalMessage = ChatMessage.fromJson(realMessageData, _currentUser!, recipient);

        final index = _messages.indexWhere((m) => m.id == tempId);
        if (index != -1) {
          _messages[index] = finalMessage;
        }

      } else {
        throw Exception('Gagal mengirim media: Error ${response.statusCode}');
      }
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
}