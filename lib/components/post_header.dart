// lib/components/post_header.dart

import 'package:flutter/material.dart';
import 'package:portal_si/models/post_model.dart';
import 'package:portal_si/services/follow_service.dart';
import 'package:portal_si/components/circular_avatar_fetcher.dart';
import 'package:portal_si/helper/time_helper.dart'; // Pastikan path ini benar

class PostHeader extends StatefulWidget {
  final Post post;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFollowChanged;
  final List<Widget>? actions; // <--- TAMBAHAN UTAMA DI SINI

  const PostHeader({
    super.key,
    required this.post,
    this.onProfileTap,
    this.onFollowChanged,
    this.actions, // <--- TAMBAHAN UTAMA DI SINI
  });

  @override
  State<PostHeader> createState() => _PostHeaderState();
}

class _PostHeaderState extends State<PostHeader> {
  final FollowService _followService = FollowService();
  bool isFollowing = false;
  bool isLoading = false;
  bool isCurrentUser = false;
  bool isPrivateAccount = false;
  String? followStatus;
  String? currentUsername;

  static final Map<String, bool> _isCurrentUserCache = {};
  static final Map<String, bool> _privateAccountCache = {};
  static String? _cachedCurrentUsername;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(PostHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.user.username != widget.post.user.username) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    await _checkIfCurrentUser();
    if (isCurrentUser) {
      if (mounted) setState(() => isLoading = false);
      return;
    }
    setState(() => isLoading = true);
    try {
      await Future.wait([
        _checkAccountType(),
        _checkFollowStatus(),
      ]);
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _getCurrentUsername() async {
    if (_cachedCurrentUsername != null) {
      currentUsername = _cachedCurrentUsername;
      return;
    }
    try {
      final myProfile = await _followService.getMyProfile();
      currentUsername = myProfile['username'];
      _cachedCurrentUsername = currentUsername;
    } catch (e) {
      print('Error getting current username: $e');
    }
  }

  Future<void> _checkIfCurrentUser() async {
    final targetUsername = widget.post.user.username;
    if (_isCurrentUserCache.containsKey(targetUsername)) {
      isCurrentUser = _isCurrentUserCache[targetUsername]!;
      return;
    }
    await _getCurrentUsername();
    isCurrentUser =
        currentUsername != null && currentUsername == targetUsername;
    _isCurrentUserCache[targetUsername] = isCurrentUser;
  }

  Future<void> _checkAccountType() async {
    final targetUsername = widget.post.user.username;
    if (_privateAccountCache.containsKey(targetUsername)) {
      isPrivateAccount = _privateAccountCache[targetUsername]!;
      return;
    }
    try {
      final profile = await _followService.getUserProfile(targetUsername);
      isPrivateAccount = profile['is_private'] ?? false;
      _privateAccountCache[targetUsername] = isPrivateAccount;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking account type: $e');
      isPrivateAccount = false;
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final statusData = await _followService.getFollowStatus(widget.post.user.username);
      if (mounted) {
        setState(() {
          isFollowing = statusData['isFollowing'] ?? false;
          followStatus = statusData['status'];
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
      if (mounted) {
        setState(() {
          isFollowing = false;
          followStatus = null;
        });
      }
    }
  }

  Future<void> _handleFollowAction() async {
    if (isLoading || isCurrentUser) return;
    setState(() => isLoading = true);
    try {
      bool success;
      String action = isFollowing ? 'unfollow' : 'follow';
      if (isFollowing) {
        success = await _followService.unfollowUser(widget.post.user.username);
      } else {
        success = await _followService.followUser(widget.post.user.username);
      }
      if (success) {
        _privateAccountCache.remove(widget.post.user.username);
        _followService.clearFollowStatusCache();
        await Future.delayed(const Duration(milliseconds: 300));
        await _checkFollowStatus();
        widget.onFollowChanged?.call();
        if (mounted) {
          _showSuccessMessage(action);
        }
      } else {
        await _checkFollowStatus();
        _showErrorSnackbar('Aksi $action gagal.');
      }
    } catch (e) {
      print('Error in follow action: $e');
      _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showSuccessMessage(String action) {
    String message;
    if (action == 'follow') {
      message = isPrivateAccount
          ? 'Permintaan mengikuti @${widget.post.user.username} terkirim'
          : 'Berhasil mengikuti @${widget.post.user.username}';
    } else {
      message = 'Berhasil berhenti mengikuti @${widget.post.user.username}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan widget aksi (berisi tombol follow dan tombol hapus/more)
    final List<Widget> actionWidgets = [];

    // 1. Tambahkan tombol follow/unfollow jika pengguna bukan pemilik postingan
    final followButton = _buildFollowButton(); // Ubah nama metode dari _buildTrailingWidget()
    if (followButton != null) {
      actionWidgets.add(followButton);
    }

    // 2. Tambahkan widget actions tambahan (misalnya, tombol 'more' untuk pemilik)
    if (widget.actions != null) {
      // Tambahkan sedikit jarak jika ada tombol follow
      if (followButton != null && widget.actions!.isNotEmpty) {
        actionWidgets.add(const SizedBox(width: 8));
      }
      actionWidgets.addAll(widget.actions!);
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: SizedBox(
        width: 60,
        height: 60,
        child: Center(
          child: CircularAvatarFetcher(
            userId: widget.post.user.id ?? 0,
            radius: 24,
            onTap: widget.onProfileTap,
          ),
        ),
      ),
      title: GestureDetector(
        onTap: widget.onProfileTap,
        child: Row(
          children: [
            Flexible(
              child: Text(
                widget.post.user.username,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.post.user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
          ],
        ),
      ),
      subtitle: Text(
        timeAgoFromDate(widget.post.createdAt.toIso8601String()),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Row( // <--- WRAP DALAM ROW
        mainAxisSize: MainAxisSize.min,
        children: actionWidgets,
      ),
    );
  }

  Widget? _buildFollowButton() {
    if (isCurrentUser) return null;
    if (isFollowing && followStatus == 'accepted') return null;

    if (isLoading && followStatus == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: 100,
      height: 32,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleFollowAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade600, Colors.orange.shade800],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              _getButtonText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }


  String _getButtonText() {
    if (!isFollowing) {
      return isPrivateAccount ? 'Minta Ikuti' : 'Ikuti';
    }
    switch (followStatus) {
      case 'pending':
        return 'Diminta';
      default:
        return 'Mengikuti';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  static void clearCache() {
    _isCurrentUserCache.clear();
    _privateAccountCache.clear();
    _cachedCurrentUsername = null;
  }
}