// lib/pages/post_detail.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/components/post_action_counts.dart';
import 'package:portal_si/components/post_header.dart';
import 'package:portal_si/components/post_info_section.dart';
import 'package:portal_si/providers/navigation_provider.dart';
import 'package:portal_si/services/bookmark_service.dart';
import 'package:provider/provider.dart';
import '../components/video_player_widget.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/comment_like_service.dart';
import '../services/post_service.dart';
import '../services/comment_service.dart';
import '../services/like_service.dart';
import '../helper/time_helper.dart';
import '../utils/comment_utils.dart';
import '../utils/navigation_helper.dart';
import '../utils/user_provider.dart';

class PostDetail extends StatefulWidget {
  final int postId;

  const PostDetail({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  late Future<Post> _postFuture;
  final PostService _postService = PostService();

  @override
  void initState() {
    super.initState();
    _fetchPostData();
  }

  void _fetchPostData() {
    setState(() {
      _postFuture = _postService.getPostDetail(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb, // On web let Navigator handle pops (dialog barrier, system back)
      onPopInvoked: (bool didPop) {
        if (!didPop && !kIsWeb) {
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: AppBar(
              title: const Text('Postingan', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (kIsWeb) {
                    Navigator.of(context, rootNavigator: true).pop();
                  } else {
                    Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
                  }
                },
              ),
            ),
          ),
        ),
        body: Padding(
          // Beri padding bawah setinggi Bottom Navigation Bar
          padding: const EdgeInsets.only(bottom: 90.0),
          child: FutureBuilder<Post>(
            future: _postFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Gagal memuat data: ${snapshot.error}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPostData,
                        child: const Text("Coba Lagi"),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: Text("Data postingan tidak ditemukan."));
              }
              final post = snapshot.data!;
              return PostDetailView(post: post);
            },
          ),
        ),
      ),
    );
  }
}

class PostDetailView extends StatefulWidget {
  final Post post;

  const PostDetailView({Key? key, required this.post}) : super(key: key);

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late Post _post;
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();
  final BookmarkService _bookmarkService = BookmarkService();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final CommentLikeService _commentLikeService = CommentLikeService();

  late final AudioPlayer _audioPlayer;
  bool _isMusicMuted = false;
  bool _audioReady = false;   // true once the audio source is loaded
  bool _audioPlaying = false; // manual play state (web requires gesture)
  StreamSubscription? _likeSubscription;
  StreamSubscription? _bookmarkSubscription;
  Comment? _replyingToComment;
  List<Comment> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchComments();
    _initAudioPlayer();
    _likeSubscription = _likeService.likeUpdates
        .where((update) => update.postId == _post.id)
        .listen((update) {
      if (mounted) {
        // Cek apakah state memang berbeda
        if (_post.isLikedByUser != update.isLiked ||
            (update.likesCount != null && _post.likesCount != update.likesCount)) {
          setState(() {
            _post = _post.copyWith(
              isLikedByUser: update.isLiked,
              // Hanya update jumlah like jika stream mengirimkannya
              likesCount: update.likesCount ?? _post.likesCount,
            );
          });
        }
      }
    });

