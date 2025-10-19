import 'package:flutter/material.dart';
import 'package:portal_si/components/video_thumbnail_widget.dart'; // Pastikan path ini benar
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/pages/post_detail_page.dart';
import 'package:portal_si/services/bookmark_service.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late Future<List<Post>> _bookmarksFuture;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  void _loadBookmarks() {
    setState(() {
      _bookmarksFuture = BookmarkService().getBookmarkedPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Postingan Disimpan',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add, color: Colors.black),
        //     onPressed: () {
        //       // TODO: Fungsionalitas untuk membuat koleksi baru
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // _buildFilterChips(),vvf
          Expanded(
            child: RefreshIndicator(
              color: Colors.orange,
              // Mengatur warna latar belakang lingkaran
              backgroundColor: Colors.orange.shade50,
              onRefresh: () async => _loadBookmarks(),
              child: FutureBuilder<List<Post>>(
                future: _bookmarksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Anda belum menyimpan postingan apapun.'));
                  }

                  final posts = snapshot.data!;
                  return _buildBookmarksGrid(posts);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFilterChips() {
  //   // Untuk saat ini, filter chips hanya sebagai UI
  //   return SingleChildScrollView(
  //     scrollDirection: Axis.horizontal,
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: Align(child: Row(
  //       children: [
  //         _Chip(label: 'Postingan', isSelected: true),
  //         // _Chip(label: 'Koleksi'),
  //         // _Chip(label: 'Reels'),
  //         // _Chip(label: 'Postingan'),
  //         // _Chip(label: 'Audio'),
  //       ],
  //     ),),
  //   );
  // }

  Widget _buildBookmarksGrid(List<Post> posts) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailPage(
                  postId: post.id,
                  initialPost: post, // Kirim data awal agar loading lebih cepat
                ),
              ),
            );
          },
          child: _GridItem(post: post),
        );
      },
    );
  }
}

// Widget internal untuk item di dalam grid
class _GridItem extends StatelessWidget {
  final Post post;
  const _GridItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tampilkan media (gambar atau thumbnail video)
        post.isVideo
            ? VideoThumbnailWidget(videoUrl: post.mediaUrl!)
            : Image.network(post.mediaUrl!, fit: BoxFit.cover),

        // Tambahkan ikon di pojok kanan atas jika ini adalah video
        if (post.isVideo)
          const Positioned(
            top: 8,
            right: 8,
            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
          ),
      ],
    );
  }
}

// Widget internal untuk filter chip
class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _Chip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}