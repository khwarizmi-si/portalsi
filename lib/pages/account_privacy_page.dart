// lib/pages/account_privacy_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/services/user_service.dart';
import 'package:portal_si/models/user_model.dart';

class AccountPrivacyPage extends StatefulWidget {
  const AccountPrivacyPage({Key? key}) : super(key: key);

  @override
  State<AccountPrivacyPage> createState() => _AccountPrivacyPageState();
}

class _AccountPrivacyPageState extends State<AccountPrivacyPage> {
  final ProfileService _profileService = ProfileService();

  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// Mengambil data profil awal dari server menggunakan ProfileService
  Future<void> _fetchInitialData() async {
    try {
      final user = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  /// Memperbarui status privasi melalui ProfileService
  Future<void> _updatePrivacyStatus(bool newStatus) async {
    if (_currentUser == null) return;

    setState(() { _isLoading = true; });

    try {
      final updatedUser = _currentUser!.copyWith(isPrivate: newStatus);

      // Kirim objek 'updatedUser' secara langsung sebagai argumen posisi
      final success = await _profileService.updateProfile(updatedUser);
      // --------------------------

      if (success) {
        // Jika berhasil, perbarui state lokal dan tampilkan notifikasi
        setState(() {
          _currentUser = updatedUser;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan privasi diperbarui!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Gagal memperbarui dari server.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Colors.white;
    const Color textColor = Colors.black87;
    final Color? mutedTextColor = Colors.grey[600];
    const Color linkColor = Colors.blue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: const Text('Privasi Akun', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && _currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Akun Privat', style: TextStyle(color: textColor, fontSize: 16)),
            trailing: _isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Switch.adaptive(
              value: _currentUser?.isPrivate ?? false,
              onChanged: (value) => _updatePrivacyStatus(value),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ketika akun Anda privat, hanya pengikut yang Anda setujui yang dapat melihat apa yang Anda bagikan, termasuk foto atau video Anda di halaman tagar dan lokasi, serta daftar pengikut dan yang Anda ikuti.',
            style: TextStyle(color: mutedTextColor, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text.rich(
            TextSpan(
              style: TextStyle(color: mutedTextColor, height: 1.5),
              children: [
                const TextSpan(
                  text: 'Ketika akunmu tidak privat, semua orang dapat melihat ceritamu, postinganmu, biodatamu, on atau off statusmu bahkan jika mereka adalah orang yang tidak dikenal.',
                ),
                const TextSpan(
                  text: ' Pelajari lebih lanjut',
                  style: TextStyle(color: linkColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}