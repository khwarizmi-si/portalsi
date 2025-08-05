// widgets/comment_input_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommentInputWidget extends StatefulWidget {
  final String currentUserName;
  final String currentUserAvatar;
  final Function(String) onCommentSubmit;

  const CommentInputWidget({
    Key? key,
    required this.currentUserName,
    required this.currentUserAvatar,
    required this.onCommentSubmit,
  }) : super(key: key);

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildUserAvatar(),
            SizedBox(width: 12),
            Expanded(child: _buildTextInput()),
            SizedBox(width: 8),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    if (widget.currentUserAvatar.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(widget.currentUserAvatar),
        backgroundColor: Colors.grey[300],
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading profile picture: $exception');
        },
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.deepOrangeAccent,
        child: Text(
          widget.currentUserName.isNotEmpty
              ? widget.currentUserName[0].toUpperCase()
              : 'A',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  Widget _buildTextInput() {
    return Container(
      constraints: BoxConstraints(maxHeight: 100),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _commentController,
        decoration: InputDecoration(
          hintText: 'Tulis komentar Anda...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          border: InputBorder.none,
        ),
        maxLines: null,
        textInputAction: TextInputAction.send,
        onSubmitted: (_) => _submitComment(),
        onChanged: (text) {
          setState(() {}); // Update send button
        },
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _commentController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasText) {
          _submitComment();
          HapticFeedback.lightImpact();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasText ? Colors.deepOrangeAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(22),
          boxShadow: hasText
              ? [
                  BoxShadow(
                    color: Colors.deepOrangeAccent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.send_rounded,
          color: hasText ? Colors.white : Colors.grey[500],
          size: 20,
        ),
      ),
    );
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    widget.onCommentSubmit(content);
    _commentController.clear();
    setState(() {}); // Update send button state
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
