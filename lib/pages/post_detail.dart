// lib/pages/post_detail.dart

import 'package:flutter/material.dart';
import '../components/post_card.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/comment_service.dart';
import '../services/like_service.dart';
import '../helper/time_helper.dart';

// NAMA KELAS DIUBAH
class PostDetail extends StatefulWidget {
  final Post post;

  const PostDetail({Key? key, required this.post}) : super(key: key);

  @override
  // NAMA KELAS DIUBAH
  State<PostDetail> createState() => _PostDetailState();
}

// NAMA KELAS DIUBAH
class _PostDetailState extends State<PostDetail> {
  late Post _post;
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();
  final TextEditingController _commentController = TextEditingController();

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

  @override
  void dispose() {
    _commentController.dispose();
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
                SliverToBoxAdapter(
                  child: PostCard(
                    username: _post.user.username,
                    timeAgo: timeAgoFromDate(_post.createdAt.toIso8601String()),
                    imageUrl: _post.mediaUrl ?? '',
                    likes: _post.likesCount,
                    comments: _post.commentsCount,
                    content: _post.caption ?? '',
                    isVerified: _post.user.isVerified,
                    isLiked: _post.isLikedByUser,
                    isBookmarked: false,
                    profileImageUrl: _post.user.profilePictureUrl ?? '',
                    user: _post.user.toJson(),
                    postId: _post.id,
                    onLike: _toggleLike,
                    onBookmark: () {},
                    onShare: () {},
                    onComment: () {},
                    onProfileTap: () {},
                    hasCardDecoration: false,
                  ),
                ),
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _commentController,
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
