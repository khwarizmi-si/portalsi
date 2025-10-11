// lib/pages/edit_post_page.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:crop_image/crop_image.dart';

import '../models/song_model.dart';
import '../models/text_overlay_model.dart';
import '../services/music_service.dart';
import '../widgets/custom_emoji_picker.dart';
import '../widgets/music_picker_sheet.dart';
import 'share_post_page.dart';

// Model untuk Brush/Drawing
class DrawingPath {
  final Path path;
  final Paint paint;
  DrawingPath({required this.path, required this.paint});
}

// Enum untuk mengelola state aspek rasio
enum AspectRatioPreset { ratio4_5, ratio5_4 }

class EditPostPage extends StatefulWidget {
  final List<AssetEntity> mediaItems;

  const EditPostPage({super.key, required this.mediaItems});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  AspectRatioPreset _currentAspectRatio = AspectRatioPreset.ratio4_5;
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  Song? _selectedSong;
  final GlobalKey _repaintKey = GlobalKey();
  bool _isProcessing = false;
  File? _croppedImageFile;

  final List<TextOverlay> _textOverlays = [];
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  TextOverlay? _activeTextOverlay;

  VideoPlayerController? _videoController;

  Song? _singleRecommendedSong;
  bool _isLoadingRecommendations = true;

  final AudioPlayer _recommendationAudioPlayer = AudioPlayer();
  bool _isRecommendationPlaying = false;
  String? _currentRecommendationPreviewUrl;
  bool _isRecommendationLoading = false;


  bool _isDrawingMode = false;
  final List<DrawingPath> _drawingPaths = [];
  Path? _currentPath;
  Color _currentDrawingColor = Colors.white;
  double _currentStrokeWidth = 5.0;

  bool _isFilterEditing = false;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _exposure = 0.0;
  double _warmth = 0.0;
  double _tint = 0.0;
  String _currentFilter = 'Original';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _initializePlayerForCurrentAsset();
    _fetchRecommendedSong();

