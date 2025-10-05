// lib/pages/permissions_page.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:portal_si/pages/welcome_page.dart';
import 'dart:developer' as developer;

import '../utils/slide_transition_route.dart'; // Tambahkan ini jika ingin menggunakan log yang lebih terstruktur

class PermissionsPage extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionsPage({
    super.key,
    required this.onPermissionsGranted,
  });

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> {
  // Daftar izin yang akan diminta
  final List<Permission> _requiredPermissions = [
    Permission.notification,
    Permission.camera,
    Permission.storage, // Untuk Android versi lama//
    Permission.photos,  // Untuk Android 13+
    Permission.videos,  // Untuk Android 13+//
  ];

  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Meminta semua izin dalam daftar sekaligus
    Map<Permission, PermissionStatus> statuses = await _requiredPermissions.request();

    // Tambahkan ini untuk debugging:
    // Menggunakan print biasa untuk output debug sederhana
    print("Status Izin yang Diminta:");
    statuses.forEach((permission, status) {
      print('${permission.toString()}: ${status.toString()}');
    });
    // Atau menggunakan developer.log untuk output yang lebih terstruktur di tab Debug Console Flutter
    // statuses.forEach((permission, status) {
    //   developer.log('Status Izin - ${permission.toString()}: ${status.toString()}', name: 'PermissionsPage');
    // });

    // Cek apakah semua izin sudah diberikan
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Jika semua sudah diizinkan, panggil callback untuk melanjutkan ke aplikasi
      print("Semua izin diberikan.");
      // developer.log('Semua izin diberikan.', name: 'PermissionsPage');
      widget.onPermissionsGranted();
      Navigator.of(context).push(
        SlideTransitionRoute(page: const WelcomePage()),
      );
    } else {
      // Jika ada yang ditolak, beri tahu pengguna
      // print("Satu atau lebih izin tidak diberikan.");
      // // developer.log('Satu atau lebih izin tidak diberikan.', name: 'PermissionsPage');
      // statuses.forEach((permission, status) {
      //   if (!status.isGranted) {
      //     print("Izin yang tidak diberikan: ${permission.toString()} - Status: ${status.toString()}");
      //     // developer.log('Izin yang tidak diberikan: ${permission.toString()} - Status: ${status.toString()}', name: 'PermissionsPage');
      //   }
      // });
      // if (mounted) { // Pastikan widget masih mounted sebelum menampilkan SnackBar
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(
      //       content: Text('Beberapa izin tidak diberikan. Fitur mungkin terbatas.'),
      //       backgroundColor: Colors.red,
      //     ),
      //   );
      // }
      print("Semua izin diberikan.");
      // developer.log('Semua izin diberikan.', name: 'PermissionsPage');
      widget.onPermissionsGranted();
      Navigator.of(context).push(
        SlideTransitionRoute(page: const WelcomePage()),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield_outlined, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 32),
            const Text(
              'Izin Diperlukan',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Portal SI memerlukan beberapa izin untuk dapat berfungsi secara optimal, termasuk notifikasi, akses media, dan penyimpanan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isLoading ? null : _requestPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
                  : const Text('Berikan Izin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
