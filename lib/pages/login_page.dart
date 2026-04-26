import 'dart:async'; // <-- TAMBAHAN: Import untuk Timer/Future.delayed
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // ADDED IMPORT for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/register_page.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import 'package:url_launcher/url_launcher.dart'; // ADDED IMPORT for url_launcher

import '../models/user_model.dart';
import '../services/user_cache_service.dart';
// Jika Anda menggunakan SVG untuk ikon, tambahkan dependency flutter_svg
// import 'package:flutter_svg/flutter_svg.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  StreamSubscription? _sub;
  // --- SEMUA STATE DAN CONTROLLER LAMA TETAP DIPERTAHANKAN ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final _appLinks = AppLinks(); // Buat instance AppLinks
  StreamSubscription<Uri>? _linkSubscription;

  late AnimationController _loadingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
    _checkToken();
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.elasticOut),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimationController, curve: Curves.easeInOut),
    );

    // --- MODIFIKASI: TAMPILKAN BOTTOM SHEET SETELAH 2 DETIK ---
    // Future.delayed(const Duration(milliseconds: 500), () {
    //   if (mounted) {
    //     _showLoginWithSdkBottomSheet();
    //   }
    // });
  }

  // --- SEMUA FUNGSI LOGIC TETAP SAMA ---
  void _checkToken() async {
    final hasToken = await SecureStorage.hasToken();
    if (hasToken && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _loadingAnimationController.dispose();
    _pulseAnimationController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _showLoadingAnimation() {
    setState(() => _isLoading = true);
    _loadingAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
  }

  void _hideLoadingAnimation() {
    _loadingAnimationController.reverse().then((_) {
      _pulseAnimationController.stop();
      _pulseAnimationController.reset();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  /// Menangani link yang masuk saat aplikasi dibuka dari link
  void _handleIncomingLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      // Logika di dalam sini SAMA PERSIS seperti sebelumnya
      if (!mounted) return;

      print('Mendapat link dari app_links: $uri');
      if (uri.scheme == 'portalsi' && uri.host == 'callback') {
        String? authCode = uri.queryParameters['kode'];

        if (authCode != null) {
          print('Kode otentikasi berhasil didapat: $authCode');
          // TODO: Kirim kode ini ke server Anda untuk ditukar dengan session token
          // Contoh: _exchangeCodeForToken(authCode);
          // Lalu navigasi ke halaman dashboard
          // Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    }, onError: (err) {
      print('Error saat mendengarkan link app_links: $err');
    });
  }

  Future<void> _lupaPassword() async {
    setState(() {
      _isLoading = true;
    });

    const String forgotPasswordUrl = 'https://portalsi.com/forgot-password';

    try {
      if (kIsWeb) {
        // For web, use url_launcher to open in a new tab
        if (!await launchUrl(Uri.parse(forgotPasswordUrl), webOnlyWindowName: '_blank')) {
          throw 'Could not launch $forgotPasswordUrl';
        }
      } else {
        // For mobile, use FlutterWebBrowser
        await FlutterWebBrowser.openWebPage(
          url: forgotPasswordUrl,
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka halaman lupa password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithSDK() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ⚠️ Ganti 'localhost' dengan IP Address Anda jika testing di HP
      // final uri = Uri.parse('http://localhost:90/layanan-akun/sdk-akun-rg-v1/portal-run.php');
      // final response = await http.get(uri);

      // if (response.statusCode != 200) {
      //   throw Exception('Gagal memuat konfigurasi: Status code ${response.statusCode}');
      // }

      // final config = jsonDecode(response.body);
      final baseUrl = 'https://akunrg.com/au/pengenalan';
      // final response = await http.get(baseUrl);
      // final params = {
      //   'client_id': config['client_id'],
      //   'client_secret': config['client_secret'],
      //   'auth_v1': config['auth_v1'],
      //   'auth_v2': config['auth_v2'],
      //   'redirect': config['redirect'],
      //   'target': config['target'],
      //   'redirect_from': 'https://kimo.com/',
      //   'via': 'tombolLogin',
      // };
      final params = {
        'client_id': "6ab3cbd0-51ce-4987-94fd-9e66db9f0abf",
        'client_secret': "8c0f8331-2364-4e69-86e6-bd91b013e3ca",
        'auth_v1': "0e3ef8f9-55fd-43cc-a52f-f7d13299dfc2",
        'auth_v2': "047c6d2e-e0c6-459f-85a1-54e35561d2ae",
        'redirect': "portalsi://callback",
        'target': "connect",
        'redirect_from': "https://portalsi.com",
        'via': 'tombolLoginApp',
      };

      final finalUri = Uri.parse(baseUrl).replace(queryParameters: params);

      await FlutterWebBrowser.openWebPage(
        url: finalUri.toString(),
        customTabsOptions: const CustomTabsOptions(
          // Perbarui parameter ini
          colorScheme: CustomTabsColorScheme.system,
          showTitle: true,
          urlBarHidingEnabled: true,
        ),
        safariVCOptions: const SafariViewControllerOptions(
          barCollapsingEnabled: true,
          preferredBarTintColor: Colors.white,
          preferredControlTintColor: Colors.black,
          // Perbarui parameter dan nama enum ini
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _showLoadingAnimation();

      final authService = AuthService();
      final result = await authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      print('HASIL DARI API: $result');

      _hideLoadingAnimation();

      if (result['success'] == true && mounted) {
        if (result['user'] != null) {
          final user = User.fromJson(result['user']);
          await UserCacheService().saveUser(user);
        }

        // Cukup langsung navigasi, tanpa menampilkan SnackBar
        Navigator.pushNamedAndRemoveUntil(context, '/home', (Route<dynamic> route) => false);

      } else if (mounted) {
        // Biarkan SnackBar untuk notifikasi error tetap ada
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- TAMBAHAN: FUNGSI UNTUK MENAMPILKAN BOTTOM SHEET ---
  void _showLoginWithSdkBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- MODIFIKASI: MENGGUNAKAN GAMBAR ASSET ---
              Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Row(
                mainAxisAlignment: MainAxisAlignment.start, // Pastikan gambar rata kiri
                children: [
                  Image.asset(
                    'assets/logoakunrg.png', // Path ke gambar Anda
                    height: 20, // Sesuaikan tinggi gambar jika perlu
                  ),
                ],
              ),),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // --- AKHIR MODIFIKASI ---

              Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    // Judul
                    const Text(
                      'Login dengan Sekali Klik.',
                      style: TextStyle(
                        fontSize: 37,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    // Deskripsi
                    const Text(
                      'Login ke PortalSI kini menjadi lebih mudah dengan hanya satu kali klik menggunakan akun Anda yang terhubung secara aman dan tersinkron di berbagai platform.',
                      textAlign: TextAlign.left,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    const SizedBox(height: 32),
                    // Tombol Utama
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup bottom sheet
                          _loginWithSDK();      // Jalankan fungsi login SDK
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC92828), // Warna merah tua
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Lanjutkan dengan Akun RG',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol Sekunder
                    TextButton(
                      onPressed: () => Navigator.pop(context), // Tutup bottom sheet
                      child: const Text(
                        'Lain Kali',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET LOADING OVERLAY TETAP SAMA ---
  Widget _buildLoadingOverlay() {
    // (Kode untuk _buildLoadingOverlay tidak berubah sama sekali, hanya teksnya disesuaikan)
    return AnimatedBuilder(
      animation: _loadingAnimationController,
      builder: (context, child) {
        return _isLoading
            ? Material(
          color: Colors.black.withOpacity(0.5 * _fadeAnimation.value),
          child: Center(
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text('Logging in...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        )
            : const SizedBox.shrink();
      },
    );
  }

  // --- METHOD BUILD UTAMA DENGAN DESAIN MODERN ---
  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97C33);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
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
              // Bagian gambar atas dengan gradient overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: screenHeight * (isSmallScreen ? 0.3 : 0.38),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(36),
                        bottomRight: Radius.circular(36),
                      ),
                      child: Image.asset(
                        'assets/images/login.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(36),
                            bottomRight: Radius.circular(36),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Tombol Back
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 12,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Konten utama
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    SizedBox(height: screenHeight * (isSmallScreen ? 0.24 : 0.32)),
                    // Container putih untuk form
                    Container(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masuk ke\nAkun Anda',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              letterSpacing: -0.5,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Silakan masukkan email dan password Anda',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildCustomTextField(
                                  controller: _emailController,
                                  hintText: 'Email atau Username',
                                  icon: Icons.person_outline_rounded,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Kolom ini tidak boleh kosong';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _buildCustomTextField(
                                  controller: _passwordController,
                                  hintText: 'Password',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: Colors.grey.shade400,
                                      size: 22,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                                    if (value.length < 6) return 'Password minimal 6 karakter';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _lupaPassword,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    ),
                                    child: const Text(
                                      'Lupa Password?',
                                      style: TextStyle(
                                        color: primaryOrange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: primaryOrange.withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                children: const [
                                  TextSpan(text: 'Dengan melanjutkan, Anda menyetujui\n'),
                                  TextSpan(text: 'Ketentuan', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600)),
                                  TextSpan(text: ' dan '),
                                  TextSpan(text: 'Kebijakan Privasi', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Belum punya akun?",
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.rightToLeft,
                                      child: RegisterPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                child: const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    color: primaryOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildLoadingOverlay(),
            ],
          ),
        ),
    );
  }

  // Widget text field modern
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFF97C33), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  // Widget _buildSocialButton({required String iconPath, required VoidCallback? onPressed}) {
  //   return ElevatedButton(
  //     onPressed: onPressed, // Langsung gunakan nilainya di sini
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: const Color(0xFFF7F7F7),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //       padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
  //       elevation: 0,
  //     ),
  //     child: Image.asset(iconPath, height: 24, width: 24),
  //   );
  // }
  Widget _buildAkunRgLoginButton({required VoidCallback? onPressed}) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Warna latar tombol
          foregroundColor: Colors.black, // Warna default untuk teks di dalamnya
          elevation: 1, // Sedikit bayangan agar terangkat
          shape: const StadiumBorder(), // Membuat bentuk tombol menjadi kapsul/pill
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Padding di dalam tombol
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Membuat Row hanya selebar kontennya
          children: [
            const Text(
              'Login dengan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8), // Jarak antara teks dan logo
            Image.asset(
              'assets/logoakunrg.png', // Pastikan path ke logo ini benar
              height: 16, // Sesuaikan tinggi logo agar pas dengan teks
            ),
          ],
        ),
      ),
    );
  }
}