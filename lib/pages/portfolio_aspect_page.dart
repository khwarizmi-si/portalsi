import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/portfolio_item_model.dart';
import '../services/portfolio_service.dart';

class PortfolioAspectPage extends StatefulWidget {
  final String pageTitle;
  final String aspectName;

  const PortfolioAspectPage({
    Key? key,
    required this.pageTitle,
    required this.aspectName,
  }) : super(key: key);

  @override
  State<PortfolioAspectPage> createState() => _PortfolioAspectPageState();
}

class _PortfolioAspectPageState extends State<PortfolioAspectPage> {
  late Future<List<PortfolioItem>> _portfoliosFuture;
  final PortfolioService _portfolioService = PortfolioService();

  @override
  void initState() {
    super.initState();
    _portfoliosFuture = _portfolioService.getPortfoliosByAspect(widget.aspectName);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
      extendBodyBehindAppBar: true, // Membuat body berada di belakang AppBar
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar kaca
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(widget.pageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Latar belakang gambar
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Konten dengan FutureBuilder
          FutureBuilder<List<PortfolioItem>>(
            future: _portfoliosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.black)));
              }
              if (snapshot.hasData) {
                final portfolios = snapshot.data!;
                if (portfolios.isEmpty) {
                  return const Center(child: Text('Belum ada portofolio di bidang ini.', style: TextStyle(color: Colors.black)));
                }

                // Gunakan AnimationLimiter untuk memulai animasi staggered
                return AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, left: 16, right: 16, bottom: 20),
                    itemCount: portfolios.length,
                    itemBuilder: (context, index) {
                      final item = portfolios[index];
                      // Setiap item dibungkus dengan konfigurasi animasi
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation( // Animasi geser
                          verticalOffset: 50.0,
                          child: FadeInAnimation( // Animasi pudar
                            child: _buildPortfolioCard(item),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
              return const Center(child: Text('Terjadi kesalahan.', style: TextStyle(color: Colors.black)));
            },
          ),
        ],
      ),
      ),
    );
  }

  // --- KARTU PORTFOLIO DENGAN GAYA LIQUID GLASS BARU ---
  Widget _buildPortfolioCard(PortfolioItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Foto Profil & Username
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: item.user.profilePictureUrl != null
                            ? NetworkImage(item.user.profilePictureUrl!)
                            : null,
                        child: item.user.profilePictureUrl == null
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.user.username,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                // Gambar Utama Portofolio
                if (item.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      item.imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      // Placeholder saat loading
                      loadingBuilder: (context, child, progress) =>
                      progress == null ? child : Container(height: 180, color: Colors.black12),
                    ),
                  ),
                // Footer: Judul Portofolio
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}