// widgets/comment_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/services/user_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
import '../services/comment_service.dart';
import '../models/comment.dart';
import '../utils/comment_utils.dart';
import 'comment_header_widget.dart';
import 'comment_list_widget.dart';
import 'comment_input_widget.dart';

class CommentSection extends StatefulWidget {
  final ScrollController? scrollController;
  final int postId;
  final VoidCallback? onCommentAdded;

  const CommentSection({
    Key? key,
    this.scrollController,
    required this.postId,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _commentService = CommentService();
  final ProfileService _profileService = ProfileService(); // Gunakan singleton
  String _currentUserName = '';
  String _currentUserAvatar = '';
  List<Comment> _comments = [];
  bool _hasError = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Gabungkan dua load awal
  }

  // Gabungkan dua fungsi load awal menjadi satu
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadCurrentUserData(),
      _loadCommentsInBackground(),
    ]);
  }

  Future<void> _loadCurrentUserData() async {
    try {
      // 1. Coba ambil dari SecureStorage dulu
      String? username = await SecureStorage.getUsername();
      String? profilePicture = await SecureStorage.getProfilePicture();

      // 2. Jika tidak ada di storage, ambil dari API
      if (username == null || profilePicture == null) {
        final profile = await _profileService.getCurrentUserForComments();
        if (profile != null) {
          username = profile.username;
          profilePicture = profile.profilePictureUrl;
        }
      }

      // 3. Update UI dengan data yang valid
      if (mounted) {
        setState(() {
          _currentUserName = username ?? 'Anda';
          _currentUserAvatar = profilePicture ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUserName = 'Anda';
          _currentUserAvatar = '';
        });
      }
    }
  }

  Future<void> _loadCommentsInBackground() async {
    try {
      final data = await _commentService.getComments(widget.postId);
      final comments = data.map((item) => Comment.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _comments = CommentUtils.sortCommentsByDate(comments);
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Gagal memuat komentar';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCommentSubmit(String content) async {
    // Optimistic update
    final tempComment = CommentUtils.createTemporaryComment(
      postId: widget.postId,
      content: content,
      username: _currentUserName,
      profilePictureUrl: _currentUserAvatar,
    );

    setState(() {
      _comments.insert(0, tempComment);
      _comments = CommentUtils.sortCommentsByDate(_comments);
    });

    _scrollToTop();

    try {
      final success =
          await _commentService.sendCommentOptimistic(widget.postId, content);

      if (success) {
        await _autoSyncAfterAdd();
        widget.onCommentAdded?.call();
        _showSuccessFeedback();
      } else {
        _rollbackComment(tempComment);
        _showErrorSnackbar('Gagal mengirim komentar');
      }
    } catch (e) {
      _rollbackComment(tempComment);
      _showErrorSnackbar('Koneksi bermasalah, coba lagi');
    }
  }

  Future<void> _autoSyncAfterAdd() async {
    try {
      final data = await _commentService.getComments(widget.postId);
      final serverComments =
          data.map((item) => Comment.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _comments = CommentUtils.sortCommentsByDate(serverComments);
          _hasError = false;
        });
      }
    } catch (e) {
      // Handle error sync, tapi jangan rollback UI
      if (mounted) {
        _showErrorSnackbar('Gagal sinkronisasi data terbaru');
      }
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController?.hasClients == true) {
        widget.scrollController?.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _rollbackComment(Comment tempComment) {
    if (mounted) {
      setState(() {
        _comments.removeWhere((comment) => comment.id == tempComment.id);
      });
    }
  }

  void _showSuccessFeedback() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Komentar berhasil dikirim'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _loadCommentsInBackground(); // Panggil ulang untuk memuat ulang
            },
          ),
        ),
      );
    }
  }

  Future<void> _manualRefresh() async {
    try {
      HapticFeedback.lightImpact();
      final data = await _commentService.getComments(widget.postId);
      final comments = data.map((item) => Comment.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _comments = CommentUtils.sortCommentsByDate(comments);
          _hasError = false;
          _errorMessage = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar diperbarui'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memperbarui komentar');
    }
  }

  void _toggleLike(Comment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });

    HapticFeedback.lightImpact();
    // TODO: Implementasi pengiriman ke server di background
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _loadCommentsInBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          CommentHeaderWidget(
            comments: _comments,
            onRefresh: _manualRefresh,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CommentListWidget(
                    comments: _comments,
                    scrollController: widget.scrollController,
                    onLikeToggle: _toggleLike,
                    onRetry: _handleRetry,
                    hasError: _hasError,
                  ),
          ),
          CommentInputWidget(
            currentUserName: _currentUserName,
            currentUserAvatar: _currentUserAvatar,
            onCommentSubmit: _handleCommentSubmit,
          ),
        ],
      ),
    );
  }
}
