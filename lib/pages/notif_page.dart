import 'package:flutter/material.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';
import 'post_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // 2. Tentukan indeks halaman saat ini.
  // Home=0, Search=1, Add=2, Activity=3, Profile=4
  static const int _selectedIndex = 3;

  // 3. Buat logika untuk menangani navigasi
  void _onItemTapped(int index, BuildContext context) {
    if (index == _selectedIndex)
      return; // Tidak melakukan apa-apa jika tab yang sama ditekan

    switch (index) {
      case 0:
        // Gunakan pushReplacementNamed agar tidak menumpuk halaman
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/explore');
        break;
      // Tambahkan case untuk halaman lain jika ada
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationController(),
      child: Consumer<NotificationController>(
        builder: (context, controller, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Aktivitas',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0.5,
              actions: [
                if (controller.hasUnreadNotifications)
                  TextButton(
                    onPressed: () => controller.markAllAsRead(),
                    child: const Text('Tandai semua dibaca'),
                  )
              ],
            ),
            body: _buildBody(context, controller),

            // 4. Tambahkan properti bottomNavigationBar ke Scaffold
            // bottomNavigationBar: CustomBottomNavigation(
            //   selectedIndex: _selectedIndex,
            //   onTap: (index) => _onItemTapped(index, context),
            // ),
          );
        },
      ),
    );
  }


  Widget _buildBody(BuildContext context, NotificationController controller) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }
    if (controller.notifications.isEmpty) {
      return const Center(child: Text('Tidak ada aktivitas terbaru.'));
    }
    return _NotificationList(controller: controller);
  }
}

class _NotificationList extends StatelessWidget {
  final NotificationController controller;
  const _NotificationList({required this.controller});

  @override
  Widget build(BuildContext context) {
    final grouped = controller.groupedNotifications;
    final groupOrder = ['Minggu Ini', 'Bulan Ini', 'Lebih Awal'];

    return RefreshIndicator(
      onRefresh: () => controller.refreshNotifications(),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: groupOrder.map((groupName) {
          if (grouped.containsKey(groupName)) {
            return _NotificationGroupSection(
              title: groupName,
              notifications: grouped[groupName]!,
              controller: controller,
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }
}

class _NotificationGroupSection extends StatelessWidget {
  final String title;
  final List<NotificationModel> notifications;
  final NotificationController controller;

  const _NotificationGroupSection({
    required this.title,
    required this.notifications,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...notifications.map((notification) {
          final relatedPost = controller.postCache[notification.relatedPostId];
          return _NotificationItem(
            notification: notification,
            relatedPost: relatedPost,
            onTap: () => controller.onNotificationTapped(context, notification),
            controller: controller, // <-- Teruskan controller
          );
        }).toList(),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final Post? relatedPost;
  final VoidCallback onTap;
  final NotificationController controller; // <-- Terima controller

  const _NotificationItem({
    required this.notification,
    this.relatedPost,
    required this.onTap,
    required this.controller, // <-- Terima controller
  });

  String _getActionText(String type) {
    // ... (fungsi ini tidak berubah) ...
    switch (type) {
      case 'like':
        return 'menyukai postingan Anda.';
      case 'comment':
        return 'mengomentari postingan Anda.';
      case 'follow':
        return 'mulai mengikuti Anda.';
      case 'mention':
        return 'menyebut Anda dalam postingannya.';
      default:
        return 'berinteraksi dengan Anda.';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (fungsi build ini tidak berubah) ...
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: notification.isRead
            ? Colors.transparent
            : Colors.blue.withOpacity(0.05),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundImage: notification.sender.profilePictureUrl != null
                  ? NetworkImage(notification.sender.profilePictureUrl!)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  children: [
                    TextSpan(
                      text: notification.sender.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' ${_getActionText(notification.type)}'),
                    TextSpan(
                      text: ' ${CommentUtils.timeAgo(notification.createdAt)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildTrailingWidget(),
          ],
        ),
      ),
    );
  }

  // --- GANTI SELURUH FUNGSI _buildTrailingWidget DENGAN INI ---
  Widget _buildTrailingWidget() {
    // Untuk notifikasi like dan comment
    if (notification.type == 'like' || notification.type == 'comment') {
      if (relatedPost?.mediaUrl != null && relatedPost!.mediaUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Image.network(
            relatedPost!.mediaUrl!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // Untuk notifikasi follow
    if (notification.type == 'follow') {
      // Ambil status dari controller
      final isFollowing =
          controller.followStatus[notification.sender.username] ?? false;

      return SizedBox(
        height: 32,
        width: 100, // Beri lebar agar tampilan tidak "loncat" saat teks berubah
        child: ElevatedButton(
          // Panggil fungsi toggleFollow dari controller
          onPressed: () => controller.toggleFollow(notification),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.blue,
            foregroundColor: isFollowing ? Colors.black87 : Colors.white,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            elevation: 0,
            side: isFollowing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
          child: Text(
            isFollowing ? 'Diikuti' : 'Ikuti Balik',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      );
    }

    // Default widget jika tidak ada yang cocok
    return const SizedBox(width: 44, height: 44);
  }
}
