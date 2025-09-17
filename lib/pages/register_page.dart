import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/login_page.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/utils/secure_storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- STATE DAN CONTROLLER LAMA TETAP DIPERTAHANKAN ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController(); // Tetap ada
  final _usernameController = TextEditingController(); // Tetap ada
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Baru untuk konfirmasi
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
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
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Validasi tambahan untuk konfirmasi password
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password dan konfirmasi password tidak cocok.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final authService = AuthService();
      final result = await authService.register(
        _usernameController.text.trim(),
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registrasi berhasil! Silakan login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Registrasi gagal.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // --- METHOD BUILD UTAMA DIUBAH TOTAL SESUAI DESAIN BARU ---
  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97C33);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bagian gambar atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                'assets/images/register.webp', // <-- GANTI DENGAN GAMBAR ANDA
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Konten utama
          SafeArea(
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.28),
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
                      const Text('Daftar Portal SI', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // --- KOLOM INPUT BARU DITAMBAHKAN DI SINI ---
                            _buildCustomTextField(
                              controller: _fullNameController,
                              hintText: 'Nama Lengkap Kamu',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Nama lengkap tidak boleh kosong';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _usernameController,
                              hintText: 'Bikin Username Kamu',
                              icon: Icons.alternate_email,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
                                if (value.length < 3) return 'Username minimal 3 karakter';
                                return null;
                              },
                            ),
                            // ---------------------------------------------
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _emailController,
                              hintText: 'Email Kamu',
                              icon: Icons.email_outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
                                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Format email tidak valid';
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
                            const SizedBox(height: 16),
                            _buildCustomTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Ulangin passwordnya',
                              icon: Icons.lock_outline,
                              obscureText: _obscureConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Daftar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Row(
                      //   children: [
                      //     const Expanded(child: Divider(color: Colors.grey)),
                      //     Padding(
                      //       padding: const EdgeInsets.symmetric(horizontal: 16),
                      //       child: Text('Atau daftar dengan', style: TextStyle(color: Colors.grey.shade600)),
                      //     ),
                      //     const Expanded(child: Divider(color: Colors.grey)),
                      //   ],
                      // ),
                      // const SizedBox(height: 30),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     _buildSocialButton(iconPath: 'assets/logo_google.png', onPressed: () {}),
                      //     const SizedBox(width: 20),
                      //     _buildSocialButton(iconPath: 'assets/logo_la_rg.png', onPressed: () {}),
                      //   ],
                      // ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Sudah memiliki akun? ", style: TextStyle(color: Colors.grey)),
                          TextButton(
                            // onPressed: () {
                            //   Navigator.pushReplacementNamed(context, '/login');
                            // },
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageTransition(
                                  type: PageTransitionType.leftToRight, // Tipe animasi dari kanan ke kiri
                                  child: LoginPage(),
                                ),
                              );
                            },
                            child: const Text('Login', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget bantuan untuk text field
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

  // Widget bantuan untuk tombol social
  Widget _buildSocialButton({required String iconPath, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
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