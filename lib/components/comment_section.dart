// comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../services/comment_service.dart';

void showCommentSheet(BuildContext context, int postId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true, // klik luar bisa nutup
    enableDrag: true, // swipe ke bawah bisa nutup
    builder: (_) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(), // klik luar nutup
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return GestureDetector(
              onTap: () {}, // agar tap di dalam tidak menutup
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
                child: CommentSection(
                  scrollController: controller,
                  postId: postId,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

// comment_section.dart
class CommentSection extends StatefulWidget {
  final ScrollController? scrollController;
  final int postId;

  const CommentSection({Key? key, this.scrollController, required this.postId})
    : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class Comment {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final int? parentCommentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Tambahan
  final String username;
  bool liked;
  int likes;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    required this.updatedAt,
    required this.username, // ← Tambahan
    this.liked = false, // ← Tambahan
    this.likes = 0, // ← Tambahan
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['comment_id'],
      postId: json['post_id'],
      userId: json['user_id'],
      content: json['content'],
      parentCommentId: json['parent_comment_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      username: json['username'] ?? 'User', // ← Pastikan backend kirim ini
      likes: json['likes'] ?? 0, // ← Default 0 jika tidak ada
      liked: json['liked'] ?? false, // ← Default false jika tidak ada
    );
  }
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();

  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      print("Loading comments for postId: ${widget.postId}");
      final data = await _commentService.getComments(widget.postId);
      setState(() {
        _comments = data.map((e) => Comment.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e, stacktrace) {
      print('Error loading comments: $e');
      print(stacktrace);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final success = await _commentService.addComment(widget.postId, content);
    if (success) {
      _commentController.clear();
      await _loadComments(); // reload data

      // Scroll ke atas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.scrollController?.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Untuk like bisa ditambahkan nanti pakai API kalau ada
  void _toggleLike(Comment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Komentar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(child: Text('Belum ada komentar'))
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments.reversed.toList()[index];
                      return Column(
                        children: [
                          _buildComment(comment),
                          Divider(
                            color: Colors.grey[300],
                            height: 16,
                            thickness: 1,
                            indent: 52,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  CircleAvatar(radius: 16, child: Text('U')),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Tambahkan komentar...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.send), onPressed: _addComment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[600],
            child: Text(
              comment.username[0].toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: comment.liked
                    ? ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.orangeAccent, Colors.deepOrange],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Icon(Icons.favorite, size: 18),
                      )
                    : Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                onPressed: () => _toggleLike(comment),
              ),
              if (comment.likes > 0)
                Text(
                  comment.likes.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
