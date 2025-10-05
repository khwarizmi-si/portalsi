import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/models/group_member_model.dart';
import 'package:portal_si/services/group_service.dart';

import '../widgets/add_members_bottom_sheet.dart';


class GroupMembersPage extends StatefulWidget {
  final int groupId;
  // [PERUBAHAN 1] Tambahkan properti untuk menerima status admin
  final bool isCurrentUserAdmin;

  const GroupMembersPage({
    super.key,
    required this.groupId,
    // Tambahkan ke constructor
    required this.isCurrentUserAdmin,
  });

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  final GroupService _groupService = GroupService();
  late Future<List<GroupMember>> _membersFuture;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    // Memulai proses pengambilan data saat halaman dibuka
    _membersFuture = _groupService.getGroupMembers(widget.groupId);
  }

  void _refreshMemberList() {
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
          feedbackMessage = '${member.fullName} telah dijadikan admin.';
          break;
        case 'demote':
          success = await _groupService.demoteMember(widget.groupId, member.userId);
          feedbackMessage = 'Admin ${member.fullName} telah diubah menjadi anggota.';
          break;
        case 'mute':
          success = await _groupService.muteMember(widget.groupId, member.userId);
          feedbackMessage = '${member.fullName} telah dibisukan.';
          break;
        case 'unmute':
          success = await _groupService.unmuteMember(widget.groupId, member.userId);
          feedbackMessage = 'Status bisu untuk ${member.fullName} telah dimatikan.';
          break;
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedbackMessage), backgroundColor: Colors.green),
        );
        _refreshMemberList(); // Refresh daftar setelah aksi berhasil
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
          onPressed: () => {
            HapticFeedback.lightImpact(),
            Navigator.of(context).pop()
          },
        ),
        title: const Text('Anggota', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          // [PERUBAHAN 2] Tampilkan tombol 'Tambah Anggota' hanya jika pengguna adalah admin
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
                    _refreshMemberList();
                  }
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<List<GroupMember>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat anggota: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada anggota di grup ini.'));
          }

          final members = snapshot.data!;
          final admins = members.where((m) => m.role.toLowerCase() == 'admin').toList();
          final otherMembers = members.where((m) => m.role.toLowerCase() != 'admin').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (admins.isNotEmpty) ...[
                _buildSectionHeader('Admin (${admins.length})'),
                ...admins.map((member) => _buildMemberTile(member, isAdmin: true)),
              ],
              if (otherMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Anggota Lainnya (${otherMembers.length})'),
                ...otherMembers.map((member) => _buildMemberTile(member)),
              ]
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
        title.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMemberTile(GroupMember member, {bool isAdmin = false}) {
    // Jangan tampilkan menu opsi untuk diri sendiri
    final bool isCurrentUser = member.userId == _currentUserId;
    return ListTile(
      leading: CircleAvatar(
        radius: 22,
        backgroundImage: member.profilePictureUrl != null && member.profilePictureUrl!.isNotEmpty
            ? NetworkImage(member.profilePictureUrl!)
            : null,
        child: (member.profilePictureUrl == null || member.profilePictureUrl!.isEmpty)
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
      ),
      title: Row(
        children: [
          // --- PERBAIKAN DI SINI ---
          // Bungkus Text widget dengan Expanded agar lebarnya fleksibel
          Expanded(
            child: Text(
              member.fullName ?? member.username, // Menggunakan fallback ke username
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false, // softWrap: false baik untuk memastikan tidak ada line break
            ),
          ),
          // -------------------------
          if (member.isMuted)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ),
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200)
              ),
              child: const Text(
                'Admin',
                style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      subtitle: Text('@${member.username}'),
      trailing: isCurrentUser || !widget.isCurrentUserAdmin
          ? null // Sembunyikan jika itu adalah pengguna sendiri ATAU jika pengguna bukan admin
          : PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, color: Colors.black54),
        onSelected: (value) => _handleMenuSelection(value, member),
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
        ],
      ),
    );
  }
}