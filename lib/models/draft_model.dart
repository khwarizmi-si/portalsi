// lib/models/draft_model.dart
import 'package:photo_manager/photo_manager.dart';
import 'package:portal_si/utils/safe_parse.dart';

class Draft {
  final String id; // ID unik untuk setiap draf
  final String originalVideoPath;
  final String? selectedSongJson; // Simpan data lagu sebagai JSON string
  final List<String> textOverlaysJson; // Simpan list teks sebagai JSON string
  final List<String> stickerOverlaysJson; // Simpan list stiker sebagai JSON string
  final String effectName;
  final DateTime createdAt;

  Draft({
    required this.id,
    required this.originalVideoPath,
    this.selectedSongJson,
    required this.textOverlaysJson,
    required this.stickerOverlaysJson,
    required this.effectName,
    required this.createdAt,
  });

  // Fungsi untuk mengubah Draft menjadi Map (untuk disimpan di Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'originalVideoPath': originalVideoPath,
      'selectedSongJson': selectedSongJson,
      'textOverlaysJson': textOverlaysJson,
      'stickerOverlaysJson': stickerOverlaysJson,
      'effectName': effectName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Fungsi untuk membuat Draft dari Map (saat dibaca dari Hive)
  factory Draft.fromMap(Map<String, dynamic> map) {
    return Draft(
      id: map['id'],
      originalVideoPath: map['originalVideoPath'],
      selectedSongJson: map['selectedSongJson'],
      textOverlaysJson: List<String>.from(map['textOverlaysJson']),
      stickerOverlaysJson: List<String>.from(map['stickerOverlaysJson']),
      effectName: map['effectName'],
      createdAt: safeParseDate(map['createdAt']),
    );
  }
}