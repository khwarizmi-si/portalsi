// lib/utils/gradient_generator.dart

import 'dart:async'; // Pastikan import ini ada untuk TimeoutException
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

/// Menghasilkan daftar warna gradien dari URL gambar dengan timeout yang bisa diatur.
Future<List<Color>> generateGradientColors(String? imageUrl) async {
  const defaultColors = [Color(0xFF1A1A1A), Colors.black];

  if (imageUrl == null || imageUrl.isEmpty) {
    return defaultColors;
  }

  try {
    final response = await http.get(Uri.parse(imageUrl)).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Image request timed out');
      },
    );

    if (response.statusCode == 200) {
      final Uint8List imageBytes = response.bodyBytes;
      if (imageBytes.isEmpty) return defaultColors;

      // --- 👇 PERBAIKAN UTAMA DI SINI 👇 ---
      // Bungkus imageBytes dengan MemoryImage sebelum diberikan ke PaletteGenerator
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(imageBytes),
        size: const Size(100, 100), // Optimasi ukuran untuk analisis cepat
      );
      // --- 👆 BATAS PERBAIKAN 👆 ---

      final dominantColor = palette.dominantColor?.color ?? Colors.black;
      final vibrantColor = palette.vibrantColor?.color ?? palette.mutedColor?.color ?? dominantColor;

      return [vibrantColor.withOpacity(0.8), dominantColor];
    } else {
      return defaultColors;
    }
  } catch (e) {
    print("Error generating gradient: $e");
    return defaultColors;
  }
}