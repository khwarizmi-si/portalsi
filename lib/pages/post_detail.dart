// lib/pages/post_detail.dart

import 'package:flutter/material.dart';
// --- [PERUBAHAN] --- Import widget PostCard dan helper lainnya
import '../components/post_card.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/like_service.dart';
import '../helper/time_helper.dart';
import '../utils/navigation_helper.dart';


class PostDetail extends StatefulWidget {
  final Post post;

  const PostDetail({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  late Post _post;
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode(); // Untuk fokus ke input komentar

  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentService.getComments(_post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
        });
      }
    } catch (e) {
      print("Error fetching comments: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    // Fungsi ini sama, tapi sekarang akan mengupdate state _post
    // yang kemudian akan di-pass ke PostCard untuk re-render
    final originalLikedStatus = _post.isLikedByUser;
    final originalLikesCount = _post.likesCount;
    setState(() {
      _post.isLikedByUser = !originalLikedStatus;
      _post.likesCount += originalLikedStatus ? -1 : 1;
    });

    try {
      await _likeService.toggleLike(_post.id);
    } catch (e) {
      setState(() {
        _post.isLikedByUser = originalLikedStatus;
        _post.likesCount = originalLikesCount;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) {
      return;
    }

    setState(() => _isPostingComment = true);

    try {
      final newComment = await _commentService.addComment(
        _post.id,
        _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus(); // Tutup keyboard
      setState(() {
        _comments.insert(0, newComment);
        _post.commentsCount++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengirim komentar: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  void _focusCommentField() {
    // Fungsi untuk memberi fokus pada input text field komentar
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // --- [PERUBAHAN UTAMA] ---
                // Layout kustom diganti dengan satu widget PostCard
                SliverToBoxAdapter(
                  child: PostCard(
                    // Menggunakan data dari state `_post`
                    username: _post.user.username,
                    timeAgo: timeAgoFromDate(_post.createdAt.toIso8601String()),
                    mediaUrl: _post.mediaUrl ?? '',
                    isVideo: _post.isVideo, // Penting untuk membedakan video
                    likes: _post.likesCount,
                    comments: _post.commentsCount,
                    content: _post.caption ?? '',
                    isVerified: _post.user.isVerified,
                    isLiked: _post.isLikedByUser,
                    isBookmarked: false, // Ganti jika ada datanya
                    profileImageUrl: _post.user.profilePictureUrl ?? '',
                    user: _post.user.toJson(),
                    postId: _post.id,
                    onLike: _toggleLike, // Hubungkan dengan fungsi like
                    onBookmark: () {},
                    onShare: () {},
                    onComment: _focusCommentField, // Arahkan ke input komentar
                    onProfileTap: () => NavigationHelper.navigateToProfile(context, _post.user.toJson()),
                    // Hilangkan dekorasi kartu agar menyatu dengan halaman
                    hasCardDecoration: false,
                  ),
                ),
                // --- AKHIR PERUBAHAN ---
                const SliverToBoxAdapter(child: Divider(height: 1)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Text(
                      'Komentar (${_comments.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                _buildCommentList(),
              ],
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  // --- [DIHAPUS] ---
  // Widget `_buildPostContent()` yang panjang tidak lagi diperlukan.

  Widget _buildCommentList() {
    if (_isLoadingComments) {
      return const SliverToBoxAdapter(
        child: Center(
            child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator())),
      );
    }

    if (_comments.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40.0),
            child: Text('Jadilah yang pertama berkomentar!'),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final comment = _comments[index];
          return _CommentTile(comment: comment);
        },
        childCount: _comments.length,
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            // Anda mungkin ingin menampilkan foto profil user yang sedang login di sini
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode, // Hubungkan focus node
              decoration: InputDecoration(
                hintText: 'Tambahkan komentar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          const SizedBox(width: 8),
          _isPostingComment
              ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _postComment,
          ),
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
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.profilePictureUrl ?? ''),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${comment.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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