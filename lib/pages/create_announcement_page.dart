import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/announcement_service.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({Key? key}) : super(key: key);

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  File? _imageFile;
  bool _isPinned = false;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  Future<void> _submitAnnouncement() async {
    // Validasi form seperti biasa
    if (_formKey.currentState!.validate() == false) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Panggil service menggunakan singleton instance
      await AnnouncementService().createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        isPinned: _isPinned,
        image: _imageFile,
      );

      // Jika kode sampai di sini, berarti API call berhasil
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengumuman berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);

    } catch (e) {
      // Jika terjadi error (misal: 401, 500, atau tidak ada koneksi),
      // service akan melempar exception yang akan ditangkap di sini.
      print('Error saat membuat pengumuman: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat pengumuman. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Pastikan loading indicator selalu berhenti, baik berhasil maupun gagal
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buat Pengumuman'),
        centerTitle: true,
        actions: [
          _isLoading
              ? Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
                child:
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))),
          )
              : IconButton(
            icon: Icon(Icons.check),
            onPressed: _submitAnnouncement,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Judul Pengumuman',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Konten
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: 'Isi Pengumuman',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Konten tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Pinned Switch
              SwitchListTile(
                title: Text('Sematkan Pengumuman'),
                subtitle: Text('Pengumuman ini akan selalu di atas.'),
                value: _isPinned,
                onChanged: (bool value) {
                  setState(() {
                    _isPinned = value;
                  });
                },
                secondary: Icon(Icons.push_pin_outlined),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),

              // Gambar
              Text('Gambar (Opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              _imageFile == null
                  ? OutlinedButton.icon(
                icon: Icon(Icons.add_photo_alternate_outlined),
                label: Text('Pilih Gambar'),
                onPressed: _pickImage,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton.icon(
                    icon: Icon(Icons.close, color: Colors.red),
                    label: Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                    onPressed: _removeImage,
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}