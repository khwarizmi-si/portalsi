// lib/pages/portfolio_page.dart

import 'package:flutter/material.dart';

class PortfolioPage extends StatelessWidget {
  // Anda bisa meneruskan data user yang relevan ke halaman ini
  final String studentName;
  final String schoolName = "Sekolah Impian"; // Bisa juga dijadikan parameter

  const PortfolioPage({super.key, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFBF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Portofolio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildPortfolioItem(
            title: 'Aplikasi Jogja Love Palestine untuk TDA 2024 (Goes to Jogja)',
            role: 'Front-End APP developer',
            className: '1 pondok, Level 1',
          ),
          _buildPortfolioItem(
            title: 'Aplikasi Portal SI',
            role: 'Front-End APP developer',
            className: '1 pondok, Level 1',
          ),
          _buildPortfolioItem(
            title: 'Sistem Layanan Akun',
            role: 'Front-End & Back-End APP and Website developer',
            className: '1 pondok, Level 1',
          ),
        ],
      ),
    );
  }

  // Widget untuk header dengan avatar di dalam teks
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black87,
            height: 1.5,
          ),
          children: [
            const TextSpan(text: 'Anda sekarang sedang melihat portofolio '),
            // WidgetSpan untuk menampilkan CircleAvatar di dalam teks
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$studentName'),
                ),
              ),
            ),
            TextSpan(
              text: '$studentName ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: 'dari santri '),
            TextSpan(
              text: schoolName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk membuat satu item portofolio
  Widget _buildPortfolioItem({
    required String title,
    required String role,
    required String className,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.desktop_windows, color: Colors.orange.shade800, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Peran: $role',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kelas: $className',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}