    _recommendationAudioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          if (state == PlayerState.playing) {
            _isRecommendationPlaying = true;
            _isRecommendationLoading = false;
          } else if (state == PlayerState.paused || state == PlayerState.completed || state == PlayerState.stopped) {
            _isRecommendationPlaying = false;
            _isRecommendationLoading = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    _recommendationAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    if (_isProcessing) return;
    final AssetEntity currentMedia = widget.mediaItems[_currentIndex];
    final File? originalFile = await currentMedia.file;
    if (originalFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat file gambar untuk di-crop.')),
      );
      return;
    }
    final double cropAspectRatio = _currentAspectRatio == AspectRatioPreset.ratio4_5 ? 4 / 5 : 5 / 4;
    final File? croppedFile = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageCropperPage(
          imageFile: originalFile,
          aspectRatio: cropAspectRatio,
        ),
        fullscreenDialog: true,
      ),
    );
    if (croppedFile != null) {
      setState(() {
        _croppedImageFile = croppedFile;
      });
    }
  }

  void _toggleFilterEditor() {
    setState(() {
      _isFilterEditing = !_isFilterEditing;
    });
  }

  void _applyPresetFilter(String filterName) {
    setState(() {
      _currentFilter = filterName;
      switch (filterName) {
        case 'Vivid':
          _brightness = 0.05; _contrast = 1.3; _saturation = 1.5; _exposure = 0.0; _warmth = 0.1; _tint = 0.0;
          break;
        case 'Cyberpunk':
          _brightness = -0.1; _contrast = 1.5; _saturation = 1.2; _exposure = 0.1; _warmth = -0.2; _tint = 0.1;
          break;
        case 'Cinematic':
          _brightness = 0.0; _contrast = 1.2; _saturation = 0.8; _exposure = 0.0; _warmth = 0.2; _tint = -0.1;
          break;
        case 'Cobalt':
          _brightness = 0.0; _contrast = 1.2; _saturation = 1.1; _exposure = 0.0; _warmth = -0.4; _tint = 0.1;
          break;
        case 'Zenith':
          _brightness = 0.1; _contrast = 1.1; _saturation = 1.2; _exposure = 0.1; _warmth = 0.1; _tint = -0.1;
          break;
        case 'Canals':
          _brightness = 0.0; _contrast = 1.1; _saturation = 0.9; _exposure = 0.0; _warmth = 0.2; _tint = -0.2;
          break;
        case 'FreeHand':
          _brightness = -0.1; _contrast = 1.8; _saturation = 0.0; _exposure = 0.2; _warmth = 0.0; _tint = 0.0;
          break;
        case 'Original':
        default:
          _brightness = 0.0; _contrast = 1.0; _saturation = 1.0; _exposure = 0.0; _warmth = 0.0; _tint = 0.0;
          break;
      }
    });
  }

  List<double> _calculateColorMatrix() {
    List<double> matrix = List.from([
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ]);
    final brightnessValue = _brightness * 255.0;
    matrix[4] += brightnessValue;
    matrix[9] += brightnessValue;
    matrix[14] += brightnessValue;
    final exposureValue = pow(2, _exposure).toDouble();
    matrix[0] *= exposureValue;
    matrix[6] *= exposureValue;
    matrix[12] *= exposureValue;
    final contrastValue = _contrast;
    final translate = (-0.5 * contrastValue + 0.5) * 255.0;
    matrix[0] *= contrastValue;
    matrix[6] *= contrastValue;
    matrix[12] *= contrastValue;
    matrix[4] += translate;
    matrix[9] += translate;
    matrix[14] += translate;
    final saturationValue = _saturation;
    final invSat = 1.0 - saturationValue;
    final r = 0.213 * invSat;
    final g = 0.715 * invSat;
    final b = 0.072 * invSat;
    final satMatrix = [
      r + saturationValue, g, b, 0.0, 0.0,
      r, g + saturationValue, b, 0.0, 0.0,
      r, g, b + saturationValue, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
    matrix = _multiplyMatrices(matrix, satMatrix);
    final warmthValue = _warmth * 30;
    matrix[4] += warmthValue;
    matrix[14] -= warmthValue;
    final tintValue = _tint * 30;
    matrix[9] += tintValue;
    return matrix;
  }

  List<double> _multiplyMatrices(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double val = 0;
        for (int k = 0; k < 4; k++) {
          val += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j < 4) {
          result[i * 5 + j] = val;
        } else {
          result[i * 5 + j] = val + a[i * 5 + 4];
        }
      }
    }
    return result;
  }

  Future<void> _fetchRecommendedSong() async {
    setState(() => _isLoadingRecommendations = true);
    try {
      final songs = await MusicService().getTrendingSongs();
      if (mounted && songs.isNotEmpty) {
        setState(() {
          _singleRecommendedSong = songs.first;
          _currentRecommendationPreviewUrl = _singleRecommendedSong!.previewUrl;
        });
      }
    } catch (e) {
      print("Gagal memuat rekomendasi: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRecommendations = false);
    }
  }

  Future<void> _toggleRecommendationPreview() async {
    if (_singleRecommendedSong == null || _singleRecommendedSong!.previewUrl.isEmpty) return;
    if (_isRecommendationPlaying) {
      await _recommendationAudioPlayer.pause();
    } else {
      if (_currentRecommendationPreviewUrl != _singleRecommendedSong!.previewUrl) {
        await _recommendationAudioPlayer.stop();
        _currentRecommendationPreviewUrl = _singleRecommendedSong!.previewUrl;
      }
      setState(() { _isRecommendationLoading = true; });
      try {
        await _recommendationAudioPlayer.play(UrlSource(_singleRecommendedSong!.previewUrl));
      } catch (e) {
        if (mounted) setState(() { _isRecommendationLoading = false; _isRecommendationPlaying = false; });
      }
    }
  }

  Future<void> _initializePlayerForCurrentAsset() async {
    await _videoController?.dispose();
    _videoController = null;
    if (_currentIndex >= widget.mediaItems.length) return;
    final currentAsset = widget.mediaItems[_currentIndex];
    if (currentAsset.type == AssetType.video) {
      final file = await currentAsset.file;
      if (file != null && mounted) {
        _videoController = VideoPlayerController.file(file)
          ..initialize().then((_) {
            _videoController?.play();
            _videoController?.setLooping(true);
            if(mounted) setState(() {});
          });
      }
    } else {
      if(mounted) setState(() {});
    }
  }

  void _showCustomEmojiPicker() async {
    final String? selectedEmoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomEmojiPicker(),
    );
    if (selectedEmoji != null) {
      setState(() {
        final newOverlay = TextOverlay(text: selectedEmoji, position: const Offset(100, 150), backgroundStyle: TextBackgroundStyle.none);
        _textOverlays.add(newOverlay);
      });
    }
  }

  Future<void> _showLinkInputDialog() async {
    final textController = TextEditingController();
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Tambahkan Link', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: textController, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Teks Tampilan', hintStyle: TextStyle(color: Colors.grey)), validator: (value) => (value?.isEmpty ?? true) ? 'Teks tidak boleh kosong' : null),
            TextFormField(controller: urlController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'https://contoh.com', hintStyle: TextStyle(color: Colors.grey)), validator: (value) { if (value?.isEmpty ?? true) return 'URL tidak boleh kosong'; if (!Uri.tryParse(value!)!.isAbsolute) return 'URL tidak valid'; return null; }),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
          ElevatedButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.of(context).pop({'text': textController.text, 'url': urlController.text}); }, child: const Text('Selesai')),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        final newOverlay = TextOverlay(text: result['text']!, url: result['url']!, isLink: true, position: const Offset(100, 200), color: Colors.white, backgroundStyle: TextBackgroundStyle.solid);
        _textOverlays.add(newOverlay);
      });
    }
  }

  void _toggleDrawingMode() {
    setState(() => _isDrawingMode = !_isDrawingMode);
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDrawingMode) return;
    _currentPath = Path()..moveTo(details.localPosition.dx, details.localPosition.dy);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawingMode || _currentPath == null) return;
    setState(() {
      // Membuat path baru dengan menyalin yang lama dan menambahkan garis baru.
      // Ini memastikan Flutter mendeteksi perubahan dan menggambar ulang.
      _currentPath = Path.from(_currentPath!)
        ..lineTo(details.localPosition.dx, details.localPosition.dy);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawingMode || _currentPath == null) return;
    setState(() {
      _drawingPaths.add(DrawingPath(path: _currentPath!, paint: Paint()..color = _currentDrawingColor..strokeWidth = _currentStrokeWidth..style = PaintingStyle.stroke..strokeCap = StrokeCap.round));
      _currentPath = null;
    });
  }

  void _showTextOptionsSheet(TextOverlay overlay) {
    setState(() => _activeTextOverlay = overlay);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _buildColorOption(Colors.white, setSheetState), _buildColorOption(Colors.black, setSheetState), _buildColorOption(Colors.red, setSheetState), _buildColorOption(Colors.blue, setSheetState), _buildColorOption(Colors.yellow, setSheetState),
            ]),
            const Divider(color: Colors.grey, height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              TextButton.icon(onPressed: () { setState(() { final currentStyleIndex = overlay.backgroundStyle.index; final nextStyleIndex = (currentStyleIndex + 1) % TextBackgroundStyle.values.length; overlay.backgroundStyle = TextBackgroundStyle.values[nextStyleIndex]; }); setSheetState(() {}); }, icon: const Icon(Icons.format_color_text, color: Colors.white), label: const Text('Gaya', style: TextStyle(color: Colors.white))),
              TextButton.icon(onPressed: () { setState(() => overlay.fontWeight = overlay.fontWeight == FontWeight.bold ? FontWeight.normal : FontWeight.bold); setSheetState(() {}); }, icon: const Icon(Icons.format_bold, color: Colors.white), label: const Text('Tebal', style: TextStyle(color: Colors.white))),
              TextButton.icon(onPressed: () { setState(() { _textOverlays.remove(overlay); _activeTextOverlay = null; }); Navigator.pop(context); }, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Hapus', style: TextStyle(color: Colors.red))),
            ])
          ]));
        },
      ),
    ).whenComplete(() => setState(() => _activeTextOverlay = null));
  }

  Widget _buildColorOption(Color color, StateSetter setSheetState) {
    bool isSelected = _activeTextOverlay?.color == color;
    return GestureDetector(
      onTap: () { setState(() => _activeTextOverlay!.color = color); setSheetState(() {}); },
      child: Container(width: 30, height: 30, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: Colors.blue, width: 2) : null)),
    );
  }

  Future<void> _showTextInputDialog() async {
    final textController = TextEditingController();
    final String? newText = await showDialog<String>(context: context, builder: (context) => AlertDialog(backgroundColor: Colors.grey[850], title: const Text('Masukkan Teks', style: TextStyle(color: Colors.white)), content: TextField(controller: textController, autofocus: true, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Tulis sesuatu...')), actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')), ElevatedButton(onPressed: () => Navigator.of(context).pop(textController.text), child: const Text('Selesai'))]));
    if (newText != null && newText.isNotEmpty) {
      setState(() { final newOverlay = TextOverlay(text: newText, position: const Offset(100, 150)); _textOverlays.add(newOverlay); _showTextOptionsSheet(newOverlay); });
    }
  }

  Color _getContrastingTextColor(Color backgroundColor) => backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  void _runAnimation() {
    _animationController.stop();
    _animation = Matrix4Tween(begin: _transformationController.value, end: Matrix4.identity()).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animation!.addListener(() => _transformationController.value = _animation!.value);
    _animationController.forward(from: 0);
  }

  void _openMusicPicker() async {
    await _recommendationAudioPlayer.stop();
    setState(() { _isRecommendationPlaying = false; _isRecommendationLoading = false; });
    final selectedSong = await showModalBottomSheet<Song>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const MusicPickerSheet());
    if (selectedSong != null) setState(() => _selectedSong = selectedSong);
  }

  Future<void> _processAndNavigate() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _videoController?.pause();
    await _recommendationAudioPlayer.stop();

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      List<File> processedFiles = [];
      final AssetEntity currentMedia = widget.mediaItems[_currentIndex];
      if (_croppedImageFile != null) {
        processedFiles.add(_croppedImageFile!);
      } else if (currentMedia.type == AssetType.video) {
        final originalFile = await currentMedia.file;
        if (originalFile != null) {
          processedFiles.add(originalFile);
        } else {
          throw Exception("Gagal mendapatkan file video.");
        }
      } else {
        final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List pngBytes = byteData!.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png').create();
        await file.writeAsBytes(pngBytes);
        processedFiles.add(file);
      }
      if (processedFiles.isEmpty) {
        throw Exception("Tidak ada media untuk diproses.");
      }
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SharePostPage(
          mediaFiles: processedFiles,
          selectedSong: _selectedSong,
          textOverlays: _textOverlays,
        ),
      ));
    } catch (e) {
      print("Error saat memproses media: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses media: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AssetEntity currentMedia = widget.mediaItems[_currentIndex];
    final bool isVideo = currentMedia.type == AssetType.video;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GestureDetector(
            onTap: _openMusicPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _selectedSong != null ? Colors.blueAccent.withOpacity(0.5) : Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.music_note, color: Colors.white, size: 16), const SizedBox(width: 8),
                Flexible(child: Text(_selectedSong?.trackName ?? 'Pilih Musik', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(height: 50, child: _isLoadingRecommendations ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))) : _singleRecommendedSong == null ? const Center(child: Text("Gagal memuat tren", style: TextStyle(color: Colors.grey, fontSize: 12))) : Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [
            CircleAvatar(radius: 25, backgroundImage: NetworkImage(_singleRecommendedSong!.artworkUrl)), const SizedBox(width: 12),
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_singleRecommendedSong!.trackName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              Text(_singleRecommendedSong!.artistName, style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
            ])),
            IconButton(icon: _isRecommendationLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(_isRecommendationPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white), onPressed: _toggleRecommendationPreview),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white), onPressed: () { setState(() { _selectedSong = _singleRecommendedSong; _recommendationAudioPlayer.stop(); _isRecommendationPlaying = false; _isRecommendationLoading = false; }); }),
          ]))),
        ]),
        toolbarHeight: 110,
      ),
      body: Column(
        children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(16.0), child: Center(child: AspectRatio(
              aspectRatio: _currentAspectRatio == AspectRatioPreset.ratio4_5 ? 4 / 5 : 5 / 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // LAPISAN 1: GAMBAR/VIDEO DASAR
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(_calculateColorMatrix()),
                          child: (isVideo && _videoController != null && _videoController!.value.isInitialized)
                              ? FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoController!.value.size.width, height: _videoController!.value.size.height, child: VideoPlayer(_videoController!)))
                              : InteractiveViewer(
                            transformationController: _transformationController,
                            panEnabled: !isVideo && !_isDrawingMode,
                            scaleEnabled: !isVideo && !_isDrawingMode,
                            onInteractionEnd: (details) {
                              if (_transformationController.value.getMaxScaleOnAxis() < 1.0) _runAnimation();
                            },
                            child: _croppedImageFile != null
                                ? Image.file(_croppedImageFile!, fit: BoxFit.cover)
                                : _MediaFileViewer(assetEntity: currentMedia),
                          ),
                        ),

                        // --- 👇 PERBAIKAN UTAMA (SUSUN ULANG URUTAN) 👇 ---

                        // LAPISAN 2: KANVAS UNTUK CORETAN YANG SUDAH JADI
                        CustomPaint(painter: DrawingPainter(paths: _drawingPaths), child: Container()),

                        // LAPISAN 3: KANVAS UNTUK CORETAN YANG SEDANG DIGAMBAR
                        if (_isDrawingMode && _currentPath != null)
                          CustomPaint(
                              painter: DrawingPainter(paths: [
                                DrawingPath(
                                    path: _currentPath!,
                                    paint: Paint()
                                      ..color = _currentDrawingColor
                                      ..strokeWidth = _currentStrokeWidth
                                      ..style = PaintingStyle.stroke
                                      ..strokeCap = StrokeCap.round)
                              ]),
                              child: Container()),

                        // LAPISAN 4: TEKS OVERLAY (SEKARANG BERADA DI ATAS CORETAN)
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
                                      onTap: () => _showTextOptionsSheet(overlay),
                                      onScaleStart: (details) { _baseScale = overlay.scale; _baseRotation = overlay.rotation; },
                                      onScaleUpdate: (details) {
                                        setState(() {
                                          overlay.position += details.focalPointDelta;
                                          overlay.scale = (_baseScale * details.scale).clamp(0.5, 3.0);
                                          overlay.rotation = _baseRotation + details.rotation;
                                        });
                                      },
                                      child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: overlay.backgroundStyle == TextBackgroundStyle.none
                                                ? Colors.transparent
                                                : (overlay.backgroundStyle == TextBackgroundStyle.semiTransparent
                                                ? Colors.black.withOpacity(0.5)
                                                : overlay.color),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            overlay.text,
                                            style: TextStyle(
                                              fontSize: 24,
                                              color: overlay.backgroundStyle == TextBackgroundStyle.solid
                                                  ? _getContrastingTextColor(overlay.color)
                                                  : overlay.color,
                                              fontWeight: overlay.fontWeight,
                                            ),
                                          )
                                      )
                                  )
                              )
                          );
                        }).toList(),

                        // LAPISAN 5 (PALING ATAS): SENSOR SENTUH UNTUK MENGGAMBAR (HANYA AKTIF SAAT MODE GAMBAR)
                        if (_isDrawingMode)
                          GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onPanStart: _onPanStart,
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: Container(color: Colors.transparent)
                          ),

                        // --- AKHIR PERBAIKAN ---

                        // Tombol utilitas (tidak terpengaruh urutan di atas)
                        if (!isVideo)
                          Positioned(
                              bottom: 8,
                              left: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentAspectRatio =
                                    _currentAspectRatio == AspectRatioPreset.ratio4_5
                                        ? AspectRatioPreset.ratio5_4
                                        : AspectRatioPreset.ratio4_5;
                                  });
                                },
                                icon: const Icon(Icons.aspect_ratio, color: Colors.white),
                                style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.4)),
                              )),
                      ]),
                ),
              )
          )))),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterEditing ? 320 : 0,
            child: _buildFilterEditor(),
          ),

          SafeArea(
            top: false,
            child: _isFilterEditing ? const SizedBox.shrink() : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isDrawingMode
                  ? Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(icon: const Icon(Icons.undo, color: Colors.white), onPressed: () => setState(() { if(_drawingPaths.isNotEmpty) _drawingPaths.removeLast(); })),
                ...[Colors.white, Colors.red, Colors.blue, Colors.yellow, Colors.green].map((color) => GestureDetector(onTap: () => setState(() => _currentDrawingColor = color), child: CircleAvatar(radius: 14, backgroundColor: color, child: _currentDrawingColor == color ? const Icon(Icons.check, size: 16, color: Colors.black) : null))),
                ElevatedButton(onPressed: _toggleDrawingMode, child: const Text('Selesai')),
              ])
                  : Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _buildEditorButton(Icons.music_note, 'Audio', onTap: _openMusicPicker),
                _buildEditorButton(Icons.text_fields, 'Teks', onTap: _showTextInputDialog),
                _buildEditorButton(Icons.sentiment_satisfied_alt, 'Emoji', onTap: _showCustomEmojiPicker),
                _buildEditorButton(Icons.crop, 'Pangkas', onTap: isVideo ? null : _cropImage),
                _buildEditorButton(Icons.filter_vintage, 'Filter', onTap: isVideo ? null : _toggleFilterEditor),
                _buildEditorButton(Icons.brush, 'Brush', onTap: _toggleDrawingMode),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processAndNavigate,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterEditor() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              const Text("Edit Filter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _toggleFilterEditor,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSlider("Brightness", _brightness, -1.0, 1.0, (val) => setState(() { _brightness = val; _currentFilter = 'Custom'; })),
                _buildSlider("Contrast", _contrast, 0.0, 4.0, (val) => setState(() { _contrast = val; _currentFilter = 'Custom'; })),
                _buildSlider("Saturation", _saturation, 0.0, 2.0, (val) => setState(() { _saturation = val; _currentFilter = 'Custom'; })),
                _buildSlider("Exposure", _exposure, -1.0, 1.0, (val) => setState(() { _exposure = val; _currentFilter = 'Custom'; })),
                _buildSlider("Warmth", _warmth, -1.0, 1.0, (val) => setState(() { _warmth = val; _currentFilter = 'Custom'; })),
                _buildSlider("Tint", _tint, -1.0, 1.0, (val) => setState(() { _tint = val; _currentFilter = 'Custom'; })),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['Original', 'Vivid', 'Cyberpunk', 'Cinematic', 'Cobalt', 'Zenith', 'Canals', 'FreeHand'].map((name) {
                final bool isSelected = _currentFilter == name;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => _applyPresetFilter(name),
                        style: TextButton.styleFrom(foregroundColor: isSelected ? Colors.blueAccent : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      ),
                      if (isSelected)
                        Container(height: 2, width: 40, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(1)))
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              activeColor: Colors.white,
              inactiveColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: onTap == null ? Colors.grey : Colors.white),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: onTap == null ? Colors.grey : Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _MediaFileViewer extends StatelessWidget {
  final AssetEntity assetEntity;
  const _MediaFileViewer({required this.assetEntity});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: assetEntity.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Center(child: Icon(Icons.error_outline, color: Colors.red, size: 48));
        }
        return Image.file(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}


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

class _ImageCropperPage extends StatelessWidget {
  final File imageFile;
  final double aspectRatio;

  const _ImageCropperPage({required this.imageFile, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final controller = CropController(
      aspectRatio: aspectRatio,
      defaultCrop: const Rect.fromLTRB(0.05, 0.05, 0.95, 0.95),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Sesuaikan Gambar'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
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

                if (context.mounted) Navigator.pop(context); // Tutup loading
                if (context.mounted) Navigator.pop(context, tempFile); // Kembali dengan hasil

              } catch (e) {
                if (context.mounted) Navigator.pop(context); // Tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal memproses gambar: $e')),
                );
              }
            },
            child: const Text('SELESAI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CropImage(
            controller: controller,
            image: Image.file(imageFile),
            gridColor: Colors.white54,
            scrimColor: Colors.black.withOpacity(0.7),
            paddingSize: 20,
            alwaysShowThirdLines: true,
          ),
        ),
      ),
    );
  }
}