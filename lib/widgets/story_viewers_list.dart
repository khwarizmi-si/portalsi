// lib/widgets/story_viewers_list.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Model sederhana untuk data pemirsa (ganti dengan model asli Anda)
class StoryViewer {
  final String username;
  final String avatarUrl;

  StoryViewer({required this.username, required this.avatarUrl});
}

class StoryViewersList extends StatelessWidget {
  // Data dummy (ganti dengan data asli dari API)
  final List<StoryViewer> viewers = [
    StoryViewer(username: 'farmumz', avatarUrl: 'https://i.pravatar.cc/150?img=4'),
    StoryViewer(username: '~iyall~', avatarUrl: 'https://i.pravatar.cc/150?img=6'),
    StoryViewer(username: 'fznhisyam_', avatarUrl: 'https://i.pravatar.cc/150?img=7'),
    StoryViewer(username: 'fdlmbrk_', avatarUrl: 'https://i.pravatar.cc/150?img=8'),
  ];

  StoryViewersList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // Tinggi awal sheet
      minChildSize: 0.3,     // Tinggi minimal
      maxChildSize: 0.8,     // Tinggi maksimal
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2C2C2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${viewers.length} viewers',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: () {
                        // TODO: Implementasi hapus cerita dari sini jika perlu
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Daftar Pemirsa
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(viewer.avatarUrl),
                      ),
                      title: Text(viewer.username, style: const TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.send_outlined, color: Colors.white), onPressed: () {}),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}