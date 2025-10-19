import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Tambahkan ini
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../../models/draft_model.dart';
import '../../models/song_model.dart';
import '../../models/text_overlay_model.dart';
import '../../models/sticker_overlay_model.dart';
import '../../services/draft_service.dart';
import '../../services/location_service.dart';
import '../../services/music_service.dart';
import '../../widgets/custom_emoji_picker.dart';
import '../../widgets/music_picker_sheet.dart';
import '../share_post_page.dart';
import 'cutout_editor_page.dart';
import 'widgets/app_bar/edit_clips_app_bar.dart';
import 'widgets/bottom_sheets/effects_bottom_sheet.dart';
import 'widgets/bottom_sheets/sticker_bottom_sheet.dart';
import 'widgets/bottom_sheets/text_edit_bottom_sheet.dart';
import 'widgets/toolbars/edit_clips_toolbar.dart';
import 'widgets/video/video_preview.dart';

// Dummy AuthService & User Model (untuk contoh Avatar)
class User {
  final String profilePictureUrl;
  User({required this.profilePictureUrl});
}
class AuthService {
  static Future<User> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return User(profilePictureUrl: "https://i.pravatar.cc/150?u=a042581f4e29026704d");
  }
}

class EditClipsPage extends StatefulWidget {
  final File videoFile;
  final Draft? initialDraft;

  const EditClipsPage({
    super.key,
    required this.videoFile,
    this.initialDraft,
  });

  @override
  State<EditClipsPage> createState() => _EditClipsPageState();
}

