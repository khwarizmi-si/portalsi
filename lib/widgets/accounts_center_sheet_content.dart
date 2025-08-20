// lib/accounts_center_sheet_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AccountsCenterSheetContent extends StatelessWidget {
  const AccountsCenterSheetContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- PALET WARNA BARU UNTUK TEMA TERANG ---
    const Color cardColor = Color.fromARGB(200, 255, 255, 255); // Putih semi-transparan untuk efek 'frosted glass'
    const Color textColor = Color(0xFF1C1E21); // Hitam pekat untuk teks utama
    const Color mutedTextColor = Color(0xFF555555); // Abu-abu gelap untuk teks sekunder
    const Color linkColor = Colors.blue; // Warna biru standar untuk link
    const String metaLogoUrl = 'https://upload.wikimedia.org/wikipedia/commons/a/ab/Meta-Logo.svg';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFFFF0D0), // peach lembut di kiri
            Color(0xFFFFFFFF), // putih di tengah
            Color(0xFFDFFEF8), // mint lembut di kanan
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header BottomSheet
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[400], // Warna drag handle disesuaikan
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                // Tombol Close dan Logo Meta
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: textColor), // Warna ikon disesuaikan
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SvgPicture.network(
                      metaLogoUrl,
                      colorFilter: const ColorFilter.mode(textColor, BlendMode.srcIn), // Warna logo disesuaikan
                      height: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Konten yang bisa di-scroll
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const Text(
                  'Accounts Center',
                  style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: mutedTextColor, fontSize: 14, height: 1.4),
                    children: [
                      const TextSpan(text: 'Manage your connected experiences and account settings across Meta technologies like Facebook, Instagram and Meta Horizon. '),
                      TextSpan(text: 'Learn more', style: TextStyle(color: linkColor)), // Warna link disesuaikan
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard( // Metode _buildCard sekarang menggunakan warna baru secara otomatis
                  color: cardColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    leading: SizedBox(
                      width: 50,
                      child: Stack(
                        children: [
                          const CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12')),
                          Positioned(
                            left: 15,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: cardColor, // Warna background avatar disesuaikan
                              child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=5')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    title: const Text('Profiles', style: TextStyle(color: textColor)),
                    subtitle: const Text('mr_ha.09, West Kevin', style: TextStyle(color: mutedTextColor)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('2', style: TextStyle(color: mutedTextColor, fontSize: 16)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: mutedTextColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Semua item di bawah ini sekarang akan menggunakan palet warna yang baru
                _buildSectionHeader('Connected experiences', mutedTextColor),
                _buildSettingsItem(Icons.sync_alt, 'Sharing across profiles', textColor, mutedTextColor),
                _buildSettingsItem(Icons.login, 'Logging in with accounts', textColor, mutedTextColor),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0),
                  child: Text('View all', style: TextStyle(color: linkColor)), // Warna link disesuaikan
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Account settings', mutedTextColor),
                _buildSettingsItem(Icons.security, 'Password and security', textColor, mutedTextColor),
                _buildSettingsItem(Icons.account_box_outlined, 'Personal details', textColor, mutedTextColor),
                _buildSettingsItem(Icons.article_outlined, 'Your information and permissions', textColor, mutedTextColor),
                _buildSettingsItem(Icons.campaign_outlined, 'Ad preferences', textColor, mutedTextColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tidak ada perubahan yang diperlukan di helper methods, karena mereka sudah menerima warna sebagai parameter
  Widget _buildCard({required Widget child, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color textColor, Color iconColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      trailing: Icon(Icons.chevron_right, color: iconColor),
    );
  }
}