// lib/widgets/feed/feed_post_preview.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../../components/video_thumbnail_widget.dart';
import '../../models/post_model.dart'; // Pastikan path ini benar

class FeedPostPreview extends StatelessWidget {
  final Post post;

  const FeedPostPreview({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      // Efek blur pada background
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Konten utama popup
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gambar Postingan
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Hero(
                      tag:
                          'feed-post-${post.id}', // Tag HARUS sama dengan di grid
                      child: SizedBox(
                        height: 300,
                        child: post.isVideo && (post.mediaUrl ?? '').isNotEmpty
                            ? VideoThumbnailWidget(
                                videoUrl: post.mediaUrl!,
                                thumbnailUrl: post.thumbnailUrl,
                              )
                            : CachedNetworkImage(
                                imageUrl: post.mediaUrl ?? '',
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image,
                                      color: Colors.grey[400]),
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Informasi Post
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage:
                                  post.user.profilePictureUrl != null
                                      ? CachedNetworkImageProvider(
                                          post.user.profilePictureUrl!)
                                      : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              post.user.username,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        if (post.caption != null &&
                            post.caption!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            post.caption!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tombol Aksi
            _buildActionButton(context, Icons.share_outlined, 'Bagikan'),
            const SizedBox(height: 8),
            _buildActionButton(context, Icons.link, 'Salin Tautan'),
            const SizedBox(height: 8),
            _buildActionButton(context, Icons.flag_outlined, 'Laporkan',
                isDestructive: true),
          ],
        ),
      ),
    );
  }

  // Helper untuk membuat tombol aksi
  Widget _buildActionButton(BuildContext context, IconData icon, String label,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: () {
        // TODO: Tambahkan logika untuk setiap tombol di sini
        Navigator.of(context).pop(); // Tutup dialog setelah diklik
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isDestructive ? Colors.red : Colors.black, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDestructive ? Colors.red : Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
