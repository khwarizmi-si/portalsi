// lib/pages/link_santri_page.dart

import 'package:flutter/material.dart';
import '../models/santri_model.dart';
// Hapus import service karena data sudah didapat dari halaman sebelumnya

class LinkSantriPage extends StatefulWidget {
  // Tambahkan parameter untuk menerima data santri
  final List<Santri> santriList;

  const LinkSantriPage({
    Key? key,
    required this.santriList,
  }) : super(key: key);

  @override
  State<LinkSantriPage> createState() => _LinkSantriPageState();
}

class _LinkSantriPageState extends State<LinkSantriPage> {
  String? _selectedSantriId;
  String? _selectedSantriName;

  @override
  void initState() {
    super.initState();
    // Hapus pemanggilan API dari sini
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah daftar santri kosong
    final bool isSantriListEmpty = widget.santriList.isEmpty;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ... (Widget handle, logo, dan teks deskripsi tetap sama)
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Image.asset(
              'assets/logo_sekolah.png',
              height: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tautkan dengan Data Santri',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Anda perlu menautkan akun ini dengan data santri Sekolah Impian sebelum membuat Portofolio Anda di Portal SI',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- HAPUS FUTUREBUILDER, GUNAKAN DATA LANGSUNG ---
            if (isSantriListEmpty)
              const Text("Data santri tidak ditemukan.")
            else
              DropdownButtonFormField<String>(
                value: _selectedSantriId,
                hint: const Text('Pilih Nama Anda'),
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                // Gunakan widget.santriList yang dikirim dari profile page
                items: widget.santriList.map((Santri santri) {
                  return DropdownMenuItem<String>(
                    value: santri.studentId,
                    child: Text(santri.name),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedSantriId = newValue;
                    _selectedSantriName = widget.santriList
                        .firstWhere((s) => s.studentId == newValue)
                        .name;
                  });
                },
              ),

            const SizedBox(height: 12),
            Text(
              'Data aktivitas Anda nantinya akan terhubung langsung ke pusat data pengelolaan statistik Sekolah Impian yang akan dikontrol secara penuh oleh Tim IT sekolah',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // --- MODIFIKASI TOMBOL AJUKAN PENAUTAN ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                // Buat warna menjadi abu-abu jika belum ada nama yang dipilih
                gradient: _selectedSantriId != null
                    ? const LinearGradient(
                  colors: [Color(0xFFFDE1A9), Color(0xFFF6C35F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
                    : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: _selectedSantriId != null ? [
                  BoxShadow(
                    color: const Color(0xFFF6C35F).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ] : [],
              ),
              child: ElevatedButton(
                // Atur onPressed menjadi null jika _selectedSantriId adalah null
                onPressed: _selectedSantriId != null ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mengajukan penautan untuk $_selectedSantriName...')),
                  );
                } : null, // Ini akan menonaktifkan tombol secara otomatis
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Ajukan Penautan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF5C4033),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}