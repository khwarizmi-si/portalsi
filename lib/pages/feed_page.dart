// lib/pages/feed_page.dart

import 'package:portal_si/config/api_endpoint.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../components/circular_avatar_fetcher.dart';
import '../components/verified_badge.dart';
import '../providers/scroll_provider.dart';
import '../models/post_model.dart';
import '../components/video_thumbnail_widget.dart';
import '../models/user_model.dart';
import '../utils/navigation_helper.dart';
import '../utils/secure_storage.dart';
import 'clips_viewer_page.dart';
import 'post_detail_page.dart';


class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with AutomaticKeepAliveClientMixin<FeedPage> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearchLoading = false;
  List<Post>? _cachedPosts;
  DateTime? _cacheTimestamp;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void deactivate() {
    _searchFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        if (mounted) {
          setState(() {
            _showSearchResults = false;
            _searchResults = [];
          });
        }
      }
    });
  }

  Future<void> _searchUsers(String query) async {
    if (!mounted) return;
    setState(() {
      _isSearchLoading = true;
      _showSearchResults = true;
    });

    try {
      final String? token = await SecureStorage.getToken();
      if (token == null) {
        log('❌ GAGAL: Token tidak ditemukan untuk pencarian.');
        return;
      }
      final url = Uri.parse('${ApiEndpoints.apiUrl}/users/search?username=$query');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List usersJson = decodedData is List ? decodedData : decodedData['data'];
        if (mounted) {
          setState(() {
            _searchResults = usersJson.map((u) => User.fromJson(u)).toList();
          });
        }
      } else {
        log('❌ GAGAL mencari pengguna: ${response.body}');
      }
    } catch (e) {
      log('🚨 EXCEPTION saat mencari pengguna: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPosts({bool isRefresh = false}) async {
    if (_currentPage == 1 && !isRefresh && _cachedPosts != null && _cacheTimestamp != null) {
      final Duration cacheAge = DateTime.now().difference(_cacheTimestamp!);
      if (cacheAge < const Duration(minutes: 3)) {
        if (mounted) {
          setState(() {
            _posts = _cachedPosts!;
            _isLoading = false;
          });
        }
        log('✅ Menggunakan data dari cache. Usia: ${cacheAge.inSeconds} detik.');
        return;
      }
    }

    if (isRefresh) {
      if (mounted) {
        setState(() {
          _posts = [];
          _currentPage = 1;
          _hasNextPage = true;
          _isLoading = true;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isFetchingMore = true;
      });
    }

    log('🚀 Memulai fetch data untuk halaman: $_currentPage');
    try {
      final String? token = await SecureStorage.getToken();
      if (token == null) {
        log('❌ GAGAL: Token tidak ditemukan. Pengguna mungkin belum login.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi Anda telah berakhir. Silakan login kembali.')),
          );
        }
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFetchingMore = false;
          });
        }
        return;
      }
      final url = Uri.parse('${ApiEndpoints.apiUrl}/explore?page=$_currentPage');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        log('✅ SUKSES: Respons diterima dengan status 200.');
        final data = json.decode(response.body);
        final List postsJson = data['data'];
        final List<Post> newPosts = postsJson.map((p) => Post.fromJson(p)).toList();

        if (_currentPage == 1) {
          _cachedPosts = newPosts;
          _cacheTimestamp = DateTime.now();
          log('💾 Data baru dari API disimpan ke cache.');
        }

        if (mounted) {
          setState(() {
            if (isRefresh || _currentPage == 1) {
              _posts = newPosts;
            } else {
              _posts.addAll(newPosts);
            }
            _hasNextPage = data['next_page_url'] != null;
            if (_hasNextPage) {
              _currentPage++;
            }
          });
        }
      } else {
        log('❌ GAGAL: Status code ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memuat data dari server.')),
          );
        }
      }
    } catch (e) {
      log('🚨 EXCEPTION TERJADI: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  void _onScroll() {
    final scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse) {
      scrollProvider.setScrolled(false);
    } else if (direction == ScrollDirection.forward) {
      scrollProvider.setScrolled(true);
    }
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_hasNextPage && !_isFetchingMore) {
        _fetchPosts();
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Color(0xFFFFFFFF),
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: !_showSearchResults,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _searchController.clear();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildFeedAppBar(),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration( // Ubah menjadi InputDecoration
              hintText: 'Cari pengguna...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
              // --- PERUBAHAN UTAMA ADA DI SINI ---
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  // Membersihkan teks, menyembunyikan hasil, dan menghapus fokus
                  _searchController.clear();
                  if (_searchFocusNode.hasFocus) {
                    _searchFocusNode.unfocus();
                  }
                  if (mounted) {
                    setState(() {
                      // setState akan dipanggil juga oleh _onSearchChanged,
                      // tetapi ini memastikan tampilan segera diperbarui.
                      _showSearchResults = false;
                      _searchResults = [];
                    });
                  }
                },
              )
                  : null,
              // ------------------------------------
            ),
          ),
        ),
      ),
    );
  }

  // lib/pages/feed_page.dart

