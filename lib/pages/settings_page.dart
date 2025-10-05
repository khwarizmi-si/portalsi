import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import '../widgets/accounts_center_sheet_content.dart'; // Sesuaikan dengan path Anda
import '../services/auth_service.dart';
import 'account_privacy_page.dart';
import 'bookmarks_page.dart';
import 'login_history_page.dart'; // Sesuaikan dengan path Anda

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // State untuk AppBar dinamis tidak kita ubah
  late final ScrollController _scrollController;
  bool _isAppBarOpaque = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isAppBarOpaque) {
          setState(() => _isAppBarOpaque = true);
        }
      } else {
        if (_isAppBarOpaque) {
          setState(() => _isAppBarOpaque = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fungsi untuk menampilkan BottomSheet Akun (tidak berubah)
  void _showAccountsCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.95,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
          child: const AccountsCenterSheetContent(),
        ),
      ),
    );
  }

  // >> PERUBAHAN UTAMA DI SINI <<
  // Helper baru untuk membuat item menu dengan gaya seperti gambar
  Widget _buildStyledMenuItem({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Container untuk ikon
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3E4), // Warna latar ikon
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF57C00), size: 20),
            ),
            const SizedBox(width: 16),
            // Teks judul
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            // Teks tambahan di kanan (jika ada)
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            const SizedBox(width: 8),
            // Ikon panah ke kanan
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ganti warna latar belakang utama
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        // AppBar dinamis seperti sebelumnya, tapi dengan warna baru
        backgroundColor: _isAppBarOpaque ? Colors.white : Colors.transparent,
        elevation: _isAppBarOpaque ? 1.0 : 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pengaturan',
          style: TextStyle(
            color: _isAppBarOpaque ? Colors.black : Colors.transparent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header halaman
          const Text(
            'Pengaturan',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola profil, akun, dan aktivitas Anda',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Menggunakan helper baru untuk setiap item menu
          _buildSectionHeader('Akun anda'),
          // _buildStyledMenuItem(
          //   icon: Icons.account_circle_outlined,
          //   title: 'Pusat Akun',
          //   onTap: () => _showAccountsCenterSheet(context),
          // ),
          // _buildStyledMenuItem(
          //   icon: Icons.lock_outline,
          //   title: 'Privasi Akun',
          //   trailingText: 'Publik',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       PageTransition(
          //         type: PageTransitionType.rightToLeft, // Tipe animasi dari kanan ke kiri
          //         child: const AccountPrivacyPage(),
          //       ),
          //     );
          //   },
          // ),
          _buildStyledMenuItem(
            icon: Icons.history, // Atau Icons.devices
            title: 'Histori Login',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginHistoryPage()),
              );
            },
          ),

          _buildSectionHeader('Aktivitasmu di Portal SI'),
          _buildStyledMenuItem(icon: Icons.bookmark_border, title: 'Postingan Tersimpan', onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BookmarksPage()),
            );
          }),
          _buildStyledMenuItem(icon: Icons.history, title: 'Arsip Cerita Anda', onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur ini akan segera hadir..',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            );
          }),
          // _buildStyledMenuItem(icon: Icons.bar_chart, title: 'Aktivitas Anda', onTap: () {}),
          // _buildStyledMenuItem(icon: Icons.notifications_none, title: 'Notifikasi', onTap: () {}),

          _buildSectionHeader('Login'),
          _buildStyledMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            onTap: () async {
              await AuthService().logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
          // _buildStyledMenuItem(icon: Icons.logout, title: 'Keluar dari Semua Akun', onTap: () {}),
        ],
      ),
    );
  }
}