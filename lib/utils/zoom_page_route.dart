import 'package:flutter/material.dart';

class ZoomPageRoute extends PageRouteBuilder {
  final Widget page;
  final GlobalKey buttonKey;

  ZoomPageRoute({required this.page, required this.buttonKey})
      : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Dapatkan posisi dan ukuran tombol dari GlobalKey
      final RenderBox renderBox = buttonKey.currentContext!.findRenderObject() as RenderBox;
      final buttonSize = renderBox.size;
      final buttonPosition = renderBox.localToGlobal(Offset.zero);

      final screenSize = MediaQuery.of(context).size;

      // Buat tween untuk rectangle, dari ukuran tombol ke ukuran layar penuh
      final tween = RelativeRectTween(
        begin: RelativeRect.fromLTRB(
          buttonPosition.dx,
          buttonPosition.dy,
          screenSize.width - buttonPosition.dx - buttonSize.width,
          screenSize.height - buttonPosition.dy - buttonSize.height,
        ),
        end: RelativeRect.fill,
      );

      // Gunakan CurvedAnimation untuk efek ease-in-out
      final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOut);

      return Stack(
        children: [
          PositionedTransition(
            rect: tween.animate(curvedAnimation),
            child: ClipRRect(
              // Animasikan radius border agar dari bulat menjadi kotak
              borderRadius: BorderRadius.circular(30.0 * (1 - animation.value)),
              child: child,
            ),
          ),
        ],
      );
    },
  );
}