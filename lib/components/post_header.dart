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
  String? targetUsername;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didUpdateWidget(PostHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh status jika user berubah
    if (oldWidget.user != widget.user ||
        oldWidget.username != widget.username) {
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);

    try {
      await _getCurrentUsername();
      _checkIfCurrentUser();

      if (!isCurrentUser && targetUsername != null) {
        // Check if account is private
        await _checkAccountType();
        await _checkFollowStatus();
      }
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ✅ UPDATED: Get current username instead of userId
  Future<void> _getCurrentUsername() async {
    try {
      final myProfile = await _followService.getMyProfile();
      currentUsername = myProfile['username'];
      print('Current username: $currentUsername');

      if (currentUsername == null || currentUsername!.isEmpty) {
        print('⚠️ Current username tidak valid!');
      }
    } catch (e) {
      print('Error getting current username: $e');
    }
  }

  // ✅ UPDATED: Check if current user using username comparison
  void _checkIfCurrentUser() {
    try {
      // Get target username from widget
      targetUsername = widget.username;

      if (targetUsername == null || targetUsername!.isEmpty) {
        // Fallback: try to get from user object
        targetUsername = widget.user['username']?.toString();
      }

      print('Target username: $targetUsername');

      isCurrentUser = currentUsername != null &&
          targetUsername != null &&
          currentUsername == targetUsername;

      print('Is current user: $isCurrentUser');
    } catch (e) {
      print('Error checking if current user: $e');
      isCurrentUser = false;
    }
  }

  // ✅ UPDATED: Check account type using username
  Future<void> _checkAccountType() async {
    if (targetUsername == null) return;

    try {
      final profile = await _followService.getUserProfile(targetUsername!);
      if (mounted) {
        setState(() {
          isPrivateAccount = profile['is_private'] ?? false;
        });
        print('Account type: ${isPrivateAccount ? 'Private' : 'Public'}');
      }
    } catch (e) {
      print('Error checking account type: $e');
      // Default to false if we can't determine
      isPrivateAccount = false;
    }
  }

  // Method untuk force refresh status
  Future<void> forceRefreshStatus() async {
    if (!isCurrentUser && targetUsername != null) {
      await _checkAccountType();
      await _checkFollowStatus();
    }
  }

  // ✅ UPDATED: Check follow status using username
  Future<void> _checkFollowStatus() async {
    if (targetUsername == null) {
      print('Cannot check follow status: targetUsername is null');
      return;
    }

    try {
      final statusData = await _followService.getFollowStatus(targetUsername!);

      if (mounted) {
        setState(() {
          isFollowing = statusData['isFollowing'] ?? false;
          followStatus = statusData['status'];
        });

        print(
            'Follow status updated: isFollowing=$isFollowing, status=$followStatus');
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

  // ✅ UPDATED: Handle follow action using username
  Future<void> _handleFollowAction() async {
    if (targetUsername == null || isLoading || isCurrentUser) {
      print(
          '❌ Cannot handle follow action: targetUsername=$targetUsername, isLoading=$isLoading, isCurrentUser=$isCurrentUser');
      return;
    }

    print('🎯 Starting follow action for user $targetUsername');
    print('📊 Current state: isFollowing=$isFollowing, status=$followStatus');

    setState(() => isLoading = true);

    try {
      bool success;
      String action;

      if (isFollowing) {
        // User is currently following, so unfollow
        action = 'unfollow';
        print('🔄 Attempting to unfollow user $targetUsername');
        success = await _followService.unfollowUser(targetUsername!);
      } else {
        // User is not following, so follow
        action = 'follow';
        print('🔄 Attempting to follow user $targetUsername');
        success = await _followService.followUser(targetUsername!);
      }

      print('📈 Action result: $action = $success');

      if (success) {
        print('✅ Action successful, refreshing status...');

        // Wait a bit for server to process
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh status dari server untuk memastikan data terbaru
        await _checkFollowStatus();

        // Panggil callback
        widget.onFollowChanged?.call();

        if (mounted) {
          _showSuccessMessage(action);
        }
      } else {
        print('❌ Action failed');

        // Jika action gagal, coba refresh status dulu
        // Mungkin state kita tidak sinkron dengan server
        print('🔄 Refreshing status to check current state...');
        await _checkFollowStatus();

        _showErrorSnackbar('Aksi $action gagal. Status telah diperbarui.');
      }
    } catch (e) {
      print('💥 Error in follow action: $e');
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
      if (isPrivateAccount) {
        message =
            'Permintaan mengikuti @${targetUsername} terkirim dan menunggu persetujuan';
      } else {
        message = followStatus == 'pending'
            ? 'Permintaan mengikuti @${targetUsername} terkirim'
            : 'Berhasil mengikuti @${targetUsername}';
      }
    } else {
      if (followStatus == 'pending') {
        message = 'Permintaan mengikuti @${targetUsername} dibatalkan';
      } else {
        message = 'Berhasil berhenti mengikuti @${targetUsername}';
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
          onBackgroundImageError: (_, __) {
            print('Error loading profile image: ${widget.profileImageUrl}');
          },
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
    // Jangan tampilkan tombol untuk user sendiri
    if (isCurrentUser) return null;

    // Jangan tampilkan tombol jika sudah following dengan status accepted
    if (isFollowing && followStatus == 'accepted') return null;

    // Jika masih loading awal, tampilkan loading kecil
    if (isLoading && followStatus == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return SizedBox(
      width: 100, // Increased width for longer text
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
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
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
      case 'accepted':
        return Colors.grey[600]!;
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
        return isPrivateAccount ? 'Diminta' : 'Pending';
      case 'accepted':
        return 'Mengikuti';
      default:
        return 'Mengikuti';
    }
  }
}
