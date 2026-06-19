import 'package:portal_si/config/api_endpoint.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:portal_si/pages/main_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/song_model.dart';
import '../models/user_model.dart';
import '../providers/navigation_provider.dart';
import '../providers/upload_provider.dart';
import '../widgets/music_picker_sheet.dart';
import 'close_friends_page.dart';
import 'dashboard_page.dart';
import '../utils/secure_storage.dart';
import '../widgets/collage_layout_view.dart';
import 'package:crop_image/crop_image.dart';
import 'package:image_picker/image_picker.dart';

// --- SALINAN MODEL & ENUM DARI text_overlay_model.dart ---
enum TextBackgroundStyle { none, semiTransparent, solid }

class TextOverlay {
  String text;
  Offset position;
  Color color;
  double scale;
  double rotation;
  FontWeight fontWeight;
  TextBackgroundStyle backgroundStyle;
  String fontFamily;
  TextAlign textAlign;
  final bool isLink;
  final String? url;

  TextOverlay({
    required this.text,
    this.position = const Offset(100, 150),
    this.color = Colors.white,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.fontWeight = FontWeight.bold,
    this.backgroundStyle = TextBackgroundStyle.semiTransparent,
    this.fontFamily = 'Roboto',
    this.textAlign = TextAlign.center,
    this.isLink = false,
    this.url,
  });

  TextOverlay copyWith({
    String? text,
    Offset? position,
    Color? color,
    double? scale,
    double? rotation,
    FontWeight? fontWeight,
    TextBackgroundStyle? backgroundStyle,
    String? fontFamily,
    TextAlign? textAlign,
    bool? isLink,
    String? url,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      position: position ?? this.position,
      color: color ?? this.color,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      fontWeight: fontWeight ?? this.fontWeight,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      isLink: isLink ?? this.isLink,
      url: url ?? this.url,
    );
  }
}
// --- AKHIR SALINAN MODEL & ENUM ---

// --- MODEL DRAWING (diperlukan untuk fungsi corat-coret) ---
class DrawingPath {
  final Path path;
  final Paint paint;
  DrawingPath({required this.path, required this.paint});
}
// --- AKHIR MODEL DRAWING ---

enum StoryPreviewMode { single, separate, layout, music }
enum MusicDisplayStyle { vinyl, largeCard, smallCard, style3, style4 }

class StoryPreviewPage extends StatefulWidget {
  final List<AssetEntity>? assets;
  final Song? song;
  final StoryPreviewMode mode;
  final Uint8List? imageBytes;

  const StoryPreviewPage({
    super.key,
    this.assets,
    this.song,
    this.mode = StoryPreviewMode.single,
    this.imageBytes,
  }) : assert(assets != null || song != null || imageBytes != null,
  'assets, song, atau imageBytes harus disediakan');

  @override
  State<StoryPreviewPage> createState() => _StoryPreviewPageState();
}

