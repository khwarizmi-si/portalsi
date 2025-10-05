import 'dart:async';
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

  // --- 👇 State baru untuk gestur cubit (pinch) 👇 ---
  Offset _stickerPosition = Offset.zero;
  double _stickerScale = 1.0;
  double _stickerRotation = 0.0;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  // --- 👆 Batas state baru 👆 ---


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
      final response = await dio.get('https://api-new.portalsi.com/api/user', options: Options(headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'}));
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
    if (_isUploading) return;
    setState(() => _isUploading = true);
    Map<String, dynamic> dataMap = {};
    dataMap['caption'] = _captionController.text;

    if (_currentSong != null) {
      dataMap['type'] = 'music';
      dataMap.addAll({
        'music_track_name': _currentSong!.trackName, 'music_artist_name': _currentSong!.artistName,
        'music_preview_url': _currentSong!.previewUrl, 'music_album_art_url': _currentSong!.artworkUrl,
        'music_start_position_ms': _clipStartPosition.inMilliseconds,
        'music_display_style': MusicDisplayStyle.values[_musicStyleIndex].name,
        'music_clip_duration_ms': _clipDuration.inMilliseconds,
      });

      if (MusicDisplayStyle.values[_musicStyleIndex] != MusicDisplayStyle.vinyl) {
        final containerContext = _storyContainerKey.currentContext;
        final stickerContext = _stickerKey.currentContext;
        if (containerContext != null && stickerContext != null) {
          final RenderBox containerBox = containerContext.findRenderObject() as RenderBox;
          final RenderBox stickerBox = stickerContext.findRenderObject() as RenderBox;
          final stickerOffset = stickerBox.localToGlobal(Offset.zero, ancestor: containerBox);
          final containerSize = containerBox.size;
          if (containerSize.width > 0 && containerSize.height > 0) {
            final relativeX = stickerOffset.dx / containerSize.width;
            final relativeY = stickerOffset.dy / containerSize.height;
            dataMap.addAll({'music_sticker_position_x': relativeX, 'music_sticker_position_y': relativeY});
          }
        }
      }
      if (_currentAsset != null) {
        final File? mediaFile = await _getMediaFileFromAsset(_currentAsset!);
        if (mediaFile != null) {
          dataMap['media'] = await MultipartFile.fromFile(mediaFile.path, filename: mediaFile.path.split('/').last);
        }
      }
    } else if (_currentAsset != null) {
      final File? mediaFile = await _getMediaFileFromAsset(_currentAsset!);
      if (mediaFile == null) {
        _showErrorToast('Gagal memproses file media.');
        setState(() => _isUploading = false);
        return;
      }
      dataMap['media'] = await MultipartFile.fromFile(mediaFile.path, filename: mediaFile.path.split('/').last);
      dataMap['type'] = _currentAsset!.type == AssetType.video ? 'video' : 'image';
    } else {
      _showErrorToast('Tidak ada konten untuk diunggah.');
      setState(() => _isUploading = false);
      return;
    }

    final formData = FormData.fromMap(dataMap);
    try {
      final dio = Dio();
      await dio.post('https://api-new.portalsi.com/api/stories', data: formData, options: Options(headers: {'Authorization': 'Bearer $_token', 'Accept': 'application/json'}));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MainScaffold()), (Route<dynamic> route) => false);
      }
    } on DioException catch (e) {
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

  void _showErrorToast(String message) {
    Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.BOTTOM, backgroundColor: Colors.red, textColor: Colors.white, fontSize: 16.0);
  }

  void _showShareBottomSheet() {
    HapticFeedback.lightImpact();
    setState(() => _isBottomSheetVisible = true);
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF262626),
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
                  const Text('Bagikan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundImage: NetworkImage(userProfileImageUrl)),
                    title: const Text('Cerita Anda', style: TextStyle(color: Colors.white)),
                    subtitle: Text('akan diunggah sebagai cerita Anda', style: TextStyle(color: Colors.grey[400])),
                    trailing: Radio<int>(value: 1, groupValue: _groupValue, onChanged: (int? value) => setState(() => _groupValue = value!), activeColor: Colors.blue),
                    onTap: () => setState(() => _groupValue = 1),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleShare,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
    if (_mode == StoryPreviewMode.music || _mode == StoryPreviewMode.layout) {
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(systemNavigationBarColor: Colors.black, statusBarColor: Colors.transparent),
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
                if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),
                _buildAnimatedMediaContainer(),
                if (!_isEditingCaption) _isEditingMusic ? _buildMusicEditingTopBar() : _buildAnimatedTopBar(),
                if (_isEditingMusic) _buildMusicStyleSelector(),
                if (!_isEditingCaption) _isEditingMusic ? _buildMusicClipEditor() : _buildBottomUI(),
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

  // --- 👇 MODIFIKASI UTAMA UNTUK GESTUR CUBIT 👇 ---
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
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24.0)),
          child: ClipRRect(
            key: _storyContainerKey,
            borderRadius: BorderRadius.circular(24.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildMainContent(),
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
                  _buildActionButton(Icons.arrow_back_ios_new, onPressed: () async {
                    final shouldPop = await _onWillPop();
                    if (shouldPop && mounted) Navigator.of(context).pop();
                  }),
                  Row(
                    children: [
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
      backgroundColor: const Color(0xFF2C2C2E),
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
                  const Text('Bagikan ini ke..', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(30)),
            child: Row(
              children: [
                CircleAvatar(radius: 18, backgroundImage: NetworkImage(_currentUser?.profilePictureUrl ?? placeholderUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'Type a caption...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
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
    if (widget.imageBytes != null) {
      return Image.memory(widget.imageBytes!, fit: BoxFit.fitWidth);
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
        color: Colors.black.withOpacity(0.4),
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