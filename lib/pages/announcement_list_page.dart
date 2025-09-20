import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/announcement_model.dart';
import '../services/announcement_service.dart';
import '../utils/user_provider.dart';

class AnnouncementListPage extends StatefulWidget {
  const AnnouncementListPage({super.key});

  @override
  State<AnnouncementListPage> createState() => _AnnouncementListPageState();
}

class _AnnouncementListPageState extends State<AnnouncementListPage> {
  List<Announcement>? _announcements;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('id', timeago.IdMessages());
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final data = await AnnouncementService().getAnnouncements();
      data.sort((a, b) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      setState(() {
        _announcements = data;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat pengumuman: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool?> _showConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus pengumuman ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // --- 1. FUNGSI BARU UNTUK MENAMPILKAN POPUP PERINGATAN ---
  Future<void> _showPermissionDeniedDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Aksi Ditolak'),
          content: const Text('Anda tidak bisa menghapus pengumuman yang dibuat oleh orang lain.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleDelete(int id, int index) {
    final announcementToRemove = _announcements![index];
    setState(() {
      _announcements!.removeAt(index);
    });

    AnnouncementService().deleteAnnouncement(id).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${announcementToRemove.title} telah dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $error'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _announcements!.insert(index, announcementToRemove);
      });
    });
  }

  Widget _buildSwipeBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Hapus',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Pengumuman'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_announcements == null || _announcements!.isEmpty) {
      return const Center(child: Text('Tidak ada pengumuman.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _announcements!.length,
      itemBuilder: (context, index) {
        final announcement = _announcements![index];
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final bool isAdmin = userProvider.currentUser?.isVerified == true;

        if (isAdmin) {
          return Dismissible(
            key: Key(announcement.id.toString()),
            direction: DismissDirection.startToEnd,
            background: _buildSwipeBackground(),
            // --- 2. MODIFIKASI LOGIKA confirmDismiss ---
            confirmDismiss: (direction) async {
              // Dapatkan ID user yang sedang login
              final currentUserId = userProvider.currentUser?.id;

              // Cek apakah user ID ada dan sama dengan ID pembuat pengumuman
              if (currentUserId != null && currentUserId == announcement.creator.userId) {
                // Jika pemiliknya sama, tampilkan dialog konfirmasi hapus
                return await _showConfirmationDialog();
              } else {
                // Jika pemiliknya berbeda, tampilkan dialog peringatan
                _showPermissionDeniedDialog();
                // Kembalikan false agar item tidak terhapus dari UI
                return false;
              }
            },
            onDismissed: (direction) {
              // Fungsi ini hanya akan terpanggil jika confirmDismiss mengembalikan true
              _handleDelete(announcement.id, index);
            },
            child: AnnouncementCard(announcement: announcement),
          );
        } else {
          return AnnouncementCard(announcement: announcement);
        }
      },
    );
  }
}

// Widget AnnouncementCard dan FullScreenImagePage tidak perlu diubah
class AnnouncementCard extends StatefulWidget {
  // ... (kode tetap sama)
  final Announcement announcement;
  final int? currentIndex;
  final int? totalCount;
  final Function(bool isExpanded)? onExpansionChanged;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.currentIndex,
    this.totalCount,
    this.onExpansionChanged,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  // ... (kode tetap sama)
  bool _isExpanded = false;

  Widget _buildExpandableContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.announcement.content,
            style: TextStyle(color: Colors.grey.shade800, height: 1.5),
          ),
          if (widget.announcement.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImagePage(
                        imageUrl: widget.announcement.imageUrl!,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Hero(
                    tag: widget.announcement.imageUrl!,
                    child: Image.network(
                      widget.announcement.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        widget.onExpansionChanged?.call(_isExpanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.yellow.shade100.withOpacity(0.5),
              Colors.amber.shade100.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.announcement.creator.profilePictureUrl != null
                      ? NetworkImage(widget.announcement.creator.profilePictureUrl!)
                      : null,
                  child: widget.announcement.creator.profilePictureUrl == null
                      ? const Icon(Icons.person, size: 22)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.announcement.pinned) ...[
                            Icon(Icons.push_pin, color: Colors.brown.shade600, size: 14),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            timeago.format(widget.announcement.createdAt, locale: 'id'),
                            style: TextStyle(
                              color: widget.announcement.pinned ? Colors.brown.shade800 : Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.announcement.creator.fullName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.announcement.title,
                        maxLines: _isExpanded ? 5 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1A237E),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.currentIndex != null && widget.totalCount != null && widget.totalCount! > 1 && !_isExpanded)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${widget.currentIndex! + 1} dari ${widget.totalCount} pengumuman',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: _isExpanded ? _buildExpandableContent() : const SizedBox.shrink(),
            )
          ],
        ),
      ),
    );
  }
}

class FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Hero(
              tag: imageUrl,
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}