// lib/pages/edit_group_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:portal_si/models/group_model.dart';
import 'package:portal_si/services/group_service.dart';

class EditGroupPage extends StatefulWidget {
  final Group group;

  const EditGroupPage({super.key, required this.group});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late final TextEditingController _nameController;
  final GlobalKey _previewAvatarKey = GlobalKey(); // Kunci untuk menangkap gambar
  final GroupService _groupService = GroupService();
  final ImagePicker _picker = ImagePicker();

  // State untuk mengelola avatar
  File? _selectedAvatarFile;
  String? _currentAvatarUrl;
  String? _selectedEmoji;
  bool _isLoading = false;

  final List<String> _defaultAvatars = [
    '🎉', '💎', '🏈', '🌮', '😎', '❤️', '✨', '👀', '🌈', '🦄', '🌻', '🎂',
    '👗', '✌️', '🎄', '🌶️', '🏠', '📣', '🚀', '☁️',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _currentAvatarUrl = widget.group.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Fungsi untuk memilih gambar dari galeri
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedAvatarFile = File(image.path);
        _selectedEmoji = null; // Reset pilihan emoji
        _currentAvatarUrl = null;
      });
    }
  }

  /// 🎨 [BARU] Fungsi untuk mengubah widget menjadi file gambar
  Future<File?> _generateFileFromWidget() async {
    try {
      RenderRepaintBoundary boundary = _previewAvatarKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // Tingkatkan pixelRatio untuk kualitas
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/avatar_emoji.png').create();
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint("Error generating file from widget: $e");
      return null;
    }
  }

  /// Fungsi yang dipanggil saat tombol 'Done' ditekan
  void _handleSaveChanges() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama grup tidak boleh kosong.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    File? avatarToUpload;

    // Tentukan file avatar yang akan di-upload
    if (_selectedAvatarFile != null) {
      // 1. Jika pengguna memilih file dari galeri
      avatarToUpload = _selectedAvatarFile;
    } else if (_selectedEmoji != null) {
      // 2. Jika pengguna memilih emoji, generate file dari emoji
      avatarToUpload = await _generateFileFromWidget();
    }
    // 3. Jika tidak keduanya, biarkan `avatarToUpload` null (tidak mengubah gambar)

    try {
      final success = await _groupService.updateGroup(
        groupId: widget.group.id,
        name: newName,
        avatarFile: avatarToUpload,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Info grup berhasil diperbarui.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Gagal memperbarui grup.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Widget untuk menampilkan preview avatar
  Widget _buildAvatarPreview() {
    Widget avatarContent;

    if (_selectedAvatarFile != null) {
      // Prioritas 1: Tampilkan gambar dari galeri
      avatarContent = CircleAvatar(
        radius: 45,
        backgroundImage: FileImage(_selectedAvatarFile!),
      );
    } else if (_selectedEmoji != null) {
      // Prioritas 2: Tampilkan emoji yang dipilih
      avatarContent = CircleAvatar(
        radius: 45,
        backgroundColor: Colors.grey.shade800,
        child: Text(_selectedEmoji!, style: const TextStyle(fontSize: 50)),
      );
    } else if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
      // Prioritas 3: Tampilkan gambar dari URL (data awal)
      avatarContent = CircleAvatar(
        radius: 45,
        backgroundImage: NetworkImage(_currentAvatarUrl!),
      );
    } else {
      // Fallback jika tidak ada gambar sama sekali
      avatarContent = CircleAvatar(
        radius: 45,
        backgroundColor: Colors.grey.shade800,
        child: const Icon(Icons.group, size: 50, color: Colors.white70),
      );
    }

    // Bungkus dengan RepaintBoundary agar bisa "ditangkap" sebagai gambar
    return RepaintBoundary(
      key: _previewAvatarKey,
      child: avatarContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batalkan', style: TextStyle(color: Colors.red, fontSize: 16)),
        ),
        leadingWidth: 100,
        title: const Text('Edit Grup', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          _isLoading
              ? const Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          )
              : TextButton(
            onPressed: _handleSaveChanges,
            child: const Text('Terapkan', style: TextStyle(color: Color(0xFF209A83), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                _buildAvatarPreview(),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey.shade700,
                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                )
              ],
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.black, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Nama Grup',
                labelStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white.withOpacity(0.5),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _defaultAvatars.length,
              itemBuilder: (context, index) {
                final emoji = _defaultAvatars[index];
                final isSelected = _selectedEmoji == emoji; // Cek apakah emoji ini sedang dipilih

                return GestureDetector(
                  onTap: () {
                    // [FUNGSI UTAMA] Update state saat emoji dipilih
                    setState(() {
                      _selectedEmoji = emoji;
                      _selectedAvatarFile = null; // Reset pilihan file
                      _currentAvatarUrl = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.blue, width: 3) // Tampilkan border jika terpilih
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.primaries[index % Colors.primaries.length].withOpacity(0.3),
                      child: Text(emoji, style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}