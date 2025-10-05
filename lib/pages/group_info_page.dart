import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/models/group_model.dart';
import 'package:provider/provider.dart';
import '../controllers/group_chat_controller.dart';
import '../utils/slide_right_route.dart';
import '../widgets/add_members_bottom_sheet.dart';
import 'edit_group_page.dart';
import 'group_members_page.dart';

class GroupInfoPage extends StatefulWidget {
  final Group group;
  final GroupChatRoomController controller; // Tambahkan controller di sini
  final bool isCurrentUserAdmin;

  const GroupInfoPage({
    super.key,
    required this.group,
    required this.controller, // Tambahkan controller ke constructor
    required this.isCurrentUserAdmin,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => {
            HapticFeedback.lightImpact(),
            Navigator.of(context).pop(),
          },
        ),
        title: const Text('Info Grup', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildGroupHeader(),
          const SizedBox(height: 16),
          _buildActionIcons(),
          const Divider(height: 32, indent: 16, endIndent: 16),
          _buildOptionList(),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan header (avatar, nama, dan tombol ubah)
  Widget _buildGroupHeader() {
    // Gunakan widget.controller untuk mengakses group dan reloadMessages
    final group = widget.controller.group; 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: widget.group.avatarUrl != null && widget.group.avatarUrl!.isNotEmpty
                ? NetworkImage(widget.group.avatarUrl!)
                : null,
            child: (widget.group.avatarUrl == null || widget.group.avatarUrl!.isEmpty)
                ? Icon(Icons.group, size: 50, color: Colors.grey.shade400)
                : null,
          ),
          const SizedBox(height: 16),
          Text(widget.group.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                SlideRightRoute(
                  page: EditGroupPage(group: group),
                ),
              );

              // Jika halaman edit mengembalikan 'true', refresh data
              if (result == true && mounted) {
                widget.controller.reloadMessages(); // Gunakan widget.controller
              }
            },
            child: Text('Ubah nama dan gambar', style: TextStyle(color: Colors.blue.shade700, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan ikon aksi (Tambahkan, Cari, dll)
  Widget _buildActionIcons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSingleActionIcon(Icons.person_add_alt_1, 'Tambahkan', () {
            // Membuka bottom sheet untuk menambah anggota
            HapticFeedback.lightImpact();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => AddMembersBottomSheet(groupId: widget.group.id),
            );
          }),
          _buildSingleActionIcon(Icons.search, 'Cari', () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur ini akan segera hadir..',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            );
          }),
          if (widget.isCurrentUserAdmin)
            _buildSingleActionIcon(Icons.notifications_off_outlined, 'Bisukan', () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Fitur ini akan segera hadir..',
                  ),
                  backgroundColor: Colors.blueAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              );
            }),

          // Tampilkan tombol "Opsi" HANYA JIKA pengguna adalah admin
          if (widget.isCurrentUserAdmin)
            _buildSingleActionIcon(Icons.more_horiz, 'Opsi', () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Fitur ini akan segera hadir..',
                  ),
                  backgroundColor: Colors.blueAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  /// Helper widget untuk satu ikon aksi
  Widget _buildSingleActionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// Widget untuk menampilkan daftar opsi (Tema, Anggota, dll)
  Widget _buildOptionList() {
    // Menampilkan jumlah anggota jika tersedia
    final memberCountText = widget.group.memberCount != null
        ? '${widget.group.memberCount} anggota'
        : 'Lihat anggota';

    return Column(
      children: [
        _buildListTile(Icons.color_lens_outlined, 'Tema', subtitle: 'Bawaan', onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Fitur ini akan segera hadir..',
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
          );
        }),
        _buildListTile(Icons.link, 'Tautan Undangan', subtitle: 'Mati', onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Fitur ini akan segera hadir..',
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
          );
        }),
        _buildListTile(
            Icons.people_outline,
            'Anggota',
            subtitle: memberCountText,
            onTap: () {
              HapticFeedback.lightImpact();
              // Navigasi ke halaman daftar anggota dengan animasi
              Navigator.push(
                context,
                SlideRightRoute(page: GroupMembersPage(groupId: widget.group.id, isCurrentUserAdmin: widget.isCurrentUserAdmin,)),
              );
            }
        ),
        _buildListTile(Icons.lock_outline, 'Privasi & Keamanan', onTap: () {
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Fitur ini akan segera hadir..',
              ),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
          );
        }),
        if (widget.isCurrentUserAdmin)
          _buildListTile(Icons.badge_outlined, 'Nama Panggilan', onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur ini akan segera hadir..',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            );
          }),

        // Tampilkan "Buat grup baru" HANYA JIKA pengguna adalah admin
        if (widget.isCurrentUserAdmin)
          _buildListTile(Icons.add_circle_outline, 'Buat grup baru', color: Colors.blue.shade700, onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Fitur ini akan segera hadir..',
                ),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Helper widget untuk satu baris opsi
  Widget _buildListTile(IconData icon, String title, {String? subtitle, Color? color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.black87),
      title: Text(title, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}