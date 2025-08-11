// lib/pages/notification_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/notification_controller.dart';
import '../models/post_model.dart';
// ... import lainnya

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationController(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Notifikasi')),
        body: Consumer<NotificationController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.errorMessage != null) {
              return Center(child: Text('Error: ${controller.errorMessage}'));
            }
            if (controller.notifications.isEmpty) {
              return const Center(child: Text('Tidak ada notifikasi.'));
            }
            // Tampilkan daftar notifikasi menggunakan data dari controller
            return ListView.builder(
              itemCount: controller.notifications.length,
              itemBuilder: (context, index) {
                final notification = controller.notifications[index];
                final Post? relatedPost =
                    controller.postCache[notification.relatedPostId];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                        notification.sender.profilePictureUrl ?? ''),
                  ),
                  title: Text(
                      '${notification.sender.username} ${notification.message}'),
                  subtitle: relatedPost != null
                      ? Text('Tentang post: "${relatedPost.caption}"')
                      : null,
                  tileColor: notification.isRead
                      ? Colors.white
                      : Colors.blue.withOpacity(0.1),
                  onTap: () {
                    // Logika navigasi...
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
