// lib/pages/camera_settings_page.dart

import 'package:flutter/material.dart';
import 'package:portal_si/pages/story_settings_page.dart';

class CameraSettingsPage extends StatefulWidget {
  const CameraSettingsPage({Key? key}) : super(key: key);

  @override
  _CameraSettingsPageState createState() => _CameraSettingsPageState();
}

class _CameraSettingsPageState extends State<CameraSettingsPage> {
  bool _startOnFrontCamera = false;
  int _toolbarSide = 1; // 1 untuk Kiri, 2 untuk Kanan

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Latar belakang hitam pekat
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pengaturan Kamera',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Simpan pengaturan
              print('Pengaturan disimpan!');
              Navigator.of(context).pop();
            },
            child: const Text(
              'Simpan',
              style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          _buildSettingsTile(
            icon: Icons.add_circle_outline,
            label: 'Cerita',
            onTap: () {
              // Gunakan PageRouteBuilder untuk animasi slide dari bawah
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const StorySettingsPage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutCubic;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.movie_creation_outlined,
            label: 'Reels',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.settings_input_antenna,
            label: 'Siaran Langsung',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Kontrol'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Selalu mulai dari kamera depan', style: TextStyle(color: Colors.white)),
            value: _startOnFrontCamera,
            onChanged: (bool value) {
              setState(() {
                _startOnFrontCamera = value;
              });
            },
            activeColor: Colors.blue,
            inactiveTrackColor: Colors.grey[800],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Alat Kamera'),
          Text(
            'Pilih sisi untuk bilah alat kamera akan ditampilkan',
            style: TextStyle(color: Colors.grey[500]),
          ),
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sisi Kiri', style: TextStyle(color: Colors.white)),
            value: 1,
            groupValue: _toolbarSide,
            onChanged: (int? value) {
              setState(() {
                _toolbarSide = value!;
              });
            },
            activeColor: Colors.blue,
          ),
          RadioListTile<int>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sisi Kanan', style: TextStyle(color: Colors.white)),
            value: 2,
            groupValue: _toolbarSide,
            onChanged: (int? value) {
              setState(() {
                _toolbarSide = value!;
              });
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat baris pengaturan (Story, Reels, Live)
  Widget _buildSettingsTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // Helper untuk membuat judul bagian
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}