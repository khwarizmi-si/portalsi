// lib/pages/create_announcement_page.dart (SUDAH DIPERBAIKI)

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // <-- TAMBAHKAN IMPORT INI
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/announcement_service.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({Key? key}) : super(key: key);

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  XFile? _imageXFile;
  int _isPinned = 0; // MODIFIED: Changed to int, default to 0
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageXFile = pickedFile;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageXFile = null;
    });
  }

  Future<void> _submitAnnouncement() async {
    if (_formKey.currentState!.validate() == false) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      print(_titleController.text);
      print(_contentController.text);
      print(_isPinned); // This will now print 0 or 1

      // Assuming AnnouncementService().createAnnouncement expects an int for isPinned
      // If it expects a boolean, it should be: isPinned: _isPinned == 1,
      await AnnouncementService().createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        isPinned: _isPinned, // MODIFIED: Passing int directly
        image: _imageXFile,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pengumuman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    required double delay,
    required Color color,
    int maxLines = 1,
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

  Widget _buildAnimatedContainer({
    required Widget child,
    required double delay,
    Color shadowColor = Colors.grey,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade200, width: 1.5)
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pengumuman', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submitAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
              const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 24),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
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
                      'Informasi Pengumuman',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lengkapi informasi pengumuman dengan data yang akurat',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedTextField(
                      controller: _titleController,
                      labelText: 'Judul Pengumuman',
                      icon: Icons.title_rounded,
                      delay: 0.1,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(height: 20),

                    _buildAnimatedTextField(
                      controller: _contentController,
                      labelText: 'Isi Pengumuman',
                      icon: Icons.notes_rounded,
                      delay: 0.2,
                      color: Colors.blue.shade700,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 24),

                    _buildAnimatedContainer(
                      delay: 0.3,
                      shadowColor: Colors.purple,
                      child: SwitchListTile(
                        title: const Text('Pin Pengumuman', style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('Pengumuman yang Anda pin akan muncul di bagian atas halaman dashboard.', style: TextStyle(color: Colors.grey[600])),
                        value: _isPinned == 1, // MODIFIED: Convert int to bool for SwitchListTile
                        onChanged: (bool value) {
                          setState(() {
                            _isPinned = value ? 1 : 0; // MODIFIED: Convert bool to int
                          });
                          print(_isPinned.toString());
                        },
                        activeColor: Colors.purple.shade600,
                        secondary: Container(
                          margin: const EdgeInsets.only(left: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.push_pin_outlined, color: Colors.purple.shade600, size: 20,),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Gambar (Opsional)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildAnimatedContainer(
                      delay: 0.4,
                      shadowColor: Colors.green,
                      child: _imageXFile == null
                          ? GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(14)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey[600]),
                              const SizedBox(height: 8),
                              const Text('Ketuk untuk memilih gambar')
                            ],
                          ),
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: kIsWeb
                                  ? Image.network(_imageXFile!.path, fit: BoxFit.cover)
                                  : Image.file(File(_imageXFile!.path), fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _removeImage,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
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
}
