import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart'; // Import package url_launcher

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with AutomaticKeepAliveClientMixin {
  // Controller hanya akan diinisialisasi jika bukan di web
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;

  // Ini penting agar state halaman tidak hilang saat berpindah tab
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Hanya inisialisasi WebView controller jika di platform mobile
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (!mounted) return;
              setState(() { _loadingProgress = progress / 100; });
            },
            onPageStarted: (String url) {
              if (!mounted) return;
              setState(() { _isLoading = true; _loadingProgress = 0; });
            },
            onPageFinished: (String url) {
              if (!mounted) return;
              setState(() { _isLoading = false; });
            },
            onWebResourceError: (WebResourceError error) {},
          ),
        )
        ..loadRequest(Uri.parse('https://store.portalsi.com/'));
    }
  }

  // Fungsi untuk menangani tombol kembali di mobile
  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Cek platform: tampilkan UI berbeda untuk web dan mobile
    if (kIsWeb) {
      return _buildWebViewAlternative();
    } else {
      return _buildMobileWebView();
    }
  }

  // --- WIDGET UNTUK TAMPILAN MOBILE (KODE LAMA ANDA) ---
  Widget _buildMobileWebView() {
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Stack(
                  children: [
                    WebViewWidget(
                      controller: _controller,
                      gestureRecognizers: {
                        Factory<VerticalDragGestureRecognizer>(
                              () => VerticalDragGestureRecognizer(),
                        ),
                      },
                    ),
                    if (_isLoading)
                      LinearProgressIndicator(
                        value: _loadingProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BARU UNTUK TAMPILAN WEB ---
  Widget _buildWebViewAlternative() {
    final storeUri = Uri.parse('https://store.portalsi.com/');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Marketplace PSI",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 1,
        centerTitle: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Selamat Datang di Marketplace!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Toko online kami siap melayani Anda. Klik tombol di bawah untuk membuka di tab baru.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Marketplace'),
                onPressed: () async {
                  // Fungsi untuk membuka URL
                  if (await canLaunchUrl(storeUri)) {
                    // Buka di tab baru (_blank)
                    await launchUrl(storeUri, webOnlyWindowName: '_blank');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak bisa membuka link')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AppBar yang digunakan di versi mobile
  Widget _buildAppBar() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Row(
        children: [
          const SizedBox(width: 16,),
          const Text(
            "Marketplace PSI",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
    );
  }
}