// lib/pages/edit_profile_page.dart (Sudah Diperbaiki)

// MODIFIKASI: Tambahkan import yang dibutuhkan
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/secure_storage.dart';

class EditProfilePage extends StatefulWidget {
  final User initialProfile;

  const EditProfilePage({Key? key, required this.initialProfile})
      : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;

  // State variables
  bool _isSaving = false;
  // MODIFIKASI: Ganti tipe state dari `File?` menjadi `XFile?`
  XFile? _selectedImageXFile;
  String _profilePictureUrl = '';
  late User _currentProfile;

  bool _isFetchingLatest = true;

  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchLatestProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fullNameController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _fullNameController = TextEditingController();
    _bioController = TextEditingController();
  }

  void _setProfileData(User profile) {
    _currentProfile = profile;
    _usernameController.text = profile.username;
    _emailController.text = profile.email ?? '';
    _fullNameController.text = profile.fullName ?? '';
    _bioController.text = profile.bio ?? '';
    _profilePictureUrl = profile.profilePictureUrl ?? '';
  }

  Future<void> _fetchLatestProfile() async {
    setState(() => _isFetchingLatest = true);
    try {
      final latestProfile = await ProfileService().refreshProfile();
      if (mounted) {
        _setProfileData(latestProfile);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Gagal memuat data terbaru: $e");
        _setProfileData(widget.initialProfile);
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLatest = false);
      }
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      // ... (kode bottom sheet tidak berubah)
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  'Pilih Foto Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildImageSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Pilih dari Galeri',
                subtitle: 'Akses galeri foto Anda',
                onTap: () => _selectImage(ImageSource.gallery),
                color: Colors.amber.shade700,
              ),
              _buildImageSourceTile(
                icon: Icons.camera_alt_outlined,
                title: 'Ambil Foto Baru',
                subtitle: 'Gunakan kamera perangkat',
                onTap: () => _selectImage(ImageSource.camera),
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    // ... (kode ini tidak berubah)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Salin dan ganti fungsi _selectImage
  Future<void> _selectImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      // MODIFIKASI: Pastikan variabel 'image' bertipe XFile?
      // Ini akan cocok dengan variabel state '_selectedImageXFile'.
      final XFile? image = await _profileService.pickImage(source: source);
      if (image != null) {
        setState(() => _selectedImageXFile = image);
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar: $e');
    }
  }

  Future<XFile?> pickImage({required ImageSource source}) async {
    final ImagePicker picker = ImagePicker();
    try {
      // Fungsi pickImage dari package image_picker akan mengembalikan XFile
      final XFile? pickedFile = await picker.pickImage(source: source);
      // Langsung kembalikan hasil XFile ini tanpa diubah menjadi File
      return pickedFile;
    } catch (e) {
      print('Error picking image in service: $e');
      throw Exception('Gagal memilih gambar.');
    }
  }

