import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// TAMBAHAN: Import paket yang diperlukan untuk HTTP dan URL Launcher
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'dart:convert';

import '../utils/slide_transition_route.dart';
import 'login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _outController;
  late AnimationController _inController;

  late Animation<Offset> _slideOutAnim1, _slideOutAnim2, _slideOutAnim3, _slideOutAnim4;
  late Animation<double> _fadeOutAnim1, _fadeOutAnim2, _fadeOutAnim3, _fadeOutAnim4;

  late Animation<Offset> _slideInAnim1, _slideInAnim2, _slideInAnim3, _slideInAnim4, _slideInAnim5, _slideInAnim6;
  late Animation<double> _fadeInAnim1, _fadeInAnim2, _fadeInAnim3, _fadeInAnim4, _fadeInAnim5, _fadeInAnim6;

  // TAMBAHAN: State untuk menampilkan loading indicator
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _outController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _inController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    final slideUpTween = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.3));
    final fadeOutTween = Tween<double>(begin: 1.0, end: 0.0);

    _slideOutAnim1 = slideUpTween.animate(_createCurve(_outController, 0.0, 0.5));
    _fadeOutAnim1 = fadeOutTween.animate(_createCurve(_outController, 0.0, 0.5));
    _slideOutAnim2 = slideUpTween.animate(_createCurve(_outController, 0.1, 0.6));
    _fadeOutAnim2 = fadeOutTween.animate(_createCurve(_outController, 0.1, 0.6));
    _slideOutAnim3 = slideUpTween.animate(_createCurve(_outController, 0.2, 0.7));
    _fadeOutAnim3 = fadeOutTween.animate(_createCurve(_outController, 0.2, 0.7));
    _slideOutAnim4 = slideUpTween.animate(_createCurve(_outController, 0.3, 0.8));
    _fadeOutAnim4 = fadeOutTween.animate(_createCurve(_outController, 0.3, 0.8));

    final slideDownTween = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero);
    final fadeInTween = Tween<double>(begin: 0.0, end: 1.0);

    _slideInAnim1 = slideDownTween.animate(_createCurve(_inController, 0.0, 0.5));
    _fadeInAnim1 = fadeInTween.animate(_createCurve(_inController, 0.0, 0.5));
    _slideInAnim2 = slideDownTween.animate(_createCurve(_inController, 0.1, 0.6));
    _fadeInAnim2 = fadeInTween.animate(_createCurve(_inController, 0.1, 0.6));
    _slideInAnim3 = slideDownTween.animate(_createCurve(_inController, 0.2, 0.7));
    _fadeInAnim3 = fadeInTween.animate(_createCurve(_inController, 0.2, 0.7));
    _slideInAnim4 = slideDownTween.animate(_createCurve(_inController, 0.4, 0.9));
    _fadeInAnim4 = fadeInTween.animate(_createCurve(_inController, 0.4, 0.9));
    _slideInAnim5 = slideDownTween.animate(_createCurve(_inController, 0.5, 1.0));
    _fadeInAnim5 = fadeInTween.animate(_createCurve(_inController, 0.5, 1.0));
    _slideInAnim6 = slideDownTween.animate(_createCurve(_inController, 0.6, 1.0));
    _fadeInAnim6 = fadeInTween.animate(_createCurve(_inController, 0.6, 1.0));
  }

  CurvedAnimation _createCurve(AnimationController controller, double begin, double end) {
    return CurvedAnimation(parent: controller, curve: Interval(begin, end, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _outController.dispose();
    _inController.dispose();
    super.dispose();
  }

  void _triggerTransition() {
    _outController.forward();
    _inController.forward();
  }

  void _triggerBackTransition() {
    _inController.reverse();
    _outController.reverse();
  }

  Future<void> _loginWithSDK() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl = 'https://akunrg.com/au/pengenalan';
      final params = {
        'client_id': "6ab3cbd0-51ce-4987-94fd-9e66db9f0abf",
        'client_secret': "8c0f8331-2364-4e69-86e6-bd91b013e3ca",
        'auth_v1': "0e3ef8f9-55fd-43cc-a52f-f7d13299dfc2",
        'auth_v2': "047c6d2e-e0c6-459f-85a1-54e35561d2ae",
        'redirect': "https://portalsi.com/get/larg",
        'target': "connect",
        'redirect_from': "https://portalsi.com",
        'via': 'tombolLoginApp',
      };

      final finalUri = Uri.parse(baseUrl).replace(queryParameters: params);

      await FlutterWebBrowser.openWebPage(
        url: finalUri.toString(),
        customTabsOptions: const CustomTabsOptions(
          colorScheme: CustomTabsColorScheme.system,
          showTitle: true,
          urlBarHidingEnabled: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          barCollapsingEnabled: true,
          preferredBarTintColor: Colors.white,
          preferredControlTintColor: Colors.black,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses login: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // MODIFIKASI: Kita tidak lagi set _isLoading ke false di sini
        // karena kita menunggu redirect untuk menutup halaman.
        // Jika pengguna menutup browser secara manual, kita perlu cara lain
        // untuk menghandle-nya, tapi untuk alur sukses, ini lebih baik.
      }
    }
  }


  Widget _buildFirstPage() {
    const Color primaryOrange = Color(0xFFF97C33);
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: FadeTransition(
            opacity: _fadeOutAnim1,
            child: SlideTransition(
              position: _slideOutAnim1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                child: Container(
                  color: const Color(0xFFFDE1D2),
                  child: Image.asset('assets/images/welkam.webp', fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeOutAnim2,
                  child: SlideTransition(
                    position: _slideOutAnim2,
                    child: const Text('Selamat Datang di Portal SI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black, height: 1.2)),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeOutAnim3,
                  child: SlideTransition(
                    position: _slideOutAnim3,
                    child: const Text('Terkoneksi dengan Iman, Terinspirasi untuk Kebaikan', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Center(
              child: FadeTransition(
                opacity: _fadeOutAnim4,
                child: SlideTransition(
                  position: _slideOutAnim4,
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      // onPressed: _triggerTransition,
                      onPressed: () {
                        Navigator.of(context).push(
                          SlideTransitionRoute(page: const LoginPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Lanjutkan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSecondPage() {
    const Color rgRed = Color(0xFFB71C1C);
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: _fadeInAnim1,
                    child: SlideTransition(
                      position: _slideInAnim1,
                      child: Image.asset('assets/logo_la_rg.png', height: 48),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _fadeInAnim2,
                    child: SlideTransition(
                      position: _slideInAnim2,
                      child: const Text('Login akan Terasa\nJauh Lebih Mudah\ndengan Akun RG.', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black, height: 1.3)),
                    ),
                  ),
                ],
              ),
              FadeTransition(
                opacity: _fadeInAnim3,
                child: SlideTransition(
                  position: _slideInAnim3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Image.asset(
                      'assets/images/muslim_man.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      height: MediaQuery.of(context).size.height * 0.3,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  FadeTransition(
                    opacity: _fadeInAnim4,
                    child: SlideTransition(
                      position: _slideInAnim4,
                      child: const Center(
                        child: Text('Login ke berbagai layanan dengan\nsekali klik tanpa khawatir harus ngisi-ngisi form tambahan lagi', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeInAnim5,
                    child: SlideTransition(
                      position: _slideInAnim5,
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          // TAMBAHAN: Panggil fungsi _loginWithSDK saat ditekan
                          onPressed: _isLoading ? null : _loginWithSDK,
                          style: ElevatedButton.styleFrom(backgroundColor: rgRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                          // TAMBAHAN: Tampilkan loading atau teks
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                              : const Text('Lanjutkan dengan Akun RG', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _fadeInAnim6,
                    child: SlideTransition(
                      position: _slideInAnim6,
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              SlideTransitionRoute(page: const LoginPage()),
                            );
                          },
                          child: const Text('Lain Kali', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_inController.status == AnimationStatus.forward || _inController.status == AnimationStatus.completed) {
          _triggerBackTransition();
          return false;
        }
        return true;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildFirstPage(),
            AnimatedBuilder(
              animation: _inController,
              builder: (context, child) {
                return IgnorePointer(
                  ignoring: _inController.status == AnimationStatus.dismissed ||
                      _inController.status == AnimationStatus.reverse,
                  child: _buildSecondPage(),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}