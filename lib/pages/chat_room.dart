// lib/chat_room_page.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../models/chat.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatUser user;
  const ChatRoomPage({super.key, required this.user});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final ImagePicker _picker = ImagePicker();

  // Tambahkan state untuk perekaman suara
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // Fungsi untuk mengirim pesan (sekarang lebih fleksibel)
  void _sendMessage(
      {String? text,
      File? file,
      MessageType type = MessageType.text,
      String? fileName}) {
    if (text == null && file == null) return;
    setState(() {
      _messages.add(ChatMessage(
        type: type,
        text: text,
        file: file,
        fileName: fileName,
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });
    _messageController.clear();
    _scrollToBottom();
  }

  // Menampilkan menu pilihan lampiran
  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Dokumen'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Logika untuk memilih gambar
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _sendMessage(file: File(pickedFile.path), type: MessageType.image);
    }
  }

  // Logika untuk memilih file (dokumen, video, dll)
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Bisa dispesifikkan, misal: FileType.video
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      // Deteksi tipe file sederhana
      final type =
          fileName.endsWith('.mp4') ? MessageType.video : MessageType.file;
      _sendMessage(file: file, type: type, fileName: fileName);
    }
  }

  // == FUNGSI BARU UNTUK REKAM SUARA ==

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Izin mikrofon ditolak';
    }

    setState(() => _isRecording = true);
    const encoder = AudioEncoder.aacLc;
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    _audioPath = '${appDocumentsDir.path}/recording.m4a';

    await _audioRecorder.start(const RecordConfig(encoder: encoder),
        path: _audioPath!);
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (path != null) {
      _sendMessage(
        type: MessageType.voice,
        file: File(path),
        fileName: 'Voice Note',
      );
    }
  }

  // == AKHIR FUNGSI BARU ==

  // ... (fungsi _scrollToBottom tetap sama)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(
        const Duration(milliseconds: 100),
        () => _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.user.imageUrl != null
                  ? AssetImage(widget.user.imageUrl!)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.user.name,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Tampilkan UI rekam jika sedang merekam
          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.red.withOpacity(0.1),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Merekam suara...', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),

          // Input bar yang sudah di-upgrade
          _MessageInputBar(
            controller: _messageController,
            isRecording: _isRecording,
            onSend: () => _sendMessage(text: _messageController.text.trim()),
            onAttach: _showAttachmentMenu,
            onStartRecord: _startRecording,
            onStopRecord: _stopRecording,
          ),
        ],
      ),
    );
  }
}

// WIDGET BUBBLE DINAMIS
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text!,
          style: TextStyle(color: message.isMe ? Colors.white : Colors.black),
        );
      case MessageType.image:
        return Image.file(message.file!);
      case MessageType.file:
      case MessageType.video:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                message.type == MessageType.video
                    ? Icons.videocam
                    : Icons.insert_drive_file,
                color: message.isMe ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.fileName ?? 'File',
                style: TextStyle(
                    color: message.isMe ? Colors.white : Colors.black),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.voice:
        // Voice Note Player akan dibuat terpisah agar lebih rapi
        return _VoiceNotePlayer(message: message);
      default:
        return const Text('Unsupported message type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: _buildMessageContent(),
      ),
    );
  }
}

// WIDGET INPUT BAR BARU
class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onStartRecord;
  final VoidCallback onStopRecord;

  const _MessageInputBar({
    required this.controller,
    required this.isRecording,
    required this.onSend,
    required this.onAttach,
    required this.onStartRecord,
    required this.onStopRecord,
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan ikon berdasarkan teks di controller
    final bool showSendButton = controller.text.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.add), onPressed: onAttach),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Kirim pesan...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            // Tombol dinamis: Send atau Mic
            if (showSendButton)
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: onSend,
              )
            else
              // GestureDetector untuk handle tap start/stop
              GestureDetector(
                onTap: isRecording ? onStopRecord : onStartRecord,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    isRecording ? Icons.stop_circle_outlined : Icons.mic,
                    color: isRecording
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// WIDGET KHUSUS UNTUK VOICE NOTE PLAYER
class _VoiceNotePlayer extends StatefulWidget {
  final ChatMessage message;
  const _VoiceNotePlayer({required this.message});

  @override
  State<_VoiceNotePlayer> createState() => __VoiceNotePlayerState();
}

class __VoiceNotePlayerState extends State<_VoiceNotePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.message.isMe ? Colors.white : Colors.black;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: color),
          onPressed: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play(DeviceFileSource(widget.message.file!.path));
            }
          },
        ),
        Expanded(
          child: Slider(
            min: 0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.toDouble(),
            onChanged: (value) async {
              final position = Duration(seconds: value.toInt());
              await _audioPlayer.seek(position);
            },
            activeColor: color,
            inactiveColor: color.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
