// lib/pages/preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_room_controller.dart';

class PreviewScreen extends StatelessWidget {
  final String imagePath;
  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Tampilkan gambar preview
          Center(
            child: Image.file(File(imagePath)),
          ),
          // Tombol Kembali
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Tombol Kirim
          Positioned(
            bottom: 40,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {
                final chatController = context.read<ChatRoomController>();
                // Panggil controller untuk mengirim file
                chatController.sendMediaFile(File(imagePath));
                // Kembali ke halaman chat
                Navigator.of(context).pop();
              },
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.send),
            ),
          )
        ],
      ),
    );
  }
}