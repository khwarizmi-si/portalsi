import 'package:flutter/material.dart';

class SlideTransitionRoute extends PageRouteBuilder {
  final Widget page;

  SlideTransitionRoute({required this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionDuration: const Duration(milliseconds: 800), // Atur durasi transisi
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      // Animasi untuk halaman yang masuk (dari kiri ke kanan)
      final slideInTween = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      // Animasi untuk halaman yang keluar (dari kanan ke kiri)
      final slideOutTween = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.0, 0.0), // Bergeser ke kiri
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return Stack(
        children: <Widget>[
          // Halaman yang keluar (dianimasikan oleh secondaryAnimation)
          SlideTransition(
            position: secondaryAnimation.drive(slideOutTween),
            // 'this' di sini adalah halaman lama (welcome_page)
            // Kita tidak perlu menampilkannya secara eksplisit,
            // Flutter menanganinya di belakang layar
          ),
          // Halaman yang masuk (dianimasikan oleh animation)
          SlideTransition(
            position: animation.drive(slideInTween),
            child: child, // 'child' di sini adalah halaman baru (login_page)
          ),
        ],
      );
    },
  );
}