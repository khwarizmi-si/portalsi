import 'package:flutter/material.dart';
import '../../../../models/song_model.dart';

class EditClipsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Song? selectedSong;
  final Song? recommendedSong;
  final bool isRecommendationLoading;
  final bool isRecommendationPlaying;
  final VoidCallback onMusicTap;
  final VoidCallback onRemoveSong;
  final VoidCallback onToggleRecommendation;
  final VoidCallback onUseRecommendation;
  final VoidCallback onSaveDraft;
  final VoidCallback? onBackButtonPressed;

  const EditClipsAppBar({
    super.key,
    this.selectedSong,
    this.recommendedSong,
    required this.isRecommendationLoading,
    required this.isRecommendationPlaying,
    required this.onMusicTap,
    required this.onRemoveSong,
    required this.onToggleRecommendation,
    required this.onUseRecommendation,
    required this.onSaveDraft,
    this.onBackButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.black),
        onPressed: onBackButtonPressed ?? () => Navigator.of(context).pop(),
      ),
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 56.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: onMusicTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.music_note, color: Colors.black, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: selectedSong != null
                            ? Text(
                          '${selectedSong!.trackName} - ${selectedSong!.artistName}',
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        )
                            : const Text(
                          'Tambahkan Musik',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                      ),
                      if (selectedSong != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: onRemoveSong,
                          child: const Icon(Icons.close, color: Colors.black, size: 16),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: isRecommendationLoading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                    : recommendedSong == null
                    ? const Center(child: Text("Gagal memuat tren", style: TextStyle(color: Colors.grey, fontSize: 12)))
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (recommendedSong!.artworkUrl.isNotEmpty)
                      CircleAvatar(radius: 25, backgroundImage: NetworkImage(recommendedSong!.artworkUrl)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recommendedSong!.trackName, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          Text(recommendedSong!.artistName, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(isRecommendationPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.black),
                      onPressed: onToggleRecommendation,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                      onPressed: onUseRecommendation,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: Colors.black),
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          onSelected: (String value) {
            if (value == 'save_draft') {
              onSaveDraft();
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'save_draft',
              child: Row(
                children: [
                  Icon(Icons.add_to_photos_outlined, color: Colors.black.withOpacity(0.9)),
                  const SizedBox(width: 12),
                  Text(
                    'Simpan di Draf',
                    style: TextStyle(color: Colors.black.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
      toolbarHeight: preferredSize.height,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}