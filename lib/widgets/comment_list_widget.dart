// widgets/comment_list_widget.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/comment_utils.dart';
import 'comment_item_widget.dart';

class CommentListWidget extends StatelessWidget {
  final List<Comment> comments;
  final ScrollController? scrollController;
  final Function(Comment) onLikeToggle;
  final VoidCallback onRetry;
  final bool hasError;

  const CommentListWidget({
    Key? key,
    required this.comments,
    this.scrollController,
    required this.onLikeToggle,
    required this.onRetry,
    this.hasError = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hasError && comments.isEmpty) {
      return _buildErrorState();
    }

    if (comments.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCommentsList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Gagal memuat komentar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Periksa koneksi internet Anda',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Belum ada yang berkomentar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Jadilah yang pertama memberikan komentar!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        final isTemporary = CommentUtils.isTemporary(comment);

        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Column(
            children: [
              CommentItemWidget(
                comment: comment,
                isTemporary: isTemporary,
                onLikeToggle: onLikeToggle,
              ),
              if (index < comments.length - 1)
                Divider(
                  color: Colors.grey[200],
                  height: 20,
                  thickness: 1,
                  indent: 52,
                ),
            ],
          ),
        );
      },
    );
  }
}
