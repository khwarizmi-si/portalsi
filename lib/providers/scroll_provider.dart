// lib/providers/scroll_provider.dart

import 'package:flutter/material.dart';

class ScrollProvider with ChangeNotifier {
  bool _isScrolled = false;
  // --- 👇 TAMBAHAN 1: Variabel untuk menyimpan controller ---
  ScrollController? _dashboardScrollController;

  bool get isScrolled => _isScrolled;

  void setScrolled(bool scrolled) {
    if (_isScrolled != scrolled) {
      _isScrolled = scrolled;
      notifyListeners();
    }
  }

  // --- 👇 TAMBAHAN 2: Method untuk mendaftarkan controller ---
  /// Mendaftarkan ScrollController dari DashboardPage ke provider.
  void setDashboardController(ScrollController controller) {
    _dashboardScrollController = controller;
  }

  // --- 👇 TAMBAHAN 3: Method untuk memicu scroll ke atas ---
  /// Memicu animasi scroll ke paling atas.
  void scrollToTop() {
    // Pastikan controller ada dan terpasang ke scroll view
    if (_dashboardScrollController != null && _dashboardScrollController!.hasClients) {
      _dashboardScrollController!.animateTo(
        0.0, // Kembali ke posisi 0 (paling atas)
        duration: const Duration(milliseconds: 500), // Durasi animasi
        curve: Curves.easeInOut, // Jenis kurva animasi
      );
    }
  }
}