// ... (kode Anda yang lain di atas)

  Widget _buildBody() {
    if (_showSearchResults) {
      return _buildSearchResults();
    }
    if (_isLoading && _posts.isEmpty) {
      return _buildSkeletonLoader();
    }
    // --- PERUBAHAN UTAMA DIMULAI DI SINI ---
    if (_posts.isEmpty) {
      // Sekarang kita memanggil widget khusus untuk tampilan feed kosong
      return _buildEmptyFeed();
    }
    // --- PERUBAHAN UTAMA SELESAI DI SINI ---
    return RefreshIndicator(
      color: Colors.orange,
      // Mengatur warna latar belakang lingkaran
      backgroundColor: Colors.orange.shade50,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 104.0, top: 8.0),
            sliver: SliverGrid(
              gridDelegate: SliverQuiltedGridDelegate(
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                pattern: const [
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(2, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(2, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                ],
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final post = _posts[index];
                  return _buildPostItem(post);
                },
                childCount: _posts.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isFetchingMore && _posts.isNotEmpty
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

// ... (kode Anda yang lain di bawah)

  Widget _buildSearchResults() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Pengguna tidak ditemukan.'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircularAvatarFetcher(
            radius: 22,
            userId: user.id ?? 0,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.username),
              if (user.isVerified) const SizedBox(width: 6),
              if (user.isVerified) const VerifiedBadge(size: 15),
            ],
          ),
          subtitle: Text(user.fullName ?? ''),
          onTap: () {
            NavigationHelper.navigateToProfile(context, user);
          },
        );
      },
    );
  }

  // lib/pages/feed_page.dart

// ... (letakkan ini di dalam class _FeedPageState)

  /// Widget yang akan ditampilkan ketika feed kosong.
  Widget _buildEmptyFeed() {
    return RefreshIndicator(
      color: Colors.orange,
      // Mengatur warna latar belakang lingkaran
      backgroundColor: Colors.orange.shade50,
      onRefresh: _onRefresh,
      child: LayoutBuilder( // Menggunakan LayoutBuilder agar bisa scroll
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.dynamic_feed_rounded,
                        size: 80.0,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 24.0),
                      const Text(
                        "Feed Masih Kosong",
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        "Sepertinya belum ada postingan untuk ditampilkan. Coba muat ulang untuk melihat konten terbaru.",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24.0),
                      GestureDetector(
                        onTap: _onRefresh,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28.0,
                            vertical: 14.0,
                          ),
                          decoration: BoxDecoration(
                            // 1. Membuat background gradien
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade600, Colors.orange.shade800],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            // 2. Mengecilkan lengkungan sudut
                            borderRadius: BorderRadius.circular(12.0),
                            // 3. Menambahkan bayangan agar terlihat 'terangkat'
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFA7C38).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min, // Agar container menyesuaikan ukuran konten
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10.0),
                              Text(
                                "Muat Ulang",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

// ... (kode Anda yang lain di bawahnya)

  Widget _buildPostItem(Post post) {
    final heroTag = 'post_hero_${post.id}';
    return GestureDetector(
      onTap: () {
        if (post.isVideo) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ClipsViewerPage(initialClip: post)));
        } else {
          NavigationHelper.navigateToPostDetail(context, post.id, initialPost: post);
        }
      },
      child: Hero(
        tag: heroTag,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              if (post.isVideo)
                (post.mediaUrl != null && post.mediaUrl!.isNotEmpty
                    ? VideoThumbnailWidget(videoUrl: post.mediaUrl!)
                    : Container(color: Colors.grey[300]))
              else
                (post.mediaUrl != null && post.mediaUrl!.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: post.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  ),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                )),
              if (post.isVideo)
                const Positioned(
                  top: 8.0,
                  right: 8.0,
                  child: Icon(
                    Icons.video_camera_back_rounded,
                    color: Colors.white,
                    size: 22.0,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(), // Non-aktifkan scroll saat loading
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 104.0, top: 8.0),
            sliver: SliverGrid(
              gridDelegate: SliverQuiltedGridDelegate(
                crossAxisCount: 3,
                mainAxisSpacing: 8.0,
                crossAxisSpacing: 8.0,
                // Gunakan pattern yang sama persis dengan konten asli Anda
                pattern: const [
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(2, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(2, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                  QuiltedGridTile(1, 1),
                ],
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  // Ini adalah placeholder untuk setiap item grid
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0, // Tidak perlu shadow untuk skeleton
                    child: Container(
                      color: Colors.white, // Warna ini akan ditimpa oleh shimmer
                    ),
                  );
                },
                // Bangun sekitar 10-20 item untuk mengisi layar awal
                childCount: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}