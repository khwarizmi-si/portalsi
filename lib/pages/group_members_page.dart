import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/models/group_member_model.dart';
import 'package:portal_si/services/group_service.dart';

import '../models/user_model.dart';
import '../widgets/add_members_bottom_sheet.dart';
import 'chat_room.dart';

class GroupMembersPage extends StatefulWidget {
  final int groupId;
  final bool isCurrentUserAdmin;

  const GroupMembersPage({
    super.key,
    required this.groupId,
    required this.isCurrentUserAdmin,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final GroupService _groupService = GroupService();
  late Future<Map<String, List<GroupMember>>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() {
      _membersFuture = _groupService.getGroupMembers(widget.groupId);
    });
  }

  void _handleMenuSelection(String value, GroupMember member) async {
    bool success = false;
    String feedbackMessage = '';
    String errorMessage = 'Aksi gagal dilakukan.';

    try {
      switch (value) {
        case 'remove':
          success = await _groupService.removeMember(widget.groupId, member.userId);
          feedbackMessage = 'Anggota berhasil dikeluarkan.';
          break;
        case 'promote':
          success = await _groupService.promoteMember(widget.groupId, member.userId);
          feedbackMessage = '${member.fullName ?? member.username} telah dijadikan admin.';
          break;
        case 'demote':
          success = await _groupService.demoteMember(widget.groupId, member.userId);
          feedbackMessage = 'Admin ${member.fullName ?? member.username} telah diubah menjadi anggota.';
          break;
        case 'mute':
          success = await _groupService.muteMember(widget.groupId, member.userId);
          feedbackMessage = '${member.fullName ?? member.username} telah dibisukan.';
          break;
        case 'unmute':
          success = await _groupService.unmuteMember(widget.groupId, member.userId);
          feedbackMessage = 'Status bisu untuk ${member.fullName ?? member.username} telah dimatikan.';
          break;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedbackMessage), backgroundColor: Colors.green),
        );
        _loadMembers();
      } else if (!success) {
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Anggota', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (widget.isCurrentUserAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddMembersBottomSheet(groupId: widget.groupId),
                ).then((wasMemberAdded) {
                  if (wasMemberAdded == true) {
                    _loadMembers();
                  }
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<Map<String, List<GroupMember>>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat anggota: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.values.every((list) => list.isEmpty)) {
            return const Center(child: Text('Tidak ada anggota di grup ini.'));
          }

          final me = snapshot.data!['me'] ?? [];
          final following = snapshot.data!['following'] ?? [];
          final notFollowing = snapshot.data!['not_following'] ?? [];

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (me.isNotEmpty) ...[
                _buildSectionHeader('Anda'),
                ...me.map((member) => _buildMemberTile(member, isMe: true)),
                const Divider(height: 32),
              ],

              if (following.isNotEmpty) ...[
                _buildSectionHeader('Mengikuti (${following.length})'),
                ...following.map((member) => _buildMemberTile(member)),
                const Divider(height: 32),
              ],

              if (notFollowing.isNotEmpty) ...[
                _buildSectionHeader('Lainnya (${notFollowing.length})'),
                ...notFollowing.map((member) => _buildMemberTile(member)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member, {bool isMe = false}) {
    Widget? trailingWidget;
    if (!isMe) {
      if (member.isFollowing) {
        // --- 👇 PERUBAHAN UTAMA ADA DI SINI 👇 ---
        trailingWidget = OutlinedButton(
          onPressed: () {
            // 1. Buat objek User dari data GroupMember
            final userToChat = User(
              id: member.userId,
              username: member.username,
              fullName: member.fullName,
              profilePictureUrl: member.profilePictureUrl,
              // isVerified tidak ada di model GroupMember, jadi kita beri nilai default
              isVerified: false,
            );

            // 2. Navigasi ke ChatRoomPage dengan data user tersebut
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(user: userToChat),
              ),
            );
          },
          child: const Text('Message'),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade400),
            foregroundColor: Colors.black,
          ),
        );
        // --- 👆 BATAS PERUBAHAN 👆 ---
      } else {
        trailingWidget = ElevatedButton(
          onPressed: () {},
          child: const Text('Follow'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.blue.shade800,
          ),
        );
      }
    }

    final adminPopupMenu = widget.isCurrentUserAdmin && !isMe
        ? PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.black54),
      onSelected: (value) => _handleMenuSelection(value, member),
      itemBuilder: (BuildContext context) {
        final isAdmin = member.role.toLowerCase() == 'admin';
        return <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: isAdmin ? 'demote' : 'promote',
            child: Text(isAdmin ? 'Hentikan Jadi Admin' : 'Jadikan Admin'),
          ),
          PopupMenuItem<String>(
            value: member.isMuted ? 'unmute' : 'mute',
            child: Text(member.isMuted ? 'Matikan Bisukan' : 'Bisukan Anggota'),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: 'remove',
            child: Text('Keluarkan dari Grup', style: TextStyle(color: Colors.red)),
          ),
        ];
      },
    )
        : null;

    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: member.profilePictureUrl != null && member.profilePictureUrl!.isNotEmpty
            ? NetworkImage(member.profilePictureUrl!)
            : null,
        child: (member.profilePictureUrl == null || member.profilePictureUrl!.isEmpty)
            ? Icon(Icons.person, color: Colors.grey.shade400)
            : null,
      ),
      title: Row(
        children: [
          Text(
            member.fullName ?? member.username,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (member.role.toLowerCase() == 'admin')
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200)),
              child: const Text('Admin', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      subtitle: Text('@${member.username}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingWidget != null) trailingWidget,
          if (adminPopupMenu != null) adminPopupMenu,
        ],
      ),
    );
  }
}