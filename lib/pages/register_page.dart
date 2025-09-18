import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- TAMBAHAN: Import untuk InputFormatters
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/login_page.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/utils/secure_storage.dart';

// --- TAMBAHAN: Custom Input Formatter untuk mengubah spasi menjadi underscore ---
class _SpaceToUnderscoreFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Jika teks baru mengandung spasi, ganti dengan underscore
    if (newValue.text.contains(' ')) {
      final String newText = newValue.text.replaceAll(' ', '_');
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
    // Jika tidak, biarkan seperti biasa
    return newValue;
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- STATE DAN CONTROLLER LAMA TETAP DIPERTAHANKAN ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  // --- FUNGSI LOGIC LAMA TETAP SAMA ---
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

  // --- MODIFIKASI: Tambahkan validasi kekuatan password di sini ---
  Future<void> _handleRegister() async {
    // Validasi form (termasuk kekuatan password) akan dijalankan di sini
    if (_formKey.currentState!.validate()) {
      // Validasi konfirmasi password tetap ada
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

  // --- METHOD BUILD UTAMA ---
  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF97C33);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.35,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset('assets/images/register.webp', fit: BoxFit.cover),
            ),
          ),
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
                            // --- MODIFIKASI: Input Nama Lengkap ---
                            _buildCustomTextField(
                              controller: _fullNameController,
                              hintText: 'Nama Lengkap Kamu',
                              icon: Icons.person_outline,
                              inputFormatters: [
                                // Hanya izinkan huruf dan spasi
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Nama lengkap tidak boleh kosong';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // --- MODIFIKASI: Input Username ---
                            _buildCustomTextField(
                              controller: _usernameController,
                              hintText: 'Bikin Username Kamu',
                              icon: Icons.alternate_email,
                              inputFormatters: [
                                // Ganti spasi dengan underscore
                                _SpaceToUnderscoreFormatter(),
                                // Hanya izinkan huruf, angka, titik, dan underscore
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
                                if (value.length < 3) return 'Username minimal 3 karakter';
                                return null;
                              },
                            ),
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
                            // --- MODIFIKASI: Input Password dengan validasi kekuatan ---
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
                                if (value == null || value.isEmpty) {
                                  return 'Password tidak boleh kosong';
                                }
                                // Cek kekuatan password
                                String? strengthResult = _validatePasswordStrength(value);
                                if (strengthResult != null) {
                                  return strengthResult;
                                }
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
                                if (value != _passwordController.text) return 'Password tidak cocok'; // Validasi langsung
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
                      // ... (sisa widget sama seperti sebelumnya)
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

  // --- TAMBAHAN: Fungsi untuk validasi kekuatan password ---
  String? _validatePasswordStrength(String value) {
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Harus ada minimal 1 huruf kapital';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Harus ada minimal 1 huruf kecil';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Harus ada minimal 1 angka';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Harus ada minimal 1 simbol';
    }
    return null; // Return null jika password kuat
  }
  // Widget bantuan untuk text field (ditambah parameter inputFormatters)
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters, // <-- TAMBAHAN
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      inputFormatters: inputFormatters, // <-- TAMBAHAN
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
}