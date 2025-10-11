import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/draft_model.dart';
import '../services/draft_service.dart';
import 'edit_clips/edit_clips_page.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  late Future<List<Draft>> _draftsFuture;
  final DraftService _draftService = DraftService();

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftsFuture = _draftService.getAllDrafts();
    });
  }

  Future<void> _deleteDraft(String draftId) async {
    await _draftService.deleteDraft(draftId);
    _loadDrafts();
  }

  // --- AKTIFKAN FUNGSI INI ---
  Future<void> _openDraft(Draft draft) async {
    final videoFile = File(draft.originalVideoPath);

    if (!await videoFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: File video asli tidak ditemukan atau telah dihapus.'))
      );
      return;
    }

    // Navigasi ke EditClipsPage, membawa file video dan objek draf
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditClipsPage(
          videoFile: videoFile,
          initialDraft: draft,
        ))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Draf Postingan'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<List<Draft>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          final drafts = snapshot.data;
          if (drafts == null || drafts.isEmpty) {
            return const Center(child: Text('Tidak ada draf tersimpan.', style: TextStyle(color: Colors.grey)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(4.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              return _DraftItem(
                draft: draft,
                onTap: () => _openDraft(draft), // Pastikan onTap terhubung
                onDelete: () => _deleteDraft(draft.id),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget _DraftItem tidak perlu diubah
class _DraftItem extends StatelessWidget {
  final Draft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftItem({required this.draft, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<dynamic>(
            future: VideoThumbnail.thumbnailData(
              video: draft.originalVideoPath,
              imageFormat: ImageFormat.JPEG,
              maxWidth: 200,
              quality: 25,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                return Image.memory(snapshot.data, fit: BoxFit.cover);
              }
              return Container(color: Colors.grey[800]);
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}