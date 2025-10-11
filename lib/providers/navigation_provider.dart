// lib/providers/navigation_provider.dart
import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  Widget? _overlayPage;
  Widget? get overlayPage => _overlayPage;
  bool get isOverlayActive => _overlayPage != null;

  late Function() _showAnimation;
  late Function() _hideAnimation;

  void registerAnimationTriggers({
    required Function() showAnimation,
    required Function() hideAnimation,
  }) {
    _showAnimation = showAnimation;
    _hideAnimation = hideAnimation;
  }

  void showOverlay(Widget page) {
    if (_overlayPage != null) return; // Mencegah show dipanggil dua kali
    _overlayPage = page;
    notifyListeners();
    _showAnimation();
  }

  Future<void> replaceOverlay(Widget newPage) async {
    _hideAnimation();
    // Tunggu animasi hide selesai
    await Future.delayed(const Duration(milliseconds: 350));
    _overlayPage = newPage;
    notifyListeners();
    _showAnimation();
  }

  void hideOverlay() {
    if (_overlayPage != null) {
      _hideAnimation();
    }
  }

  void clearOverlayPage() {
    if (_overlayPage != null) {
      _overlayPage = null;
      notifyListeners();
    }
  }

  late Function(int) navigateToTab;
}