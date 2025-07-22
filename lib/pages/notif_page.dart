import 'package:flutter/material.dart';
import '../components/bottom_navigation.dart';
import 'dashboard_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedIndex = 3; // Assuming notifications is at index 3

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add your navigation logic here
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
              );
            },
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
              'https://i.pinimg.com/736x/7f/b6/05/7fb60538564ceef755080d388a5148ea.jpg',
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
              'https://i.pinimg.com/736x/94/39/cc/9439cc145747f432fed80917ca405ad5.jpg',
              'jiwanyaa',
              'menyukai cerita Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/db/a1/87/dba1876518e51faf50bc88a928b4d821.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/94/39/cc/9439cc145747f432fed80917ca405ad5.jpg',
              'jiwanyaa',
              'menyukai postingan Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/9b/26/c9/9b26c9599f066aa085a9415a426727dc.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/6e/8f/9d/6e8f9df9a785c7867fc638ee0e334707.jpg',
              'r_herdians',
              'menyukai reel Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/12/aa/9b/12aa9ba5f065173862a5589c09f40b19.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/33/6b/e5/336be5a2a0d218ce89348072b46d0e74.jpg',
              'wannshoot.id',
              'menyukai cerita Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/12/aa/9b/12aa9ba5f065173862a5589c09f40b19.jpg',
            ),
            _buildNotificationItem(
              'https://i.pinimg.com/736x/4d/a9/b5/4da9b5b7a9d0e5bdcbdf5c301b15a3e1.jpg',
              'kiantza',
              'menyukai cerita Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/12/aa/9b/12aa9ba5f065173862a5589c09f40b19.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/ee/72/b5/ee72b5d69d9747d8c940e0f94ec6c3a6.jpg',
              'vya_created',
              'menyukai cerita Anda.',
              '20 menit',
              true,
              'https://i.pinimg.com/736x/12/aa/9b/12aa9ba5f065173862a5589c09f40b19.jpg',
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Kemarin'),
            const SizedBox(height: 12),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/ee/72/b5/ee72b5d69d9747d8c940e0f94ec6c3a6.jpg',
              'vya_created',
              'baru saja membagikan reel baru.',
              '1 jam',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/94/39/cc/9439cc145747f432fed80917ca405ad5.jpg',
              'jiwanyaa',
              'baru saja menambahkan cerita.',
              '20 menit',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/6e/8f/9d/6e8f9df9a785c7867fc638ee0e334707.jpg',
              'r_herdians',
              'baru saja menambahkan cerita.',
              '20 menit',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),
            _buildNotificationItem(
              'https://i.pinimg.com/736x/4d/a9/b5/4da9b5b7a9d0e5bdcbdf5c301b15a3e1.jpg',
              'kiantza',
              'baru saja menambahkan cerita.',
              '20 menit',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('7 hari terakhir'),
            const SizedBox(height: 12),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/33/6b/e5/336be5a2a0d218ce89348072b46d0e74.jpg',
              'wannshoot.id',
              'baru saja membagikan postingan baru.',
              '1 mg',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),

            _buildNotificationItem(
              'https://i.pinimg.com/736x/94/39/cc/9439cc145747f432fed80917ca405ad5.jpg',
              'jiwanyaa',
              'baru saja membagikan postingan baru.',
              '1 mg',
              false,
              'https://i.pinimg.com/736x/e7/0d/21/e70d2112848f65c4773fb695eb955a69.jpg',
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('30 hari terakhir'),
            const SizedBox(height: 12),

            _buildFollowNotificationItem(
              'https://i.pinimg.com/736x/6e/8f/9d/6e8f9df9a785c7867fc638ee0e334707.jpg',
              'r_herdians',
              'mulai mengikuti Anda.',
              '4 mg',
            ),

            _buildFollowNotificationItem(
              'https://i.pinimg.com/736x/33/6b/e5/336be5a2a0d218ce89348072b46d0e74.jpg',
              'wannshoot.id',
              'mulai mengikuti Anda.',
              '4 mg',
            ),

            _buildFollowNotificationItem(
              'https://i.pinimg.com/736x/94/39/cc/9439cc145747f432fed80917ca405ad5.jpg',
              'jiwanyaa',
              'mulai mengikuti Anda.',
              '4 mg',
            ),
            _buildFollowNotificationItem(
              'https://i.pinimg.com/736x/4d/a9/b5/4da9b5b7a9d0e5bdcbdf5c301b15a3e1.jpg',
              'kiantza',
              'mulai mengikuti Anda.',
              '4 mg',
            ),

            _buildFollowNotificationItem(
              'https://i.pinimg.com/736x/ee/72/b5/ee72b5d69d9747d8c940e0f94ec6c3a6.jpg',
              'vya_created',
              'mulai mengikuti Anda.',
              '4 mg',
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onTap: _onBottomNavTapped,
        ),
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
