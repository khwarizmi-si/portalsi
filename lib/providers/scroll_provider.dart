import 'package:flutter/material.dart';

class ScrollProvider with ChangeNotifier {
  // false = Teks terlihat (scroll ke atas / idle di atas)
  // true = Teks tersembunyi (scroll ke bawah)
  bool _isScrolled = false;

  bool get isScrolled => _isScrolled;

  void setScrolled(bool scrolled) {
    // Hanya beri notifikasi jika nilainya benar-benar berubah
    // Ini penting untuk efisiensi.
    if (_isScrolled != scrolled) {
      _isScrolled = scrolled;
      notifyListeners();
    }
  }
}