class _StoryPreviewPageState extends State<StoryPreviewPage>
    with TickerProviderStateMixin {
  final GlobalKey _collageKey = GlobalKey();
  final GlobalKey _repaintKey = GlobalKey(); // Kunci RepaintBoundary untuk menangkap drawing/text
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
  int _musicStyleIndex = 0;
  bool _isEditingMusic = false;
  Duration _clipStartPosition = Duration.zero;
  Duration _clipDuration = const Duration(seconds: 15);
  final Duration _totalSongDuration = const Duration(seconds: 30);
  StreamSubscription? _audioPositionSubscription;
  StreamSubscription? _playerStateSubscription;
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

  Offset _stickerPosition = Offset.zero;
  double _stickerScale = 1.0;
  double _stickerRotation = 0.0;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  // --- STATE UNTUK EDITING (TEKS DAN DRAWING) ---
  bool _isTextEditingMode = false;
  bool _isDrawingMode = false;
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _activeTextOverlay;
  final List<DrawingPath> _drawingPaths = [];
  Path? _currentPath;
  Color _currentDrawingColor = Colors.white;
  double _currentStrokeWidth = 5.0;


  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _mode = StoryPreviewMode.single;
    } else if (widget.song != null) {
      _mode = StoryPreviewMode.music;
      _currentSong = widget.song;
    } else if (widget.assets != null && widget.assets!.isNotEmpty) {
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

    _audioPositionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      if (_currentSong != null && (position >= _clipStartPosition + _clipDuration)) {
        _audioPlayer.seek(_clipStartPosition);
      }
    });

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

  @override
  void dispose() {
    _vinylController.dispose();
    _audioPlayer.dispose();
    _audioPositionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _videoController?.dispose();
    _captionController.dispose();
    _captionFocusNode.removeListener(_onFocusChange);
    _captionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialContent() async {
    if (widget.imageBytes != null) {
      setState(() => _isLoading = true);
      await _generateGradientFromImageProvider(MemoryImage(widget.imageBytes!));
      setState(() => _isLoading = false);
    } else if (_mode == StoryPreviewMode.music && _currentAsset == null) {
      await _updateSong(_currentSong!);
    } else {
      await _loadAssetAtIndex(_currentIndex);
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
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
      if (_currentSong != null) _audioPlayer.resume();
      _videoController?.play();
      return;
    }
    if (mounted) {
      _updateSong(selectedSong);
      setState(() => _isEditingMusic = true);
    }
  }

  Future<void> _updateSong(Song newSong) async {
    if (_currentAsset == null) {
      await _generateGradientFromImageProvider(NetworkImage(newSong.artworkUrl));
    }
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
    final thumbData = await _currentAsset!.thumbnailDataWithSize(const ThumbnailSize(100, 100));
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
      setState(() => _isEditingCaption = _captionFocusNode.hasFocus);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final user = await _fetchCurrentUser(token);
        if (mounted) {
          setState(() {
            _token = token;
            _currentUser = user;
            if (user != null) _userId = user.id ?? 0;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<User?> _fetchCurrentUser(String token) async {
    final dio = Dio();
    try {
      final response = await dio.get('${ApiEndpoints.apiUrl}/user', options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}));
      if (response.statusCode == 200 && response.data != null) {
        return User.fromJson(response.data);
      }
    } on DioException catch (e) {
      print("Gagal mengambil data user: ${e.response?.data ?? e.message}");
    }
    return null;
  }

  Future<void> _generateGradientFromImageProvider(ImageProvider provider) async {
    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(provider);
      final Color dominantColor = palette.dominantColor?.color ?? Colors.black;
      final Color vibrantColor = palette.vibrantColor?.color ?? dominantColor;
      if (mounted) {
        setState(() => _gradientColors = [vibrantColor, dominantColor]);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _gradientColors = [const Color(0xFF1A1A1A), Colors.black]);
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_currentAsset == null) return;
    setState(() => _isVideoLoading = true);
    if (kIsWeb) {
      try {
        final String? url = await _currentAsset!.getMediaUrl();
        if (url == null) {
          throw Exception("Gagal mendapatkan URL video untuk web.");
        }
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
        await _videoController!.initialize();
        if (mounted) {
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() => _isVideoLoading = false);
        }
      } catch (e) {
        print("Error inisialisasi video di web: $e");
        if (mounted) setState(() => _isVideoLoading = false);
        _showErrorToast("Gagal memuat video.");
      }
    } else {
      final File? videoFile = await _currentAsset!.file;
      if (videoFile == null) {
        if (mounted) setState(() => _isVideoLoading = false);
        return;
      }
      _videoController = VideoPlayerController.file(videoFile)
        ..initialize().then((_) {
          if (mounted) {
            _videoController!.setLooping(true);
            _videoController!.play();
            setState(() => _isVideoLoading = false);
          }
        });
    }
  }

  Future<void> _handleShare() async {
    final uploadProvider = Provider.of<UploadProvider>(context, listen: false);
    if (uploadProvider.isUploading) {
      _showErrorToast('Harap tunggu unggahan sebelumnya selesai.');
      return;
    }

    // Tampilkan loading sementara untuk persiapan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, String> fields = {'caption': _captionController.text};

      log('--- 🕵️‍♂️ Debugging _handleShare ---', name: 'StoryPreview');
      log('Nilai _gradientColors sebelum diproses: $_gradientColors', name: 'StoryPreview');

      if (_gradientColors.isNotEmpty) {
        // 2. Ubah List<Color> menjadi List<String> (kode hex)
        final List<String> hexPalette = _gradientColors.map(_colorToHex).toList();

        // 3. Ubah list string menjadi satu JSON string
        final String paletteJsonString = jsonEncode(hexPalette);

        // 4. Tambahkan ke 'fields' yang akan dikirim ke API
        fields['color_pallete'] = paletteJsonString;
      }

      File? finalMediaFile;
      Uint8List? thumbnailData;

      log('Final `fields` yang akan dikirim ke provider: ${jsonEncode(fields)}', name: 'StoryPreview');
      log('------------------------------------', name: 'StoryPreview');

      final bool hasOverlays = _textOverlays.isNotEmpty || _drawingPaths.isNotEmpty;

      // 1. Dapatkan File Media dan Thumbnail
      if (hasOverlays && _currentAsset != null && _currentAsset!.type == AssetType.image) {
        final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception('Gagal konversi data gambar.');

        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        finalMediaFile = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_final_story.png').create();
        await finalMediaFile.writeAsBytes(pngBytes);

        fields['type'] = 'image';
        thumbnailData = pngBytes;

      } else if (widget.imageBytes != null) { // Handle upload dari web
        final tempDir = await getTemporaryDirectory();
        finalMediaFile = await File('${tempDir.path}/web_image.png').writeAsBytes(widget.imageBytes!);
        fields['type'] = 'image';
        thumbnailData = widget.imageBytes;

      } else if (_currentAsset != null) {
        finalMediaFile = await _getMediaFileFromAsset(_currentAsset!);
        if (finalMediaFile == null) throw Exception('Gagal memproses file media.');
        fields['type'] = _currentAsset!.type == AssetType.video ? 'video' : 'image';

        if (_currentAsset!.type == AssetType.video) {
          thumbnailData = await VideoThumbnail.thumbnailData(
              video: finalMediaFile.path, imageFormat: ImageFormat.JPEG, maxWidth: 128, quality: 25
          );
        } else {
          thumbnailData = await finalMediaFile.readAsBytes();
        }
      }

      // 2. Tambahkan data musik jika ada
      if (_currentSong != null) {
        fields['type'] = 'music';
        fields.addAll({
          'music_track_name': _currentSong!.trackName,
          'music_artist_name': _currentSong!.artistName,
          'music_preview_url': _currentSong!.previewUrl,
          'music_album_art_url': _currentSong!.artworkUrl,
          'music_start_position_ms': _clipStartPosition.inMilliseconds.toString(),
          'music_display_style': MusicDisplayStyle.values[_musicStyleIndex].name,
          'music_clip_duration_ms': _clipDuration.inMilliseconds.toString(),
        });
        // Jika thumbnail belum ada (mode musik murni), ambil dari artwork
        thumbnailData ??= (await NetworkAssetBundle(Uri.parse(_currentSong!.artworkUrl)).load(_currentSong!.artworkUrl)).buffer.asUint8List();
      }

      // Validasi Akhir
      if (thumbnailData == null) throw Exception("Gagal membuat thumbnail untuk diunggah.");
      if (finalMediaFile == null && fields['type'] != 'music') throw Exception("Media tidak ditemukan.");

      // 3. Mulai Unggahan di Latar Belakang
      uploadProvider.startUpload(
        type: UploadType.story,
        fields: fields,
        mediaFile: finalMediaFile,
        thumbnail: thumbnailData,
      );

      // --- 👇 PERBAIKAN UTAMA DI SINI JUGA 👇 ---
      // 1. Dapatkan NavigationProvider.
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);

      // 2. Perintahkan untuk pindah ke tab 0 (Beranda).
      navProvider.navigateToTab(0);
      // --- AKHIR PERBAIKAN ---

      // 4. Tutup semua halaman dan kembali ke dashboard
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);

    } catch (e) {
      log("❌ Gagal memulai proses unggah story: $e");
      if (mounted) Navigator.of(context).pop(); // Tutup dialog loading
      _showErrorToast('Gagal memulai unggahan: ${e.toString()}');
    }
  }

  Future<File?> _getMediaFileFromAsset(AssetEntity asset) async {
    // --- PERBAIKAN BUG: Cek apakah ID dan relativePath sama (yang menunjukkan dummy asset) ---
    if (asset.relativePath != null && asset.id == asset.relativePath!) {

      final File croppedFile = File(asset.relativePath!);
      if (await croppedFile.exists()) {
        return croppedFile; // Langsung kembalikan File hasil crop dari path sementara.
      }
    }
    // --- BATAS PERBAIKAN ---

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

  void _showErrorToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.green, textColor: Colors.white, fontSize: 16.0);
  }

  void _showShareBottomSheet() {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    HapticFeedback.lightImpact();
    setState(() => _isBottomSheetVisible = true);
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFFFF),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            int _groupValue = 1;
            const String userProfileImageUrl = 'https://i.pravatar.cc/150?img=3';
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 24),
                  const Text('Bagikan', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(radius: 18, backgroundImage: NetworkImage(_currentUser?.profilePictureUrl ?? placeholderUrl)),
                    title: const Text('Cerita Anda', style: TextStyle(color: Colors.black)),
                    subtitle: Text('akan diunggah sebagai cerita Anda', style: TextStyle(color: Colors.grey[400])),
                    trailing: Radio<int>(value: 1, groupValue: _groupValue, onChanged: (int? value) => setState(() => _groupValue = value!), activeColor: Colors.blue),
                    onTap: () => setState(() => _groupValue = 1),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleShare,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text('Bagikan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => setState(() => _isBottomSheetVisible = false));
  }

  Future<bool> _onWillPop() async {
    if (_mode == StoryPreviewMode.music || _mode == StoryPreviewMode.layout || _isDrawingMode || _textOverlays.isNotEmpty) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Discard edits?', style: TextStyle(color: Colors.white)),
          content: const Text("If you go back now, you'll lose all the edits you've made.", style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Discard', style: TextStyle(color: Colors.redAccent))),
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Save draft', style: TextStyle(color: Colors.white))),
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep editing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  // --- FUNGSI UNTUK CROPPING GAMBAR ---
  Future<void> _cutCurrentImage() async {
    if (_currentAsset == null || _currentAsset!.type != AssetType.image) {
      _showErrorToast("Fitur crop hanya untuk gambar.");
      return;
    }

    _audioPlayer.pause();
    _videoController?.pause();
    HapticFeedback.lightImpact();

    try {
      final File? originalFile = await _currentAsset!.file;
      if (originalFile == null) {
        _showErrorToast("Gagal mendapatkan file gambar.");
        return;
      }

      final File? croppedFile = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImageCropperPage(
            imageFile: originalFile,
            isBanner: false,
            initialAspectRatio: 9/16, // Default story ratio
          ),
          fullscreenDialog: true,
        ),
      );

      _audioPlayer.resume();
      _videoController?.play();

      if (croppedFile != null && mounted) {

        // WORKAROUND: Buat AssetEntity DUMMY. ID = Path File untuk konsistensi deteksi.
        final dummyAsset = AssetEntity(
          id: croppedFile.path, // ID = Path File
          typeInt: AssetType.image.index,
          width: 0,
          height: 0,
          duration: 0,
          relativePath: croppedFile.path, // relativePath = Path File
        );

        setState(() {
          _currentAsset = dummyAsset;
        });

        HapticFeedback.mediumImpact();
        _showSuccessToast("Gambar berhasil dipotong dan siap diunggah!");
      }

    } catch (e) {
      print("Error cutting image: $e");
      _showErrorToast("Gagal memotong gambar.");
      _audioPlayer.resume();
      _videoController?.play();
    }
  }
  // --- BATAS FUNGSI CROPPING GAMBAR ---

  // --- FUNGSI BARU UNTUK EDITING TEKS ---
  void _showTextInputDialog() async {
    _audioPlayer.pause();
    _videoController?.pause();

    final textController = TextEditingController();
    final String? newText = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            title: const Text('Masukkan Teks', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Tulis sesuatu...'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(textController.text), child: const Text('Selesai'))
            ]
        )
    );

    _audioPlayer.resume();
    _videoController?.play();

    if (newText != null && newText.isNotEmpty) {
      setState(() {
        // Menggunakan properti TextOverlay yang default (bold, semiTransparent)
        final newOverlay = TextOverlay(text: newText, position: const Offset(100, 150));
        _textOverlays.add(newOverlay);
        _showTextOptionsSheet(newOverlay);
        _isTextEditingMode = true;
      });
    }
  }

  void _showTextOptionsSheet(TextOverlay overlay) {
    _audioPlayer.pause();
    _videoController?.pause();
    setState(() => _activeTextOverlay = overlay);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _buildTextEditorColorOption(Colors.white, setSheetState),
                      _buildTextEditorColorOption(Colors.black, setSheetState),
                      _buildTextEditorColorOption(Colors.red, setSheetState),
                      _buildTextEditorColorOption(Colors.blue, setSheetState),
                      _buildTextEditorColorOption(Colors.yellow, setSheetState),
                    ]),
                    const Divider(color: Colors.grey, height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      TextButton.icon(
                          onPressed: () {
                            setState(() {
                              final currentStyleIndex = overlay.backgroundStyle.index;
                              final nextStyleIndex = (currentStyleIndex + 1) % TextBackgroundStyle.values.length;
                              overlay.backgroundStyle = TextBackgroundStyle.values[nextStyleIndex];
                            });
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.format_color_text, color: Colors.white),
                          label: const Text('Gaya', style: TextStyle(color: Colors.white))
                      ),
                      TextButton.icon(
                          onPressed: () {
                            setState(() => overlay.fontWeight = overlay.fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold);
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.format_bold, color: Colors.white),
                          label: const Text('Tebal', style: TextStyle(color: Colors.white))
                      ),
                      TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _textOverlays.remove(overlay);
                              _activeTextOverlay = null;
                            });
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Hapus', style: TextStyle(color: Colors.red))
                      ),
                    ])
                  ]
              )
          );
        },
      ),
    ).whenComplete(() {
      _audioPlayer.resume();
      _videoController?.play();
      setState(() => _activeTextOverlay = null);
    });
  }

  Widget _buildTextEditorColorOption(Color color, StateSetter setSheetState) {
    bool isSelected = _activeTextOverlay?.color == color;
    return GestureDetector(
      onTap: () {
        setState(() => _activeTextOverlay!.color = color);
        setSheetState(() {});
      },
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.blue, width: 2) : null
          )
      ),
    );
  }

  // --- FUNGSI BARU UNTUK DRAWING (CORAT CORET) ---
  void _toggleDrawingMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (_isDrawingMode) {
        _audioPlayer.pause();
        _videoController?.pause();
      } else {
        _audioPlayer.resume();
        _videoController?.play();
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDrawingMode) return;
    _currentPath = Path()..moveTo(details.localPosition.dx, details.localPosition.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawingMode || _currentPath == null) return;
    setState(() => _currentPath!.lineTo(details.localPosition.dx, details.localPosition.dy));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawingMode || _currentPath == null) return;
    setState(() {
      _drawingPaths.add(DrawingPath(path: _currentPath!, paint: Paint()..color = _currentDrawingColor..strokeWidth = _currentStrokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round));
      _currentPath = null;
    });
  }

  // Tombol undo di Drawing mode
  void _undoDrawing() {
    setState(() {
      if(_drawingPaths.isNotEmpty) _drawingPaths.removeLast();
    });
  }

  // Tombol warna di Drawing mode
  void _setDrawingColor(Color color) {
    setState(() => _currentDrawingColor = color);
  }
  // --- AKHIR FUNGSI BARU ---


  MusicDisplayStyle get _currentMusicStyle => MusicDisplayStyle.values[_musicStyleIndex];

  Widget _buildMusicPreview() {
    switch (_currentMusicStyle) {
      case MusicDisplayStyle.vinyl: return _buildVinylPreview();
      case MusicDisplayStyle.largeCard: return _buildLargeMusicCard();
      case MusicDisplayStyle.smallCard: return _buildSmallMusicCard();
      default: return _buildSmallMusicCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mode editing aktif jika isDrawingMode, isEditingMusic, atau _isTextEditingMode aktif
    final bool isEditingActive = _isDrawingMode || _isEditingMusic || _isTextEditingMode;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: Colors.transparent, statusBarColor: Colors.transparent),
      child: GestureDetector(
        // Hanya unfocus jika tidak di mode drawing/music/text
        onTap: () {
          if (!_isDrawingMode && !_isEditingMusic && !_isTextEditingMode) {
            FocusScope.of(context).unfocus();
          }
        },
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (didPop) return;
            if (_scale < 1.0) return;
            if (_isEditingMusic) {
              setState(() => _isEditingMusic = false);
              return;
            }
            if (_isDrawingMode) {
              _toggleDrawingMode(); // Keluar dari mode drawing
              return;
            }
            if (_isTextEditingMode) {
              setState(() => _isTextEditingMode = false); // Keluar dari mode teks
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
                if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),
                _buildAnimatedMediaContainer(),
                // Sembunyikan top bar saat mode editing non-music/caption aktif
                if (!_isEditingCaption && !isEditingActive) _buildAnimatedTopBar(),

                if (_isEditingMusic) _buildMusicEditingTopBar(),
                if (_isEditingMusic) _buildMusicStyleSelector(),

                // Tampilkan bottom UI sesuai mode
                if (!_isEditingCaption && !isEditingActive) _buildBottomUI(),
                if (_isDrawingMode) _buildDrawingBottomBar(),

                if (_isEditingCaption) _buildCaptionEditor(),
                if (_isUploading) _buildUploadingOverlay(),
                if (_isAudioBuffering)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawingBottomBar() {
    return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: _undoDrawing),
                      ...[Colors.white, Colors.red, Colors.blue, Colors.yellow, Colors.green].map((color) => GestureDetector(
                          onTap: () => _setDrawingColor(color),
                          child: CircleAvatar(
                              radius: 14,
                              backgroundColor: color,
                              child: _currentDrawingColor == color ? const Icon(Icons.check, size: 16, color: Colors.black) : null
                          )
                      )),
                      ElevatedButton(onPressed: _toggleDrawingMode, child: const Text('Selesai')),
                    ]
                )
            )
        )
    );
  }


  Widget _buildMusicEditingTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 16.0,
      child: ElevatedButton(
        onPressed: () => setState(() => _isEditingMusic = false),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        child: const Text("Selesai", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMusicStyleSelector() {
    final List<IconData> styleIcons = [Icons.music_note, Icons.square, Icons.waves,];
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 70,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: styleIcons.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final isSelected = _musicStyleIndex == index;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _musicStyleIndex = index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 50,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Icon(styleIcons[index], color: isSelected ? Colors.white : Colors.white.withOpacity(0.7), size: 24),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDurationPicker() {
    final maxDuration = _totalSongDuration.inSeconds;
    final List<int> durationOptions = List<int>.generate(maxDuration, (i) => i + 1);
    final FixedExtentScrollController scrollController = FixedExtentScrollController(initialItem: _clipDuration.inSeconds - 1);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        int selectedValue = _clipDuration.inSeconds;
        return Container(
          height: 350,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12))),
              const SizedBox(height: 16),
              const Text('Pilih durasi klip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 50,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) => selectedValue = durationOptions[index],
                  childDelegate: ListWheelChildLoopingListDelegate(
                    children: durationOptions.map((seconds) => Center(child: Text('$seconds SECONDS', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)))).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _clipDuration = Duration(seconds: selectedValue);
                        if (_clipStartPosition > (_totalSongDuration - _clipDuration)) {
                          _clipStartPosition = _totalSongDuration - _clipDuration;
                          if (_clipStartPosition.isNegative) _clipStartPosition = Duration.zero;
                        }
                        _isAudioBuffering = true;
                      });
                      if (_currentSong != null) _playClip(_currentSong!);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Selesai'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMusicClipEditor() {
    final maxSliderValue = (_totalSongDuration - _clipDuration).inMilliseconds.toDouble();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 24, top: 16),
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.9)])),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showDurationPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Center(child: Text(_clipDuration.inSeconds.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: _clipStartPosition.inMilliseconds.toDouble().clamp(0.0, maxSliderValue),
                    min: 0,
                    max: maxSliderValue < 0 ? 0 : maxSliderValue,
                    onChanged: (val) => setState(() => _clipStartPosition = Duration(milliseconds: val.round())),
                    onChangeEnd: (val) {
                      if (_currentSong != null) {
                        setState(() => _isAudioBuffering = true);
                        _playClip(_currentSong!);
                      }
                    },
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_mode == StoryPreviewMode.music && _currentSong != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(_currentSong!.artworkUrl, fit: BoxFit.cover),
          BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0), child: Container(color: Colors.black.withOpacity(0.4))),
        ],
      );
    }
    return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors, begin: Alignment.topCenter, end: Alignment.bottomCenter)));
  }

  Widget _buildBottomUI() {
    if (_mode == StoryPreviewMode.separate) {
      return _buildMultiPreviewBottomBar();
    }
    return _buildBottomBar();
  }

  Widget _buildAnimatedMediaContainer() {
    // Tentukan apakah gestur untuk teks harus aktif
    final bool isGestureActive = !_isEditingMusic && _textOverlays.isNotEmpty;

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
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24.0)),
          child: ClipRRect(
            key: _storyContainerKey,
            borderRadius: BorderRadius.circular(24.0),
            child: RepaintBoundary( // <--- BUNGKUS DENGAN REPAINTBOUNDARY BARU
              key: _repaintKey,    // <--- PINDAHKAN KUNCI DI SINI
              child: Stack(
                // HAPUS key: _repaintKey dari Stack
                fit: StackFit.expand,
                children: [
                  _buildMainContent(),

                  // KANVAS MENGGAMBAR DAN INTERAKSI (DIURUTKAN AGAR CORE TAN MUNCUL)

                  // 1. Kanvas Gambar/Jejak Core tan (CustomPaint)
                  CustomPaint(painter: DrawingPainter(paths: _drawingPaths), child: Container()),
                  if (_isDrawingMode && _currentPath != null) CustomPaint(painter: DrawingPainter(paths: [DrawingPath(path: _currentPath!, paint: Paint()..color = _currentDrawingColor..strokeWidth = _currentStrokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round)])),

                  // 2. Area Interaksi Core tan (GestureDetector) - HARUS DI ATAS SEMUANYA
                  if (_isDrawingMode)
                    GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        onPanEnd: _onPanEnd,
                        child: Container(color: Colors.transparent)
                    ),

                  // TEXT OVERLAYS
                  ..._textOverlays.map((overlay) {
                    return Positioned(
                        left: overlay.position.dx,
                        top: overlay.position.dy,
                        child: Transform(
                            transform: Matrix4.identity()
                              ..scale(overlay.scale)
                              ..rotateZ(overlay.rotation),
                            alignment: FractionalOffset.center,
                            child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: isGestureActive ? () => _showTextOptionsSheet(overlay) : null,
                                onScaleStart: isGestureActive ? (details) { _baseScale = overlay.scale; _baseRotation = overlay.rotation; } : null,
                                onScaleUpdate: isGestureActive ? (details) {
                                  setState(() {
                                    overlay.position += details.focalPointDelta;
                                    overlay.scale = (_baseScale * details.scale).clamp(0.5, 3.0);
                                    overlay.rotation = _baseRotation + details.rotation;
                                  });
                                } : null,
                                child: _buildTextOverlayWidget(overlay)
                            )
                        )
                    );
                  }).toList(),

                  if (_currentSong != null)
                    Center(
                      child: GestureDetector(
                        onScaleStart: (details) {
                          if (_isEditingMusic && _currentMusicStyle != MusicDisplayStyle.vinyl) {
                            _baseScale = _stickerScale;
                            _baseRotation = _stickerRotation;
                          }
                        },
                        onScaleUpdate: (details) {
                          if (_isEditingMusic && _currentMusicStyle != MusicDisplayStyle.vinyl) {
                            setState(() {
                              _stickerPosition += details.focalPointDelta;
                              _stickerScale = (_baseScale * details.scale).clamp(0.5, 2.0);
                              _stickerRotation = _baseRotation + details.rotation;
                            });
                          }
                        },
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translate(_stickerPosition.dx, _stickerPosition.dy)
                            ..scale(_stickerScale)
                            ..rotateZ(_stickerRotation),
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
      ),
    );
  }

  Widget _buildTextOverlayWidget(TextOverlay overlay) {
    Color backgroundColor;
    Color textColor = overlay.color;

    switch (overlay.backgroundStyle) {
      case TextBackgroundStyle.semiTransparent:
        backgroundColor = overlay.color.withOpacity(0.4);
        textColor = (overlay.color.computeLuminance() > 0.5) ? Colors.black : Colors.white;
        break;
      case TextBackgroundStyle.solid:
        backgroundColor = overlay.color;
        textColor = (overlay.color.computeLuminance() > 0.5) ? Colors.black : Colors.white;
        break;
      case TextBackgroundStyle.none:
      default:
        backgroundColor = Colors.transparent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        overlay.text,
        style: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: overlay.fontWeight,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_mode == StoryPreviewMode.layout) {
      return RepaintBoundary(key: _collageKey, child: CollageLayoutView(assets: widget.assets!));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [_buildMediaContent()]),
          ),
        );
      },
    );
  }

  Widget _buildVinylPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        RotationTransition(
          turns: _vinylController,
          child: Container(
            width: 280, height: 280,
            decoration: const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: NetworkImage('https://i.imgur.com/HgflQqA.png'))),
            child: Center(
              child: ClipOval(
                child: SizedBox.fromSize(size: const Size.fromRadius(100), child: Image.network(_currentSong!.artworkUrl, fit: BoxFit.cover)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(_currentSong!.trackName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_currentSong!.artistName, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  Widget _buildLargeMusicCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_currentSong!.artworkUrl, width: 80, height: 80, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.equalizer, color: Colors.white),
              const SizedBox(height: 4),
              Text(_currentSong!.trackName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(_currentSong!.artistName, style: const TextStyle(color: Colors.white70)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSmallMusicCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(_currentSong!.artworkUrl, width: 24, height: 24, fit: BoxFit.cover)),
          const SizedBox(width: 8),
          const Icon(Icons.equalizer, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text('${_currentSong!.trackName} • ${_currentSong!.artistName}', style: const TextStyle(color: Colors.white)),
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
    final bool isImage = _currentAsset?.type == AssetType.image;
    final bool isSingleMediaMode = _mode != StoryPreviewMode.layout;
    final bool isEditingNonMusic = _isDrawingMode || _isTextEditingMode;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              color: Colors.white.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(Icons.arrow_back_ios_new, onPressed: () async {
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) Navigator.of(context).pop();
                  }),
                  Row(
                    children: [
                      // Tombol Corat Coret
                      if (isSingleMediaMode && !_isEditingMusic && !isEditingNonMusic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildActionButton(Icons.brush, onPressed: _toggleDrawingMode),
                        ),

                      // Tombol Teks
                      if (isSingleMediaMode && !_isEditingMusic && !isEditingNonMusic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildActionButton(Icons.text_fields, onPressed: _showTextInputDialog),
                        ),

                      // Tombol Cut Gambar
                      if (isSingleMediaMode && isImage && !_isEditingMusic && !isEditingNonMusic)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: _buildActionButton(Icons.crop, onPressed: _cutCurrentImage),
                        ),

                      if (_currentSong != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _isEditingMusic = true),
                            child: CircleAvatar(radius: 20, backgroundImage: NetworkImage(_currentSong!.artworkUrl)),
                          ),
                        )
                      else
                        _buildActionButton(Icons.music_note_outlined, onPressed: _showMusicPicker),
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

  Widget _buildActionButton(IconData icon, {String? label, VoidCallback? onPressed, double size = 22}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.black.withOpacity(0.5), child: Icon(icon, color: Colors.white, size: size)),
            if (label != null) ...[
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMultiPreviewBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
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
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2.5)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(6), child: AssetEntityImage(asset, isOriginal: false, fit: BoxFit.cover)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text('Next >', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)])),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isEditingCaption = true),
                    child: Container(
                      color: Colors.transparent, width: double.infinity,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 18, backgroundImage: NetworkImage(_currentUser?.profilePictureUrl ?? placeholderUrl)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _captionController.text.isEmpty ? 'Tambahkan Caption...' : _captionController.text,
                              style: TextStyle(color: _captionController.text.isEmpty ? Colors.white70 : Colors.white, fontSize: 16),
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
                                label: 'Cerita Anda',
                                onTap: _handleShare,
                                onLongPress: _showSharingOptionsBottomSheet,
                                iconWidget: CircleAvatar(radius: 14, backgroundImage: NetworkImage(_currentUser?.profilePictureUrl ?? placeholderUrl)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStoryButton(
                                label: 'Teman Dekat',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: const Text('Fitur ini akan segara hadir...'),
                                    backgroundColor: Colors.blueAccent,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ));
                                },
                                iconWidget: const CircleAvatar(radius: 14, backgroundColor: Colors.green, child: Icon(Icons.star, color: Colors.white, size: 20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.black, size: 20), onPressed: _showShareBottomSheet),
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

  void _showSharingOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.0))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            bool shareToStory = true;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 24),
                  const Text('Bagikan ini ke..', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildShareOptionTile(
                    avatarUrl: _currentUser?.profilePictureUrl,
                    title: 'Cerita Anda',
                    subtitle: 'Unggah sebagai cerita Anda di Portal SI',
                    isSelected: shareToStory,
                    onTap: () => setModalState(() => shareToStory = !shareToStory),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleShare();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Bagikan', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildShareOptionTile({required String? avatarUrl, required String title, required String subtitle, required bool isSelected, required VoidCallback onTap, bool hasFacebookIcon = false}) {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(radius: 28, backgroundImage: NetworkImage(avatarUrl ?? placeholderUrl)),
              if (hasFacebookIcon)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Color(0xFF2C2C2E), shape: BoxShape.circle),
                    child: const CircleAvatar(radius: 10, backgroundColor: Color(0xFF1877F2), child: Icon(Icons.facebook, color: Colors.white, size: 14)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.blue : Colors.transparent, border: Border.all(color: isSelected ? Colors.blue : Colors.grey[600]!, width: 2)),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionEditor() {
    const String placeholderUrl = 'https://www.gravatar.com/avatar/?d=mp';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      left: 0, right: 0, bottom: keyboardHeight,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(_currentUser?.profilePictureUrl ?? placeholderUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    autofocus: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(hintText: 'Tambahkan Caption...', hintStyle: TextStyle(color: Colors.black54), border: InputBorder.none),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.green,
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
    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!, fit: BoxFit.fitWidth);
    }

    // Workaround untuk AssetEntity Palsu setelah crop (digunakan untuk menampilkan file yang di-crop)
    if (_currentAsset != null && _currentAsset!.relativePath != null && _currentAsset!.id == _currentAsset!.relativePath! && _currentAsset!.type == AssetType.image) {
      final File croppedFile = File(_currentAsset!.relativePath!);
      return Image.file(croppedFile, fit: BoxFit.fitWidth);
    }

    if (_currentAsset == null) return const SizedBox.shrink();
    if (_currentAsset!.type == AssetType.video) {
      if (_isVideoLoading || _videoController == null || !_videoController!.value.isInitialized) {
        return AssetEntityImage(_currentAsset!, fit: BoxFit.fitWidth);
      }
      return AspectRatio(aspectRatio: _videoController!.value.aspectRatio, child: VideoPlayer(_videoController!));
    } else {
      return AssetEntityImage(_currentAsset!, isOriginal: true, fit: BoxFit.fitWidth);
    }
  }

  Widget _buildStoryButton({required String label, required Widget iconWidget, VoidCallback? onTap, VoidCallback? onLongPress}) {
    return Material(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
            onTap: onTap ?? () => print('Tombol "$label" di-klik'),
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(30),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  iconWidget,
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(label,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            Text('Mengunggah Story...', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

// --- SALINAN KELAS _ImageCropperPage DARI edit_profile_page.dart ---
class _ImageCropperPage extends StatelessWidget {
  final File imageFile;
  final bool isBanner;
  final double initialAspectRatio;

  const _ImageCropperPage({
    required this.imageFile,
    required this.isBanner,
    this.initialAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final double aspectRatio = isBanner ? 16 / 7 : initialAspectRatio;

    final controller = CropController(
      aspectRatio: aspectRatio,
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFDDBC), Colors.white],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Sesuaikan Gambar'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                );

                try {
                  final result = await controller.croppedBitmap();
                  final data = await result.toByteData(format: ui.ImageByteFormat.png);

                  if (data == null) {
                    throw Exception("Gagal mengonversi gambar yang di-crop.");
                  }

                  final bytes = data.buffer.asUint8List();
                  final tempDir = await getTemporaryDirectory();
                  final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
                  final File tempFile = File('${tempDir.path}/$fileName');
                  await tempFile.writeAsBytes(bytes);

                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) Navigator.pop(context, tempFile);

                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted) Navigator.pop(context, null);
                }
              },
              child: const Text('Terapkan', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCropper(controller, isBanner),
          ),
        ),
      ),
    );
  }

  Widget _buildCropper(CropController controller, bool isBanner) {
    final cropper = CropImage(
      controller: controller,
      image: Image.file(imageFile),
      gridColor: Colors.white54,
      scrimColor: Colors.black.withOpacity(0.7),
      paddingSize: 20,
      alwaysShowThirdLines: true,
    );

    if (!isBanner) {
      return cropper;
    }
    return cropper;
  }
}

// --- SALINAN KELAS UNTUK DRAWING (DARI edit_post_page.dart) ---
class DrawingPainter extends CustomPainter {
  final List<DrawingPath> paths;
  DrawingPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawingPath in paths) { canvas.drawPath(drawingPath.path, drawingPath.paint); }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}