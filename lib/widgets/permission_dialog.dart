// lib/widgets/permission_dialog.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NotificationPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onLater;

  const NotificationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/notification_bell.json',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Jangan Lewatkan Pesan Penting!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Izinkan kami mengirim notifikasi agar Anda selalu tahu saat ada pesan baru dari teman Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: onLater,
                  child: const Text(
                    'Nanti Saja',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: onAllow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    'Izinkan',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}