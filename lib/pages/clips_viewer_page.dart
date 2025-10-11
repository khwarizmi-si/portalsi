// lib/pages/clips_viewer_page.dart
import 'dart:async';
import 'package:flutter/rendering.dart'; // Import untuk ScrollDirection
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/services/post_service.dart';
import 'package:portal_si/widgets/single_clip_player.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../services/video_cache_service.dart';

class ClipsViewerPage extends StatefulWidget {
  final Post initialClip;
  const ClipsViewerPage({super.key, required this.initialClip});

  @override
  State<ClipsViewerPage> createState() => _ClipsViewerPageState();
}

class _ClipsViewerPageState extends State<ClipsViewerPage> {
  final List<Post> _clips = [];
  late final PageController _pageController;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextPageUrl;
  bool _isScrolling = false;
  static Timer? _cacheClearTimer;

  @override
  void initState() {
    super.initState();
    _cacheClearTimer?.cancel();
    _clips.add(widget.initialClip);
    _pageController = PageController();
    // HAPUS LISTENER LAMA DARI SINI
    // _pageController.addListener(_scrollListener);
    _fetchNextClips();
  }

  @override
  void dispose() {
    _cacheClearTimer?.cancel();
    _cacheClearTimer = Timer(const Duration(minutes: 1, seconds: 30), () {
      VideoCacheService().emptyCache();
    });
    // HAPUS removeListener JUGA
    // _pageController.removeListener(_scrollListener);
    _pageController.dispose();
    super.dispose();
  }

  // HAPUS SELURUH FUNGSI _scrollListener
  // void _scrollListener() { ... }

  Future<void> _fetchNextClips() async {
    // ... (fungsi ini tidak berubah)
    try {
      final result = await PostService().getClipsFeed(startingPostId: widget.initialClip.id);
      if (mounted) {
        setState(() {
          _clips.addAll(result['clips']);
          _nextPageUrl = result['next_page_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMoreClips() async {
    // ... (fungsi ini tidak berubah)
    if (_nextPageUrl == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await PostService().getClipsFeed(nextUrl: _nextPageUrl);
      if (mounted) {
        setState(() {
          _clips.addAll(result['clips']);
          _nextPageUrl = result['next_page_url'];
        });
      }
    } catch (e) {
      print("Gagal memuat klip selanjutnya: $e");
    } finally {
      if(mounted) setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFF1A1A1A),
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Color(0xFF1A1A1A),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // GANTI LOGIKA onNotification MENJADI SEPERTI DI BAWAH INI
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // Gunakan UserScrollNotification untuk deteksi yang lebih akurat
                if (notification is UserScrollNotification) {
                  if (notification.direction == ScrollDirection.idle) {
                    // Jika scroll sudah benar-benar berhenti, set _isScrolling ke false
                    if (_isScrolling) {
                      setState(() => _isScrolling = false);
                    }
                  } else {
                    // Jika scroll sedang berjalan (maju atau mundur), set _isScrolling ke true
                    if (!_isScrolling) {
                      setState(() => _isScrolling = true);
                    }
                  }
                }
                // Pindahkan logika fetch more ke sini juga, lebih efisien
                else if (notification is ScrollUpdateNotification) {
                  // Ambil 3 video sebelum akhir list
                  final prefetchIndex = _clips.length - 3;
                  if (_pageController.page != null && _pageController.page! >= prefetchIndex && !_isLoadingMore && _nextPageUrl != null) {
                    _fetchMoreClips();
                  }
                }
                return true;
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _clips.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _clips.length) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  final bool isCurrentPage = _pageController.positions.isNotEmpty
                      ? index == (_pageController.page?.round() ?? 0)
                      : index == 0;

                  final bool videoIsActive = isCurrentPage && !_isScrolling;

                  return SingleClipPlayer(
                    post: _clips[index],
                    isActive: videoIsActive,
                  );
                },
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomBottomNavigation(
                isDarkMode: true,
                selectedIndex: -1,
                onTap: (index) {
                  Provider.of<NavigationProvider>(context, listen: false).navigateToTab(index);
                  Navigator.of(context).pop();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}