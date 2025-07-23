import 'package:flutter/material.dart';

class PostHeader extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String profileImageUrl;
  final bool isVerified;
  final Map<String, dynamic> user;
  final VoidCallback? onProfileTap;

  const PostHeader({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.profileImageUrl,
    required this.isVerified,
    required this.user,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: GestureDetector(
        onTap: onProfileTap,
        child: CircleAvatar(
          backgroundImage: NetworkImage(profileImageUrl),
          radius: 30,
          onBackgroundImageError: (_, __) {},
        ),
      ),
      title: GestureDetector(
        onTap: onProfileTap,
        child: Row(
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
      ),
      subtitle: Text(timeAgo),
    );
  }
}
