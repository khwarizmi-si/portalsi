// lib/pages/post_detail.dart

import 'package:flutter/material.dart';
import '../components/video_player_widget.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/comment_service.dart';
import '../services/like_service.dart';
import '../helper/time_helper.dart';
import '../utils/navigation_helper.dart';

class PostDetail extends StatefulWidget {
  final int postId;

  const PostDetail({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  late Future<Post> _postFuture;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  void _fetchPostData() {
    setState(() {
      _postFuture = _postService.getPostDetail(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Postingan', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<Post>(
        future: _postFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Gagal memuat data: ${snapshot.error}"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchPostData,
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("Data postingan tidak ditemukan."));
          }
          final post = snapshot.data!;
          return PostDetailView(post: post);
        },
      ),
    );
  }
}

// =======================================================================
// Widget Utama untuk Tampilan Detail Postingan
// =======================================================================
class PostDetailView extends StatefulWidget {
  final Post post;

  const PostDetailView({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late Post _post;
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  // --- 1. FUNGSI BARU UNTUK MENGURUS PENGHAPUSAN POST ---
  Future<void> _handleDeletePost() async {
    // Tampilkan dialog konfirmasi
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat diurungkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    // Jika pengguna mengonfirmasi, lanjutkan penghapusan
    if (confirmDelete == true) {
      try {
        // Panggil service untuk menghapus post
        final success = await PostService().deletePost(_post.id);
        if (success && mounted) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
          // Tutup halaman detail setelah berhasil dihapus
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Tampilkan pesan error jika gagal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus postingan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentService.getComments(_post.id);
      if (mounted) setState(() => _comments = comments);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    final originalLikedStatus = _post.isLikedByUser;
    final originalLikesCount = _post.likesCount;
    setState(() {
      _post = _post.copyWith(
        isLikedByUser: !originalLikedStatus,
        likesCount: originalLikesCount + (originalLikedStatus ? -1 : 1),
      );
    });
    try {
      await _likeService.toggleLikeHttp(_post.id);
    } catch (e) {
      setState(() {
        _post = _post.copyWith(
          isLikedByUser: originalLikedStatus,
          likesCount: originalLikesCount,
        );
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) return;
    setState(() => _isPostingComment = true);
    try {
      final newComment = await _commentService.addComment(
        _post.id,
        _commentController.text.trim(),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _comments.insert(0, newComment);
        _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _focusCommentField() {
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildPostHeader()),
              SliverToBoxAdapter(child: _buildPostMedia()),
              SliverToBoxAdapter(child: _buildPostActions()),
              SliverToBoxAdapter(child: _buildPostInfo()),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Komentar (${_comments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              _buildCommentList(),
            ],
          ),
        ),
        _buildCommentInputField(),
      ],
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(_post.user.profilePictureUrl ?? '')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_post.user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(timeAgoFromDate(_post.createdAt.toIso8601String()), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          // --- 2. GANTI IconButton DENGAN PopupMenuButton ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'delete') {
                _handleDeletePost();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hapus Postingan', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              // Tambahkan item menu lain di sini jika perlu
            ],
          ),
        ],
      ),
    );
  }

  // Sisa widget lainnya tidak perlu diubah
  Widget _buildPostMedia() {
    if (_post.mediaUrl == null || _post.mediaUrl!.isEmpty) return const SizedBox.shrink();
    if (_post.isVideo) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: VideoPlayerWidget(videoUrl: _post.mediaUrl!));
    } else {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Hero(tag: 'post_hero_${_post.id}', child: Image.network(_post.mediaUrl!)));
    }
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_post.isLikedByUser ? Icons.favorite : Icons.favorite_border, color: _post.isLikedByUser ? Colors.red : Colors.black),
            onPressed: _toggleLike,
          ),
          IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: _focusCommentField),
          IconButton(icon: const Icon(Icons.send_outlined), onPressed: () {}),
          const Spacer(),
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildPostInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_post.likesCount} suka', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(text: '${_post.user.username} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: _post.caption ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    if (_isLoadingComments) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())));
    if (_comments.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('Jadilah yang pertama berkomentar!'))));
    return SliverList(delegate: SliverChildBuilderDelegate((context, index) => _CommentTile(comment: _comments[index]), childCount: _comments.length));
  }

  Widget _buildCommentInputField() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))]),
      padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, MediaQuery.of(context).padding.bottom + 8.0),
      child: Row(
        children: [
          const CircleAvatar(radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: 'Tambahkan komentar...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _postComment),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              final userJson = {'id': comment.userId, 'username': comment.username, 'profile_picture_url': comment.profilePictureUrl, 'is_verified': false, 'followers_count': 0, 'following_count': 0, 'posts_count': 0, 'bio': '', 'full_name': comment.username};
              Navigator.pop(context);
              NavigationHelper.navigateToProfile(context, userJson);
            },
            child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(comment.profilePictureUrl ?? '')),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '${comment.username} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: comment.content)])),
                const SizedBox(height: 4),
                Text(timeAgoFromDate(comment.createdAt.toIso8601String()), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}