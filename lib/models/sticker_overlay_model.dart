import 'package:flutter/material.dart';

class StickerOverlay {
  Offset position;
  double scale;
  double rotation;
  final String? imageUrl; // Untuk GIF & Avatar dari URL
  final String? filePath; // Untuk Foto dari galeri
  final bool isAvatar;   // Untuk membedakan dan membuatnya jadi bulat

  StickerOverlay({
    this.position = const Offset(100, 150),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.imageUrl,
    this.filePath,
    this.isAvatar = false,
  }) : assert(imageUrl != null || filePath != null, 'imageUrl atau filePath harus disediakan');

  Map<String, dynamic> toJson() {
    return {
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'imageUrl': imageUrl,
      'filePath': filePath,
      'isAvatar': isAvatar,
    };
  }

  factory StickerOverlay.fromJson(Map<String, dynamic> json) {
    return StickerOverlay(
      position: Offset(json['position']['dx'], json['position']['dy']),
      scale: json['scale'],
      rotation: json['rotation'],
      imageUrl: json['imageUrl'],
      filePath: json['filePath'],
      isAvatar: json['isAvatar'] ?? false,
    );
  }
}