// Fungsi _saveProfile Anda sudah benar, tidak perlu diubah.
// Error kedua pada gambar akan hilang setelah kita memperbaiki file user_service.dart
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });

    setState(() => _isSaving = true);

    try {
      String? newProfilePictureUrl;

      if (_selectedImageXFile != null) {
        // Baris ini sudah benar memanggil dengan _selectedImageXFile
        newProfilePictureUrl =
        await _profileService.uploadProfilePicture(_selectedImageXFile!);
      }

      final updatedUserData = _currentProfile.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
        profilePictureUrl: newProfilePictureUrl ?? _currentProfile.profilePictureUrl,
      );

      final success = await _profileService.updateProfile(updatedUserData);

      if (success) {
        HapticFeedback.mediumImpact();
        _showSuccessDialog('Profil berhasil diperbarui!');
      } else {
        HapticFeedback.heavyImpact();
        _showErrorDialog('Gagal memperbarui profil');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ... (kode _showErrorDialog dan _showSuccessDialog tidak berubah)
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Oops!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
            const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
              const Icon(Icons.check_circle_outline, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Text('Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green.withOpacity(0.1),
              foregroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
            const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (kode build utama tidak berubah, tapi _buildProfileImage di dalamnya akan diubah)
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: Stack(
        children: [
          const _CoolBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white.withOpacity(0.8),
                foregroundColor: Colors.brown.shade800,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'Edit Profil',
                    style: TextStyle(
                      color: Colors.brown.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Container(color: Colors.transparent),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Center(
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 0.95)
                            .animate(_buttonAnimationController),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isSaving
                                ? null
                                : LinearGradient(
                              colors: [
                                Colors.amber.shade600,
                                Colors.orange.shade800
                              ],
                            ),
                            color: _isSaving ? Colors.grey[300] : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSaving
                                ? null
                                : [
                              BoxShadow(
                                color: Colors.amber
                                    .withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isSaving ? null : _saveProfile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: _isSaving
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text(
                                  'Simpan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileImage(),
                        const SizedBox(height: 40),
                        _buildFormCard(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (kode _buildFormCard, _buildAnimatedTextField tidak berubah)
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lengkapi informasi profil Anda dengan data yang akurat',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildAnimatedTextField(
              controller: _fullNameController,
              labelText: 'Nama Lengkap',
              icon: Icons.badge_outlined,
              delay: 0.1,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _usernameController,
              labelText: 'Username',
              icon: Icons.alternate_email_outlined,
              delay: 0.2,
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _emailController,
              labelText: 'Email',
              icon: Icons.email_outlined,
              delay: 0.3,
              keyboardType: TextInputType.emailAddress,
              color: Colors.brown.shade400,
            ),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _bioController,
              labelText: 'Bio',
              icon: Icons.info_outline,
              delay: 0.4,
              maxLines: 4,
              isOptional: true,
              color: Colors.deepOrange.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required double delay,
    required Color color,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isOptional = false,
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
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            validator: isOptional
                ? null
                : (value) => (value?.isEmpty ?? true)
                ? '$labelText tidak boleh kosong'
                : null,
          ),
        ),
      ),
    );
  }

  // MODIFIKASI: Ubah cara widget ini menampilkan gambar baru
  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Hero(
            tag: 'profile_image',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade800],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: _selectedImageXFile != null
                    // --- Blok ini yang diubah ---
                        ? (kIsWeb
                        ? Image.network( // Tampilkan via network untuk Web
                      _selectedImageXFile!.path,
                      key: ValueKey(_selectedImageXFile!.path),
                      fit: BoxFit.cover,
                      width: 124,
                      height: 124,
                    )
                        : Image.file( // Tampilkan via file untuk Mobile
                      File(_selectedImageXFile!.path),
                      key: ValueKey(_selectedImageXFile!.path),
                      fit: BoxFit.cover,
                      width: 124,
                      height: 124,
                    ))
                    // --- Akhir dari blok yang diubah ---
                        : _profilePictureUrl.isNotEmpty
                        ? CachedNetworkImage(
                      key: ValueKey(_profilePictureUrl),
                      imageUrl: _profilePictureUrl,
                      // ... sisa kode CachedNetworkImage sama
                      fit: BoxFit.cover,
                      width: 124,
                      height: 124,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade300,
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.amber),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade200,
                              Colors.grey.shade300,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                        : Container(
                      // ... sisa kode placeholder sama
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade300,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _pickImage,
              // ... sisa kode icon kamera sama
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber.shade700,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (kode _CoolBackground dan _BackgroundPainter tidak berubah)
class _CoolBackground extends StatelessWidget {
  const _CoolBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = Colors.yellow.shade50.withOpacity(0.9)
      ..style = PaintingStyle.fill
      ..imageFilter = ImageFilter.blur(sigmaX: 100, sigmaY: 100);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 150, paint1);

    final paint2 = Paint()
      ..color = Colors.amber.shade100.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..imageFilter = ImageFilter.blur(sigmaX: 120, sigmaY: 120);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.85), 120, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}