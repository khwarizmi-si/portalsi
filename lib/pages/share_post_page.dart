import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../components/verified_badge.dart';
import '../models/song_model.dart';
import '../models/text_overlay_model.dart';
import '../models/user_model.dart';
import '../services/post_service.dart';
import '../utils/secure_storage.dart';

class SharePostPage extends StatefulWidget {
  final List<File> mediaFiles;
  final Song? selectedSong;
  final List<TextOverlay> textOverlays;

  const SharePostPage({
    super.key,
    required this.mediaFiles,
    this.selectedSong,
    this.textOverlays = const [],
  });

  @override
  State<SharePostPage> createState() => _SharePostPageState();
}

class _SharePostPageState extends State<SharePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isUploading = false;

  // --- 👇 State baru untuk fitur Tag dan Lokasi 👇 ---
  bool _showLocationInput = false;
  bool _isMentionSheetOpen = false;
  Timer? _debounce;
  List<User> _mentionResults = [];
  bool _isMentionLoading = false;
  String _previousCaptionText = '';
  String _currentMentionQuery = '';

  @override
  void initState() {
    super.initState();
    _captionController.addListener(_onCaptionChanged);
    _previousCaptionText = _captionController.text;
  }

  @override
  void dispose() {
    _captionController.removeListener(_onCaptionChanged);
    _captionController.dispose();
    _locationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCaptionChanged() {
    final text = _captionController.text;
    final cursorPosition = _captionController.selection.baseOffset;

    // Cek apakah aksi saat ini adalah menghapus teks
    final bool isDeleting = text.length < _previousCaptionText.length;
    _previousCaptionText = text; // Update teks sebelumnya untuk pengecekan berikutnya

    final int lastAt = text.substring(0, cursorPosition).lastIndexOf('@');
    final int lastSpace = text.substring(0, cursorPosition).lastIndexOf(' ');

    // Kondisi untuk memeriksa apakah kita sedang dalam mode mention
    final bool isTypingMention = lastAt != -1 && lastAt > lastSpace;

    if (isTypingMention) {
      final query = text.substring(lastAt + 1, cursorPosition);
      _currentMentionQuery = query;
      // --- PERBAIKAN UTAMA DI SINI ---
      // Buka sheet HANYA jika tidak sedang terbuka DAN bukan aksi hapus
      if (!_isMentionSheetOpen && !isDeleting) {
        setState(() => _isMentionSheetOpen = true);
        _showMentionSheet().whenComplete(() {
          if(mounted) {
            setState(() => _isMentionSheetOpen = false);
          }
        });
      }
    } else {
      // Jika tidak dalam mode mention dan sheet sedang terbuka, tutup
      if (_isMentionSheetOpen) {
        Navigator.of(context).pop();
      }
    }
  }
  // --- 👇 Fungsi baru untuk mencari pengguna via API 👇 ---
  Future<void> _searchUsersForMention(String query, StateSetter setSheetState) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.trim().isEmpty) {
        setSheetState(() {
          _mentionResults.clear();
          _isMentionLoading = false;
        });
        return;
      }

      setSheetState(() => _isMentionLoading = true);

      try {
        final token = await SecureStorage.getToken();
        if (token == null) throw Exception("Token tidak ditemukan");

        final url = Uri.parse('https://api-new.portalsi.com/api/users/search?username=$query');
        final response = await http.get(url, headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        if (response.statusCode == 200) {
          final List usersJson = json.decode(response.body);
          setSheetState(() {
            _mentionResults = usersJson.map((json) => User.fromJson(json)).toList();
          });
        } else {
          throw Exception('Gagal memuat data pengguna');
        }
      } catch (e) {
        log('Error mencari mention: $e');
      } finally {
        setSheetState(() => _isMentionLoading = false);
      }
    });
  }

  // --- 👇 Fungsi baru untuk menampilkan BottomSheet mention 👇 ---
  Future<void> _showMentionSheet() {
    final searchController = TextEditingController(text: _currentMentionQuery);
    _searchUsersForMention(_currentMentionQuery, (fn) { setState(fn); });

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (sheetContext) { // Menggunakan sheetContext yang aman
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              searchController.addListener(() {
                _searchUsersForMention(searchController.text, setSheetState);
              });

              return DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.8,
                expand: false,
                builder: (_, scrollController) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            hintText: 'Cari pengguna...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isMentionLoading
                            ? _buildShimmerList()
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: _mentionResults.length,
                          itemBuilder: (context, index) {
                            final user = _mentionResults[index];
                            return ListTile(
                              key: ValueKey(user.id),
                              leading: CircleAvatar(
                                backgroundImage: CachedNetworkImageProvider(user.profilePictureUrl ?? ''),
                              ),
                              title: Row(
                                children: [
                                  Text(user.username, style: const TextStyle(color: Colors.white)),
                                  if (user.isVerified) const SizedBox(width: 4),
                                  if (user.isVerified) const VerifiedBadge(size: 14),
                                ],
                              ),
                              subtitle: user.fullName != null
                                  ? Text(user.fullName!, style: const TextStyle(color: Colors.grey))
                                  : null,
                              // --- 👇 PERBAIKAN UTAMA ADA DI SINI 👇 ---
                              onTap: () {
                                // 1. Matikan state sheet terlebih dahulu
                                _isMentionSheetOpen = false;

                                // 2. Tutup bottom sheet secara eksplisit
                                Navigator.pop(sheetContext);

                                // 3. BARU perbarui teks caption
                                final text = _captionController.text;
                                final cursorPosition = _captionController.selection.baseOffset;
                                final int lastAt = text.substring(0, cursorPosition).lastIndexOf('@');

                                final newText = text.substring(0, lastAt) + '@${user.username} ' + text.substring(cursorPosition);

                                _captionController.text = newText;
                                _captionController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: lastAt + user.username.length + 2)
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SizedBox(height: 10, child: ColoredBox(color: Colors.white)),
          subtitle: SizedBox(height: 8, child: ColoredBox(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _handleSharePost() async {
    if (_isUploading) return;
    if (widget.mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada media untuk diunggah!')),
      );
      return;
    }

    setState(() { _isUploading = true; });

    try {
      final File mediaFile = widget.mediaFiles.first;
      final bool isVideo = mediaFile.path.toLowerCase().endsWith('.mp4');

      final userId = await SecureStorage.getUserId();
      if (userId == null) throw Exception("User ID tidak ditemukan.");

      final Map<String, String> fields = {
        'user_id': userId.toString(),
        'caption': _captionController.text,
        'location': _locationController.text,
        'is_archived': '0',
        'is_video': isVideo ? '1' : '0',
      };

      if (widget.selectedSong != null) {
        final song = widget.selectedSong!;
        fields['music_track_name'] = song.trackName ?? '';
        fields['music_artist_name'] = song.artistName ?? '';
        fields['music_preview_url'] = song.previewUrl ?? '';
        fields['music_album_art_url'] = song.artworkUrl ?? '';
      }

      if (widget.textOverlays.isNotEmpty) {
        final List<Map<String, dynamic>> overlaysAsMap =
        widget.textOverlays.map((overlay) => overlay.toJson()).toList();
        fields['text_overlays_json'] = jsonEncode(overlaysAsMap);
      }

      log("⬆️ Mengirim data ke Endpoint /posts...");
      log("   DATA FIELDS: ${jsonEncode(fields)}");
      log("   MEDIA FILE PATH: ${mediaFile.path}");

      final newPost = await PostService().createPost(fields, mediaFile: mediaFile);

      if (newPost != null) {
        print("🎉 Postingan berhasil dibuat!");
        if(mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        throw Exception("Gagal membuat postingan via service.");
      }

    } catch (e) {
      print("❌ Terjadi error saat mengunggah: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunggah postingan! Cek log untuk detail.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Postingan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80 * (5 / 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.mediaFiles.isNotEmpty
                                ? _MediaThumbnailPreview(file: widget.mediaFiles.first)
                                : Container(color: Colors.grey.shade800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _captionController,
                            maxLines: 5,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Tambahkan Caption...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _Divider(),
                  if (widget.selectedSong != null)
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(widget.selectedSong!.artworkUrl, width: 40, height: 40),
                      ),
                      title: Text(widget.selectedSong!.trackName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(widget.selectedSong!.artistName, style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {},
                      ),
                    ),
                  if (widget.selectedSong != null) const _Divider(),
                  _ActionTile(icon: Icons.people_outline, title: 'Tag Orang', onTap: () {
                    HapticFeedback.lightImpact();
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[850],
                          title: const Text('Tag Pengguna', style: TextStyle(color: Colors.white)),
                          content: const Text('Untuk mention seseorang, sertakan simbol "@" diikuti dengan username mereka di dalam caption Anda.', style: TextStyle(color: Colors.grey)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Mengerti'),
                            )
                          ],
                        )
                    );
                  }),
                  _ActionTile(icon: Icons.location_on_outlined, title: 'Tambahkan Lokasi', onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _showLocationInput = !_showLocationInput;
                    });
                  }),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _showLocationInput
                        ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Sertakan lokasi...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade800.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    )
                        : const SizedBox(width: double.infinity),
                  ),
                  const _Divider(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleSharePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Bagikan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.grey.shade800, height: 1);
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _OptionChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool hasNewBadge;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.hasNewBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing!, style: const TextStyle(color: Colors.grey)),
          if (hasNewBadge) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 10)),
            )
          ],
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}


class _MediaThumbnailPreview extends StatefulWidget {
  final File file;
  const _MediaThumbnailPreview({required this.file});

  @override
  State<_MediaThumbnailPreview> createState() => _MediaThumbnailPreviewState();
}

class _MediaThumbnailPreviewState extends State<_MediaThumbnailPreview> {
  Future<Uint8List?>? _thumbnailFuture;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isVideo = widget.file.path.toLowerCase().endsWith('.mp4');
    if (_isVideo) {
      _thumbnailFuture = VideoThumbnail.thumbnailData(
        video: widget.file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 25,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideo) {
      return Image.file(widget.file, fit: BoxFit.cover);
    }

    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(color: Colors.grey.shade800, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
      },
    );
  }
}