// lib/widgets/music_picker_sheet.dart

import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song_model.dart';
import '../services/music_service.dart';

// --- ENUM DIPERBARUI: Menambahkan status untuk Search ---
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA DIPERBARUI: Saat search kosong, kembali ke lagu tren ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if(_searchController.text.trim().isEmpty) {
        _handleFilterChange(MusicFilter.trending); // Jika search kosong, kembali ke daftar tren
      } else {
        _fetchSongs(_searchController.text);
      }
    });
  }

  // --- LOGIKA DIPERBARUI: Saat mencari, ubah status filter menjadi 'search' ---
  Future<void> _fetchSongs(String term) async {
    if (term.isEmpty) return;
    setState(() {
      _isLoading = true;
      _activeFilter = MusicFilter.search; // Set filter ke search agar chip tidak aktif
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleFilterChange(MusicFilter filter) {
    if (filter == MusicFilter.search) return; // Jangan lakukan apa-apa jika filter adalah search

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

  Future<void> _playPreview(Song song) async {
    if (_currentlyPlayingSong?.previewUrl == song.previewUrl) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.stop();
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
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[200]!,
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
            color: Colors.white,
          ),
          subtitle: Container(
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            color: Colors.white,
          ),
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
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari musik..',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        filled: true,
                        fillColor: Colors.grey[300],
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
                          backgroundColor: Colors.white,
                          selectedColor: Colors.grey[600],
                          labelStyle: TextStyle(color: _activeFilter == MusicFilter.trending ? Colors.white : Colors.grey[400]),
                          showCheckmark: false,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Tersimpan'),
                          selected: _activeFilter == MusicFilter.saved,
                          onSelected: (_) => _handleFilterChange(MusicFilter.saved),
                          backgroundColor: Colors.white,
                          selectedColor: Colors.grey[600],
                          labelStyle: TextStyle(color: _activeFilter == MusicFilter.saved ? Colors.white : Colors.grey[400]),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? _buildLoadingSkeleton()
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
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.network(song.artworkUrl, width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              if(isLoadingThisSong)
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(4.0)),
                                    child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)))
                                )
                              else if (!isPlaying)
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(4.0)),
                                    child: const Icon(Icons.play_arrow, color: Colors.black)
                                )
                            ],
                          ),
                          title: Row(
                            children: [
                              if(isPlaying && !isLoadingThisSong)
                                Icon(Icons.equalizer, color: Colors.blueAccent, size: 20),
                              if(isPlaying && !isLoadingThisSong)
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  song.trackName,
                                  style: TextStyle(color: isPlaying ? Colors.blueAccent : Colors.black, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              '↗ ${song.artistName} • ${song.duration}',
                              style: TextStyle(color: Colors.grey[400])
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: isBookmarked ? Colors.blueAccent : Colors.grey[400],
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
                      color: const Color(0xD1121212),
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
                            icon: const Icon(Icons.pause_circle_filled, color: Colors.white, size: 32),
                            onPressed: () => _playPreview(_currentlyPlayingSong!),
                          ),
                          ElevatedButton(
                            onPressed: _selectSongAndClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: const Text('Tambahkan', style: TextStyle(fontWeight: FontWeight.bold)),
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