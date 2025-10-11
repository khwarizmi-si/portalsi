// lib/pages/edit_clips/widgets/overlays/overlay_item.dart

import 'package:flutter/material.dart';
import '../../../../models/text_overlay_model.dart';

class OverlayItem extends StatelessWidget {
  final TextOverlay overlay;
  final bool isActive;
  final Function(TextOverlay, ScaleStartDetails) onScaleStart;
  final Function(TextOverlay, ScaleUpdateDetails) onScaleUpdate;
  final VoidCallback onTap;

  const OverlayItem({
    super.key,
    required this.overlay,
    required this.isActive,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    BoxDecoration decoration;
    TextStyle style;

    switch (overlay.backgroundStyle) {
      case TextBackgroundStyle.solid:
        decoration = BoxDecoration(color: overlay.color, borderRadius: BorderRadius.circular(8));
        style = TextStyle(
          color: overlay.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          fontSize: 24,
          fontWeight: overlay.fontWeight,
        );
        break;
      case TextBackgroundStyle.semiTransparent:
        decoration = BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8));
        style = TextStyle(color: overlay.color, fontSize: 24, fontWeight: overlay.fontWeight);
        break;
      case TextBackgroundStyle.none:
      default:
        decoration = const BoxDecoration();
        style = TextStyle(
          color: overlay.color,
          fontSize: 24,
          fontWeight: overlay.fontWeight,
          shadows: const [Shadow(blurRadius: 3.0, color: Colors.black, offset: Offset(1.0, 1.0))],
        );
        break;
    }
    content = Text(overlay.text, textAlign: TextAlign.center, style: style);

    return Positioned(
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: GestureDetector(
        onScaleStart: (details) => onScaleStart(overlay, details),
        onScaleUpdate: (details) => onScaleUpdate(overlay, details),
        onTap: onTap,
        child: Transform(
          transform: Matrix4.identity()
            ..scale(overlay.scale)
            ..rotateZ(overlay.rotation),
          alignment: FractionalOffset.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: isActive
                    ? Border.all(color: Colors.white.withOpacity(0.7), width: 2, style: BorderStyle.solid)
                    : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: decoration,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}