// lib/pages/change_password_page.dart

import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Pastikan path model Anda benar
import '../services/auth_service.dart';
import '../services/user_service.dart'; // Untuk mendapatkan username

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _username;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fetchCurrentUser();
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final User currentUser = await ProfileService().getProfile();
      if (mounted) {
        setState(() {
          _username = currentUser.username;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data pengguna: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru tidak cocok.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_username != null && _newPasswordController.text == _username) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru tidak boleh sama dengan username.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService().changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Password berhasil diganti!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required double delay,
    required Color color,
    required bool isPassword,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(animation),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword && !isVisible,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              suffixIcon: isPassword
                  ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onVisibilityToggle,
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: color, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            validator: validator,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      // =======================================================================
      // >> PERUBAHAN UTAMA ADA DI DALAM `body` DAN `bottomNavigationBar` <<
      // =======================================================================
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFF0D0),
              Color(0xFFFFFFFF),
              Color(0xFFDFFEF8),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  // Membuat konten di dalam SingleChildScrollView setidaknya setinggi layar
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  // Membantu Column di dalamnya untuk bisa menggunakan Expanded
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        // Memberi jarak dari atas (agar gradien terlihat)
                        const SizedBox(height: 24.0),
                        // Expanded membuat container putih mengisi sisa ruang
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 32.0),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40),
                                  topRight: Radius.circular(40),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(0, 0, 0, 0.05),
                                    blurRadius: 15,
                                    offset: Offset(0, -5),
                                  )
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Keamanan Akun',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Untuk keamanan, mohon jangan bagikan kata sandi Anda.',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),
                                _buildAnimatedTextField(
                                  controller: _currentPasswordController,
                                  labelText: 'Password Sekarang',
                                  icon: Icons.lock_clock_outlined,
                                  delay: 0.1,
                                  color: Colors.blue.shade700,
                                  isPassword: true,
                                  isVisible: _isCurrentPasswordVisible,
                                  onVisibilityToggle: () => setState(() =>
                                  _isCurrentPasswordVisible =
                                  !_isCurrentPasswordVisible),
                                  validator: (value) => (value?.isEmpty ?? true)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                _buildAnimatedTextField(
                                  controller: _newPasswordController,
                                  labelText: 'Password Baru',
                                  icon: Icons.lock_outline,
                                  delay: 0.2,
                                  color: Colors.purple.shade700,
                                  isPassword: true,
                                  isVisible: _isNewPasswordVisible,
                                  onVisibilityToggle: () => setState(() =>
                                  _isNewPasswordVisible =
                                  !_isNewPasswordVisible),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Wajib diisi';
                                    }
                                    if (value.length < 6) {
                                      return 'Minimal 6 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildAnimatedTextField(
                                  controller: _confirmPasswordController,
                                  labelText: 'Ulangi Password Baru',
                                  icon: Icons.lock_person_outlined,
                                  delay: 0.3,
                                  color: Colors.orange.shade800,
                                  isPassword: true,
                                  isVisible: _isConfirmPasswordVisible,
                                  onVisibilityToggle: () => setState(() =>
                                  _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible),
                                  validator: (value) => (value?.isEmpty ?? true)
                                      ? 'Wajib diisi'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white, // Beri warna latar belakang agar konsisten
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
        child: _isLoading
            ? const Center(heightFactor: 1, child: CircularProgressIndicator())
            : SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _submitChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Ganti Password',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}