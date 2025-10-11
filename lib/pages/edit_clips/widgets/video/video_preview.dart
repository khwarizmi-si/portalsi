import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/text_overlay_model.dart';
import '../../../../models/sticker_overlay_model.dart';

class VideoPreview extends StatelessWidget {
  final VideoPlayerController controller;
  final List<TextOverlay> textOverlays;
  final List<StickerOverlay> stickerOverlays;
  final Object? activeOverlay;
  final String effectName;
  final ValueChanged<Object> onOverlayTap;
  final VoidCallback onBackgroundTap;
  final Function(Object, ScaleStartDetails) onScaleStart;
  final Function(Object, ScaleUpdateDetails) onScaleUpdate;

  const VideoPreview({
    super.key,
    required this.controller,
    required this.textOverlays,
    required this.stickerOverlays,
    this.activeOverlay,
    required this.effectName,
    required this.onOverlayTap,
    required this.onBackgroundTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  static const Map<String, ColorFilter> _effectFilters = {
    'No effect': ColorFilter.mode(Colors.transparent, BlendMode.dst),
    'Grayscale': ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]),
    'Sepia': ColorFilter.matrix([0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]),
    'Vivid': ColorFilter.matrix([1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0]),
    'Bubble Captions': ColorFilter.mode(Colors.transparent, BlendMode.dst),
    'Soft Nature': ColorFilter.matrix([1, 0, 0, 0, 0, 0, 1.1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]),
    'Teal & tangerine': ColorFilter.matrix([1.1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0]),
    'HDR': ColorFilter.matrix([1.5, 0, 0, 0, -25.5, 0, 1.5, 0, 0, -25.5, 0, 0, 1.5, 0, -25.5, 0, 0, 0, 1, 0]),
    'Indie Trip': ColorFilter.matrix([1, 0, 0, 0, 10, 0, 0, 1, 0, 10, 0, 0, 1, 0, 10, 0, 0, 0, 1, 0]),
    '8K Quality': ColorFilter.mode(Colors.transparent, BlendMode.dst),
    'Old Video': ColorFilter.matrix([0.35, 0.68, 0.16, 0, 0, 0.31, 0.61, 0.15, 0, 0, 0.24, 0.48, 0.12, 0, 0, 0, 0, 0, 1, 0]),
  };

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(color: Colors.black, child: const Center(child: CircularProgressIndicator(color: Colors.white)));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onBackgroundTap,
            child: Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: ColorFiltered(
                  colorFilter: _effectFilters[effectName] ?? _effectFilters['No effect']!,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ),
        Stack(
          children: [
            ...textOverlays.map((overlay) {
              return Positioned(
                left: overlay.position.dx,
                top: overlay.position.dy,
                child: GestureDetector(
                  onTap: () => onOverlayTap(overlay),
                  onScaleStart: (details) => onScaleStart(overlay, details),
                  onScaleUpdate: (details) => onScaleUpdate(overlay, details),
                  behavior: HitTestBehavior.translucent,
                  child: Transform.rotate(
                    angle: overlay.rotation,
                    child: Transform.scale(
                      scale: overlay.scale,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(40.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: overlay.backgroundStyle == TextBackgroundStyle.solid ? overlay.color : overlay.backgroundStyle == TextBackgroundStyle.semiTransparent ? Colors.black.withOpacity(0.5) : Colors.transparent,
                            borderRadius: BorderRadius.circular(overlay.backgroundStyle == TextBackgroundStyle.none ? 0 : 8),
                            border: overlay == activeOverlay ? Border.all(color: Colors.blue.withOpacity(0.7), width: 2) : null,
                          ),
                          padding: overlay.backgroundStyle == TextBackgroundStyle.none ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            overlay.text,
                            style: TextStyle(
                              color: overlay.backgroundStyle == TextBackgroundStyle.solid ? (overlay.color.computeLuminance() > 0.5 ? Colors.black : Colors.white) : overlay.color,
                              fontSize: 20,
                              fontFamily: overlay.fontFamily,
                              fontWeight: overlay.fontWeight,
                              shadows: overlay.backgroundStyle == TextBackgroundStyle.none ? const [Shadow(blurRadius: 3, color: Colors.black, offset: Offset(1, 1))] : null,
                            ),
                            textAlign: overlay.textAlign,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            ...stickerOverlays.map((overlay) {
              Widget imageWidget;
              if (overlay.imageUrl != null) {
                imageWidget = CachedNetworkImage(imageUrl: overlay.imageUrl!, placeholder: (context, url) => const CircularProgressIndicator(), errorWidget: (context, url, error) => const Icon(Icons.error));
              } else {
                imageWidget = Image.file(File(overlay.filePath!));
              }

              return Positioned(
                left: overlay.position.dx,
                top: overlay.position.dy,
                child: GestureDetector(
                  onTap: () => onOverlayTap(overlay),
                  onScaleStart: (details) => onScaleStart(overlay, details),
                  onScaleUpdate: (details) => onScaleUpdate(overlay, details),
                  behavior: HitTestBehavior.translucent,
                  child: Transform.rotate(
                    angle: overlay.rotation,
                    child: Transform.scale(
                      scale: overlay.scale,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.all(40.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: overlay == activeOverlay ? Border.all(color: Colors.blue.withOpacity(0.7), width: 2) : null,
                            shape: overlay.isAvatar ? BoxShape.circle : BoxShape.rectangle,
                          ),
                          child: overlay.isAvatar ? ClipOval(child: imageWidget) : imageWidget,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}