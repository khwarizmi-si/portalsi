import 'package:flutter/material.dart';

class PostActions extends StatelessWidget {
  final int likes;
  final int comments;
  final bool isLiked; // Tambahan untuk status like
  final VoidCallback onLikePressed;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const PostActions({
    super.key,
    required this.likes,
    required this.comments,
    required this.isLiked,
    required this.onLikePressed,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Mengambil warna dari tema untuk konsistensi
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color secondaryTextColor =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          // Aksi Like dan Komentar
          _buildActionItem(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: likes.toString(),
            color: primaryColor,
            onTap: onLikePressed,
            // Tambahkan background untuk item pertama
            hasBackground: true,
          ),
          const SizedBox(width: 16),
          _buildActionItem(
            icon: Icons.chat_bubble_outline,
            label: comments.toString(),
            color: secondaryTextColor,
            onTap: onCommentPressed,
          ),

          const Spacer(),

          // Aksi Share
          IconButton(
            onPressed: onSharePressed,
            splashRadius: 24, // Radius efek splash
            icon: Transform.rotate(
              angle: -0.5,
              child: Icon(Icons.send, color: secondaryTextColor, size: 22),
            ),
            tooltip: 'Bagikan', // Tambahan untuk aksesibilitas
          ),
        ],
      ),
    );
  }

  /// Helper widget untuk membangun setiap item aksi (Like, Comment)
  /// Ini mengurangi duplikasi kode secara signifikan.
  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool hasBackground = false,
  }) {
    // Gunakan InkWell untuk mendapatkan efek splash saat ditekan
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(20), // Samakan dengan radius background
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: hasBackground
            ? BoxDecoration(
                color:
                    color.withOpacity(0.1), // Warna background dari warna utama
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cara Menggunakannya di Widget Induk:
//
// PostActions(
//   likes: post.likes,
//   comments: post.comments,
//   isLiked: post.isLikedByUser, // Anda perlu state ini
//   onLikePressed: () {
//     // Logika untuk menyukai/batal suka post
//   },
//   onCommentPressed: () {
//     showCommentSheet(context, post.id);
//   },
//   onSharePressed: () {
//     // Logika untuk membagikan post
//   },
// )
