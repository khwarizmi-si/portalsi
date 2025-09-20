import 'package:flutter/material.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:provider/provider.dart';
import '../components/video_thumbnail_widget.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';
import 'post_detail_page.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  static const int _selectedIndex = 3;

  void _onItemTapped(int index, BuildContext context) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/explore');
        break;
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
            controller: controller,
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
  final NotificationController controller;

  const _NotificationItem({
    required this.notification,
    this.relatedPost,
    required this.onTap,
    required this.controller,
  });

  String _getActionText(String type) {
    switch (type) {
      case 'like':
        return 'menyukai postingan Anda.';
      case 'comment':
        return 'mengomentari postingan Anda.';
      case 'follow':
        return 'mulai mengikuti Anda.';
      case 'story_mention':
        return 'menyebut Anda dalam Ceritanya.';
      case 'mention':
        return 'menyebut Anda dalam suatu postingan.';
      default:
        return 'berinteraksi dengan Anda.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        color: notification.isRead
            ? Colors.transparent
            : Colors.blue.withOpacity(0.05),
        child: Row(
          children: [
            // --- PERUBAHAN UTAMA DI SINI ---
            // Bungkus CircleAvatar dengan GestureDetector
            GestureDetector(
              onTap: () {
                // Panggil helper navigasi saat avatar diklik
                Navigator.pop(context);
                NavigationHelper.navigateToProfile(context, notification.sender.toJson());
              },
              child: CircleAvatar(
                radius: 22,
                backgroundImage: notification.sender.profilePictureUrl != null
                    ? NetworkImage(notification.sender.profilePictureUrl!)
                    : null,
              ),
            ),
            // --- Batas Perubahan ---
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

  Widget _buildTrailingWidget() {
    if ((notification.type == 'like' || notification.type == 'comment') && relatedPost != null) {
      Widget mediaDisplay;
      if (relatedPost!.isVideo && relatedPost!.mediaUrl != null) {
        mediaDisplay = VideoThumbnailWidget(videoUrl: relatedPost!.mediaUrl!);
      } else if (relatedPost!.mediaUrl != null && relatedPost!.mediaUrl!.isNotEmpty) {
        mediaDisplay = Image.network(
          relatedPost!.mediaUrl!,
          fit: BoxFit.cover,
        );
      } else {
        mediaDisplay = Container(color: Colors.grey.shade200);
      }

      return SizedBox(
        width: 44,
        height: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: mediaDisplay,
        ),
      );
    }

    if (notification.type == 'follow') {
      final isFollowing =
          controller.followStatus[notification.sender.username] ?? false;

      return SizedBox(
        height: 32,
        width: 100,
        child: ElevatedButton(
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

    return const SizedBox(width: 44, height: 44);
  }
}