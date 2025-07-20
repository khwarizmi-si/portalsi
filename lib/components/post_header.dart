import 'package:flutter/material.dart';

class PostHeader extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String profileImageUrl;
  final bool isVerified;
  final Map<String, dynamic> user;

  const PostHeader({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.profileImageUrl,
    required this.isVerified,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(profileImageUrl),
        radius: 20,
        onBackgroundImageError: (_, __) {},
      ),
      title: Row(
        children: [
          Text(
            username,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ],
      ),
      subtitle: Text(timeAgo),
      onTap: () {
        // Navigasi ke profil user bisa ditambahkan di sini
        print('Tampilkan profil user: ${user['username']}');
      },
    );
  }
}
