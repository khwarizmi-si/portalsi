// lib/widgets/comment_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../components/circular_avatar_fetcher.dart';
import '../components/verified_badge.dart';
import '../controllers/comment_controller.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';

// Widget utama yang dipanggil oleh showModalBottomSheet
class CommentSection extends StatelessWidget {
  final ScrollController? scrollController;
  final int postId;
  final VoidCallback? onCommentAdded;
  final List<Comment> initialComments;

  const CommentSection({
    Key? key,
    this.scrollController,
    required this.postId,
    this.onCommentAdded,
    required this.initialComments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommentController(
        postId: postId,
        initialComments: initialComments, // <-- Perubahan di sini
      ),
      // Gunakan Material agar semua komponennya (seperti TextField) berfungsi normal
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Consumer<CommentController>(
          builder: (context, controller, _) {
            // Gunakan Scaffold untuk struktur header, body, dan input yang kokoh.
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _CommentAppBar(controller: controller),
              body: _CommentList(
                controller: controller,
                scrollController: scrollController,
              ),
              // Pin input field ke bagian bawah dan membuatnya keyboard-aware.
              bottomNavigationBar: _CommentInput(
                controller: controller,
                onCommentAdded: onCommentAdded,
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGET-WIDGET INTERNAL UNTUK MEMBANGUN UI
// -----------------------------------------------------------------------------

/// **AppBar Khusus untuk Panel Komentar**
class _CommentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CommentController controller;
  const _CommentAppBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Hilangkan tombol back otomatis
      centerTitle: true,
      title: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Komentar',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      shape: Border(
        bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

/// **Widget untuk Menampilkan Daftar Komentar**
class _CommentList extends StatelessWidget {
  final CommentController controller;
  final ScrollController? scrollController;

  const _CommentList({required this.controller, this.scrollController});

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    }

    if (controller.errorMessage != null) {
      return Center(child: Text(controller.errorMessage!));
    }

    if (controller.comments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('Belum ada komentar',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Jadilah yang pertama berkomentar!',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: controller.comments.length,
      itemBuilder: (context, index) {
        final comment = controller.comments[index];
        return Padding(padding: EdgeInsets.only(left: 16.0),
        child: _CommentItem(comment: comment),
        );
        // _CommentItem(comment: comment);
      },
    );
  }
}

/// **Widget untuk Menampilkan Satu Item Komentar**
class _CommentItem extends StatelessWidget {
  final Comment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isTemporary = CommentUtils.isTemporary(comment);
    final controller = Provider.of<CommentController>(context, listen: false);

    return Padding(
      padding: EdgeInsets.only(
          left: (comment.depth * 24.0), top: 12.0, bottom: 12.0, right: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================================
          // --- GANTI BAGIAN AVATAR DENGAN INI ---
          // =================================================================
          CircularAvatarFetcher(
            radius: 18,
            userId: comment.userId,
            onTap: isTemporary ? null : () {
              Navigator.pop(context);

              // 1. Buat objek User baru dari data yang ada di 'comment'
              final userToNavigate = User(
                id: comment.userId,
                username: comment.username,
                profilePictureUrl: comment.profilePictureUrl,
                // Tambahkan properti lain dari 'comment' jika ada dan diperlukan
                // Contoh: fullName: comment.fullName, isVerified: comment.isVerified
              );

              // 2. Kirim objek User yang baru dibuat ke fungsi navigasi
              NavigationHelper.navigateToProfile(
                context,
                userToNavigate,
              );
            },
          ),
          // =================================================================
          const SizedBox(width: 12),
          // Konten Komentar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '${comment.username} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (comment.isVerified)
                        const WidgetSpan(
                          child: VerifiedBadge(size: 14),
                          alignment: PlaceholderAlignment.middle,
                        ),
                      TextSpan(
                        text: comment.content,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      CommentUtils.timeAgo(comment.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    if (!isTemporary)
                      GestureDetector(
                        onTap: () {
                          controller.setReplyingTo(comment);
                        },
                        child: Text(
                          'Balas',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Tombol Like
          if (!isTemporary)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    comment.liked ? Icons.favorite : Icons.favorite_border,
                    color: comment.liked ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                  onPressed: () => controller.toggleCommentLike(comment),
                ),
                if (comment.likes > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    comment.likes.toString(),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )
                ]
              ],
            )
        ],
      ),
    );
  }
}

/// **Widget untuk Input Komentar di Bagian Bawah**
class _CommentInput extends StatefulWidget {
  final CommentController controller;
  final VoidCallback? onCommentAdded;

  const _CommentInput({required this.controller, this.onCommentAdded});

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final TextEditingController _textController = TextEditingController();
  bool _canPost = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _canPost = _textController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canPost) return;

    final content = _textController.text.trim();
    _textController.clear();
    FocusScope.of(context).unfocus(); // Tutup keyboard

    final success = await widget.controller.postComment(content);

    if (success && mounted) {
      widget.onCommentAdded?.call();
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.controller.errorMessage ?? 'Gagal mengirim komentar'),
          backgroundColor: Colors.red,
        ),
      );
      // Kembalikan teks jika gagal
      _textController.text = content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = widget.controller.currentUser;
    final replyingTo = widget.controller.replyingToComment;
    // Padding ini penting agar input field tidak tertutup oleh UI sistem (misal: gesture bar)
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Membalas kepada ${replyingTo.username}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    onPressed: () {
                      // Batalkan mode membalas
                      widget.controller.setReplyingTo(null);
                    },
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
                ],
              ),
            ),
          Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1.0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: currentUser?.profilePictureUrl != null &&
                        currentUser!.profilePictureUrl!.isNotEmpty
                    ? NetworkImage(currentUser.profilePictureUrl!)
                    : null,
                child: currentUser?.profilePictureUrl == null ||
                        currentUser!.profilePictureUrl!.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    // --- 👇 UBAH HINT TEXT SESUAI KONTEKS 👇 ---
                    hintText: replyingTo != null
                        ? 'Tulis balasan Anda...'
                        : 'Tambahkan komentar sebagai ${currentUser?.username ?? 'Anda'}...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isCollapsed: true,
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 12),
              // Tombol 'Post' hanya aktif jika ada teks.
              TextButton(
                onPressed: _canPost ? _submit : null,
                child: Text(
                  'Post',
                  style: TextStyle(
                    color: _canPost ? Colors.blue : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
      ),
    );
  }
}
