// lib/widgets/music_picker_sheet.dart

import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song_model.dart';
import '../services/music_service.dart';

enum MusicFilter { trending, saved, search }

class MusicPickerSheet extends StatefulWidget {
  const MusicPickerSheet({Key? key}) : super(key: key);

  @override
  _MusicPickerSheetState createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<MusicPickerSheet> {
  final MusicService _musicService = MusicService();
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _songs = [];
  bool _isLoading = true;
  Song? _currentlyPlayingSong;
  Timer? _debounce;

  bool _isAudioLoading = false;
  String? _loadingUrl;

  List<Song> _bookmarkedSongs = [];
  MusicFilter _activeFilter = MusicFilter.trending;
  static const String _bookmarkKey = 'bookmarked_songs';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _fetchInitialSongs();
    _searchController.addListener(_onSearchChanged);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        if (mounted) {
          setState(() => _currentlyPlayingSong = null);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedSongsJson = prefs.getStringList(_bookmarkKey) ?? [];
    if (mounted) {
      setState(() {
        _bookmarkedSongs = savedSongsJson
            .map((json) => Song.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  Future<void> _toggleBookmark(Song song) async {
    final isBookmarked = _bookmarkedSongs.any((s) => s.trackId == song.trackId);

    if (isBookmarked) {
      _bookmarkedSongs.removeWhere((s) => s.trackId == song.trackId);
    } else {
      _bookmarkedSongs.add(song);
    }
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    final List<String> songsToSaveJson =
    _bookmarkedSongs.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_bookmarkKey, songsToSaveJson);

    if (_activeFilter == MusicFilter.saved && isBookmarked) {
      _fetchBookmarkedSongs();
    }
  }

  void _fetchBookmarkedSongs() {
    setState(() {
      _songs = List.from(_bookmarkedSongs);
      _isLoading = false;
    });
  }

  Future<void> _fetchInitialSongs() async {
    setState(() {
      _isLoading = true;
      _activeFilter = MusicFilter.trending;
    });
    try {
      final songs = await _musicService.getTrendingSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _songs = []; // Pastikan daftar kosong jika ada error
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if(_searchController.text.trim().isEmpty) {
        _handleFilterChange(MusicFilter.trending);
      } else {
        _fetchSongs(_searchController.text);
      }
    });
  }

  Future<void> _fetchSongs(String term) async {
    if (term.isEmpty) return;
    setState(() {
      _isLoading = true;
      _activeFilter = MusicFilter.search;
    });
    try {
      final songs = await _musicService.searchSongs(term);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _songs = []; // Pastikan daftar kosong jika ada error
      });
    }
  }

  void _handleFilterChange(MusicFilter filter) {
    if (filter == MusicFilter.search) return;

    _searchController.clear();
    _audioPlayer.stop();
    setState(() {
      _activeFilter = filter;
      _isLoading = true;
      _currentlyPlayingSong = null;
    });

    if (filter == MusicFilter.trending) {
      _fetchInitialSongs();
    } else if (filter == MusicFilter.saved) {
      _fetchBookmarkedSongs();
    }
  }

  // --- 👇 FUNGSI BARU: Logika untuk menangani refresh ---
  void _handleRefresh() {
    _audioPlayer.stop();
    setState(() => _currentlyPlayingSong = null);

    switch (_activeFilter) {
      case MusicFilter.trending:
        _fetchInitialSongs();
        break;
      case MusicFilter.saved:
        _loadBookmarks().then((_) => _fetchBookmarkedSongs());
        break;
      case MusicFilter.search:
        if (_searchController.text.trim().isNotEmpty) {
          _fetchSongs(_searchController.text.trim());
        } else {
          _fetchInitialSongs();
        }
        break;
    }
  }

  Future<void> _playPreview(Song song) async {
    if (_currentlyPlayingSong?.previewUrl == song.previewUrl) {
      await _audioPlayer.stop();
      setState(() => _currentlyPlayingSong = null);
    } else {
      setState(() {
        _isAudioLoading = true;
        _loadingUrl = song.previewUrl;
        _currentlyPlayingSong = song;
      });
      try {
        await _audioPlayer.play(UrlSource(song.previewUrl));
        if(mounted) setState(() => _isAudioLoading = false);
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAudioLoading = false;
            _loadingUrl = null;
            _currentlyPlayingSong = null;
          });
        }
      }
    }
  }

  void _selectSongAndClose() {
    if (_currentlyPlayingSong != null) {
      _audioPlayer.stop();
      Navigator.of(context).pop(_currentlyPlayingSong);
    }
  }

  Widget _buildLoadingSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          title: Container(
            height: 16,
            width: 200,
            color: Colors.white,
            margin: const EdgeInsets.only(right: 50),
          ),
          subtitle: Container(
            height: 12,
            width: 150,
            margin: const EdgeInsets.only(top: 4, right: 100),
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // --- 👇 WIDGET BARU: Tampilan futuristik saat daftar lagu kosong ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 5.0, end: 25.0),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutQuint,
              builder: (context, blurRadius, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.tealAccent,
                        Colors.teal
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.4),
                        blurRadius: blurRadius,
                        spreadRadius: blurRadius / 10,
                      ),
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.2),
                        blurRadius: blurRadius / 2,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: const Icon(
                Icons.wifi_tethering_error_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Gagal Memuat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Terjadi masalah saat memuat musik. Periksa koneksi Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _handleRefresh,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: Colors.teal.withOpacity(0.5),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.tealAccent,
                      Colors.teal
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Coba Lagi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari musik atau artis...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        FilterChip(
                          label: const Text('Untuk Anda'),
                          selected: _activeFilter == MusicFilter.trending,
                          onSelected: (_) => _handleFilterChange(MusicFilter.trending),
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.grey.shade800,
                          labelStyle: TextStyle(color: _activeFilter == MusicFilter.trending ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
                          showCheckmark: false,
                          shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Tersimpan'),
                          selected: _activeFilter == MusicFilter.saved,
                          onSelected: (_) => _handleFilterChange(MusicFilter.saved),
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.grey.shade800,
                          labelStyle: TextStyle(color: _activeFilter == MusicFilter.saved ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold),
                          showCheckmark: false,
                          shape: StadiumBorder(side: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    // --- 👇 LOGIKA UTAMA DIPERBARUI DI SINI ---
                    child: _isLoading
                        ? _buildLoadingSkeleton()
                        : _songs.isEmpty
                        ? _buildEmptyState() // Tampilkan state kosong jika tidak ada lagu
                        : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(bottom: _currentlyPlayingSong != null ? 80 : 0),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final isPlaying = _currentlyPlayingSong?.previewUrl == song.previewUrl;
                        final isLoadingThisSong = _isAudioLoading && _loadingUrl == song.previewUrl;
                        final isBookmarked = _bookmarkedSongs.any((s) => s.trackId == song.trackId);

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(song.artworkUrl, width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              if(isLoadingThisSong)
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8.0)),
                                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                )
                              else if (!isPlaying)
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(8.0)),
                                    child: const Icon(Icons.play_arrow, color: Colors.white)
                                )
                            ],
                          ),
                          title: Row(
                            children: [
                              if(isPlaying && !isLoadingThisSong)
                                Icon(Icons.equalizer_rounded, color: Colors.blueAccent, size: 18),
                              if(isPlaying && !isLoadingThisSong)
                                const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  song.trackName,
                                  style: TextStyle(color: isPlaying ? Colors.blueAccent : Colors.black87, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              '${song.artistName} • ${song.duration}',
                              style: TextStyle(color: Colors.grey.shade500)
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                              color: isBookmarked ? Colors.blueAccent : Colors.grey.shade400,
                            ),
                            onPressed: () => _toggleBookmark(song),
                          ),
                          onTap: () => _playPreview(song),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_currentlyPlayingSong != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D1D1D),
                      border: Border(top: BorderSide(color: Colors.grey[800]!, width: 0.5)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.network(_currentlyPlayingSong!.artworkUrl, width: 40, height: 40, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentlyPlayingSong!.trackName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _currentlyPlayingSong!.artistName,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled_rounded, color: Colors.white, size: 32),
                            onPressed: () => _playPreview(_currentlyPlayingSong!),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectSongAndClose,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Pilih', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}