// lib/pages/create_post_page.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'edit_post_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
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
    return Container(
      color: Colors.black,
      height: height,
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

class _CreatePostPageState extends State<CreatePostPage> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _assets = [];
  AssetEntity? _selectedGalleryAsset;
  int _currentPage = 0;
  bool _isLoading = false;
  List<AssetPathEntity> _allAlbums = [];
  AssetPathEntity? _selectedAlbum;
  RequestType _currentRequestType = RequestType.common;
  String _selectedFilterName = 'Belakangan ini';
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isMultiSelectMode = false;
  final List<AssetEntity> _selectedAssets = [];
  BoxFit _singlePreviewFit = BoxFit.contain;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _requestAssets();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoController(AssetEntity asset) async {
    await _videoController?.dispose();
    _videoController = null;
    if (asset.type == AssetType.video && !_isMultiSelectMode) {
      final file = await asset.file;
      if (file != null && mounted) {
        _videoController = VideoPlayerController.file(file);
        await _videoController?.initialize();
        await _videoController?.setLooping(true);
        await _videoController?.play();
        setState(() {});
      }
    } else {
      if (mounted) setState(() {});
    }
  }

  void _handleAssetTap(AssetEntity asset) {
    _initVideoController(asset);
    setState(() {
      _selectedGalleryAsset = asset;
    });
    if (_isMultiSelectMode) {
      setState(() {
        if (_selectedAssets.contains(asset)) {
          _selectedAssets.remove(asset);
        } else {
          _selectedAssets.add(asset);
        }
      });
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedAssets.clear();
        if (_selectedGalleryAsset != null) {
          _initVideoController(_selectedGalleryAsset!);
        }
      } else {
        _videoController?.dispose();
        _videoController = null;
        if (_selectedGalleryAsset != null && _selectedAssets.isEmpty) {
          _selectedAssets.add(_selectedGalleryAsset!);
        }
      }
    });
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
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: _currentRequestType,
      filterOption: filterOptions,
    );
    if(mounted) {
      setState(() {
        _allAlbums = albums;
      });
    }
  }

  Future<void> _loadAssets() async {
    if (_selectedAlbum == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    if (_currentPage == 0) {
      _assets.clear();
    }
    final List<AssetEntity> assets = await _selectedAlbum!.getAssetListPaged(
      page: _currentPage,
      size: 60,
    );
    if(mounted) {
      setState(() {
        _assets.addAll(assets);
        _currentPage++;
        if (_selectedGalleryAsset == null && _assets.isNotEmpty) {
          _selectedGalleryAsset = _assets.first;
          _initVideoController(_selectedGalleryAsset!);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto berhasil diambil: ${photo.path}')),
      );
    }
  }

  Widget _buildSelectedMediaPreview() {
    if (_selectedGalleryAsset == null) {
      return Container(
        height: MediaQuery.of(context).size.width,
        color: Colors.grey[900],
        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final BoxFit fitMode = _isMultiSelectMode ? BoxFit.cover : _singlePreviewFit;
    return Container(
      color: Colors.black,
      height: MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          if (_videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: fitMode,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            AssetEntityImage(
              _selectedGalleryAsset!,
              isOriginal: true,
              fit: fitMode,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              },
            ),
          if (!_isMultiSelectMode)
            Positioned(
              left: 8,
              bottom: 8,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _singlePreviewFit = _singlePreviewFit == BoxFit.contain
                        ? BoxFit.cover
                        : BoxFit.contain;
                  });
                },
                icon: Icon(
                  _singlePreviewFit == BoxFit.contain
                      ? Icons.crop_free
                      : Icons.fullscreen,
                ),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaFilterChip(String label, IconData icon, RequestType type) {
    bool isSelected = _currentRequestType == type;
    Color activeColor = Colors.blue;
    Color inactiveColor = Colors.black;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentRequestType = type;
          _selectedFilterName = label;
          _currentPage = 0;
          _selectedAlbum = null;
          _selectedGalleryAsset = null;
          _assets.clear();
        });
        _loadAlbums().then((_) {
          if (_allAlbums.isNotEmpty) {
            setState(() {
              _selectedAlbum = _allAlbums.first;
            });
            _loadAssets();
          }
        });
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? activeColor : inactiveColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showAlbumSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onVerticalDragUpdate: (details) {
                      double newSize = _sheetController.size - (details.primaryDelta! / MediaQuery.of(context).size.height);
                      _sheetController.jumpTo(newSize.clamp(0.4, 0.9));
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text('Pilih Album', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Selesai', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMediaFilterChip('Terbaru', Icons.photo_library_outlined, RequestType.common),
                              _buildMediaFilterChip('Foto', Icons.photo_outlined, RequestType.image),
                              _buildMediaFilterChip('Video', Icons.play_circle_outline, RequestType.video),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Album di Perangkat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _allAlbums.length,
                      itemBuilder: (context, index) {
                        final album = _allAlbums[index];
                        return FutureBuilder<int>(
                          future: album.assetCountAsync,
                          builder: (context, snapshot) {
                            final int count = snapshot.data ?? 0;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedAlbum = album;
                                  _currentPage = 0;
                                  _selectedGalleryAsset = null;
                                  _selectedFilterName = album.name;
                                });
                                _loadAssets();
                                Navigator.pop(context);
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: count > 0
                                          ? FutureBuilder<AssetEntity?>(
                                        future: album.getAssetListPaged(page: 0, size: 1).then((list) => list.firstOrNull),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                            return AssetEntityImage(
                                              snapshot.data!,
                                              isOriginal: false,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            );
                                          }
                                          return Container(color: Colors.grey[200]);
                                        },
                                      )
                                          : Container(color: Colors.grey[200]),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    album.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    count.toString(),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Postingan Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                _videoController?.pause(); // <-- PERBAIKAN BUG 1 DI SINI
                if (_isMultiSelectMode) {
                  if (_selectedAssets.isNotEmpty) {
                    Navigator.of(context).push(
                      _createSlideRoute(EditPostPage(mediaItems: _selectedAssets)),
                    );
                  }
                } else {
                  if (_selectedGalleryAsset != null) {
                    Navigator.of(context).push(
                      _createSlideRoute(EditPostPage(mediaItems: [_selectedGalleryAsset!])),
                    );
                  }
                }
              },
              child: const Text('Lanjut', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (!_isLoading && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  _loadAssets();
                }
                return true;
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildSelectedMediaPreview(),
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
                              onTap: _showAlbumSelectionBottomSheet,
                              child: Row(
                                children: [
                                  Text(
                                    _selectedFilterName,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: _takePhoto,
                            child: Container(color: Colors.grey[800], child: const Icon(Icons.camera_alt, color: Colors.white, size: 30)),
                          );
                        }
                        final AssetEntity asset = _assets[index - 1];

                        final bool isSelected = _selectedAssets.contains(asset);
                        final int selectedIndex = isSelected ? _selectedAssets.indexOf(asset) + 1 : 0;

                        return GestureDetector(
                          key: ValueKey(asset.id),
                          onTap: () => _handleAssetTap(asset),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AssetEntityImage(asset, isOriginal: false, thumbnailSize: const ThumbnailSize(200, 200), fit: BoxFit.cover),
                              if (asset.type == AssetType.video)
                                const Positioned(bottom: 5, right: 5, child: Icon(Icons.videocam, color: Colors.white, size: 16)),
                              if (isSelected)
                                Container(color: Colors.black.withOpacity(0.5)),
                              if (_selectedGalleryAsset == asset && !_isMultiSelectMode)
                                Container(color: Colors.white.withOpacity(0.5)),
                              if (_isMultiSelectMode)
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Colors.blue : Colors.white.withOpacity(0.5),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: isSelected
                                        ? Center(child: Text('$selectedIndex', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: _assets.length + 1,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 1, mainAxisSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}