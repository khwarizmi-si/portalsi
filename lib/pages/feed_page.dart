// lib/pages/feed_page.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Pastikan import ini ada
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:portal_si/pages/post_detail_page.dart';
import 'package:provider/provider.dart';
import '../providers/scroll_provider.dart';

import '../models/post_model.dart';
import '../models/user_model.dart';
import '../utils/secure_storage.dart';
import 'other_profile_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearchLoading = false;
  List<Post>? _cachedPosts;
  DateTime? _cacheTimestamp;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchUsers(query);
      } else {
        setState(() {
          _showSearchResults = false;
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchUsers(String query) async {
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
      final url = Uri.parse('https://api-new.portalsi.com/api/users/search?username=$query');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);
        final List usersJson = decodedData is List ? decodedData : decodedData['data'];
        setState(() {
          _searchResults = usersJson.map((u) => User.fromJson(u)).toList();
        });
      } else {
        log('❌ GAGAL mencari pengguna: ${response.body}');
      }
    } catch (e) {
      log('🚨 EXCEPTION saat mencari pengguna: $e');
    } finally {
      if(mounted) {
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
        setState(() {
          _posts = _cachedPosts!;
          _isLoading = false;
        });
        log('✅ Menggunakan data dari cache. Usia: ${cacheAge.inSeconds} detik.');
        return;
      }
    }
    if (isRefresh) {
      setState(() {
        _posts = [];
        _currentPage = 1;
        _isLoading = true;
      });
    }
    setState(() {
      _isFetchingMore = true;
    });
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
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
        return;
      }
      final url = Uri.parse('https://api-new.portalsi.com/api/explore?page=$_currentPage');
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
        setState(() {
          if (isRefresh || _currentPage == 1) {
            _posts = newPosts;
          } else {
            _posts.addAll(newPosts);
          }
          _lastPage = data['last_page'];
          _currentPage++;
        });
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
      if(mounted) {
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
      if (_currentPage <= _lastPage && !_isFetchingMore) {
        _fetchPosts();
      }
    }
  }

  Future<void> _onRefresh() async {
    await _fetchPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: !_showSearchResults,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _searchController.clear();
        },
        // --- 👇 PERUBAHAN UTAMA DI SINI 👇 ---
        child: Scaffold(
          backgroundColor: Colors.transparent,
          // Hapus properti appBar
          body: Column(
            children: [
              // Tambahkan AppBar kustom sebagai widget pertama
              _buildFeedAppBar(),
              // Bungkus sisa body dengan Expanded
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BARU: APPBAR KUSTOM ---
  Widget _buildFeedAppBar() {
    return Container(
      // Atur padding untuk status bar
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
      // Konten AppBar
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25.0),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Cari pengguna...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_showSearchResults) {
      return _buildSearchResults();
    }
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_posts.isEmpty) {
      return const Center(child: Text('Tidak ada postingan untuk ditampilkan.'));
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(8.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostItem(post);
              },
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
          leading: CircleAvatar(
            backgroundImage: user.profilePictureUrl != null
                ? NetworkImage(user.profilePictureUrl!)
                : null,
            child: user.profilePictureUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(user.username),
          subtitle: Text(user.fullName ?? ''),
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherProfilePage(username: user.username),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPostItem(Post post) {
    final heroTag = 'post_hero_${post.id}';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(
              postId: post.id,
              initialPost: post,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: !post.isVideo
              ? (post.mediaUrl != null && post.mediaUrl!.isNotEmpty
              ? Image.network(
            post.mediaUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: Colors.grey[200]);
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              );
            },
          )
              : Container(
            color: Colors.grey[200],
            child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
          ))
              : AspectRatio(
            aspectRatio: 1,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                Container(color: Colors.grey[300]),
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 40.0,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}