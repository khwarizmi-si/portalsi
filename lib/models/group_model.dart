// lib/models/group_model.dart

class Group {
  final int id;
  final String name;
  final String? avatarUrl;
  final int? memberCount; // <-- TAMBAHKAN INI

  Group({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.memberCount, // <-- TAMBAHKAN INI
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      // Sesuaikan 'members_count' dengan nama field dari API Anda
      memberCount: json['members_count'], // <-- TAMBAHKAN INI
    );
  }
}
