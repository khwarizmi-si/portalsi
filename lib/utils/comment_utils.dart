// utils/comment_utils.dart
import '../models/comment.dart';

class CommentUtils {
  /// Sort comments: Terbaru di atas, terlama di bawah
  static List<Comment> sortCommentsByDate(List<Comment> comments) {
    comments.sort((a, b) {
      // Temporary comments (ID negatif) selalu di atas
      if (a.id < 0 && b.id >= 0) return -1;
      if (a.id >= 0 && b.id < 0) return 1;

      // Sort by created date: terbaru di atas
      return b.createdAt.compareTo(a.createdAt);
    });
    return comments;
  }

  /// Format waktu relative (time ago)
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 10) return 'Baru saja';
    if (diff.inSeconds < 60) return '${diff.inSeconds}d lalu';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}mg lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}bl lalu';
    return '${(diff.inDays / 365).floor()}th lalu';
  }

  /// Generate temporary ID untuk comment
  static int generateTempId() {
    return -DateTime.now().millisecondsSinceEpoch;
  }

  /// Check apakah comment adalah temporary
  static bool isTemporary(Comment comment) {
    return comment.id < 0;
  }

  /// Create temporary comment
  static Comment createTemporaryComment({
    required int postId,
    required String content,
    required String username,
    String? profilePictureUrl,
  }) {
    return Comment(
      id: generateTempId(),
      postId: postId,
      userId: 0,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      username: username,
      profilePictureUrl: profilePictureUrl,
      likes: 0,
      liked: false,
    );
  }
}
