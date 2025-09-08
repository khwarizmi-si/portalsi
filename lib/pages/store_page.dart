import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/gestures.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with AutomaticKeepAliveClientMixin {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
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

  Future<void> _onPopInvoked(bool didPop) async {
    // Jika pop sudah terjadi karena alasan lain, hentikan.
    if (didPop) return;

    // Periksa apakah WebView bisa kembali
    final bool canGoBack = await _controller.canGoBack();

    if (canGoBack) {
      // Jika bisa, perintahkan WebView untuk kembali
      await _controller.goBack();
    }
    // Jika tidak bisa kembali, tidak ada tindakan yang diambil.
    // Pengguna akan tetap di halaman StorePage.
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // --- 2. BUNGKUS KONTEN DENGAN PopScope ---
    return PopScope(
      canPop: false, // Mencegah pop otomatis
      onPopInvoked: _onPopInvoked, // Panggil fungsi kita saat ada gestur back
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

  Widget _buildAppBar() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Row(
        children: [
          // IconButton(
          //   icon: const Icon(Icons.arrow_back_ios_new),
          //   onPressed: () async {
          //     if (await _controller.canGoBack()) { await _controller.goBack(); }
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.arrow_forward_ios),
          //   onPressed: () async {
          //     if (await _controller.canGoForward()) { await _controller.goForward(); }
          //   },
          // ),
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