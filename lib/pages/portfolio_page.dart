import 'dart:ui'; // Untuk ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/pages/portfolio_aspect_page.dart'; // Untuk SystemChrome, dll.

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Portofolio Santri',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          children: [
            // Background dari asset
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 16.0),
                    // const Text(
                    //   'Portfolio Santri',
                    //   style: TextStyle(
                    //     fontSize: 24,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Data dan rangkuman portfolio para santri selama menduduki masa pendidikan di Sekolah Impian',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 32.0),
                    _buildPortfolioGrid(context),
                    const SizedBox(height: 32.0),
                    // Bagian bawah kita buat jadi kaca juga agar serasi
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2), // Warna kaca netral
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildPortfolioCard(
          icon: Icons.book_outlined,
          title: 'Bidang Tahfidz',
          // --- 👇 PERUBAHAN DI SINI 👇 ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PortfolioAspectPage(
                  pageTitle: 'Bidang Tahfidz',
                  aspectName: 'quran', // Sesuai dokumentasi API
                ),
              ),
            );
          },
        ),
        _buildPortfolioCard(
          icon: Icons.computer_outlined,
          title: 'Bidang Teknologi',
          // --- 👇 PERUBAHAN DI SINI 👇 ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PortfolioAspectPage(
                  pageTitle: 'Bidang Teknologi',
                  aspectName: 'it', // Sesuai dokumentasi API
                ),
              ),
            );
          },
        ),
        _buildPortfolioCard(
          icon: Icons.chat_bubble_outline,
          title: 'Bidang Bahasa',
          // --- 👇 PERUBAHAN DI SINI 👇 ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PortfolioAspectPage(
                  pageTitle: 'Bidang Bahasa',
                  aspectName: 'bahasa', // Sesuai dokumentasi API
                ),
              ),
            );
          },
        ),
        _buildPortfolioCard(
          icon: Icons.person_outline,
          title: 'Bidang Karakter',
          // --- 👇 PERUBAHAN DI SINI 👇 ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PortfolioAspectPage(
                  pageTitle: 'Bidang Karakter',
                  aspectName: 'karakter', // Sesuai dokumentasi API
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  // --- 👇 FUNGSI KARTU YANG DIUBAH MENJADI LIQUID GLASS NETRAL 👇 ---
  Widget _buildPortfolioCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Efek blur kaca
        child: Container(
          decoration: BoxDecoration(
            // Hapus gradient, ganti dengan warna putih transparan
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1), // Border putih tipis
              width: 1.5,
            ),
          ),

          child: Material(
            color: Color(0x80FFFFFF),

            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Ganti warna ikon agar kontras
                    Icon(icon, size: 36,
                      color: Color(0x87000000),
                      shadows: [ // Bayangan agar teks lebih terbaca
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.black26,
                      )
                    ],),

                    const Spacer(),
                    // Ganti warna teks agar kontras
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.6),
                        shadows: [ // Bayangan agar teks lebih terbaca
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black26,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      children: [
                        Text(
                          'Lihat >',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.8), // Sedikit redup
                            shadows: [ // Bayangan agar teks lebih terbaca
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black26,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}