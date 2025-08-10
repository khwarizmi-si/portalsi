// lib/widgets/music_picker_sheet.dart

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/song_model.dart';
import '../services/music_service.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchInitialSongs();
    _searchController.addListener(_onSearchChanged);

    // Listener untuk menghilangkan bar saat lagu selesai
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() => _currentlyPlayingSong = null);
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

  void _fetchInitialSongs() {
    _fetchSongs("opick");
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSongs(_searchController.text);
    });
  }

  Future<void> _fetchSongs(String term) async {
    if (term.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final songs = await _musicService.searchSongs(term);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _playPreview(Song song) async {
    if (_currentlyPlayingSong?.previewUrl == song.previewUrl) {
      // Jika lagu yang sama diklik lagi, hentikan
      await _audioPlayer.stop();
      // State akan di-clear oleh listener
    } else {
      // Hentikan lagu sebelumnya
      await _audioPlayer.stop();
      // Langsung tampilkan loading untuk lagu yang baru
      setState(() {
        _isAudioLoading = true;
        _loadingUrl = song.previewUrl;
        _currentlyPlayingSong = song;
      });
      try {
        // Mulai memutar, listener akan menangani sisanya
        await _audioPlayer.play(UrlSource(song.previewUrl));
      } catch (e) {
        print("Error playing audio: $e");
        // Handle error jika gagal
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

  // --- FUNGSI BARU UNTUK MEMILIH LAGU DAN MENUTUP SHEET ---
  void _selectSongAndClose() {
    if (_currentlyPlayingSong != null) {
      // Hentikan musik sebelum menutup
      _audioPlayer.stop();
      // Kembalikan data lagu yang dipilih saat menutup sheet
      Navigator.of(context).pop(_currentlyPlayingSong);
    }
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
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          // Stack agar bisa menumpuk daftar lagu dengan bar pemutar di bawah
          child: Stack(
            children: [
              Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search music',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  // Filter Chips
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ['For you', 'Trending', 'Saved', 'Original audio']
                          .map((label) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          label: Text(label),
                          backgroundColor: label == 'For you' ? Colors.white : Colors.grey[800],
                          labelStyle: TextStyle(color: label == 'For you' ? Colors.black : Colors.white),
                        ),
                      ))
                          .toList(),
                    ),
                  ),
                  // Daftar Lagu
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.only(bottom: _currentlyPlayingSong != null ? 80 : 0),
                      itemCount: _songs.length,
                      itemBuilder: (context, index) {
                        final song = _songs[index];
                        final isPlaying = _currentlyPlayingSong?.previewUrl == song.previewUrl;
                        // Tentukan apakah lagu ini yang sedang loading
                        final isLoadingThisSong = _isAudioLoading && _loadingUrl == song.previewUrl;

                        return ListTile(
                          // --- LEADING SEKARANG MENAMPILKAN LOADING INDICATOR ---
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.network(song.artworkUrl, width: 50, height: 50, fit: BoxFit.cover),
                              ),
                              // Tampilkan loading, atau ikon play/pause
                              if(isLoadingThisSong)
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                                )
                              else if (!isPlaying) // Ikon play hanya muncul jika tidak sedang diputar
                                Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(4.0)),
                                    child: const Icon(Icons.play_arrow, color: Colors.white)
                                )
                            ],
                          ),
                          title: Row(
                            children: [
                              if(isPlaying && !isLoadingThisSong) // Ikon equalizer hanya muncul saat benar-benar playing
                                Icon(Icons.equalizer, color: Colors.blueAccent, size: 20),
                              if(isPlaying && !isLoadingThisSong)
                                const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  song.trackName,
                                  style: TextStyle(
                                      color: isPlaying ? Colors.blueAccent : Colors.white,
                                      fontWeight: FontWeight.bold
                                  ),
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
                            icon: const Icon(Icons.bookmark_border, color: Colors.white),
                            onPressed: () {},
                          ),
                          onTap: () => _playPreview(song),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // --- TAMPILAN BAR PEMUTAR BARU DI BAWAH ---
              if (_currentlyPlayingSong != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
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
                          // Tombol Pause
                          IconButton(
                            icon: const Icon(Icons.pause_circle_filled, color: Colors.white, size: 32),
                            onPressed: () => _playPreview(_currentlyPlayingSong!),
                          ),
                          // Tombol Selesai/Pilih
                          ElevatedButton(
                            onPressed: _selectSongAndClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
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