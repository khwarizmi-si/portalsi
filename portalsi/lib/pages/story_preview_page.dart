// lib/pages/story_preview_page.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:portal_si/pages/main_scaffold.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../widgets/music_picker_sheet.dart';
import 'close_friends_page.dart';
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

  User? _currentUser;
  double _scale = 1.0;
  double _opacity = 1.0;

  final GlobalKey _storyContainerKey = GlobalKey();
  final GlobalKey _stickerKey = GlobalKey();

  final AudioPlayer _audioPlayer = AudioPlayer();
  Song? _currentSong;
  late AnimationController _vinylController;
  MusicDisplayStyle _musicStyle = MusicDisplayStyle.vinyl;
  bool _isEditingMusic = false;
  Duration _clipStartPosition = Duration.zero;
  Duration _clipDuration = const Duration(seconds: 15);
  final Duration _totalSongDuration = const Duration(seconds: 30);

  StreamSubscription? _audioPositionSubscription;
  // [ADDED] StreamSubscription untuk mengelola listener status player (playing, paused, dll).
  StreamSubscription? _playerStateSubscription;


  Offset _stickerPosition = Offset.zero;

  // [ADDED] State variable baru untuk melacak proses buffering audio.
  bool _isAudioBuffering = false;

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

    // Listener untuk looping audio.
    _audioPositionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (_currentSong != null && (position >= _clipStartPosition + _clipDuration)) {
        _audioPlayer.seek(_clipStartPosition);
      }
    });

    // [ADDED] Listener untuk status player. Digunakan untuk menghilangkan loading
    // saat audio sudah berhasil diputar (buffering selesai).
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing && _isAudioBuffering) {
        if (mounted) {
          setState(() {
            _isAudioBuffering = false;
          });
        }
      }
    });
  }

  Future<void> _loadInitialContent() async {
    // Jika masuk dengan mode musik saja (tanpa aset)
    if (_mode == StoryPreviewMode.music && _currentAsset == null) {
      await _updateSong(_currentSong!);
    } else { // Jika masuk dengan aset (gambar/video)
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

    // Jika tidak ada lagu dipilih, lanjutkan media sebelumnya
    if (selectedSong == null) {
      if (_currentSong != null) _audioPlayer.resume();
      _videoController?.play();
      return;
    }

    // Jika lagu baru dipilih
    if (mounted) {
      // Perbarui data lagu dan putar
      _updateSong(selectedSong);
      // Langsung masuk ke mode edit musik
      setState(() {
        _isEditingMusic = true;
      });
    }
  }

  Future<void> _updateSong(Song newSong) async {
    if (_currentAsset == null) {
      await _generateGradientFromImageProvider(NetworkImage(newSong.artworkUrl));
    }
    // [ADDED] Tampilkan loading saat lagu baru pertama kali dipilih
    setState(() => _isAudioBuffering = true);
    _playClip(newSong);
    if (mounted) setState(() => _currentSong = newSong);
  }

  void _playClip(Song song) async {
    await _audioPlayer.stop();
    try {
      await _audioPlayer.play(UrlSource(song.previewUrl), position: _clipStartPosition);
    } catch (e) {
      print("Error playing audio clip: $e");
      _showErrorToast("Gagal memutar pratinjau audio.");
      // [ADDED] Sembunyikan loading jika terjadi error
      if (mounted) setState(() => _isAudioBuffering = false);
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

  // Ganti fungsi _loadUserData yang ada dengan yang ini
  Future<void> _loadUserData() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // Panggil fungsi baru untuk mengambil data user lengkap
        final user = await _fetchCurrentUser(token);
        if (mounted) {
          setState(() {
            _token = token;
            _currentUser = user; // Simpan seluruh objek User ke state
            // userId bisa diambil dari objek User jika perlu
            if (user != null) _userId = user.id ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

// [BARU] Tambahkan fungsi ini untuk mengambil detail user dari API
  Future<User?> _fetchCurrentUser(String token) async {
    // Gunakan Dio yang sudah ada di proyek Anda
    final dio = Dio();
    try {
      // Ganti URL ini dengan endpoint API Anda yang mengembalikan data user
      final response = await dio.get(
        'https://api-new.portalsi.com/api/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Parse JSON response menggunakan factory dari user_model.dart
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      // Tangani error jika gagal mengambil data user
      print("Gagal mengambil data user: ${e.response?.data ?? e.message}");
    }
    return null;
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

    // Map untuk menampung data yang akan dikirim
    Map<String, dynamic> dataMap = {};

    // Selalu sertakan caption, meskipun kosong, sesuai dengan contoh Postman
    dataMap['caption'] = _captionController.text;

    // --- BLOK UNTUK STORY DENGAN MUSIK ---
    if (_currentSong != null) {
      dataMap['type'] = 'music';
      dataMap.addAll({
        'music_track_name': _currentSong!.trackName,
        'music_artist_name': _currentSong!.artistName,
        'music_preview_url': _currentSong!.previewUrl,
        'music_album_art_url': _currentSong!.artworkUrl,
        'music_start_position_ms': _clipStartPosition.inMilliseconds,
        'music_display_style': _musicStyle.name,
        'music_clip_duration_ms': _clipDuration.inMilliseconds,
      });

      if (_musicStyle != MusicDisplayStyle.vinyl) {
        // Dapatkan render box dari container dan stiker menggunakan GlobalKey
        final containerContext = _storyContainerKey.currentContext;
        final stickerContext = _stickerKey.currentContext;

        if (containerContext != null && stickerContext != null) {
          final RenderBox containerBox = containerContext.findRenderObject() as RenderBox;
          final RenderBox stickerBox = stickerContext.findRenderObject() as RenderBox;

          // Hitung posisi stiker relatif terhadap container
          final stickerOffset = stickerBox.localToGlobal(
            Offset.zero,
            ancestor: containerBox,
          );

          // Dapatkan ukuran container
          final containerSize = containerBox.size;

          if (containerSize.width > 0 && containerSize.height > 0) {
            // Hitung posisi dalam bentuk persentase
            final relativeX = stickerOffset.dx / containerSize.width;
            final relativeY = stickerOffset.dy / containerSize.height;

            // Tambahkan nilai persentase ke dataMap (TANPA .toInt())
            dataMap.addAll({
              'music_sticker_position_x': relativeX,
              'music_sticker_position_y': relativeY,
            });
          }
        }
      }

      if (_currentAsset != null) {
        final File? mediaFile = await _getMediaFileFromAsset(_currentAsset!);
        if (mediaFile != null) {
          dataMap['media'] = await MultipartFile.fromFile(mediaFile.path, filename: mediaFile.path.split('/').last);
        }
      }

      // --- BLOK UNTUK STORY GAMBAR ATAU VIDEO (TANPA MUSIK) ---
    } else if (_currentAsset != null) {
      final File? mediaFile = await _getMediaFileFromAsset(_currentAsset!);
      if (mediaFile == null) {
        _showErrorToast('Gagal memproses file media.');
        setState(() => _isUploading = false);
        return;
      }

      // [SESUAI POSTMAN] Menambahkan file media ke dalam form data.
      dataMap['media'] = await MultipartFile.fromFile(mediaFile.path, filename: mediaFile.path.split('/').last);

      // [KUNCI] Logika ini sudah benar. Jika tipe aset adalah video,
      // maka nilai 'video' akan dikirim ke API.
      dataMap['type'] = _currentAsset!.type == AssetType.video ? 'video' : 'image';

    } else {
      _showErrorToast('Tidak ada konten untuk diunggah.');
      setState(() => _isUploading = false);
      return;
    }

    // --- PROSES PENGIRIMAN DATA KE API ---

    // Logging untuk debugging (ini sangat membantu)
    print("================ UPLOAD STORY LOG ================");
    print("Endpoint: https://api-new.portalsi.com/api/stories");
    print("Token: Bearer $_token");
    print("--- Form Data ---");
    dataMap.forEach((key, value) {
      if (value is MultipartFile) {
        print("$key: File(name='${value.filename}', length=${value.length})");
      } else {
        print("$key: $value");
      }
    });
    print("================================================");

    final formData = FormData.fromMap(dataMap);

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api-new.portalsi.com/api/stories',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'}),
      );

      print("++++++++++++++ UPLOAD SUCCESS ++++++++++++++");
      print("Status Code: ${response.statusCode}");
      print("Response Data: ${response.data}");
      print("++++++++++++++++++++++++++++++++++++++++++++");

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScaffold()),
              (Route<dynamic> route) => false,
        );
      }
    } on DioException catch (e) {
      print("!!!!!!!!!!!!!! UPLOAD FAILED !!!!!!!!!!!!!!");
      if (e.response != null) {
        print("Status Code: ${e.response?.statusCode}");
        print("Response Data: ${e.response?.data}");
      } else {
        print("Error Message: ${e.message}");
      }
      print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

      String errorMessage = e.response?.data?['message'] ?? e.message ?? "Terjadi kesalahan";
      _showErrorToast('Gagal mengunggah Story: $errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<File?> _getMediaFileFromAsset(AssetEntity asset) async {
    if (_mode == StoryPreviewMode.layout) {
      try {
        final boundary = _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final pngBytes = byteData!.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        return await File('${tempDir.path}/story_layout.png').writeAsBytes(pngBytes);
      } catch (e) {
        return null;
      }
    }
    return await asset.file;
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
    _audioPositionSubscription?.cancel();
    // [MODIFIED] Batalkan juga subscription untuk state player.
    _playerStateSubscription?.cancel();
    _videoController?.dispose();
    _captionController.dispose();
    _captionFocusNode.removeListener(_onFocusChange);
    _captionFocusNode.dispose();
    super.dispose();
  }

  void _cycleMusicStyle() {
    setState(() {
      switch (_musicStyle) {
        case MusicDisplayStyle.vinyl: _musicStyle = MusicDisplayStyle.largeCard; break;
        case MusicDisplayStyle.largeCard: _musicStyle = MusicDisplayStyle.smallCard; break;
        case MusicDisplayStyle.smallCard: _musicStyle = MusicDisplayStyle.vinyl; break;
      }
      if (_musicStyle == MusicDisplayStyle.vinyl) {
        _stickerPosition = Offset.zero;
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
            resizeToAvoidBottomInset: false,
            body: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),

                _buildAnimatedMediaContainer(),

                if (!_isEditingCaption)
                  _isEditingMusic ? _buildMusicEditingTopBar() : _buildAnimatedTopBar(),

                if (!_isEditingCaption)
                  _isEditingMusic ? _buildMusicEditorBar() : _buildBottomUI(),

                if (_isEditingCaption) _buildCaptionEditor(),
                if (_isUploading) _buildUploadingOverlay(),

                // [ADDED] Widget overlay untuk menampilkan loading spinner saat audio buffering.
                if (_isAudioBuffering)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicEditingTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildActionButton(Icons.grid_view_outlined,
                    onPressed: _cycleMusicStyle),
                _buildActionButton(Icons.color_lens_outlined),
                _buildActionButton(Icons.discord),
              ],
            ),
            ElevatedButton(
              onPressed: () => setState(() => _isEditingMusic = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
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
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const Text("Edit clip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildDurationSelector(),
              const SizedBox(height: 16),
              _buildClipSlider(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final List<int> durationOptions = [5, 10, 15];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: durationOptions.map((seconds) {
        final isSelected = _clipDuration.inSeconds == seconds;
        return GestureDetector(
          onTap: () {
            setState(() {
              _clipDuration = Duration(seconds: seconds);
              if (_clipStartPosition > (_totalSongDuration - _clipDuration)) {
                _clipStartPosition = _totalSongDuration - _clipDuration;
                if (_clipStartPosition.isNegative) {
                  _clipStartPosition = Duration.zero;
                }
              }
              // [ADDED] Tampilkan loading juga saat durasi diubah
              _isAudioBuffering = true;
            });
            if (_currentSong != null) _playClip(_currentSong!);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              "$seconds s",
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildClipSlider() {
    final maxSliderValue = (_totalSongDuration - _clipDuration).inMilliseconds.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Slider(
        value: _clipStartPosition.inMilliseconds.toDouble().clamp(0.0, maxSliderValue),
        min: 0,
        max: maxSliderValue < 0 ? 0 : maxSliderValue,
        onChanged: (val) {
          setState(() {
            _clipStartPosition = Duration(milliseconds: val.round());
          });
        },
        // [MODIFIED] onChangeEnd sekarang akan memicu tampilan loading.
        onChangeEnd: (val) {
          if (_currentSong != null) {
            setState(() {
              _isAudioBuffering = true;
            });
            _playClip(_currentSong!);
          }
        },
        activeColor: Colors.white,
        inactiveColor: Colors.white.withOpacity(0.3),
      ),
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
      top: _isBottomSheetVisible ? 15.0 : 60.0,
      bottom: _isBottomSheetVisible ? 410.0 : 100.0,
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
            key: _storyContainerKey, // [TERAPKAN KEY DI SINI]
            borderRadius: BorderRadius.circular(24.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMainContent(),
                if (_currentSong != null)
                  Center(
                    child: Transform.translate(
                      offset: _stickerPosition,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (_isEditingMusic &&
                              _musicStyle != MusicDisplayStyle.vinyl) {
                            setState(() {
                              _stickerPosition += details.delta;
                            });
                          }
                        },
                        // [BUNGKUS WIDGET MUSIK DENGAN KEY]
                        child: KeyedSubtree(
                          key: _stickerKey,
                          child: _buildMusicPreview(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_mode == StoryPreviewMode.layout) {
      return RepaintBoundary(
          key: _collageKey, child: CollageLayoutView(assets: widget.assets!));
    }
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

  Widget _buildMusicPreview() {
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
      mainAxisSize: MainAxisSize.min,
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
    return Container(
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
    );
  }

  Widget _buildSmallMusicCard() {
    return Container(
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
                      if (_currentSong != null)
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

  void _showSharingOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        // StatefulBuilder untuk mengelola state di dalam bottom sheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // State untuk pilihan share
            bool shareToStory = true;
            bool shareToFacebook = true;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle (garis abu-abu di atas)
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

                  // Judul
                  const Text(
                    'Share this to',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pilihan 1: Your Story
                  _buildShareOptionTile(
                    avatarUrl: _currentUser?.profilePictureUrl,
                    title: 'Your Story',
                    subtitle: 'Always shared to Instagram',
                    isSelected: shareToStory,
                    onTap: () {
                      setModalState(() {
                        shareToStory = !shareToStory;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Pilihan 2: Your Facebook Story
                  _buildShareOptionTile(
                    avatarUrl: 'https://i.pravatar.cc/150?img=5', // Ganti dengan URL yang sesuai
                    title: 'Your Facebook Story',
                    subtitle: '${_currentUser?.fullName ?? 'Anda'} • Friends',
                    isSelected: shareToFacebook,
                    hasFacebookIcon: true,
                    onTap: () {
                      setModalState(() {
                        shareToFacebook = !shareToFacebook;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  // Tombol Share
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Tutup bottom sheet, lalu jalankan fungsi share
                        Navigator.pop(context);
                        _handleShare();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

// [BARU] Tambahkan juga method helper ini untuk membuat baris pilihan
  Widget _buildShareOptionTile({
    required String? avatarUrl,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool hasFacebookIcon = false,
  }) {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(avatarUrl ?? placeholderUrl),
              ),
              if (hasFacebookIcon)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2E), // Warna latar belakang sheet
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFF1877F2), // Warna Facebook
                      child: Icon(Icons.facebook, color: Colors.white, size: 14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue : Colors.transparent,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey[600]!,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ],
      ),
    );
  }

  // Ganti seluruh method _buildBottomBar dengan yang ini
  Widget _buildBottomBar() {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    // Variabel userProfileImageUrl sudah tidak diperlukan di sini
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
                          // [MODIFIKASI 1] CircleAvatar untuk "Add a caption..."
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              _currentUser?.profilePictureUrl ?? placeholderUrl,
                            ),
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
                                // Aksi untuk klik sekali (langsung post)
                                onTap: _handleShare,
                                // Aksi untuk tekan lama (tampilkan bottom sheet)
                                onLongPress: _showSharingOptionsBottomSheet,
                                iconWidget: CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(
                                    _currentUser?.profilePictureUrl ?? placeholderUrl,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStoryButton(
                                label: 'Close Friends',
                                onTap: _showCloseFriendsPage, // Pastikan fungsi ini sudah ada
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

  void _showCloseFriendsPage() {
    Navigator.of(context).push(_createSlideUpRoute());
  }

// Fungsi untuk membuat animasi slide dari bawah ke atas
  Route _createSlideUpRoute() {
    return PageRouteBuilder(
      // Halaman tujuan
      pageBuilder: (context, animation, secondaryAnimation) => const CloseFriendsPage(),
      // Logika transisi
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // Mulai dari bawah layar
        const end = Offset.zero;      // Selesai di tengah layar
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  Widget _buildCaptionEditor() {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    // Variabel userProfileImageUrl sudah tidak diperlukan di sini
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
                // [MODIFIKASI 3] CircleAvatar di editor caption
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    _currentUser?.profilePictureUrl ?? placeholderUrl,
                  ),
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

  // Ganti method _buildStoryButton yang sudah ada dengan yang ini

  Widget _buildStoryButton({
    required String label,
    required Widget iconWidget,
    VoidCallback? onTap, // Tambahkan parameter onTap
    VoidCallback? onLongPress,
  }) {
    return Material(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          // Gunakan parameter onTap, jika tidak ada, jalankan print
            onTap: onTap ?? () {
              print('Tombol "$label" di-klik');
            },
            onLongPress: onLongPress,
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