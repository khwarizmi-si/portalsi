// lib/pages/story_preview_page.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/song_model.dart';
import '../widgets/music_picker_sheet.dart';
import 'dashboard_page.dart';
import '../utils/secure_storage.dart';
import '../widgets/collage_layout_view.dart';

enum StoryPreviewMode { single, separate, layout, music }

enum MusicDisplayStyle { vinyl, largeCard, smallCard }

class StoryPreviewPage extends StatefulWidget {
  final List<AssetEntity>? assets;
  final Song? song;
  final StoryPreviewMode mode;

  const StoryPreviewPage({
    super.key,
    this.assets,
    this.song,
    this.mode = StoryPreviewMode.single,
  }) : assert(assets != null || song != null,
            'assets atau song harus disediakan');

  @override
  State<StoryPreviewPage> createState() => _StoryPreviewPageState();
}

class _StoryPreviewPageState extends State<StoryPreviewPage>
    with TickerProviderStateMixin {
  final GlobalKey _collageKey = GlobalKey();
  late StoryPreviewMode _mode;
  int _currentIndex = 0;
  AssetEntity? _currentAsset;

  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  late AnimationController _vinylController;
  MusicDisplayStyle _musicStyle = MusicDisplayStyle.vinyl;
  bool _isEditingMusic = false;
  Duration _clipStartPosition = Duration.zero;
  final Duration _clipDuration = const Duration(seconds: 15);
  Duration _totalSongDuration = const Duration(seconds: 30);
  Timer? _playbackTimer;

  VideoPlayerController? _videoController;
  bool _isVideoLoading = true;
  List<Color> _gradientColors = [const Color(0xFF1A1A1A), Colors.black];
  bool _isLoading = true;
  bool _isBottomSheetVisible = false;
  final TextEditingController _captionController = TextEditingController();
  bool _isUploading = false;
  final FocusNode _captionFocusNode = FocusNode();
  bool _isEditingCaption = false;
  int _userId = 0;
  String _token = '';
  double _scale = 1.0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.song != null) {
      _mode = StoryPreviewMode.music;
      _currentSong = widget.song;
    } else {
      _mode = widget.assets!.length > 1 ? widget.mode : StoryPreviewMode.single;
      _currentAsset = widget.assets!.first;
    }

    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadInitialContent();
    _loadUserData();
    _captionFocusNode.addListener(_onFocusChange);
  }

  Future<void> _loadInitialContent() async {
    if (_mode == StoryPreviewMode.music) {
      await _updateSong(_currentSong!);
    } else {
      await _loadAssetAtIndex(_currentIndex);
    }
  }

  void _showMusicPicker() async {
    _audioPlayer.pause();
    _videoController?.pause();

    final selectedSong = await showModalBottomSheet<Song>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MusicPickerSheet(),
    );

    if (selectedSong == null) {
      _audioPlayer.resume();
      _videoController?.play();
      return;
    }

    if (mounted) {
      // Tidak lagi mengubah mode, hanya menambahkan/mengganti lagu
      _updateSong(selectedSong);
    }
  }

  Future<void> _updateSong(Song newSong) async {
    // Jika belum ada aset, buat gradient dari album art. Jika sudah, biarkan.
    if (_currentAsset == null) {
      await _generateGradientFromImageProvider(
          NetworkImage(newSong.artworkUrl));
    }
    _playClip(newSong);
    if (mounted) setState(() => _currentSong = newSong);
  }

  void _playClip(Song song) async {
    _playbackTimer?.cancel();
    await _audioPlayer.stop();
    try {
      await _audioPlayer.play(UrlSource(song.previewUrl),
          position: _clipStartPosition);
      _playbackTimer = Timer(_clipDuration, () {
        if (mounted && _audioPlayer.state == PlayerState.playing) {
          _audioPlayer.stop();
        }
      });
    } catch (e) {
      print("Error playing audio clip: $e");
      _showErrorToast("Gagal memutar pratinjau audio.");
    }
  }

  Future<void> _loadAssetAtIndex(int index) async {
    if (widget.assets == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentIndex = index;
        _currentAsset = widget.assets![index];
        if (_mode != StoryPreviewMode.layout) _captionController.clear();
      });
    }
    await _videoController?.dispose();
    _videoController = null;

    final thumbData = await _currentAsset!
        .thumbnailDataWithSize(const ThumbnailSize(100, 100));
    if (thumbData != null) {
      await _generateGradientFromImageProvider(MemoryImage(thumbData));
    }

    if (_currentAsset!.type == AssetType.video) {
      await _initializeVideoPlayer();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isEditingCaption = _captionFocusNode.hasFocus;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userId = await SecureStorage.getUserId();
      final token = await SecureStorage.getToken();
      setState(() {
        _userId = userId!;
        _token = token ?? '';
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _generateGradientFromImageProvider(
      ImageProvider provider) async {
    try {
      final PaletteGenerator palette =
          await PaletteGenerator.fromImageProvider(provider);
      final Color dominantColor = palette.dominantColor?.color ?? Colors.black;
      final Color vibrantColor = palette.vibrantColor?.color ?? dominantColor;
      if (mounted) {
        setState(() => _gradientColors = [vibrantColor, dominantColor]);
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _gradientColors = [const Color(0xFF1A1A1A), Colors.black]);
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_currentAsset == null) return;
    setState(() => _isVideoLoading = true);
    final File? videoFile = await _currentAsset!.file;
    if (videoFile == null) return;
    _videoController = VideoPlayerController.file(videoFile)
      ..initialize().then((_) {
        if (mounted) {
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() => _isVideoLoading = false);
        }
      });
  }

  Future<void> _handleShare() async {
    if (_isUploading) return;
    setState(() => _isUploading = true);

    // Dapatkan file media utama (gambar/video/kolase)
    File? mediaFile;
    String finalFileName = "story_media";

    if (_mode == StoryPreviewMode.layout) {
      try {
        final boundary = _collageKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        mediaFile = await File('${tempDir.path}/story_layout.png')
            .writeAsBytes(pngBytes);
        finalFileName = "story_layout.png";
      } catch (e) {
        _showErrorToast('Gagal membuat gambar kolase.');
        setState(() => _isUploading = false);
        return;
      }
    } else if (_currentAsset != null) {
      mediaFile = await _currentAsset!.file;
      finalFileName = mediaFile?.path.split('/').last ?? "story_media";
    }

    if (mediaFile == null) {
      _showErrorToast('File media tidak ditemukan.');
      setState(() => _isUploading = false);
      return;
    }

    // Siapkan FormData
    Map<String, dynamic> dataMap = {
      'media[]': [
        await MultipartFile.fromFile(mediaFile.path, filename: finalFileName)
      ],
      'caption[]': [_captionController.text],
    };

    // Jika ada musik yang dipilih, tambahkan datanya
    if (_currentSong != null) {
      dataMap.addAll({
        'music_track_name': _currentSong!.trackName,
        'music_artist_name': _currentSong!.artistName,
        'music_preview_url': _currentSong!.previewUrl,
        'music_start_position_ms': _clipStartPosition.inMilliseconds,
        'music_display_style': _musicStyle.name,
        // Kirim album art juga sebagai media kedua jika API mendukung,
        // atau cukup andalkan mediaUrl di sisi backend.
        // Untuk saat ini, kita kirim data URL-nya saja.
        'music_album_art_url': _currentSong!.artworkUrl,
      });
    }

    final formData = FormData.fromMap(dataMap);

    final dio = Dio();
    try {
      final response = await dio.post(
        'https://api.portalsi.com/api/stories',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
            'Accept': 'application/json'
          },
        ),
      );
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on DioException catch (e) {
      String errorMessage = e.message ?? "Terjadi kesalahan jaringan.";
      int? statusCode;
      if (e.response != null) {
        statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        if (responseData is Map && responseData.containsKey('message')) {
          errorMessage = responseData['message'];
        }
      }
      _showErrorToast(
          'Gagal mengunggah Story: ${statusCode != null ? "[$statusCode] " : ""}$errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<File> _getCachedFile(String url) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${url.split('/').last}';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    } else {
      final response = await Dio().get<List<int>>(url,
          options: Options(responseType: ResponseType.bytes));
      await file.writeAsBytes(response.data!);
      return file;
    }
  }

  Future<String?> _getAuthToken() async {
    return _token;
  }

  void _showErrorToast(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void _showShareBottomSheet() {
    setState(() {
      _isBottomSheetVisible = true;
    });
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            int _groupValue = 1;
            const String userProfileImageUrl =
                'https://i.pravatar.cc/150?img=3';
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Share',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        backgroundImage: NetworkImage(userProfileImageUrl)),
                    title: const Text('Your story',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text('And Facebook Story',
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: Radio<int>(
                        value: 1,
                        groupValue: _groupValue,
                        onChanged: (int? value) =>
                            setState(() => _groupValue = value!),
                        activeColor: Colors.blue),
                    onTap: () => setState(() => _groupValue = 1),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.star, color: Colors.white, size: 22)),
                    title: const Text('Close Friends',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text('Add people',
                        style: TextStyle(color: Colors.grey[400])),
                    trailing: Radio<int>(
                        value: 2,
                        groupValue: _groupValue,
                        onChanged: (int? value) =>
                            setState(() => _groupValue = value!),
                        activeColor: Colors.blue),
                    onTap: () => setState(() => _groupValue = 2),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                        backgroundColor: Color(0xFF383838),
                        child: Icon(Icons.send,
                            color: Colors.white,
                            size: 20,
                            textDirection: TextDirection.rtl)),
                    title: const Text('Message',
                        style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white, size: 16),
                    onTap: () {},
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleShare,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Share',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {
        _isBottomSheetVisible = false;
      });
    });
  }

  Future<bool> _onWillPop() async {
    if (_mode == StoryPreviewMode.music || _mode == StoryPreviewMode.layout) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Discard edits?',
              style: TextStyle(color: Colors.white)),
          content: const Text(
              "If you go back now, you'll lose all the edits you've made.",
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Save draft',
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep editing',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _vinylController.dispose();
    _audioPlayer.dispose();
    _playbackTimer?.cancel();
    _videoController?.dispose();
    _captionController.dispose();
    _captionFocusNode.removeListener(_onFocusChange);
    _captionFocusNode.dispose();
    super.dispose();
  }

  void _cycleMusicStyle() {
    setState(() {
      switch (_musicStyle) {
        case MusicDisplayStyle.vinyl:
          _musicStyle = MusicDisplayStyle.largeCard;
          break;
        case MusicDisplayStyle.largeCard:
          _musicStyle = MusicDisplayStyle.smallCard;
          break;
        case MusicDisplayStyle.smallCard:
          _musicStyle = MusicDisplayStyle.vinyl;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.black,
        statusBarColor: Colors.transparent,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            // Cegah dialog discard muncul saat menutup dengan gestur
            if (_scale < 1.0) return;

            if (_isEditingMusic) {
              setState(() => _isEditingMusic = false);
              return;
            }
            if (_isEditingCaption) {
              FocusScope.of(context).unfocus();
              return;
            }
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            // --- Latar belakang Scaffold dibuat transparan ---
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            // --- Body dibungkus dengan Dismissible ---
            body: Dismissible(
              key: const Key('story-preview-dismissible'),
              direction: DismissDirection.down,
              onDismissed: (_) => Navigator.of(context).pop(),
              onUpdate: (details) {
                // Update skala dan opasitas saat digeser
                setState(() {
                  _scale = 1 - (details.progress * 0.2);
                  _opacity = 1 - (details.progress * 0.5);
                });
              },
              child: Opacity(
                opacity: _opacity,
                child: Transform.scale(
                  scale: _scale,
                  // ClipRRect untuk membuat sudut melengkung saat mengecil
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular((1 - _scale) * 32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildBackground(),
                        if (_isLoading)
                          const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),

                        _buildAnimatedMediaContainer(),

                        // Tampilkan stiker musik DI ATAS konten media
                        if (_currentSong != null) _buildMusicPreview(),

                        if (!_isEditingCaption)
                          _isEditingMusic
                              ? _buildMusicEditingTopBar()
                              : _buildAnimatedTopBar(),

                        if (!_isEditingCaption)
                          _isEditingMusic
                              ? _buildMusicEditorBar()
                              : _buildBottomUI(),

                        if (_isEditingCaption) _buildCaptionEditor(),
                        if (_isUploading) _buildUploadingOverlay(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI EDITOR MUSIK ATAS SEKARANG BERFUNGSI ---
  Widget _buildMusicEditingTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Tombol ini sekarang mengganti style stiker musik
                _buildActionButton(Icons.grid_view_outlined,
                    onPressed: _cycleMusicStyle),
                _buildActionButton(Icons.color_lens_outlined),
                _buildActionButton(Icons.discord), // Placeholder
              ],
            ),
            ElevatedButton(
              onPressed: () => setState(() => _isEditingMusic = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicEditorBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.videocam_outlined, size: 22),
                  _buildActionButton(Icons.square_outlined, size: 22),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.black, size: 28),
                  ),
                  _buildActionButton(Icons.videocam_off_outlined, size: 22),
                  _buildActionButton(Icons.more_horiz, size: 22),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_clipDuration.inSeconds.toString(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    Expanded(
                      child: Slider(
                        value: _clipStartPosition.inMilliseconds.toDouble(),
                        min: 0,
                        max: (_totalSongDuration - _clipDuration)
                            .inMilliseconds
                            .toDouble(),
                        // onChanged HANYA memperbarui state posisi, tidak memutar audio
                        onChanged: (val) {
                          setState(() {
                            _clipStartPosition =
                                Duration(milliseconds: val.round());
                          });
                        },
                        // onChangeEnd memutar audio SETELAH pengguna selesai menggeser
                        onChangeEnd: (val) {
                          _playClip; // <-- Musik akan berputar di sini
                        },
                        activeColor: Colors.pinkAccent,
                        inactiveColor: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Waveform Scrubber (Placeholder Visual)
              _buildWaveformPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaveformPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth * 0.8;
        final double position = (_clipStartPosition.inMilliseconds /
                (_totalSongDuration - _clipDuration).inMilliseconds) *
            (maxWidth - 80);

        return Container(
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Latar belakang waveform dummy
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(30, (index) {
                  final height = 10 + (index % 5 * 5.0) + (index % 3 * 3.0);
                  return Container(
                    width: 3,
                    height: height,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              // Jendela pemilih yang bisa digeser
              AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                left: position + (constraints.maxWidth - maxWidth) / 2,
                child: Container(
                  width: 80, // Lebar jendela pemilih
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.yellow, width: 3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(10, (index) {
                      final height = 15 + (index % 4 * 5.0);
                      final color =
                          index < 3 ? Colors.orangeAccent : Colors.grey[300];
                      return Container(
                        width: 3,
                        height: height,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    if (_mode == StoryPreviewMode.music && _currentSong != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_currentSong!.artworkUrl, fit: BoxFit.cover),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    if (_mode == StoryPreviewMode.separate) {
      return _buildMultiPreviewBottomBar();
    }
    return _buildBottomBar();
  }

  Widget _buildAnimatedMediaContainer() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      top: _isBottomSheetVisible
          ? 15.0
          : (_mode == StoryPreviewMode.layout || _mode == StoryPreviewMode.music
              ? 60.0
              : 120.0),
      bottom: _isBottomSheetVisible
          ? 410.0
          : (_mode == StoryPreviewMode.layout || _mode == StoryPreviewMode.music
              ? 100.0
              : 160.0),
      left: _isBottomSheetVisible ? 62.0 : 16.0,
      right: _isBottomSheetVisible ? 62.0 : 16.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        scale: _isBottomSheetVisible ? 0.75 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    // Fungsi ini sekarang HANYA menampilkan media visual (gambar/video/kolase)
    if (_mode == StoryPreviewMode.layout) {
      return RepaintBoundary(
          key: _collageKey, child: CollageLayoutView(assets: widget.assets!));
    }
    // Untuk mode lain (single, separate, bahkan music), tetap tampilkan aset visualnya
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildMediaContent()],
            ),
          ),
        );
      },
    );
  }

  // --- FUNGSI INI DIMODIFIKASI MENJADI PENGATUR UTAMA ---
  Widget _buildMusicPreview() {
    if (_currentSong == null) return const SizedBox.shrink();

    // Gunakan switch untuk memilih widget berdasarkan style saat ini
    switch (_musicStyle) {
      case MusicDisplayStyle.vinyl:
        return _buildVinylPreview();
      case MusicDisplayStyle.largeCard:
        return _buildLargeMusicCard();
      case MusicDisplayStyle.smallCard:
        return _buildSmallMusicCard();
    }
  }

  Widget _buildVinylPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _vinylController,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://i.imgur.com/HgflQqA.png'),
              ),
            ),
            child: Center(
              child: ClipOval(
                child: SizedBox.fromSize(
                  size: const Size.fromRadius(100),
                  child: Image.network(_currentSong!.artworkUrl,
                      fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(_currentSong!.trackName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_currentSong!.artistName,
            style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _buildLargeMusicCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_currentSong!.artworkUrl,
                  width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.equalizer, color: Colors.white),
                const SizedBox(height: 4),
                Text(_currentSong!.trackName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_currentSong!.artistName,
                    style: const TextStyle(color: Colors.white70)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMusicCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(_currentSong!.artworkUrl,
                  width: 24, height: 24, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.equalizer, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${_currentSong!.trackName} • ${_currentSong!.artistName}',
                style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTopBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      top: _isBottomSheetVisible ? -100.0 : 0,
      left: 0,
      right: 0,
      child: _buildTopBarContent(),
    );
  }

  Widget _buildTopBarContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: Colors.black.withOpacity(0.25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(Icons.arrow_back_ios_new,
                      onPressed: () async {
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) {
                      Navigator.of(context).pop();
                    }
                  }),
                  Row(
                    children: [
                      _buildActionButton(Icons.crop_rotate),
                      _buildActionButton(Icons.text_fields),
                      _buildActionButton(Icons.emoji_emotions_outlined),
                      _buildActionButton(Icons.auto_awesome_outlined),
                      if (_mode == StoryPreviewMode.music &&
                          _currentSong != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isEditingMusic = true);
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  NetworkImage(_currentSong!.artworkUrl),
                            ),
                          ),
                        )
                      else
                        _buildActionButton(Icons.music_note_outlined,
                            onPressed: _showMusicPicker),
                      _buildActionButton(Icons.more_horiz),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon,
      {VoidCallback? onPressed, double size = 22}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      // Gunakan Material agar efek ripple berbentuk lingkaran
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed ??
              () {
                print('${icon.codePoint} di-klik');
              },
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black.withOpacity(0.5),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiPreviewBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: Colors.black.withOpacity(0.3),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.assets!.length,
                    itemBuilder: (context, index) {
                      final asset = widget.assets![index];
                      final isSelected = index == _currentIndex;
                      return GestureDetector(
                        onTap: () => _loadAssetAtIndex(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          width: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AssetEntityImage(
                              asset,
                              isOriginal: false,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _showShareBottomSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Next >',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    const String userProfileImageUrl = 'https://i.pravatar.cc/150?img=3';
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEditingCaption = true;
                      });
                    },
                    child: Container(
                      color: Colors.transparent,
                      width: double.infinity,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(userProfileImageUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _captionController.text.isEmpty
                                  ? 'Add a caption...'
                                  : _captionController.text,
                              style: TextStyle(
                                color: _captionController.text.isEmpty
                                    ? Colors.white70
                                    : Colors.white,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStoryButton(
                                label: 'Your stories',
                                iconWidget: const CircleAvatar(
                                    radius: 14,
                                    backgroundImage:
                                        NetworkImage(userProfileImageUrl)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStoryButton(
                                label: 'Close Friends',
                                iconWidget: const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.star,
                                        color: Colors.white, size: 20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios,
                              color: Colors.black, size: 20),
                          onPressed: _showShareBottomSheet,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionEditor() {
    const String userProfileImageUrl = 'https://i.pravatar.cc/150?img=3';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(userProfileImageUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a caption...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: () {
                      print("Caption: ${_captionController.text}");
                      FocusScope.of(context).unfocus();
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent() {
    if (_currentAsset == null) return const SizedBox.shrink();
    if (_currentAsset!.type == AssetType.video) {
      if (_isVideoLoading ||
          _videoController == null ||
          !_videoController!.value.isInitialized) {
        return AssetEntityImage(_currentAsset!, fit: BoxFit.fitWidth);
      }
      return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!));
    } else {
      return AssetEntityImage(_currentAsset!,
          isOriginal: true, fit: BoxFit.fitWidth);
    }
  }

  Widget _buildStoryButton(
      {required String label, required Widget iconWidget}) {
    return Material(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
            onTap: () {
              print('Tombol "$label" di-klik');
            },
            borderRadius: BorderRadius.circular(30),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  iconWidget,
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis))
                ]))));
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Mengunggah Story...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AnimationController>(
        '_vinylController', _vinylController));
    properties.add(DiagnosticsProperty<AnimationController>(
        '_vinylController', _vinylController));
  }
}