    _bookmarkSubscription = _bookmarkService.bookmarkUpdates
        .where((update) => update.postId == _post.id)
        .listen((update) {
      if (mounted && _post.isBookmarked != update.isBookmarked) {
        setState(() {
          _post = _post.copyWith(isBookmarked: update.isBookmarked);
        });
      }
    });
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    final musicUrl = _post.musicPreviewUrl;
    if (musicUrl != null && musicUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(musicUrl);
        await _audioPlayer.setLoopMode(LoopMode.one);
        if (mounted) setState(() => _audioReady = true);

        // On web, browsers block autoplay until the user interacts with the page.
        // We show a play button instead of calling play() directly.
        if (!kIsWeb) {
          _audioPlayer.play();
          if (mounted) setState(() => _audioPlaying = true);
        }
      } catch (e) {
        debugPrint("Error loading audio source in detail: $e");
      }
    }
  }

  void _toggleAudioPlayback() {
    if (!_audioReady) return;
    if (_audioPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    setState(() => _audioPlaying = !_audioPlaying);
  }

  @override
  void dispose() {
    _likeSubscription?.cancel();
    _bookmarkSubscription?.cancel();
    _commentController.dispose();
    _commentFocusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
    _likeSubscription?.cancel();
  }

  void _toggleMusicMute() {
    if (_audioPlayer.audioSource == null) return;
    setState(() {
      _isMusicMuted = !_isMusicMuted;
      _audioPlayer.setVolume(_isMusicMuted ? 0.0 : 1.0);
    });
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _commentService.getComments(_post.id);
      if (mounted) {
        setState(() {
          _comments = CommentUtils.flattenComments(comments);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat komentar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleBookmark() async {
    final originalStatus = _post.isBookmarked;
    setState(() {
      _post = _post.copyWith(isBookmarked: !originalStatus);
    });
    try {
      if (_post.isBookmarked) {
        await _bookmarkService.addBookmark(_post.id);
      } else {
        await _bookmarkService.removeBookmark(_post.id);
      }
    } catch (e) {
      setState(() {
        _post = _post.copyWith(isBookmarked: originalStatus);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah bookmark: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setReplyingTo(Comment? comment) {
    setState(() {
      _replyingToComment = comment;
    });
    if (comment != null) {
      _focusCommentField();
    }
  }

  Future<void> _handleDeletePost() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus postingan ini? Tindakan ini tidak dapat diurungkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        final success = await PostService().deletePost(_post.id);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Postingan berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
          Provider.of<NavigationProvider>(context, listen: false).hideOverlay();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus postingan: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
  Future<void> _toggleLike() async {
    // Logika optimistic update di sini sudah benar
    final originalLikedStatus = _post.isLikedByUser;
    final originalLikesCount = _post.likesCount;

    setState(() {
      _post = _post.copyWith(
        isLikedByUser: !originalLikedStatus,
        likesCount: originalLikesCount + (originalLikedStatus ? -1 : 1),
      );
    });

    try {
      // Panggil service baru. Kirimkan state ASLI (sebelum di-toggle)
      // karena service akan menghitung state barunya.
      await _likeService.toggleLikeHttp(
        _post.id,
        isCurrentlyLiked: originalLikedStatus,
        currentLikesCount: originalLikesCount, // Kirim jumlah like saat ini
      );
    } catch (e) {
      // Rollback jika gagal
      setState(() {
        _post = _post.copyWith(
          isLikedByUser: originalLikedStatus,
          likesCount: originalLikesCount,
        );
      });
    }
  }
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) return;
    setState(() => _isPostingComment = true);
    try {
      if (_replyingToComment != null) {
        await _commentService.addCommentReply(
          _post.id,
          _commentController.text.trim(),
          _replyingToComment!.id,
        );
      } else {
        await _commentService.addComment(
          _post.id,
          _commentController.text.trim(),
        );
      }
      _commentController.clear();
      FocusScope.of(context).unfocus();
      _setReplyingTo(null);
      await _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim komentar: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _focusCommentField() {
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    final originalLikedStatus = comment.liked;
    final originalLikesCount = comment.likes;

    setState(() {
      comment.liked = !originalLikedStatus;
      comment.likes += originalLikedStatus ? -1 : 1;
    });

    try {
      bool success;
      if (comment.liked) {
        success = await _commentLikeService.likeComment(comment.id);
      } else {
        success = await _commentLikeService.unlikeComment(comment.id);
      }
      if (!success) throw Exception('Server gagal memproses permintaan.');
    } catch (e) {
      setState(() {
        comment.liked = originalLikedStatus;
        comment.likes = originalLikesCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyukai komentar.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildPostHeader()),
              SliverToBoxAdapter(child: _buildPostMedia()),
              SliverToBoxAdapter(child: _buildMusicInfo()),
              SliverToBoxAdapter(
                child: PostActionCounts(
                  post: _post,
                  onLike: _toggleLike,
                  onComment: _focusCommentField,
                  onShare: () {},
                  onBookmark: _toggleBookmark,
                ),
              ),
              SliverToBoxAdapter(
                child: PostInfoSection(
                  post: _post,
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Komentar (${_comments.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              _buildCommentList(),
            ],
          ),
        ),
        _buildCommentInputField(),
      ],
    );
  }

  Widget _buildMusicInfo() {
    final musicTrackName = _post.musicTrackName;
    if (musicTrackName == null || musicTrackName.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            const Icon(Icons.music_note, size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 20,
                child: Marquee(
                  text: '${_post.musicTrackName} • ${_post.musicArtistName ?? 'Unknown Artist'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  blankSpace: 20.0,
                  velocity: 50.0,
                  pauseAfterRound: const Duration(seconds: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader() {
    // Ambil ID pengguna saat ini dari provider
    final currentUserId = Provider.of<UserProvider>(context, listen: false).currentUser?.id;
    final isOwner = _post.user.id == currentUserId;

    return PostHeader(
      post: _post,
      onProfileTap: () {
        NavigationHelper.navigateToProfile(context, _post.user);
      },
      // Tambahkan actions:
      actions: isOwner
          ? [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {
            // Tampilkan menu opsi untuk pemilik postingan
            _showPostOptionsMenu(context);
          },
        ),
      ]
          : null,
    );
  }

  void _showPostOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Hapus Postingan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(bc); // Tutup bottom sheet
                  _handleDeletePost(); // Panggil fungsi hapus
                },
              ),
              // Opsi lain bisa ditambahkan di sini (misalnya: Edit Post)
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostMedia() {
    if (_post.mediaUrl == null || _post.mediaUrl!.isEmpty) return const SizedBox.shrink();

    Widget mediaContent;
    if (_post.isVideo) {
      mediaContent = VideoPlayerWidget(videoUrl: _post.mediaUrl!);
    } else {
      mediaContent = Hero(
        tag: 'post_hero_${_post.id}',
        child: Image.network(_post.mediaUrl!),

      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Stack(
        children: [
          mediaContent,
          if (_post.musicPreviewUrl != null && _post.musicPreviewUrl!.isNotEmpty)
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // On web, show play/pause button (browsers need user gesture)
                  if (kIsWeb)
                    GestureDetector(
                      onTap: _toggleAudioPlayback,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _audioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  // Mute/unmute button (always visible when audio is playing)
                  if (!kIsWeb || _audioPlaying)
                    GestureDetector(
                      onTap: _toggleMusicMute,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMusicMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 18,
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

  Widget _buildCommentList() {
    if (_isLoadingComments) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())));
    if (_comments.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('Jadilah yang pertama berkomentar!'))));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) => _CommentTile(
          comment: _comments[index],
          onReply: () => _setReplyingTo(_comments[index]),
          onLikeToggle: () => _toggleCommentLike(_comments[index]),
        ),
        childCount: _comments.length,
      ),
    );
  }

  Widget _buildCommentInputField() {
    final currentUser = Provider.of<UserProvider>(context, listen: false).currentUser;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToComment != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Membalas kepada ${_replyingToComment!.username}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                  onPressed: () => _setReplyingTo(null),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))
            ],
          ),
          padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, MediaQuery.of(context).padding.bottom + 8.0),
          child: Row(
            children: [
              CircularAvatarFetcher(
                radius: 18,
                userId: currentUser?.id ?? 0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: InputDecoration(
                    hintText: _replyingToComment != null ? 'Tulis balasan Anda...' : 'Tambahkan komentar...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    fillColor: Colors.grey[100],
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _postComment(),
                ),
              ),
              const SizedBox(width: 8),
              _isPostingComment ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _postComment),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onLikeToggle;
  const _CommentTile({required this.comment, required this.onReply, required this.onLikeToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.0 + (comment.depth * 24.0),
        8.0,
        16.0,
        8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircularAvatarFetcher(
            radius: 18,
            userId: comment.userId,
            onTap: () {
              // 1. Buat objek User sederhana dari data yang ada di 'comment'
              final userToNavigate = User(
                id: comment.userId,
                username: comment.username,
              );

              // 2. Kirim objek User yang baru dibuat ke fungsi navigasi
              NavigationHelper.navigateToProfile(context, userToNavigate);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(text: TextSpan(style: DefaultTextStyle.of(context).style, children: [TextSpan(text: '${comment.username} ', style: const TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: comment.content)])),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeAgoFromDate(comment.createdAt.toIso8601String()),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: onReply,
                      child: Text(
                        'Balas',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  comment.liked ? Icons.favorite : Icons.favorite_border,
                  color: comment.liked ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
                onPressed: onLikeToggle,
              ),
              if (comment.likes > 0)
                Text(
                  comment.likes.toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}