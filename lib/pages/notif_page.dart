import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/video_thumbnail_widget.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../models/post_model.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';
import 'post_detail_page.dart';

// 1. Ubah menjadi StatefulWidget
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // 2. Buat ScrollController dan state untuk melacak status scroll
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    // 3. Tambahkan listener pada controller
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // 4. Hapus listener dan dispose controller
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // 5. Fungsi yang akan dipanggil setiap kali ada event scroll
  void _onScroll() {
    // Cek apakah posisi scroll lebih dari 10 piksel dari atas
    final isScrolled = _scrollController.offset > 10;
    // Panggil setState hanya jika statusnya berubah untuk efisiensi
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
            // 6. Gunakan AppBar yang bisa berubah warna
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // Atur warna dan bayangan berdasarkan state _isScrolled
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
                  backgroundColor: Colors.white, // AppBar dibuat transparan
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
            // 7. Kirim scroll controller ke body
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
    // 8. Berikan controller ke _NotificationList
    return _NotificationList(controller: controller, scrollController: scrollController);
  }
}

class _NotificationList extends StatelessWidget {
  final NotificationController controller;
  final ScrollController scrollController; // Terima scroll controller
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
      onRefresh: () => controller.refreshNotifications(),
      // 9. Pasang controller ke ListView
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

// Sisa kode di bawah ini tidak perlu diubah
class _NotificationGroupSection extends StatelessWidget {
  // ...
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
  // ...
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
            GestureDetector(
              onTap: () {
                NavigationHelper.navigateToProfile(context, notification.sender.toJson());
              },
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[200],
                child: ClipOval(
                  child: _buildAvatarContent(notification.sender.profilePictureUrl),
                ),
              ),
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

  Widget _buildAvatarContent(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.person, color: Colors.grey, size: 24);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: 44,
      height: 44,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.error_outline, color: Colors.grey, size: 24);
      },
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
            // 1. Background dibuat transparan saat gradien aktif
            backgroundColor: isFollowing ? Colors.grey.shade200 : Colors.transparent,

            // Properti asli dipertahankan
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isFollowing ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
            ),

            // 2. Padding internal tombol dinolkan, akan diatur di dalam Container
            padding: EdgeInsets.zero,
            // Menghilangkan efek bayangan saat gradien aktif
            shadowColor: Colors.transparent,
          ),
          child: Ink(
            // 3. Ink digunakan untuk menampung gradien dan mempertahankan efek klik
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isFollowing
                  ? null // Tidak ada gradien saat sudah diikuti
                  : LinearGradient( // Gradien diterapkan di sini
                colors: [
                  Colors.amber.shade600,
                  Colors.orange.shade800,
                ],
              ),
            ),
            child: Container(
              // 4. Padding yang sesungguhnya diatur di sini
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Tambahkan sedikit padding vertikal
              alignment: Alignment.center,
              child: Text(
                isFollowing ? 'Diikuti' : 'Ikuti Balik',
                // 5. Warna teks diatur langsung di TextStyle
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