class _EditClipsPageState extends State<EditClipsPage> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isLoading = true;
  bool _isProcessing = false;

  bool _showFeatureCard = false;

  final List<TextOverlay> _textOverlays = [];
  final List<StickerOverlay> _stickerOverlays = [];
  Object? _activeOverlay;

  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  Song? _selectedSong;
  String _selectedEffectName = 'No effect';
  final LocationService _locationService = LocationService();
  Song? _singleRecommendedSong;
  bool _isLoadingRecommendations = true;
  final AudioPlayer _recommendationAudioPlayer = AudioPlayer();
  bool _isRecommendationPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _fetchRecommendedSong();
    _checkFirstVisit();

    if (widget.initialDraft != null) {
      _loadDraft(widget.initialDraft!);
    }

    _audioPlayer.onPlayerComplete.listen((event) {
      _audioPlayer.seek(Duration.zero);
      _videoController?.seekTo(Duration.zero);
      _videoController?.play();
    });
    _recommendationAudioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isRecommendationPlaying = (state == PlayerState.playing));
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _recommendationAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.file(widget.videoFile);
    try {
      await _videoController?.initialize();
      await _videoController?.play();
      await _videoController?.setLooping(true);
      await _videoController?.setVolume(_selectedSong == null ? 1.0 : 0.0);
      setState(() => _isLoading = false);
    } catch (e) {
      print("Error initializing video player: $e");
    }
  }

  Future<void> _checkFirstVisit() async {
    // Beri sedikit jeda agar UI selesai build frame pertama
    await Future.delayed(const Duration(milliseconds: 750));

    final prefs = await SharedPreferences.getInstance();
    // Cek key 'hasSeenEditClipsTutorial'. Jika null (belum ada), anggap false.
    final hasSeen = prefs.getBool('hasSeenEditClipsTutorial') ?? false;

    if (!hasSeen && mounted) {
      setState(() {
        _showFeatureCard = true; // Tampilkan kartu jika belum pernah terlihat
      });
    }
  }

  /// Menyimpan status "sudah dilihat" dan menyembunyikan kartu.
  Future<void> _dismissFeatureCard() async {
    final prefs = await SharedPreferences.getInstance();
    // Set key ke 'true' agar tidak muncul lagi
    await prefs.setBool('hasSeenEditClipsTutorial', true);

    if (mounted) {
      setState(() {
        _showFeatureCard = false; // Sembunyikan kartu dengan animasi
      });
    }
  }

  void _loadDraft(Draft draft) {
    setState(() {
      _selectedEffectName = draft.effectName;
      if (draft.selectedSongJson != null) {
        _selectedSong = Song.fromJson(jsonDecode(draft.selectedSongJson!));
      }
      _textOverlays.addAll(
          draft.textOverlaysJson.map((jsonString) => TextOverlay.fromJson(jsonDecode(jsonString)))
      );
      _stickerOverlays.addAll(
          draft.stickerOverlaysJson.map((jsonString) => StickerOverlay.fromJson(jsonDecode(jsonString)))
      );
    });
  }

  // --- PERBAIKAN DI SINI ---
  void _addTextOverlay(TextOverlay overlay) {
    // Hapus baris pop yang salah dari sini. Dialog/Sheet sudah menutup dirinya sendiri.
    // if (Navigator.canPop(context)) Navigator.pop(context);
    setState(() {
      _textOverlays.add(overlay);
      _activeOverlay = overlay;
    });
  }

  // --- PERBAIKAN DI SINI JUGA ---
  void _addStickerOverlay(StickerOverlay overlay) {
    // Hapus baris pop yang salah dari sini.
    // if (Navigator.canPop(context)) Navigator.pop(context);
    setState(() {
      _stickerOverlays.add(overlay);
      _activeOverlay = overlay;
    });
  }

  void _handleOverlayTap(Object overlay) {
    setState(() => _activeOverlay = overlay);
    if (overlay is TextOverlay) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TextEditBottomSheet(
          textOverlay: overlay,
          onOverlayChanged: (updatedOverlay) {
            setState(() {
              final index = _textOverlays.indexOf(overlay);
              if (index != -1) _textOverlays[index] = updatedOverlay;
            });
          },
          onDelete: () {
            setState(() {
              _textOverlays.remove(overlay);
              _activeOverlay = null;
            });
          },
        ),
      );
    }
  }

  void _handleOverlayScaleStart(Object overlay, ScaleStartDetails details) {
    setState(() {
      _activeOverlay = overlay;
      if (overlay is TextOverlay) {
        _baseScale = overlay.scale;
        _baseRotation = overlay.rotation;
      } else if (overlay is StickerOverlay) {
        _baseScale = overlay.scale;
        _baseRotation = overlay.rotation;
      }
    });
  }

  void _handleOverlayScaleUpdate(Object overlay, ScaleUpdateDetails details) {
    setState(() {
      final newPositionDelta = details.focalPointDelta;
      final newScale = (_baseScale * details.scale).clamp(0.2, 5.0);
      final newRotation = _baseRotation + details.rotation;

      if (overlay is TextOverlay) {
        overlay.position += newPositionDelta;
        overlay.scale = newScale;
        overlay.rotation = newRotation;
      } else if (overlay is StickerOverlay) {
        overlay.position += newPositionDelta;
        overlay.scale = newScale;
        overlay.rotation = newRotation;
      }
    });
  }

  Future<void> _fetchRecommendedSong() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final songs = await MusicService().getTrendingSongs();
      if (mounted && songs.isNotEmpty) {
        setState(() => _singleRecommendedSong = songs.first);
      }
    } catch (e) {
      print("Gagal memuat rekomendasi: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _toggleRecommendationPreview() async {
    if (_singleRecommendedSong == null) return;
    if (_isRecommendationPlaying) {
      await _recommendationAudioPlayer.pause();
    } else {
      await _recommendationAudioPlayer.play(UrlSource(_singleRecommendedSong!.previewUrl));
    }
  }

  void _useRecommendedSong() {
    if (_singleRecommendedSong == null) return;
    setState(() {
      _selectedSong = _singleRecommendedSong;
      _videoController?.setVolume(0.0);
      if (_isRecommendationPlaying) {
        _recommendationAudioPlayer.stop();
      }
    });
  }

  void _onRemoveSong() {
    setState(() {
      _selectedSong = null;
      _videoController?.setVolume(1.0);
      _audioPlayer.stop();
    });
  }

  void _onTextButtonTap() async {
    final textController = TextEditingController();
    final String? newText = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text('Masukkan Teks', style: TextStyle(color: Colors.white)),
          content: TextField(controller: textController, autofocus: true, style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(textController.text), child: const Text('Selesai'))
          ],
        )
    );
    if (newText != null && newText.isNotEmpty) {
      _addTextOverlay(TextOverlay(text: newText, backgroundStyle: TextBackgroundStyle.semiTransparent));
    }
  }

  void _onEmojiButtonTap() async {
    final String? selectedEmoji = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const CustomEmojiPicker()
    );
    if (selectedEmoji != null) {
      _addTextOverlay(TextOverlay(text: selectedEmoji, backgroundStyle: TextBackgroundStyle.none, scale: 2.0));
    }
  }

  Future<void> _saveDraft() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final textOverlaysJson = _textOverlays.map((o) => jsonEncode(o.toJson())).toList();
    final stickerOverlaysJson = _stickerOverlays.map((o) => jsonEncode(o.toJson())).toList();
    final selectedSongJson = _selectedSong != null ? jsonEncode(_selectedSong!.toJson()) : null;

    final draft = Draft(
      id: const Uuid().v4(),
      originalVideoPath: widget.videoFile.path,
      selectedSongJson: selectedSongJson,
      textOverlaysJson: textOverlaysJson,
      stickerOverlaysJson: stickerOverlaysJson,
      effectName: _selectedEffectName,
      createdAt: DateTime.now(),
    );

    try {
      await DraftService().saveDraft(draft);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil disimpan di Draf.')));
      if(mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan draf: $e')));
    } finally {
      if(mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _addGifSticker() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur GIF dinonaktifkan sementara.'))
    );
  }

  Future<void> _addPhotoSticker() async {
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      _addStickerOverlay(StickerOverlay(filePath: image.path, scale: 0.6));
    }
  }

  Future<void> _createCutoutSticker() async {
    if (Navigator.canPop(context)) Navigator.pop(context);
    final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final resultFile = await Navigator.of(context).push<File>(
      MaterialPageRoute(
        builder: (context) => CutoutEditorPage(imageFile: File(image.path)),
      ),
    );
    if (resultFile != null) {
      _addStickerOverlay(StickerOverlay(filePath: resultFile.path, scale: 0.8));
    }
  }

  Future<void> _addAvatarSticker() async {
    try {
      final user = await AuthService.getCurrentUser();
      _addStickerOverlay(StickerOverlay(imageUrl: user.profilePictureUrl, isAvatar: true, scale: 0.3));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat avatar: $e')));
    }
  }

  void _onStickerButtonTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))),
      builder: (_) => StickerBottomSheet(
        onTextStickerSelected: _addTextOverlay,
        onGenerateCaptions: (){},
        onLocationTap: (){},
        onGifTap: _addGifSticker,
        onPhotoTap: _addPhotoSticker,
        onAvatarTap: _addAvatarSticker,
        onCutoutTap: _createCutoutSticker,
      ),
    );
  }

  void _onEffectsButtonTap() {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF1A1A1A), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.0))), builder: (_) => EffectsBottomSheet(selectedEffectName: _selectedEffectName, onEffectSelected: (newEffect) { setState(() => _selectedEffectName = newEffect); Navigator.pop(context); }));
  }

  void _onMusicButtonTap() async {
    await _audioPlayer.stop();
    await _recommendationAudioPlayer.stop();
    final selectedSong = await showModalBottomSheet<Song>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const MusicPickerSheet());
    if (selectedSong != null) {
      setState(() {
        _selectedSong = selectedSong;
        _videoController?.setVolume(0.0);
      });
      if (selectedSong.previewUrl.isNotEmpty) {
        await _audioPlayer.play(UrlSource(selectedSong.previewUrl));
        _videoController?.seekTo(Duration.zero);
        _videoController?.play();
      }
    }
  }

  void _onNextButtonTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _videoController?.pause();
    _audioPlayer.stop();
    _recommendationAudioPlayer.stop();

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => SharePostPage(
        mediaFiles: [widget.videoFile],
        selectedSong: _selectedSong,
        textOverlays: _textOverlays,
        stickerOverlays: _stickerOverlays
    )));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _handleExitAttempt() {
    final hasEdits = _textOverlays.isNotEmpty || _stickerOverlays.isNotEmpty || _selectedSong != null;

    if (!hasEdits) {
      Navigator.of(context).pop();
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simpan di Draf?',
                style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kalau kamu langsung keluar, editan postingan ini akan menghilang.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Keluar Saja', style: TextStyle(color: Colors.red, fontSize: 18)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Simpan di Draf', style: TextStyle(color: Colors.black, fontSize: 18)),
                onTap: () {
                  _saveDraft();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lanjutkan mengedit', style: TextStyle(color: Colors.black, fontSize: 18)),
                onTap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Dapatkan tinggi AppBar (jika ada) atau perkiraan tinggi status bar + appbar kustom
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    // Perkiraan tinggi toolbar di bagian bawah. Sesuaikan jika perlu.
    const bottomToolbarHeight = -20.0;

    return WillPopScope(
      onWillPop: () async {
        _handleExitAttempt();
        return false;
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFDDBC), Colors.white],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: EditClipsAppBar(
            selectedSong: _selectedSong,
            recommendedSong: _singleRecommendedSong,
            isRecommendationLoading: _isLoadingRecommendations,
            isRecommendationPlaying: _isRecommendationPlaying,
            onMusicTap: _onMusicButtonTap,
            onRemoveSong: _onRemoveSong,
            onToggleRecommendation: _toggleRecommendationPreview,
            onUseRecommendation: _useRecommendedSong,
            onSaveDraft: _saveDraft,
            onBackButtonPressed: _handleExitAttempt,
          ),
          body: SafeArea(
            child: _isLoading || _videoController == null
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                VideoPreview(
                  controller: _videoController!,
                  textOverlays: _textOverlays,
                  stickerOverlays: _stickerOverlays,
                  activeOverlay: _activeOverlay,
                  effectName: _selectedEffectName,
                  onOverlayTap: _handleOverlayTap,
                  onBackgroundTap: () => setState(() => _activeOverlay = null),
                  onScaleStart: _handleOverlayScaleStart,
                  onScaleUpdate: _handleOverlayScaleUpdate,
                ),
                EditClipsToolbar(
                  isProcessing: _isProcessing,
                  onTextTap: _onTextButtonTap,
                  onEmojiTap: _onEmojiButtonTap,
                  onStickerTap: _onStickerButtonTap,
                  onEffectsTap: _onEffectsButtonTap,
                  onNextTap: _onNextButtonTap,
                ),
                AnimatedOpacity(
                  opacity: _showFeatureCard ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer( // Mencegah interaksi saat kartu tidak ada
                    ignoring: !_showFeatureCard,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        // Memberi sedikit warna gelap pada blur
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                // --- 👆 BATAS EFEK BLUR 👆 ---

                // Kartu fitur
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  bottom: _showFeatureCard ? (bottomToolbarHeight + 10.0) : -screenHeight,
                  left: 0,
                  right: 0,
                  child: _FeatureDiscoveryCard(
                    onDismiss: _dismissFeatureCard,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// --- 👇 GANTI KESELURUHAN WIDGET CARD LAMA DENGAN YANG INI 👇 ---
class _FeatureDiscoveryCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _FeatureDiscoveryCard({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                child: Image.asset(
                  'assets/images/edit_features.png', // <-- Pastikan path ini benar
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Text(
                          'Ganti dengan gambar Anda\n(e.g., assets/images/edit_features.png)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 0.0),
                child: Text(
                  "Selamat Datang di Editor Clips!",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildFeatureItem(
                Icons.text_fields_rounded,
                'Tambahkan Teks & Stiker',
                'Kreasikan videomu dengan tulisan dan stiker unik.',
              ),
              _buildFeatureItem(
                Icons.music_note_rounded,
                'Pilih Musik Favorit',
                'Gunakan lagu yang sedang tren atau dari galerimu.',
              ),
              _buildFeatureItem(
                Icons.auto_awesome_rounded,
                'Gunakan Efek Keren',
                'Coba berbagai filter dan efek untuk video sinematik.',
              ),
              const SizedBox(height: 10),

              // --- 👇 TOMBOL X DIHAPUS, DIGANTI DENGAN 2 TOMBOL DI BAWAH 👇 ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    // Tombol Sekunder: "Tidak sekarang"
                    TextButton(
                      onPressed: onDismiss, // Menjalankan fungsi dismiss
                      child: Text(
                        'Tidak sekarang',
                        style: TextStyle(
                          color: Colors.orange.shade700, // Tulisan oranye
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Tombol Primer: "Coba Fitur di Clips"
                    GestureDetector(
                      onTap: onDismiss, // Menjalankan fungsi dismiss
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), // Bulat
                          gradient: LinearGradient( // Gradien Amber ke Oranye
                            colors: [
                              Colors.amber.shade400,
                              Colors.orange.shade700,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Coba Fitur di Clips", // Saya sesuaikan sedikit teksnya
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // --- 👆 BATAS PERUBAHAN 👆 ---
            ],
          ),
          // Tombol 'X' (Positioned) yang sebelumnya di sini sudah dihapus
        ),
      ),
    );
  }

  // Paste juga _buildFeatureItem yang sudah dimodifikasi
  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}