// lib/widgets/story_viewers_list.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../components/verified_badge.dart';
import '../models/story_viewer_model.dart';
import '../services/story_service.dart';

class StoryViewersList extends StatefulWidget {
  final int storyId;
  final Function(int totalViewers) onDataLoaded;

  const StoryViewersList({
    Key? key,
    required this.storyId,
    required this.onDataLoaded,
  }) : super(key: key);

  @override
  _StoryViewersListState createState() => _StoryViewersListState();
}

class _StoryViewersListState extends State<StoryViewersList> {
  final StoryService _storyService = StoryService();
  late Future<StoryViewersInfo> _viewersInfoFuture;

  @override
  void initState() {
    super.initState();
    // Atur locale untuk timeago jika belum
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _viewersInfoFuture = _storyService.getStoryViewers(widget.storyId);
  }

  String _formatViewedAt(DateTime viewedAt) {
    return timeago.format(viewedAt, locale: 'id');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FutureBuilder<StoryViewersInfo>(
        future: _viewersInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat data: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.viewers.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada yang melihat cerita ini.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final viewersInfo = snapshot.data!;
          // Panggil callback untuk update jumlah viewers di halaman story
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onDataLoaded(viewersInfo.totalViewers);
          });

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  '${viewersInfo.totalViewers} Dilihat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              // Daftar Viewers
              Expanded(
                child: ListView.builder(
                  itemCount: viewersInfo.viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewersInfo.viewers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage(viewer.profilePictureUrl),
                      ),
                      title: Row(
                        children: [
                          Text(
                            viewer.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (viewer.isVerified)
                            VerifiedBadge(
                              size: 14,
                              // Kirim URL gambar agar dialog menampilkan foto yang benar
                              profilePictureUrl: viewer.profilePictureUrl,
                            ),
                        ],
                      ),
                      trailing: Text(
                        _formatViewedAt(viewer.viewedAt),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}