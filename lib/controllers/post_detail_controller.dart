// lib/controllers/post_detail_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/like_model.dart';
import '../services/post_service.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../utils/secure_storage.dart';

class PostDetailController extends ChangeNotifier {
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();
  final int mainPostId;

  Post? _mainPost;
  Post? get mainPost => _mainPost;

  List<Post> _relatedPosts = [];
  List<Post> get relatedPosts => _relatedPosts;

  bool _isLoadingMainPost = true;
  bool get isLoadingMainPost => _isLoadingMainPost;

  bool _isLoadingRelated = true;
  bool get isLoadingRelated => _isLoadingRelated;

  PostDetailController({required this.mainPostId});

  void setInitialPost(Post post) {
    if (_mainPost != null) return;
    _mainPost = post;
    _isLoadingMainPost = false;
    notifyListeners();
    // Panggil loadData setelah post awal di-set
    loadData();
  }

  Future<void> loadData() async {
    // Jika post utama belum ada, set isLoadingMainPost jadi true
    if (_mainPost == null) {
      _isLoadingMainPost = true;
      notifyListeners();
    }
    _isLoadingRelated = true;

    try {
      // Panggilan API ini sekarang sudah benar karena service telah diperbaiki
      final postFuture = _postService.getPostDetail(mainPostId);
      final relatedFuture = _postService.fetchExplorePosts(); // Akan mengembalikan List<Post>

      final results = await Future.wait([postFuture, relatedFuture]);

      _mainPost = results[0] as Post;
      final allRelated = results[1] as List<Post>;

      // Filter untuk menampilkan postingan yang tidak sama dengan post utama
      _relatedPosts = allRelated.where((p) => p.id != mainPostId).toList();

      // Anda bisa menghapus _fetchDetailsForPosts jika API sudah memberikan data lengkap
      // Jika belum, biarkan saja.
      // await _fetchDetailsForPosts();

    } catch (e) {
      debugPrint("Error loading post detail page data: $e");
    } finally {
      _isLoadingMainPost = false;
      _isLoadingRelated = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDetailsForPosts() async {
    final allPosts = [_mainPost, ..._relatedPosts]
        .where((p) => p != null)
        .cast<Post>()
        .toList();
    final currentUserId = await SecureStorage.getUserId();

    await Future.wait(allPosts.map((post) async {
      try {
        final likesFuture = _likeService.getLikes(post.id); // <-- Panggil getLikes dari LikeService
        final commentsFuture = _commentService.getComments(post.id);

        final results = await Future.wait([likesFuture, commentsFuture]);
        final likes = results[0] as List<Like>;
        final comments = results[1] as List<Comment>;

        post.likesCount = likes.length;
        post.commentsCount = comments.length;
        if (currentUserId != null) {
          post.isLikedByUser = likes.any((like) => like.user.id == currentUserId);
        }
      } catch (e) {
        debugPrint('Error fetching details for post ${post.id}: $e');
      }
    }));
  }

  Future<void> toggleLike(int postId) async {
    Post? post = (postId == _mainPost?.id) ? _mainPost : _relatedPosts.firstWhere((p) => p.id == postId);
    if (post == null) return;
    final originalStatus = post.isLikedByUser;
    final originalCount = post.likesCount;
    post.isLikedByUser = !originalStatus;
    post.likesCount += originalStatus ? -1 : 1;
    notifyListeners();

    try {
      // --- PERBAIKAN DI SINI ---
      // Panggil metode HTTP yang mengembalikan Future<bool>
      await _likeService.toggleLikeHttp(postId);
    } catch (e) {
      post.isLikedByUser = originalStatus;
      post.likesCount = originalCount;
      notifyListeners();
    }
  }
}