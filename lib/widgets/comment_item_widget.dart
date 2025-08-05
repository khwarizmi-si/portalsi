// widgets/comment_item_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/comment.dart';
import '../utils/comment_utils.dart';

class CommentItemWidget extends StatelessWidget {
  final Comment comment;
  final bool isTemporary;
  final Function(Comment) onLikeToggle;

  const CommentItemWidget({
    Key? key,
    required this.comment,
    required this.isTemporary,
    required this.onLikeToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentAvatar(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCommentHeader(),
                SizedBox(height: 6),
                _buildCommentContent(),
              ],
            ),
          ),
          _buildLikeButton(),
        ],
      ),
    );
  }

  Widget _buildCommentAvatar() {
    if (comment.profilePictureUrl == null ||
        comment.profilePictureUrl!.isEmpty) {
      return _buildAvatarFallback();
    }

    return CircleAvatar(
      radius: 20,
      backgroundImage: NetworkImage(comment.profilePictureUrl!),
      backgroundColor: Colors.grey[300],
      onBackgroundImageError: (exception, stackTrace) {
        // Error handled by showing fallback
      },
    );
  }

  Widget _buildAvatarFallback() {
    return CircleAvatar(
      radius: 20,
      backgroundColor:
          isTemporary ? Colors.orange[300] : Colors.deepOrangeAccent,
      child: Text(
        comment.username.isNotEmpty ? comment.username[0].toUpperCase() : 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCommentHeader() {
    return Row(
      children: [
        Text(
          comment.username,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isTemporary ? Colors.grey[600] : Colors.black87,
          ),
        ),
        SizedBox(width: 8),
        Text(
          CommentUtils.timeAgo(comment.createdAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
        if (isTemporary) ...[
          SizedBox(width: 8),
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.orange[400]!,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentContent() {
    return Text(
      comment.content,
      style: TextStyle(
        fontSize: 14,
        color: isTemporary ? Colors.grey[600] : Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildLikeButton() {
    return Column(
      children: [
        IconButton(
          icon: comment.liked
              ? Icon(Icons.favorite, size: 20, color: Colors.red)
              : Icon(Icons.favorite_border, size: 20, color: Colors.grey[500]),
          onPressed: isTemporary
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onLikeToggle(comment);
                },
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        if (comment.likes > 0)
          Text(
            comment.likes.toString(),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
