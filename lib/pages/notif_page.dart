import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Cerita Tentang Anda'),
          const SizedBox(height: 12),
          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'Penyebutan',
            '1 cerita menyebutkan Anda.',
            '',
            false,
            null,
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Hari Ini'),
          const SizedBox(height: 12),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'jiwanyaa',
            'menyukai cerita Anda.',
            '20 menit',
            true,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'jiwanyaa',
            'menyukai postingan Anda.',
            '20 menit',
            true,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'r_herdians',
            'menyukai reel Anda.',
            '20 menit',
            true,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'wannshoot.id',
            'menyukai cerita Anda.',
            '20 menit',
            true,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'vya_created',
            'menyukai cerita Anda.',
            '20 menit',
            true,
            'https://via.placeholder.com/50',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Kemarin'),
          const SizedBox(height: 12),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'vya_created',
            'baru saja membagikan reel baru.',
            '1 jam',
            false,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'jiwanyaa',
            'baru saja menambahkan cerita.',
            '20 menit',
            false,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'r_herdians',
            'baru saja menambahkan cerita.',
            '20 menit',
            false,
            'https://via.placeholder.com/50',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('7 hari terakhir'),
          const SizedBox(height: 12),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'wannshoot.id',
            'baru saja membagikan postingan baru.',
            '1 mg',
            false,
            'https://via.placeholder.com/50',
          ),

          _buildNotificationItem(
            'https://via.placeholder.com/40',
            'jiwanyaa',
            'baru saja membagikan postingan baru.',
            '1 mg',
            false,
            'https://via.placeholder.com/50',
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('30 hari terakhir'),
          const SizedBox(height: 12),

          _buildFollowNotificationItem(
            'https://via.placeholder.com/40',
            'r_herdians',
            'mulai mengikuti Anda.',
            '4 mg',
          ),

          _buildFollowNotificationItem(
            'https://via.placeholder.com/40',
            'wannshoot.id',
            'mulai mengikuti Anda.',
            '4 mg',
          ),

          _buildFollowNotificationItem(
            'https://via.placeholder.com/40',
            'jiwanyaa',
            'mulai mengikuti Anda.',
            '4 mg',
          ),

          _buildFollowNotificationItem(
            'https://via.placeholder.com/40',
            'vya_created',
            'mulai mengikuti Anda.',
            '4 mg',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildNotificationItem(
    String profileImage,
    String username,
    String action,
    String time,
    bool hasBlueIndicator,
    String? contentImage,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(profileImage),
              ),
              if (hasBlueIndicator)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' $action'),
                    ],
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (contentImage != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(contentImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowNotificationItem(
    String profileImage,
    String username,
    String action,
    String time,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(profileImage)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: username,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' $action'),
                    ],
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Mengikuti',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
