import 'package:portal_si/config/api_endpoint.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:portal_si/pages/osm_picker_page.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../components/verified_badge.dart';
import '../models/song_model.dart';
import '../models/sticker_overlay_model.dart';
import '../models/text_overlay_model.dart';
import '../models/user_model.dart';
import '../providers/navigation_provider.dart';
import '../providers/upload_provider.dart';
import '../services/geocoding_service.dart';
import '../utils/secure_storage.dart';
import '../services/location_service.dart'; // Pastikan path ini benar

class SharePostPage extends StatefulWidget {
  final List<File> mediaFiles;
  final Song? selectedSong;
  final List<TextOverlay> textOverlays;
  final List<StickerOverlay> stickerOverlays;

  const SharePostPage({
    super.key,
    required this.mediaFiles,
    this.selectedSong,
    this.textOverlays = const [],
    this.stickerOverlays = const [],
  });

  @override
  State<SharePostPage> createState() => _SharePostPageState();
}

class _SharePostPageState extends State<SharePostPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _isFetchingLocation = false;
  bool _isMentionSheetOpen = false;
  Timer? _debounce;
  List<User> _mentionResults = [];
  bool _isMentionLoading = false;
  bool _isMentionLoadingMore = false;
  int _mentionCurrentPage = 1;
  int _mentionLastPage = 1;
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
    final bool isDeleting = text.length < _previousCaptionText.length;
    _previousCaptionText = text;

    final int lastAt = text.substring(0, cursorPosition).lastIndexOf('@');
    final int lastSpace = text.substring(0, cursorPosition).lastIndexOf(' ');
    final bool isTypingMention = lastAt != -1 && lastAt > lastSpace;

    if (isTypingMention) {
      final query = text.substring(lastAt + 1, cursorPosition);
      _currentMentionQuery = query;
      if (!_isMentionSheetOpen && !isDeleting) {
        setState(() => _isMentionSheetOpen = true);
        _showMentionSheet().whenComplete(() {
          if (mounted) setState(() => _isMentionSheetOpen = false);
        });
      }
    } else {
      if (_isMentionSheetOpen) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _searchUsersForMention(String query, StateSetter setSheetState, {bool isNewSearch = true}) async {
    _currentMentionQuery = query;

    if (isNewSearch) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      setSheetState(() {
        _mentionResults.clear();
        _mentionCurrentPage = 1;
        _mentionLastPage = 1;
        _isMentionLoading = true;
      });
    } else {
      if (_isMentionLoadingMore || _mentionCurrentPage > _mentionLastPage) return;
      setSheetState(() => _isMentionLoadingMore = true);
    }

    final logic = () async {
      if (query.trim().isEmpty) {
        setSheetState(() {
          _mentionResults.clear();
          _isMentionLoading = false;
        });
        return;
      }
      try {
        final token = await SecureStorage.getToken();
        if (token == null) throw Exception("Token tidak ditemukan");

        final url = Uri.parse('${ApiEndpoints.apiUrl}/users/search?username=$query&page=$_mentionCurrentPage');
        final response = await http.get(url, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final List usersJson = responseData['data'];
          final List<User> newUsers = usersJson.map((json) => User.fromJson(json)).toList();

          setSheetState(() {
            _mentionResults.addAll(newUsers);
            _mentionLastPage = responseData['last_page'] ?? 1;
            _mentionCurrentPage++;
          });
        } else {
          throw Exception('Gagal memuat data pengguna');
        }
      } catch (e) {
        log('Error mencari mention: $e');
      } finally {
        if(mounted) {
          setSheetState(() {
            _isMentionLoading = false;
            _isMentionLoadingMore = false;
          });
        }
      }
    };

    if (isNewSearch) {
      _debounce = Timer(const Duration(milliseconds: 500), logic);
    } else {
      logic();
    }
  }

  Future<void> _showMentionSheet() {
    _searchUsersForMention(_currentMentionQuery, (fn) { if(mounted) setState(fn); }, isNewSearch: true);

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              final searchController = TextEditingController(text: _currentMentionQuery);
              searchController.selection = TextSelection.fromPosition(TextPosition(offset: _currentMentionQuery.length));
              searchController.addListener(() => _searchUsersForMention(searchController.text, setSheetState, isNewSearch: true));

              return DraggableScrollableSheet(
                initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.8, expand: false,
                builder: (_, scrollController) {
                  scrollController.addListener(() {
                    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
                      _searchUsersForMention(_currentMentionQuery, setSheetState, isNewSearch: false);
                    }
                  });

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: searchController, autofocus: true, style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey), hintText: 'Cari pengguna...', hintStyle: const TextStyle(color: Colors.grey),
                            filled: true, fillColor: Colors.grey.shade800,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _isMentionLoading
                            ? _buildShimmerList()
                            : ListView.builder(
                          controller: scrollController,
                          itemCount: _mentionResults.length + (_isMentionLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _mentionResults.length) {
                              return const Center(child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ));
                            }

                            final user = _mentionResults[index];
                            return ListTile(
                              key: ValueKey(user.id),
                              leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.profilePictureUrl ?? '')),
                              title: Row(children: [
                                Text(user.username, style: const TextStyle(color: Colors.white)),
                                if (user.isVerified) const SizedBox(width: 4), if (user.isVerified) const VerifiedBadge(size: 14),
                              ]),
                              subtitle: user.fullName != null ? Text(user.fullName!, style: const TextStyle(color: Colors.grey)) : null,
                              onTap: () {
                                _isMentionSheetOpen = false;
                                Navigator.pop(sheetContext);
                                final text = _captionController.text;
                                final cursorPosition = _captionController.selection.baseOffset;
                                final int lastAt = text.substring(0, cursorPosition).lastIndexOf('@');
                                final newText = text.substring(0, lastAt) + '@${user.username} ' + text.substring(cursorPosition);
                                _captionController.text = newText;
                                _captionController.selection = TextSelection.fromPosition(TextPosition(offset: lastAt + user.username.length + 2));
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

  void _showLocationOptions() async {
    final dynamic selectedResult = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _LocationSearchSheet(),
    );

    if (selectedResult == null || !mounted) return;

    if (selectedResult is String) {
      if (selectedResult == '__USE_CURRENT_LOCATION__') {
        // Logika untuk mengambil lokasi saat ini
        setState(() => _isFetchingLocation = true);
        try {
          final locationService = LocationService();
          final String? placeName = await locationService.getCurrentPlace();
          if (placeName != null && mounted) {
            setState(() => _locationController.text = placeName);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isFetchingLocation = false);
          }
        }
      } else if (selectedResult == '__PICK_FROM_MAP__') {
        // --- LOGIKA BARU UNTUK MEMBUKA PETA ---
        final String? mapResult = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (context) => const OsmPickerPage()), // Ganti ke OsmPickerPage()
        );
        if (mapResult != null && mounted) {
          setState(() {
            _locationController.text = mapResult;
          });
        }
        // --- AKHIR LOGIKA BARU ---
      } else {
        // Hasil dari pencarian lokasi
        setState(() {
          _locationController.text = selectedResult;
        });
      }
    }
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800, highlightColor: Colors.grey.shade700,
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
    final uploadProvider = Provider.of<UploadProvider>(context, listen: false);
    if (uploadProvider.isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tunggu unggahan sebelumnya selesai.')),
      );
      return;
    }

    if (widget.mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada media untuk diunggah!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final File mediaFile = widget.mediaFiles.first;
      final bool isVideo = mediaFile.path.toLowerCase().endsWith('.mp4');

      Uint8List? thumbnailData;
      if (isVideo) {
        thumbnailData = await VideoThumbnail.thumbnailData(
          video: mediaFile.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 128,
          quality: 25,
        );
      } else {
        thumbnailData = await mediaFile.readAsBytes();
      }

      if (thumbnailData == null) {
        throw Exception("Gagal membuat thumbnail media.");
      }

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

      if (widget.stickerOverlays.isNotEmpty) {
        final List<Map<String, dynamic>> stickersAsMap =
        widget.stickerOverlays.map((sticker) => sticker.toJson()).toList();
        fields['sticker_overlays_json'] = jsonEncode(stickersAsMap);
      }

      uploadProvider.startUpload(
        type: UploadType.post,
        fields: fields,
        mediaFile: mediaFile,
        thumbnail: thumbnailData,
      );

      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      navProvider.navigateToTab(0);

      if (mounted) Navigator.of(context).pop();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      log("Gagal memulai proses unggah: $e");
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai unggahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UploadProvider>(
      builder: (context, uploadProvider, child) {
        final isUploading = uploadProvider.isUploading;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Upload Postingan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFDDBC), Colors.white],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Column(
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
                                width: 80, height: 80 * (5 / 4),
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
                                  style: const TextStyle(color: Colors.black),
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
                            title: Text(widget.selectedSong!.trackName, style: const TextStyle(color: Colors.black)),
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
                                backgroundColor: Colors.white,
                                title: const Text('Tag Pengguna', style: TextStyle(color: Colors.black)),
                                content: const Text('Untuk mention seseorang, sertakan simbol "@" diikuti dengan username mereka di dalam caption Anda.', style: TextStyle(color: Colors.grey)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Mengerti'))
                                ],
                              )
                          );
                        }),
                        ListTile(
                          leading: _isFetchingLocation
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : Icon(
                            _locationController.text.isEmpty
                                ? Icons.location_on_outlined
                                : Icons.location_on,
                            color: _locationController.text.isEmpty
                                ? Colors.black
                                : Colors.blue,
                          ),
                          title: Text(
                            _locationController.text.isEmpty
                                ? 'Tambahkan Lokasi'
                                : _locationController.text,
                            style: TextStyle(
                              color: _locationController.text.isEmpty
                                  ? Colors.black
                                  : Colors.blue,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: _locationController.text.isEmpty
                              ? const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14)
                              : IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                            onPressed: () {
                              setState(() => _locationController.clear());
                            },
                          ),
                          onTap: _isFetchingLocation ? null : _showLocationOptions,
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
                      onPressed: isUploading ? null : _handleSharePost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isUploading
                          ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Memproses...'),
                        ],
                      )
                          : const Text('Bagikan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.grey.shade500, height: 1);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
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
        video: widget.file.path, imageFormat: ImageFormat.JPEG,
        maxWidth: 128, quality: 25,
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

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GeocodingService _geocodingService = GeocodingService();

  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () async {
      final query = _searchController.text;
      if (query.length < 3) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      try {
        final results = await _geocodingService.searchPlaces(query);
        if (mounted) {
          setState(() {
            _suggestions = results;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Lokasi',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Cari nama tempat, kota, atau alamat...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade300,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Opsi Gunakan Lokasi Saat Ini (tetap ada)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text('Gunakan Lokasi Saat Ini', style: TextStyle(color: Colors.black)),
              onTap: () {
                // Mengirim nilai khusus untuk ditangani oleh halaman utama
                Navigator.pop(context, '__USE_CURRENT_LOCATION__');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.map_outlined, color: Colors.green),
              title: const Text('Pilih dari Peta', style: TextStyle(color: Colors.black)),
              onTap: () {
                // Mengirim nilai khusus untuk membuka pemilih peta
                Navigator.pop(context, '__PICK_FROM_MAP__');
              },
            ),
            const Divider(color: Colors.grey, height: 1),

            // Tampilan hasil pencarian
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red))),
              )
            else if (_suggestions.isNotEmpty)
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(suggestion.displayName, style: const TextStyle(color: Colors.white)),
                        onTap: () {
                          // Mengirim nama lokasi yang dipilih kembali ke halaman utama
                          Navigator.pop(context, suggestion.displayName);
                        },
                      );
                    },
                  ),
                )
              else if (_searchController.text.length >= 3)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("Tidak ada hasil ditemukan.", style: TextStyle(color: Colors.grey))),
                  ),
          ],
        ),
      ),
    );
  }
}