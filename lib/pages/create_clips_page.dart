// lib/pages/create_clips_page.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'drafts_page.dart';
import 'edit_clips/edit_clips_page.dart';

class CreateClipsPage extends StatefulWidget {
  const CreateClipsPage({Key? key}) : super(key: key);

  @override
  _CreateClipsPageState createState() => _CreateClipsPageState();
}

Route _createSlideRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _SliverHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double opacity = (shrinkOffset / height).clamp(0.0, 1.0);
    return Material(
      color: Colors.white.withOpacity(opacity),
      elevation: overlapsContent ? 1.0 : 0.0,
      child: Center(child: child),
    );
  }

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return child != oldDelegate.child || height != oldDelegate.height;
  }
}

class _CreateClipsPageState extends State<CreateClipsPage> {
  List<AssetEntity> _assets = [];
  int _currentPage = 0;
  bool _isLoading = false;
  List<AssetPathEntity> _allAlbums = [];
  AssetPathEntity? _selectedAlbum;
  RequestType _currentRequestType = RequestType.video;
  String _selectedFilterName = 'Recents';
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isProcessing = false;
  String _selectedClipsMode = 'Edits';
  static const int _maxFileSizeInBytes = 8388608;

  // Variabel state disederhanakan, tidak lagi memerlukan progress atau subscription
  String? _compressingAssetId;

  @override
  void initState() {
    super.initState();
    _requestAssets();
  }

  @override
  void dispose() {
    // Pastikan proses kompresi dihentikan jika halaman ditutup
    VideoCompress.cancelCompression();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _requestAssets() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _loadAlbums();
      if (_selectedAlbum == null && _allAlbums.isNotEmpty) {
        _selectedAlbum = _allAlbums.first;
      }
      await _loadAssets();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _loadAlbums() async {
    final FilterOptionGroup filterOptions = FilterOptionGroup(
      orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
    );
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: _currentRequestType,
      filterOption: filterOptions,
    );
    if (mounted) {
      setState(() {
        _allAlbums = albums;
        if (albums.isNotEmpty) _selectedFilterName = albums.first.name;
      });
    }
  }

  Future<void> _loadAssets() async {
    if (_selectedAlbum == null) return;
    if (mounted) setState(() => _isLoading = true);
    if (_currentPage == 0) _assets.clear();
    final List<AssetEntity> assets = await _selectedAlbum!.getAssetListPaged(
      page: _currentPage,
      size: 60,
    );
    if (mounted) {
      setState(() {
        _assets.addAll(assets);
        _currentPage++;
        _isLoading = false;
      });
    }
  }

  void _cancelCompression() {
    VideoCompress.cancelCompression();
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _compressingAssetId = null;
      });
    }
  }

  Future<void> _showMandatoryCompressionDialog() async {
    final prefs = await SharedPreferences.getInstance();
    const String prefKey = 'dont_show_compression_info_again';
    bool shouldShow = prefs.getBool(prefKey) ?? true;

    if (!shouldShow || !mounted) {
      return;
    }

    bool dontShowAgain = false;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Wajib, tidak bisa ditutup dengan tap di luar
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              // Ikon yang melambangkan "optimasi otomatis"
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orangeAccent.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 40),
              ),
              // Judul yang bersifat informatif, bukan pertanyaan
              title: const Text(
                "Menyiapkan Video Anda",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pesan yang jelas dan to-the-point
                  Text(
                    'Ukuran video ini melebihi batas. Kami sedang mengoptimalkannya secara otomatis agar lebih cepat diunggah dan hemat kuota.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  // Opsi checkbox tetap dipertahankan untuk UX yang baik
                  InkWell(
                    onTap: () {
                      setDialogState(() {
                        dontShowAgain = !dontShowAgain;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                dontShowAgain = value ?? false;
                              });
                            },
                            activeColor: Colors.orange.shade800,
                          ),
                          const Text('Saya mengerti, jangan tampilkan lagi'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: <Widget>[
                // --- PERUBAHAN UTAMA: TOMBOL GRADIENT ---
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade800],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, // Buat transparan
                      shadowColor: Colors.transparent,     // Hilangkan bayangan bawaan
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // Teks tombol yang menyatakan pemahaman, bukan persetujuan
                    child: const Text(
                      'Oke, Saya Mengerti',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      if (dontShowAgain) {
                        prefs.setBool(prefKey, false);
                      }
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processAndNavigate(AssetEntity videoAsset) async {
    if (videoAsset.type != AssetType.video) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hanya video yang dapat dipilih.')));
      return;
    }

    if (_isProcessing) return;

    final File? mediaFile = await videoAsset.file;
    if (mediaFile == null) return;

    File fileToPass = mediaFile;

    if (mediaFile.lengthSync() > _maxFileSizeInBytes) {
      await _showMandatoryCompressionDialog();
      if (!mounted) return;

      setState(() {
        _isProcessing = true;
        _compressingAssetId = videoAsset.id;
      });

      try {
        // Logika kompresi disederhanakan tanpa stream progress yang menyebabkan error
        final MediaInfo? compressedMediaInfo = await VideoCompress.compressVideo(
          mediaFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );

        if (compressedMediaInfo == null) {
          debugPrint("Kompresi dibatalkan atau gagal.");
          _cancelCompression();
          return;
        }

        fileToPass = compressedMediaInfo.file!;
      } catch (e) {
        debugPrint("Error saat kompresi: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengompres video.')),
          );
        }
        _cancelCompression();
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _compressingAssetId = null;
      });
      Navigator.of(context).push(
        _createSlideRoute(EditClipsPage(videoFile: fileToPass)),
      );
    }
  }


  Widget _buildClipsModeButton(IconData icon, String label) {
    final bool isSelected = _selectedClipsMode == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedClipsMode = label);
        if (label == 'Drafts' && mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DraftsPage()),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          backgroundColor: Colors.white,
          elevation: 0.0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Clips Baru',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            // IconButton(
            //   icon: const Icon(Icons.settings_outlined, color: Colors.black),
            //   onPressed: () {},
            // ),
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (!_isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
              _loadAssets();
            }
            return true;
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildClipsModeButton(Icons.edit, 'Edits')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildClipsModeButton(Icons.drafts, 'Drafts')),
                      // const SizedBox(width: 8),
                      // Expanded(child: _buildClipsModeButton(Icons.view_module, 'Templates')),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverHeaderDelegate(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                _selectedFilterName,
                                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.select_all_outlined, color: Colors.black),
                          onPressed: () {},
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index >= _assets.length) return null;
                    final AssetEntity asset = _assets[index];
                    final bool isBeingCompressed = _compressingAssetId == asset.id;

                    return GestureDetector(
                      key: ValueKey(asset.id),
                      onTap: () => _processAndNavigate(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          AssetEntityImage(
                            asset,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize(250, 250),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(asset.duration ~/ 60).toString().padLeft(1, '0')}:${(asset.duration % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                          if (isBeingCompressed)
                            Container(
                              color: Colors.black.withOpacity(0.7),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // ## PERBAIKAN DI SINI: Indikator tak terbatas (spinner) ##
                                  const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Mengompres...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 24,
                                    child: TextButton(
                                      onPressed: _cancelCompression,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: const Text('Batal', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  )
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: _assets.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 1.5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 4 / 5,
                ),
              ),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}