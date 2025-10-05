import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crop_image/crop_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/user_provider.dart';

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

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _fullNameController;
  late TextEditingController _bioController;

  bool _isSaving = false;
  XFile? _selectedImageXFile;
  XFile? _selectedBannerXFile;
  String _profilePictureUrl = '';
  String _bannerUrl = '';
  late User _currentProfile;

  bool _isFetchingLatest = true;

  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchLatestProfile();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _buttonAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
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
    _bannerUrl = profile.bannerUrl ?? '';
  }

  Future<void> _fetchLatestProfile() async {
    setState(() => _isFetchingLatest = true);
    try {
      final latestProfile = await ProfileService().refreshProfile();
      if (mounted) _setProfileData(latestProfile);
    } catch (e) {
      if (mounted) {
        _showErrorDialog("Gagal memuat data terbaru: $e");
        _setProfileData(widget.initialProfile);
      }
    } finally {
      if (mounted) setState(() => _isFetchingLatest = false);
    }
  }

  Future<void> _pickAndCropImage({required bool isBanner}) async {
    HapticFeedback.lightImpact();
    final source = await _showImageSourceModal(isBanner: isBanner);
    if (source == null) return;

    try {
      final XFile? pickedImage = await _profileService.pickImage(source: source);
      if (pickedImage == null || !mounted) return;

      final File? croppedFile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImageCropperPage(
            imageFile: File(pickedImage.path),
            isBanner: isBanner,
          ),
          fullscreenDialog: true,
        ),
      );

      if (croppedFile != null) {
        if (isBanner) {
          setState(() => _selectedBannerXFile = XFile(croppedFile.path));
        } else {
          setState(() => _selectedImageXFile = XFile(croppedFile.path));
        }
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showErrorDialog("Gagal memproses gambar: $e");
    }
  }

  Future<ImageSource?> _showImageSourceModal({required bool isBanner}) {
    final title = isBanner ? 'Pilih Gambar Banner' : 'Pilih Foto Profil';
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            _buildImageSourceTile(
              icon: Icons.photo_library_outlined,
              title: 'Pilih dari Galeri',
              subtitle: 'Akses galeri foto Anda',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              color: Colors.amber.shade700,
            ),
            _buildImageSourceTile(
              icon: Icons.camera_alt_outlined,
              title: 'Ambil Foto Baru',
              subtitle: 'Gunakan kamera perangkat',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 20),
          ],
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    _buttonAnimationController.forward().then((_) => _buttonAnimationController.reverse());
    setState(() => _isSaving = true);
    try {
      final updatedUserData = _currentProfile.copyWith(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        bio: _bioController.text.trim(),
      );
      final success = await _profileService.updateProfile(
        updatedUserData,
        profilePicture: _selectedImageXFile,
        banner: _selectedBannerXFile,
      );
      if (success) {
        HapticFeedback.mediumImpact();

        // --- 👇 PERBAIKAN FINAL DI SINI 👇 ---
        // Panggil UserProvider untuk mengambil data terbaru SEBELUM menampilkan dialog sukses.
        // Ini akan memperbarui data di seluruh aplikasi secara diam-diam.
        if (mounted) {
          Provider.of<UserProvider>(context, listen: false).fetchCurrentUser();
        }

        await Future.delayed(const Duration(milliseconds: 500));
        _showSuccessDialog('Profil berhasil diperbarui!');
      } else {
        HapticFeedback.heavyImpact();
        _showErrorDialog('Gagal memperbarui profil. Silakan coba lagi.');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorDialog('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.error_outline, color: Colors.red)),
          const SizedBox(width: 12),
          const Text('Oops!', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600))),
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
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_circle_outline, color: Colors.green)),
          const SizedBox(width: 12),
          const Text('Berhasil!', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: Stack(
        children: [
          const _CoolBackground(),
          CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white.withOpacity(0.8),
              foregroundColor: Colors.brown.shade800,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Edit Profil', style: TextStyle(color: Colors.brown.shade800, fontWeight: FontWeight.bold, fontSize: 20)),
                background: Container(color: Colors.transparent),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 0.95).animate(_buttonAnimationController),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isSaving ? null : LinearGradient(colors: [Colors.amber.shade600, Colors.orange.shade800]),
                          color: _isSaving ? Colors.grey[300] : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isSaving ? null : [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSaving ? null : _saveProfile,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  child: Column(children: [
                    _buildBannerImage(),
                    const SizedBox(height: 20),
                    _buildProfileImage(),
                    const SizedBox(height: 40),
                    _buildFormCard(),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBannerImage() {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey.shade200,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _selectedBannerXFile != null
                    ? (kIsWeb
                    ? Image.network(_selectedBannerXFile!.path, key: ValueKey(_selectedBannerXFile!.path), fit: BoxFit.cover)
                    : Image.file(File(_selectedBannerXFile!.path), key: ValueKey(_selectedBannerXFile!.path), fit: BoxFit.cover))
                    : _bannerUrl.isNotEmpty
                    ? CachedNetworkImage(
                  key: ValueKey(_bannerUrl),
                  imageUrl: _bannerUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey.shade300),
                  errorWidget: (context, url, error) => const Icon(Icons.image_not_supported, color: Colors.grey),
                )
                    : Container(
                  key: const ValueKey('placeholder'),
                  color: Colors.grey.shade300,
                  child: Icon(Icons.landscape, color: Colors.grey.shade500, size: 50),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _pickAndCropImage(isBanner: true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informasi Profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown.shade800)),
            const SizedBox(height: 8),
            Text('Lengkapi informasi profil Anda dengan data yang akurat', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            _buildAnimatedTextField(controller: _fullNameController, labelText: 'Nama Lengkap', icon: Icons.badge_outlined, delay: 0.1, color: Colors.amber.shade700),
            const SizedBox(height: 20),
            _buildAnimatedTextField(controller: _usernameController, labelText: 'Username', icon: Icons.alternate_email_outlined, delay: 0.2, color: Colors.orange.shade700),
            const SizedBox(height: 20),
            _buildAnimatedTextField(
              controller: _bioController,
              labelText: 'Bio',
              icon: Icons.info_outline,
              delay: 0.4,
              maxLines: 4,
              isOptional: true,
              color: Colors.deepOrange.shade400,
              maxLength: 300,
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
    int? maxLength,
  }) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Interval(delay, 1.0, curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
          child: TextFormField(
            controller: controller,
            maxLength: maxLength,
            decoration: InputDecoration(
              labelText: labelText,
              labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: color, width: 2)),
              errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            validator: isOptional ? null : (value) => (value?.isEmpty ?? true) ? '$labelText tidak boleh kosong' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Stack(
        children: [
          Hero(
            tag: 'profile_image',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.orange.shade800]),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              padding: const EdgeInsets.all(4),
              child: CircleAvatar(
                radius: 64,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                    child: _selectedImageXFile != null
                        ? (kIsWeb
                        ? Image.network(_selectedImageXFile!.path, key: ValueKey(_selectedImageXFile!.path), fit: BoxFit.cover, width: 124, height: 124)
                        : Image.file(File(_selectedImageXFile!.path), key: ValueKey(_selectedImageXFile!.path), fit: BoxFit.cover, width: 124, height: 124))
                        : _profilePictureUrl.isNotEmpty
                        ? CachedNetworkImage(
                      key: ValueKey(_profilePictureUrl),
                      imageUrl: _profilePictureUrl,
                      fit: BoxFit.cover,
                      width: 124,
                      height: 124,
                      placeholder: (context, url) => Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300])),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber))),
                      errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300])),
                          child: Icon(Icons.person, size: 60, color: Colors.grey[600])),
                    )
                        : Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade300])),
                      child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
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
              onTap: () => _pickAndCropImage(isBanner: false),
              child: Container(
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.amber.shade700,
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageCropperPage extends StatelessWidget {
  final File imageFile;
  final bool isBanner;

  const _ImageCropperPage({required this.imageFile, required this.isBanner});

  @override
  Widget build(BuildContext context) {
    final controller = CropController(
      aspectRatio: isBanner ? 16 / 7 : 1,
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sesuaikan Gambar'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              );

              try {
                // --- 👇 PERBAIKAN UTAMA DAN FINAL DI SINI 👇 ---
                // Menggunakan method croppedBitmap() yang lebih stabil
                final result = await controller.croppedBitmap();
                final data = await result.toByteData(format: ui.ImageByteFormat.png);

                if (data == null) {
                  throw Exception("Gagal mengonversi gambar yang di-crop.");
                }

                final bytes = data.buffer.asUint8List();
                final tempDir = await getTemporaryDirectory();
                final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                final File tempFile = File('${tempDir.path}/$fileName');
                await tempFile.writeAsBytes(bytes);

                if (context.mounted) Navigator.pop(context); // Tutup loading
                if (context.mounted) Navigator.pop(context, tempFile); // Kembali dengan hasil

              } catch (e) {
                if (context.mounted) Navigator.pop(context); // Tutup loading
                if (context.mounted) Navigator.pop(context, null); // Kembali tanpa hasil
              }
            },
            child: const Text('SELESAI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildCropper(controller),
        ),
      ),
    );
  }

  Widget _buildCropper(CropController controller) {
    final cropper = CropImage(
      controller: controller,
      image: Image.file(imageFile),
      gridColor: Colors.white54,
      scrimColor: Colors.black.withOpacity(0.7),
      paddingSize: 20,
      alwaysShowThirdLines: true,
    );

    if (!isBanner) {
      return ClipOval(child: cropper);
    }
    return cropper;
  }
}

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
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), 150, paint1);
    final paint2 = Paint()
      ..color = Colors.amber.shade100.withOpacity(0.6)
      ..style = PaintingStyle.fill
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 120, sigmaY: 120);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.85), 120, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}