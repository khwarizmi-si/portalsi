// lib/pages/post_detail.dart

import 'package:flutter/material.dart';
import 'package:portal_si/components/post_header.dart';
import 'package:portal_si/controllers/home_controller.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/comment_service.dart';
import '../helper/time_helper.dart';

// HALAMAN UTAMA POST DETAIL
class PostDetail extends StatefulWidget {
  final int postId;

  const PostDetail({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  // [DIUBAH] State & logic komentar sudah dipindahkan ke CommentSheetWidget
  // _PostDetailState sekarang menjadi jauh lebih sederhana.

  // Aksi sekarang memanggil fungsi dari HomeController
  void _toggleLike(BuildContext context) {
    Provider.of<HomeController>(context, listen: false)
        .toggleLike(widget.postId);
  }

  // [BARU] Fungsi untuk menampilkan bottom sheet komentar ala Instagram
  void _showCommentSheet(BuildContext context, int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Penting agar sheet bisa fullscreen
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Menggunakan DraggableScrollableSheet untuk UX yang lebih baik
        return DraggableScrollableSheet(
          initialChildSize: 0.9, // Tinggi awal sheet (90% layar)
          minChildSize: 0.5, // Tinggi minimal saat di-drag
          maxChildSize: 0.9, // Tinggi maksimal
          builder: (_, scrollController) {
            return CommentSheetWidget(
              postId: postId,
              scrollController: scrollController,
            );
          },
        );
      },
    );
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
      body: Consumer<HomeController>(
        builder: (context, controller, child) {
          final Post post;
          try {
            post = controller.getPostById(widget.postId);
          } catch (e) {
            return const Center(
                child: Text("Post tidak ditemukan atau telah dihapus."));
          }

          // [DIUBAH] Build method sekarang hanya fokus menampilkan post
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildPostContent(context, post)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPostContent(BuildContext context, Post post) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: PostHeader(
              username: post.user.username,
              timeAgo: timeAgoFromDate(post.createdAt.toIso8601String()),
              profileImageUrl: post.user.profilePictureUrl ?? '',
              isVerified: post.user.isVerified,
              user: post.user.toJson(),
            ),
          ),
          if (post.mediaUrl != null && post.mediaUrl!.isNotEmpty)
            Image.network(post.mediaUrl!,
                width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                _buildActionButton(
                  icon: post.isLikedByUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: post.isLikedByUser ? Colors.red : Colors.black,
                  onTap: () => _toggleLike(context),
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  onTap: () => _showCommentSheet(
                      context, post.id), // Panggil bottom sheet
                ),
                const Spacer(),
                _buildActionButton(icon: Icons.bookmark_border, onTap: () {}),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.likesCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('${post.likesCount} suka',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                if (post.caption != null && post.caption!.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(
                            text: '${post.user.username} ',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: post.caption!),
                      ],
                    ),
                  ),
                if (post.commentsCount > 0) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _showCommentSheet(
                        context, post.id), // Panggil bottom sheet
                    child: Text('Lihat semua ${post.commentsCount} komentar',
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(icon, color: color ?? Colors.black, size: 26),
      ),
    );
  }
}

// =======================================================================
// [BARU] WIDGET KHUSUS UNTUK MENAMPILKAN KOMENTAR DI BOTTOM SHEET
// =======================================================================

class CommentSheetWidget extends StatefulWidget {
  final int postId;
  final ScrollController scrollController;

  const CommentSheetWidget({
    Key? key,
    required this.postId,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<CommentSheetWidget> createState() => _CommentSheetWidgetState();
}

class _CommentSheetWidgetState extends State<CommentSheetWidget> {
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentFocusNode
          .requestFocus(); // Langsung fokus ke input saat sheet muncul
    });
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _commentService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print("--- DEBUG: Gagal mengambil komentar di sheet: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    final homeController = Provider.of<HomeController>(context, listen: false);
    final currentUser = homeController.currentUser;
    final content = _commentController.text.trim();

    if (currentUser == null) return;

    homeController.postComment(widget.postId, content);
    _commentController.clear();

    final now = DateTime.now();
    final newComment = Comment(
      id: now.millisecondsSinceEpoch,
      content: content,
      username: currentUser.username,
      profilePictureUrl: currentUser.profilePictureUrl,
      createdAt: now,
      postId: widget.postId,
      userId: currentUser.id!,
      updatedAt: now,
    );

    setState(() {
      _comments.insert(0, newComment);
      _isPosting = false;
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan padding bawah untuk keyboard
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle untuk drag
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Text("Komentar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Divider(),

          // Daftar Komentar
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(
                        child: Text("Jadilah yang pertama berkomentar."))
                    : ListView.builder(
                        controller: widget
                            .scrollController, // Gunakan scroll controller dari DraggableSheet
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          return _CommentTile(comment: _comments[index]);
                        },
                      ),
          ),

          // Input Field Komentar
          _buildCommentInputField(keyboardPadding),
        ],
      ),
    );
  }

  Widget _buildCommentInputField(double keyboardPadding) {
    final currentUser =
        Provider.of<HomeController>(context, listen: false).currentUser;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + keyboardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: currentUser?.profilePictureUrl != null
                ? NetworkImage(currentUser!.profilePictureUrl!)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              decoration: InputDecoration(
                hintText: 'Tambahkan komentar...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          IconButton(
            icon: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: _postComment,
          )
        ],
      ),
    );
  }
}

// TILE UNTUK SATU KOMENTAR
class _CommentTile extends StatelessWidget {
  final Comment comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: comment.profilePictureUrl != null &&
                    comment.profilePictureUrl!.isNotEmpty
                ? NetworkImage(comment.profilePictureUrl!)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                          text: '${comment.username} ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: comment.content),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgoFromDate(comment.createdAt.toIso8601String()),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
