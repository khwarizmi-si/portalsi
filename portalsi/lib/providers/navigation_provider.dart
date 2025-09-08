import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  // Fungsi callback untuk pindah tab (tetap ada)
  late Function(int) navigateToTab;

  // --- TAMBAHAN BARU ---
  Widget? _overlayPage; // Variabel untuk menampung halaman overlay

  // Getter untuk mengakses halaman overlay
  Widget? get overlayPage => _overlayPage;

  // Fungsi untuk menampilkan halaman overlay
  void showOverlay(Widget page) {
    _overlayPage = page;
    notifyListeners(); // Beri tahu listener (MainScaffold) bahwa ada perubahan
  }

  // Fungsi untuk menyembunyikan/menghapus halaman overlay
  void hideOverlay() {
    _overlayPage = null;
    notifyListeners(); // Beri tahu listener (MainScaffold) untuk kembali menampilkan PageView
  }
}