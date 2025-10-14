import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/circular_avatar_fetcher.dart'; // <-- 1. TAMBAHKAN IMPORT
import '../components/video_thumbnail_widget.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';
import 'post_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 10;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
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
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: _isScrolled ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : [],
                ),
                child: AppBar(
                  title: const Text('Aktivitas',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  actions: [
                    if (controller.hasUnreadNotifications)
                      TextButton(
                        onPressed: () => controller.markAllAsRead(),
                        child: const Text('Tandai semua dibaca'),
                      )
                  ],
                ),
              ),
            ),
            body: _buildBody(context, controller, _scrollController),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationController controller, ScrollController scrollController) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }
    if (controller.errorMessage != null) {
      return Center(child: Text('Error: ${controller.errorMessage}'));
    }
    if (controller.notifications.isEmpty) {
      return const Center(child: Text('Tidak ada aktivitas terbaru.'));
    }
    return _NotificationList(controller: controller, scrollController: scrollController);
  }
}

class _NotificationList extends StatelessWidget {
  final NotificationController controller;
  final ScrollController scrollController;
  const _NotificationList({required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final grouped = controller.groupedNotifications;
    final groupOrder = [
      'Hari Ini',
      'Kemarin',
      '7 Hari Terakhir',
      '30 Hari Terakhir',
      'Lebih lama'
    ];

    return RefreshIndicator(
      color: Colors.orange,
      // Mengatur warna latar belakang lingkaran
      backgroundColor: Colors.orange.shade50,
      onRefresh: () => controller.refreshNotifications(),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: groupOrder.map((groupName) {
          if (grouped.containsKey(groupName) && grouped[groupName]!.isNotEmpty) {
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
            : Color(0xFFFFF3DC),
        child: Row(
          children: [
            // =================================================================
            // --- 2. GANTI BAGIAN AVATAR DENGAN INI ---
            // =================================================================
            CircularAvatarFetcher(
              radius: 22,
              userId: notification.sender.id ?? 0, // Ambil id dari sender
              onTap: () {
                // Navigasi ke profil saat avatar diklik
                NavigationHelper.navigateToProfile(context, notification.sender);
              },
            ),
            // =================================================================
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
      final isFollowing = controller.followStatus[notification.sender.username] ?? false;
      return SizedBox(
          height: 32,
          width: 100,
          child: ElevatedButton(
            onPressed: () => controller.toggleFollow(notification),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isFollowing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
              ),
              padding: EdgeInsets.zero,
              shadowColor: Colors.transparent,
            ),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: isFollowing
                    ? null
                    : LinearGradient(
                  colors: [
                    Colors.amber.shade600,
                    Colors.orange.shade800,
                  ],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  isFollowing ? 'Diikuti' : 'Ikuti Balik',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isFollowing ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          )
      );
    }
    return const SizedBox(width: 44, height: 44);
  }
}