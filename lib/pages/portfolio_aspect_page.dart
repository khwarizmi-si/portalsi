import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  // --- 👇 STATE BARU UNTUK MELACAK KARTU YANG DIPERBESAR 👇 ---
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _portfoliosFuture = _portfolioService.getPortfoliosByAspect(widget.aspectName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.1),
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
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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

                return AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.only(top: kToolbarHeight + MediaQuery.of(context).padding.top + 20, left: 16, right: 16, bottom: 20),
                    itemCount: portfolios.length,
                    itemBuilder: (context, index) {
                      final item = portfolios[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            // --- 👇 Kirim index ke dalam fungsi build kartu 👇 ---
                            child: _buildPortfolioCard(item, index),
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
    );
  }

  // --- KARTU PORTFOLIO DENGAN LOGIKA EXPAND ---
  Widget _buildPortfolioCard(PortfolioItem item, int index) {
    final bool isExpanded = _expandedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isExpanded ? 0.5 : 0.25),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.black.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        // --- 👇 PERUBAHAN/OPTIMALISASI DI SINI 👇 ---
                        CircleAvatar(
                          radius: 16,
                          // Menggunakan CachedNetworkImageProvider untuk performa lebih baik
                          // dan penanganan placeholder/error
                          backgroundImage: (item.user.profilePictureUrl != null && item.user.profilePictureUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(item.user.profilePictureUrl!)
                              : null, // Jika null atau kosong, tidak ada backgroundImage
                          child: (item.user.profilePictureUrl == null || item.user.profilePictureUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 18, color: Colors.white70) // Ikon default jika tidak ada PP
                              : null, // Jika ada PP, tidak perlu child
                          backgroundColor: Colors.white.withOpacity(0.3), // Warna latar belakang default
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.user.username,
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (item.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        item.imageUrl!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                        progress == null ? child : Container(height: 180, color: Colors.black12),
                        errorBuilder: (context, error, stackTrace) =>
                            Container(height: 180, color: Colors.grey.shade800, child: const Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: isExpanded ? double.infinity : 0),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: isExpanded ? 1.0 : 0.0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  item.description ?? 'Tidak ada deskripsi.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.85),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}