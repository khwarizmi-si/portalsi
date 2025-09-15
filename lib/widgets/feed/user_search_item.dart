// lib/widgets/feed/user_search_item.dart

import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class UserSearchItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserSearchItem({Key? key, required this.user, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // FIX 2: Berikan nilai default jika username null
                _buildProfilePicture(user.username ?? '?', user.profilePictureUrl ?? ''),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserInfo(user),
                ),
                _buildViewButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePicture(String username, String profilePicture) {
    return CircleAvatar(
      radius: 28,
      backgroundImage:
      profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
      backgroundColor: Colors.grey[300],
      child: profilePicture.isEmpty
          ? Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.grey[600],
        ),
      )
          : null,
    );
  }

  Widget _buildUserInfo(User user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.username ?? 'No Username', // Beri nilai default
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[900],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
          ],
        ),
        // FIX 1: Cek null sebelum cek isNotEmpty
        if (user.fullName != null && user.fullName!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            user.fullName!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // FIX 1: Cek null sebelum cek isNotEmpty
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.bio!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildViewButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'View',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}