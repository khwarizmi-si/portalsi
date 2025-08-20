// lib/models/santri_model.dart

class Santri {
  final String studentId;
  final String name;

  // Anda bisa menambahkan properti lain jika dibutuhkan
  // final String? photo;
  // final int pondok;

  Santri({
    required this.studentId,
    required this.name,
  });

  // Factory constructor untuk membuat instance Santri dari JSON
  factory Santri.fromJson(Map<String, dynamic> json) {
    return Santri(
      studentId: json['studentId'] as String,
      name: json['name'] as String,
    );
  }
}