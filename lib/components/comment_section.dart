// comment_bottom_sheet.dart
import 'package:flutter/material.dart';

void showCommentSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.75, // Ubah jadi 75%
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) {
          return ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(27),
              topRight: Radius.circular(27),
            ),
            child: CommentSection(scrollController: controller),
          );
        },
      );
    },
  );
}

// comment_section.dart
class CommentSection extends StatefulWidget {
  final ScrollController? scrollController;
  const CommentSection({this.scrollController});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class Comment {
  final String username;
  final String content;
  final List<Comment> replies;
  final DateTime createdAt;
  int likes;
  bool liked;

  Comment({
    required this.username,
    required this.content,
    this.replies = const [],
    this.likes = 0,
    this.liked = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final List<Comment> _comments = [
    Comment(username: 'user1', content: 'Komentar pertama', likes: 2),
    Comment(username: 'user2', content: 'Komentar kedua', likes: 0),
    Comment(username: 'user3', content: 'Komentar ketiga', likes: 1),
  ];
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

  void _addComment() {
    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        _comments.add(
          Comment(username: 'current_user', content: _commentController.text),
        );
        _commentController.clear();
      });

      // ⬆️ Scroll otomatis ke atas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollController?.hasClients ?? false) {
          widget.scrollController?.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _toggleLike(Comment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });
  }

  void _replyToComment(Comment parentComment) {
    TextEditingController replyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: replyController,
                decoration: InputDecoration(hintText: 'Balas komentar...'),
                autofocus: true,
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  if (replyController.text.trim().isNotEmpty) {
                    setState(() {
                      parentComment.replies.add(
                        Comment(
                          username: 'current_user',
                          content: replyController.text,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Kirim'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[600],
                child: Text(
                  comment.username[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              SizedBox(width: 12),

              // Content area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and time
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4),

                    // Comment content
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Like button and count
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: comment.liked
                        ? ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.orangeAccent,
                                  Colors.deepOrange,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: Icon(Icons.favorite, size: 18),
                          )
                        : Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                    onPressed: () => _toggleLike(comment),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                  ),

                  if (comment.likes > 0)
                    Text(
                      comment.likes.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.only(left: 52),
            child: GestureDetector(
              onTap: () => _replyToComment(comment),
              child: Text(
                'Balas',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, left: 52),
              child: Column(
                children: comment.replies.map(_buildReply).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReply(Comment reply) {
    return Row(
      children: [
        SizedBox(width: 16),
        CircleAvatar(
          radius: 14,
          child: Text(
            reply.username[0].toUpperCase(),
            style: TextStyle(fontSize: 12),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${reply.username} ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextSpan(text: reply.content),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reversedComments = _comments.reversed.toList();
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
            child: ListView.builder(
              controller: widget.scrollController,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: reversedComments.length,
              itemBuilder: (context, index) => Column(
                children: [
                  _buildComment(reversedComments[index]),
                  Divider(
                    color: Colors.grey[300],
                    height: 16,
                    thickness: 1,
                    indent: 52,
                  ),
                ],
              ),
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

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
