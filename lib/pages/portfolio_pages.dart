import 'package:flutter/material.dart';
import 'package:portal_si/models/user_model.dart';
import 'package:portal_si/models/portfolio_model.dart';
import 'package:portal_si/services/portfolio_service.dart';
import 'add_portfolio_page.dart';

class PortfolioPage extends StatefulWidget {
  final User user;

  const PortfolioPage({super.key, required this.user});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  Future<List<Portfolio>>? _portfoliosFuture;
  final String schoolName = "Sekolah Impian";

  @override
  void initState() {
    super.initState();
    // Memeriksa apakah user.id null sebelum memuat data
    if (widget.user.id != null) {
      _loadPortfolios();
    }
  }

  void _loadPortfolios() {
    setState(() {
      // Menggunakan '!' (bang operator) karena kita sudah yakin id tidak null dari initState
      _portfoliosFuture = PortfolioService().getPortfolios(widget.user.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tambahan: Menampilkan pesan error jika ID user tidak ada
    if (widget.user.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('ID pengguna tidak valid.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBF0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Portofolio',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Colors.black, size: 28),
            tooltip: 'Tambah Portofolio',
            onPressed: () async {
              final shouldRefresh = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  // Menggunakan '!' karena sudah dipastikan tidak null di awal build
                  builder: (context) =>
                      AddPortfolioPage(userId: widget.user.id!),
                ),
              );
              if (shouldRefresh == true) {
                _loadPortfolios();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadPortfolios(),
        child: FutureBuilder<List<Portfolio>>(
          future: _portfoliosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Gagal memuat data: ${snapshot.error}"),
              );
            }
            if (snapshot.hasData) {
              final portfolios = snapshot.data!;
              if (portfolios.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: portfolios.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildHeader();
                  }
                  final portfolio = portfolios[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildPortfolioItem(portfolio),
                  );
                },
              );
            }
            return const Center(child: Text("Tidak ada data."));
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 20,
            color: Colors.black87,
            height: 1.5,
            fontFamily: 'Inter',
          ),
          children: [
            const TextSpan(text: 'Anda sekarang sedang melihat portofolio '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(
                      widget.user.profilePictureUrl ??
                          'https://i.pravatar.cc/150'),
                ),
              ),
            ),
            TextSpan(
              text: '${widget.user.fullName ?? widget.user.username} ',
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

  Widget _buildPortfolioItem(Portfolio portfolio) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              portfolio.mediaUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400], size: 50),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  portfolio.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  portfolio.description,
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag(portfolio.aspect, Colors.orange),
                    const Spacer(),
                    Text(
                      'Tahun: ${portfolio.year}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.grey[800], fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Portofolio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Portofolio yang ditambahkan akan muncul di sini.',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
