// comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/comment_section.dart';

void showCommentSheet(BuildContext context, Post post, {VoidCallback? onCommentAdded}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (_) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                // --- 👇 PERBAIKAN #2: Sesuaikan pemanggilan CommentSection 👇 ---
                child: CommentSection(
                  scrollController: controller,
                  postId: post.id, // Ambil id dari objek post
                  initialComments: post.comments, // Kirim daftar komentar dari post
                  onCommentAdded: onCommentAdded,
                ),
              ),
            );
          },
        ),
      );
    },
  );
}