// comment_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../widgets/comment_section.dart';

void showCommentSheet(BuildContext context, int postId,
    {VoidCallback? onCommentAdded}) {
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
