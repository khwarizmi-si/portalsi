// widgets/comment_header_widget.dart
import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/comment_utils.dart';

class CommentHeaderWidget extends StatelessWidget {
  final List<Comment> comments;
  final VoidCallback onRefresh;

  const CommentHeaderWidget({
    Key? key,
    required this.comments,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final realCommentsCount = comments.where((c) => c.id > 0).length;
    final tempCommentsCount = comments.where((c) => c.id < 0).length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Komentar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child:
                    _buildCommentCounter(realCommentsCount, tempCommentsCount),
              ),
            ],
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCounter(int realCount, int tempCount) {
    if (tempCount > 0) {
      return Text(
        '$realCount komentar${tempCount > 0 ? ' (+$tempCount mengirim...)' : ''}',
        key: ValueKey('sending-$realCount-$tempCount'),
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange[600],
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (realCount > 0) {
      return Text(
        '$realCount komentar',
        key: ValueKey('count-$realCount'),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      );
    } else {
      return Text(
        'Belum ada komentar',
        key: ValueKey('empty'),
        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      );
    }
  }
}
