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
  String _currentUserName = '';
  String _currentUserAvatar = '';
  List<Comment> _comments = [];
  bool _hasError = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Track temporary comments untuk prevent duplicate
  final Set<int> _temporaryIds = {};

  @override
  void initState() {
    super.initState();
    _loadCommentsInBackground();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      print('🔄 Loading current user data...');

      // 1. Coba ambil dari SecureStorage dulu (fastest)
      String username = await SecureStorage.getUsername() ?? '';
      String profilePicture = await SecureStorage.getProfilePicture() ?? '';

      print(
          '📱 From Storage - Username: "$username", Avatar: "${profilePicture.isNotEmpty ? 'Available' : 'Empty'}"');

      // 2. Jika tidak ada di storage, ambil dari API
      if (username.isEmpty || profilePicture.isEmpty) {
        print('🌐 Loading user data from API...');
        final profileService = ProfileService();
        final userInfo = await profileService.getCurrentUserForComments();

        if (userInfo != null) {
          print('📥 API Response: $userInfo');

          // Coba berbagai field untuk username
          String apiUsername = '';
          if (userInfo.containsKey('username') &&
              userInfo['username'] != null) {
            apiUsername = userInfo['username'].toString();
          } else if (userInfo.containsKey('name') && userInfo['name'] != null) {
            apiUsername = userInfo['name'].toString();
          } else if (userInfo.containsKey('user_name') &&
              userInfo['user_name'] != null) {
            apiUsername = userInfo['user_name'].toString();
          }

          username = apiUsername.isNotEmpty ? apiUsername : username;
          profilePicture =
              userInfo['profile_picture_url']?.toString() ?? profilePicture;

          print('✅ User data loaded from API - Username: "$username"');
        } else {
          print('⚠️ Failed to load from API, using storage data');
        }
      }

      // 3. Update UI dengan data yang valid
      if (mounted) {
        setState(() {
          _currentUserName = username.isNotEmpty ? username : 'Anda';
          _currentUserAvatar = profilePicture;
        });

        print(
            '🎯 Final Current User - Name: "$_currentUserName", Avatar: "${_currentUserAvatar.isNotEmpty ? 'Available' : 'Empty'}"');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
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
      await Future.delayed(Duration.zero);
      final data = await _commentService.getComments(widget.postId);

      List<Comment> comments = [];
      if (data.isNotEmpty) {
        for (var item in data) {
          try {
            comments.add(Comment.fromJson(item));
          } catch (e) {
            print("Error parsing comment: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _comments = CommentUtils.sortCommentsByDate(comments);
          _hasError = false;
          _isLoading = false; // ✅ add this
        });
      }
    } catch (e) {
      print('Background load failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Gagal memuat komentar';
          _isLoading = false; // ✅ add this
        });
      }
    }
  }

  Future<void> _autoSyncAfterAdd() async {
    try {
      print('🔄 Auto-syncing comments after successful add...');

      final data = await _commentService.getComments(widget.postId);

      List<Comment> serverComments = [];
      if (data.isNotEmpty) {
        for (var item in data) {
          try {
            serverComments.add(Comment.fromJson(item));
          } catch (e) {
            print("Error parsing comment during auto-sync: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _comments.removeWhere((comment) => comment.id < 0);
          _temporaryIds.clear();
          _comments = CommentUtils.sortCommentsByDate(serverComments);
          _hasError = false;
        });

        print('✅ Auto-sync completed! ${_comments.length} comments loaded');
      }
    } catch (e) {
      print('⚠️ Auto-sync failed: $e');
    }
  }

  Future<void> _handleCommentSubmit(String content) async {
    final tempComment = CommentUtils.createTemporaryComment(
      postId: widget.postId,
      content: content,
      username: _currentUserName,
      profilePictureUrl: _currentUserAvatar,
    );

    // Update UI instantly
    setState(() {
      _comments.insert(0, tempComment);
      _comments = CommentUtils.sortCommentsByDate(_comments);
      _temporaryIds.add(tempComment.id);
    });

    _scrollToTop();
    _sendCommentAndAutoSync(tempComment, content);
  }

  Future<void> _sendCommentAndAutoSync(
      Comment tempComment, String content) async {
    try {
      print('📤 Sending comment to server...');
      final success =
          await _commentService.sendCommentOptimistic(widget.postId, content);

      if (success) {
        print('✅ Comment sent successfully! Auto-syncing...');
        await Future.delayed(Duration(milliseconds: 500));
        await _autoSyncAfterAdd();

        if (widget.onCommentAdded != null) {
          widget.onCommentAdded!();
        }

        _scrollToTop();
        _showSuccessFeedback();
      } else {
        _rollbackComment(tempComment);
        _showErrorSnackbar('Gagal mengirim komentar');
      }
    } catch (e) {
      print('❌ Error sending comment: $e');
      _rollbackComment(tempComment);
      _showErrorSnackbar('Koneksi bermasalah, coba lagi');
    }
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController?.hasClients == true) {
        widget.scrollController?.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _rollbackComment(Comment tempComment) {
    if (mounted) {
      setState(() {
        _comments.removeWhere((comment) => comment.id == tempComment.id);
        _temporaryIds.remove(tempComment.id);
      });
    }
  }

  void _showSuccessFeedback() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Komentar berhasil dikirim'),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
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
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[600],
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          action: SnackBarAction(
            label: 'Coba Lagi',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

      List<Comment> comments = [];
      if (data.isNotEmpty) {
        for (var item in data) {
          try {
            comments.add(Comment.fromJson(item));
          } catch (e) {
            print("Error parsing comment: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _comments = CommentUtils.sortCommentsByDate(comments);
          _hasError = false;
          _errorMessage = null;
          _temporaryIds.clear();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Komentar diperbarui'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('Manual refresh failed: $e');
      _showErrorSnackbar('Gagal memperbarui komentar');
    }
  }

  void _toggleLike(Comment comment) {
    setState(() {
      comment.liked = !comment.liked;
      comment.likes += comment.liked ? 1 : -1;
    });

    HapticFeedback.lightImpact();
    // TODO: Kirim ke server di background
  }

  void _handleRetry() {
    setState(() {
      _hasError = false;
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
          // Handle bar
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

          // Header
          CommentHeaderWidget(
            comments: _comments,
            onRefresh: _manualRefresh,
          ),
          SizedBox(height: 12),

          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : CommentListWidget(
                    comments: _comments,
                    scrollController: widget.scrollController,
                    onLikeToggle: _toggleLike,
                    onRetry: _handleRetry,
                    hasError: _hasError,
                  ),
          ),

          // Input field
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
