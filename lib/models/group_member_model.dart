// lib/models/group_member_model.dart (MODIFIED)

class GroupMember {
  final int userId;
  final String? fullName;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;
  final String username;
  final String? profilePictureUrl;
  final bool isOnline;
  final DateTime? lastSeen;

  GroupMember({
    required this.userId,
    this.fullName,
    required this.role,
    required this.joinedAt,
    required this.isMuted,
    required this.username,
    this.profilePictureUrl,
    required this.isOnline,
    this.lastSeen,
  });

  // GANTI SELURUH FUNGSI FACTORY INI
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      // Beri nilai default jika null untuk mencegah error
      userId: json['user_id'] ?? 0,

      // fullName sudah nullable (String?), jadi tidak perlu diubah
      fullName: json['full_name'],

      // Beri nilai default 'member' jika role null
      role: json['role'] ?? 'member',

      // Cek null sebelum parsing tanggal, beri nilai default jika perlu
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : DateTime.now(),

      // isMuted sudah aman dengan pengecekan null
      isMuted: json['is_muted'] ?? false,

      // Beri nama default jika username null
      username: json['username'] ?? 'Pengguna Dihapus',

      // profilePictureUrl sudah nullable (String?), jadi tidak perlu diubah
      profilePictureUrl: json['profile_picture_url'],

      // isOnline sudah aman dengan pengecekan null
      isOnline: json['is_online'] ?? false,

      // lastSeen sudah aman dengan pengecekan null
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
    );
  }
}