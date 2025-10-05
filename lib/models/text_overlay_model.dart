// lib/models/text_overlay_model.dart

import 'package:flutter/material.dart';

enum TextBackgroundStyle { none, semiTransparent, solid }

class TextOverlay {
  String text;
  Offset position;
  Color color;
  double scale;
  double rotation;
  FontWeight fontWeight;
  TextBackgroundStyle backgroundStyle;
  final bool isLink;
  final String? url;

  TextOverlay({
    required this.text,
    this.position = const Offset(100, 100),
    this.color = Colors.white,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontWeight = FontWeight.bold,
    this.backgroundStyle = TextBackgroundStyle.semiTransparent,
    this.isLink = false,
    this.url,
  });

  // --- TAMBAHKAN METHOD INI ---
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      // Ubah Offset menjadi Map
      'position': {'dx': position.dx, 'dy': position.dy},
      // Simpan nilai integer dari warna
      'color': color.value,
      'scale': scale,
      'rotation': rotation,
      // Simpan index dari enum FontWeight
      'fontWeightIndex': fontWeight.index,
      // Simpan nama dari enum TextBackgroundStyle
      'backgroundStyleName': backgroundStyle.name,
      'isLink': isLink, // -- 👇 TAMBAHKAN 👇 --
      'url': url, // -- 👇 TAMBAHKAN 👇 --
    };
  }
// --- AKHIR PENAMBAHAN ---
}