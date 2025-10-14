import 'package:flutter/material.dart';
// Pastikan semua import ini sesuai dengan struktur proyek Anda
import '../services/auth_service.dart';
import 'bookmarks_page.dart';
import 'change_password_page.dart';
import 'login_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final ScrollController _scrollController;
  bool _isAppBarOpaque = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 10) {
        if (!_isAppBarOpaque) setState(() => _isAppBarOpaque = true);
      } else {
        if (_isAppBarOpaque) setState(() => _isAppBarOpaque = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 👇 DIALOG KONFIRMASI BARU SUDAH DIMASUKKAN DI SINI 👇
  // GANTI FUNGSI LAMA DENGAN YANG INI DI DALAM _SettingsPageState
  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Memastikan latar belakang popup putih
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.redAccent.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: Colors.white, size: 40),
          ),
          title: Text(
            'Anda Yakin?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Sesi Anda akan berakhir dan Anda perlu masuk kembali untuk melanjutkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: <Widget>[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade400, width: 1.5), // Border abu-abu
                      foregroundColor: Colors.black87, // Teks hitam
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Ink( // Gunakan Ink untuk gradien
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade600, Colors.orange.shade800],
                      ),
                    ),
                    child: InkWell( // Untuk efek tap
                      onTap: () => Navigator.of(context).pop(true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: const Text(
                          'Ya, Keluar',
                          style: TextStyle(
                            color: Colors.white, // Teks putih
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  // Template item menu (kembali ke versi awal)
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
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3E4), // Warna latar ikon
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFF57C00), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            const SizedBox(width: 8),
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
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
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
          const Text(
            'Pengaturan',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola profil, akun, dan aktivitas Anda',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          _buildSectionHeader('Akun Anda'),
          _buildStyledMenuItem(
            icon: Icons.history,
            title: 'Histori Login',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginHistoryPage()),
              );
            },
          ),
          _buildStyledMenuItem(
            icon: Icons.password_rounded,
            title: 'Ubah Kata Sandi',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
              );
            },
          ),

          _buildSectionHeader('Aktivitas Anda'),
          _buildStyledMenuItem(
            icon: Icons.bookmark_border,
            title: 'Postingan Tersimpan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookmarksPage()),
              );
            },
          ),
          _buildStyledMenuItem(
            icon: Icons.history_edu_outlined,
            title: 'Arsip Cerita Anda',
            onTap: () { /* Aksi */ },
          ),

          _buildSectionHeader('Login'),
          _buildStyledMenuItem(
            icon: Icons.logout,
            title: 'Keluar',
            onTap: () async {
              final bool? shouldLogout = await _showLogoutConfirmationDialog(context);
              if (shouldLogout == true) {
                await AuthService().logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}