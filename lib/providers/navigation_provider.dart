// lib/providers/navigation_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  Widget? _overlayPage;
  Widget? get overlayPage => _overlayPage;
  bool get isOverlayActive => _overlayPage != null;

  bool _animationsRegistered = false;
  Function()? _showAnimation;
  Function()? _hideAnimation;

  void registerAnimationTriggers({
    required Function() showAnimation,
    required Function() hideAnimation,
  }) {
    _showAnimation = showAnimation;
    _hideAnimation = hideAnimation;
    _animationsRegistered = true;
  }

  void showOverlay(Widget page) {
    if (_overlayPage != null) {
      // Already showing — just replace the page content without re-animating
      _overlayPage = page;
      notifyListeners();
      return;
    }
    _overlayPage = page;
    notifyListeners();
    if (_animationsRegistered) _showAnimation?.call();
  }

  Future<void> replaceOverlay(Widget newPage) async {
    if (_animationsRegistered) _hideAnimation?.call();
    // Wait for hide animation to complete
    await Future.delayed(const Duration(milliseconds: 300));
    _overlayPage = newPage;
    notifyListeners();
    if (_animationsRegistered) _showAnimation?.call();
  }

  void hideOverlay() {
    if (_overlayPage == null) return;
    if (_animationsRegistered) {
      _hideAnimation?.call();
      // Safety fallback: if animation doesn't dismiss within 600ms, force-clear
      Timer(const Duration(milliseconds: 600), () {
        if (_overlayPage != null) {
          _overlayPage = null;
          notifyListeners();
        }
      });
    } else {
      // No animations registered (e.g. web dialog context) — clear immediately
      _overlayPage = null;
      notifyListeners();
    }
  }

  /// Immediately clears the overlay without animation. Use when the overlay
  /// is stuck or when called from a context outside the main scaffold.
  void forceHideOverlay() {
    if (_overlayPage != null) {
      _overlayPage = null;
      notifyListeners();
    }
    // Also reset the animation controller via _hideAnimation if registered,
    // so the controller's value goes back to 0.
    if (_animationsRegistered) {
      try { _hideAnimation?.call(); } catch (_) {}
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