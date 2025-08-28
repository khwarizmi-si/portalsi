import 'package:flutter/material.dart';
import 'package:flutter_web_browser/flutter_web_browser.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/register_page.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/utils/secure_storage.dart';

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
  // --- SEMUA STATE DAN CONTROLLER LAMA TETAP DIPERTAHANKAN ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _loadingAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
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
        'redirect': "https://portalsi.com/get/larg",
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

      _hideLoadingAnimation();

      if (result['success'] == true && mounted) {

        if (result['user'] != null) {
          final user = User.fromJson(result['user']); // Asumsi API mengembalikan data user
          await UserCacheService().saveUser(user);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/home', (Route<dynamic> route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // --- METHOD BUILD UTAMA DIUBAH TOTAL SESUAI DESAIN BARU ---
  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97C33);
    const Color lightGrey = Color(0xFFF7F7F7);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bagian gambar atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                'assets/images/login.webp', // <-- GANTI DENGAN GAMBAR ANDA
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Konten utama
          SafeArea(
            child: ListView(
              children: [
                // Spacer untuk memberi ruang di atas
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                // Container putih untuk form
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Login Portal SI', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'YourCustomFont')), // Ganti font jika ada
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildCustomTextField(
                              controller: _emailController,
                              hintText: 'Email atau Username', // Teks diubah
                              icon: Icons.person_outline, // Ikon diubah menjadi lebih generik
                              validator: (value) {
                                // Validasi dilonggarkan, hanya cek kosong
                                if (value == null || value.isEmpty) return 'Kolom ini tidak boleh kosong';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
                                if (value.length < 6) return 'Password minimal 6 karakter';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Row(
                          //   children: [
                          //     Checkbox(
                          //       value: _rememberMe,
                          //       onChanged: (value) => setState(() => _rememberMe = value!),
                          //       activeColor: primaryOrange,
                          //     ),
                          //     const Text('Remember me'),
                          //   ],
                          // ),
                          // TextButton(
                          //   onPressed: () {},
                          //   child: const Text('Forget password', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: const Text('Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.grey)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Atau gunakan', style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          const Expanded(child: Divider(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(iconPath: 'assets/logo_google.png', onPressed: () {}),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            iconPath: 'assets/logo_la_rg.png',
                            // Langsung berikan null jika loading, atau fungsi jika tidak
                            onPressed: _isLoading ? null : _loginWithSDK,
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            children: [
                              TextSpan(text: 'Dengan mendaftar, berarti Anda setuju dengan\n'),
                              TextSpan(text: 'Ketentuan', style: TextStyle(color: primaryOrange, decoration: TextDecoration.underline)),
                              TextSpan(text: ' dan '),
                              TextSpan(text: 'Kebijakan Privasi', style: TextStyle(color: primaryOrange, decoration: TextDecoration.underline)),
                              TextSpan(text: ' kami'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Belum memiliki akun?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.rightToLeft, // Tipe animasi dari kanan ke kiri
                                  child: RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: primaryOrange,
                                fontWeight: FontWeight.bold,
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
    );
  }

  // Widget bantuan baru untuk text field
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
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildSocialButton({required String iconPath, required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed, // Langsung gunakan nilainya di sini
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF7F7F7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        elevation: 0,
      ),
      child: Image.asset(iconPath, height: 24, width: 24),
    );
  }
}