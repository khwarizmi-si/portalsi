// lib/utils/web_frame.dart
//
// Wraps the entire app in a centered 430 px "phone frame" on wide screens.
// On mobile / narrow screens it renders children as-is.
// Applied globally via MaterialApp.builder so EVERY page benefits at once.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebFrame extends StatelessWidget {
  final Widget child;

  const WebFrame({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only constrain on web when the viewport is wider than 500 px.
    if (!kIsWeb) return child;

    final width = MediaQuery.of(context).size.width;
    if (width <= 500) return child;

    return Container(
      // Soft grey outer "desktop" background — avoids white flash on transitions
      color: const Color(0xFFE0E0E0),
      child: Center(
        child: SizedBox(
          width: 430,
          child: ClipRect(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
