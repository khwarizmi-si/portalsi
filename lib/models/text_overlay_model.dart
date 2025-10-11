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
  String fontFamily;
  TextAlign textAlign;
  final bool isLink;
  final String? url;

  TextOverlay({
    required this.text,
    this.position = const Offset(100, 150),
    this.color = Colors.white,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontWeight = FontWeight.bold,
    this.backgroundStyle = TextBackgroundStyle.semiTransparent,
    this.fontFamily = 'Roboto',
    this.textAlign = TextAlign.center,
    this.isLink = false,
    this.url,
  });

  // --- TAMBAHKAN METHOD copyWith DI SINI ---
  TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? scale,
    double? rotation,
    FontWeight? fontWeight,
    TextBackgroundStyle? backgroundStyle,
    String? fontFamily,
    TextAlign? textAlign,
    bool? isLink,
    String? url,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontWeight: fontWeight ?? this.fontWeight,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      isLink: isLink ?? this.isLink,
      url: url ?? this.url,
    );
  }
  // --- AKHIR PENAMBAHAN ---

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'color': color.value,
      'scale': scale,
      'rotation': rotation,
      'fontWeightIndex': fontWeight.index,
      'backgroundStyleName': backgroundStyle.name,
      'fontFamily': fontFamily,
      'textAlignIndex': textAlign.index,
      'isLink': isLink,
      'url': url,
    };
  }

  factory TextOverlay.fromJson(Map<String, dynamic> json) {
    return TextOverlay(
      text: json['text'],
      position: Offset(json['position']['dx'], json['position']['dy']),
      color: Color(json['color']),
      scale: json['scale'],
      rotation: json['rotation'],
      fontWeight: FontWeight.values[json['fontWeightIndex']],
      backgroundStyle: TextBackgroundStyle.values.firstWhere(
            (e) => e.name == json['backgroundStyleName'],
        orElse: () => TextBackgroundStyle.semiTransparent,
      ),
      fontFamily: json['fontFamily'] ?? 'Roboto',
      textAlign: TextAlign.values[json['textAlignIndex'] ?? TextAlign.center.index],
      isLink: json['isLink'] ?? false,
      url: json['url'],
    );
  }
}