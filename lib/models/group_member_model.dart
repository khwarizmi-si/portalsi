// file: lib/models/group_member_model.dart

import 'package:portal_si/utils/safe_parse.dart';

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
  final bool isFollowing; // <-- TAMBAHKAN BARIS INI

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
    required this.isFollowing, // <-- TAMBAHKAN BARIS INI
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] ?? 0,
      fullName: json['full_name'],
      role: json['role'] ?? 'member',
      joinedAt: safeParseDate(json['joined_at']),
      isMuted: json['is_muted'] ?? false,
      username: json['username'] ?? 'Pengguna Dihapus',
      profilePictureUrl: json['profile_picture_url'],
      isOnline: json['is_online'] ?? false,
      lastSeen: safeParseDateOrNull(json['last_seen']),
      isFollowing: json['is_following'] ?? false, // <-- TAMBAHKAN BARIS INI
    );
  }
}