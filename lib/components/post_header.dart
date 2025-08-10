import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../utils/secure_storage.dart';

class PostHeader extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String profileImageUrl;
  final bool isVerified;
  final Map<String, dynamic> user;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFollowChanged;

  const PostHeader({
    super.key,
    required this.username,
    required this.timeAgo,
    required this.profileImageUrl,
    required this.isVerified,
    required this.user,
    this.onProfileTap,
    this.onFollowChanged,
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

  // Cache untuk menghindari API calls berulang
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
    // Hanya refresh jika username benar-benar berubah
    if (oldWidget.username != widget.username) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    // Fast check untuk current user
    await _checkIfCurrentUser();

    if (isCurrentUser) {
      // Jika current user, tidak perlu API calls lain
      if (mounted) setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Parallel execution untuk account type dan follow status
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

  // Optimized: Cache current username
  Future<void> _getCurrentUsername() async {
    if (_cachedCurrentUsername != null) {
      currentUsername = _cachedCurrentUsername;
      return;
    }

    try {
      final myProfile = await _followService.getMyProfile();
      currentUsername = myProfile['username'];
      _cachedCurrentUsername = currentUsername; // Cache it
    } catch (e) {
      print('Error getting current username: $e');
    }
  }

  // Optimized: Check with caching
  Future<void> _checkIfCurrentUser() async {
    final targetUsername = widget.username;

    // Check cache first
    if (_isCurrentUserCache.containsKey(targetUsername)) {
      isCurrentUser = _isCurrentUserCache[targetUsername]!;
      return;
    }

    await _getCurrentUsername();

    isCurrentUser =
        currentUsername != null && currentUsername == targetUsername;

    // Cache the result
    _isCurrentUserCache[targetUsername] = isCurrentUser;
  }

  // Optimized: Cache account type
  Future<void> _checkAccountType() async {
    final targetUsername = widget.username;

    // Check cache first
    if (_privateAccountCache.containsKey(targetUsername)) {
      isPrivateAccount = _privateAccountCache[targetUsername]!;
      return;
    }

    try {
      final profile = await _followService.getUserProfile(targetUsername);
      isPrivateAccount = profile['is_private'] ?? false;

      // Cache the result
      _privateAccountCache[targetUsername] = isPrivateAccount;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking account type: $e');
      isPrivateAccount = false;
    }
  }

  // Optimized: Use efficient follow status check
  Future<void> _checkFollowStatus() async {
    try {
      print('🔍 Checking follow status for ${widget.username}');

      final statusData = await _followService.getFollowStatus(widget.username);

      if (mounted) {
        setState(() {
          isFollowing = statusData['isFollowing'] ?? false;
          followStatus = statusData['status'];
        });

        print(
            '📊 Follow status updated: isFollowing=$isFollowing, status=$followStatus');
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
        success = await _followService.unfollowUser(widget.username);
      } else {
        success = await _followService.followUser(widget.username);
      }

      if (success) {
        // Clear cache untuk user ini agar data fresh
        _privateAccountCache.remove(widget.username);
        _followService.clearFollowStatusCache();

        // Wait for server processing
        await Future.delayed(const Duration(milliseconds: 300));

        // Refresh status
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
          ? 'Permintaan mengikuti @${widget.username} terkirim'
          : 'Berhasil mengikuti @${widget.username}';
    } else {
      message = 'Berhasil berhenti mengikuti @${widget.username}';
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: GestureDetector(
        onTap: widget.onProfileTap,
        child: CircleAvatar(
          backgroundImage: widget.profileImageUrl.isNotEmpty
              ? NetworkImage(widget.profileImageUrl)
              : null,
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: widget.profileImageUrl.isEmpty
              ? Icon(Icons.person, size: 30, color: Colors.grey[600])
              : null,
        ),
      ),
      title: GestureDetector(
        onTap: widget.onProfileTap,
        child: Row(
          children: [
            Flexible(
              child: Text(
                '@${widget.username}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified, color: Colors.blue, size: 16),
            ],
          ],
        ),
      ),
      subtitle: Text(
        widget.timeAgo,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: _buildTrailingWidget(),
    );
  }

  Widget? _buildTrailingWidget() {
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
          backgroundColor: _getButtonColor(),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
      ),
    );
  }

  Color _getButtonColor() {
    if (!isFollowing) return Colors.blue[600]!;

    switch (followStatus) {
      case 'pending':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
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

  // Clear cache when widget is disposed
  @override
  void dispose() {
    // Optional: clear cache entries for this user
    super.dispose();
  }

  // Static method to clear all cache
  static void clearCache() {
    _isCurrentUserCache.clear();
    _privateAccountCache.clear();
    _cachedCurrentUsername = null;
  }
}
