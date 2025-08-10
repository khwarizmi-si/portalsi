import 'dart:async';
import '../services/follow_service.dart';

class FollowManager {
  static final FollowManager _instance = FollowManager._internal();
  factory FollowManager() => _instance;
  FollowManager._internal();

  final FollowService _followService = FollowService();
  final Map<String, bool> _followStatusCache = {};
  final Map<String, Map<String, int>> _followCountsCache = {};
  final StreamController<FollowEvent> _followEventController =
      StreamController.broadcast();

  // Stream untuk mendengarkan perubahan follow status
  Stream<FollowEvent> get followEventStream => _followEventController.stream;

  // ✅ UPDATED: Generate cache key using username
  String _getCacheKey(String currentUsername, String targetUsername) {
    return '${currentUsername}_follows_${targetUsername}';
  }

  // ✅ UPDATED: Check follow status dengan cache using username
  Future<bool> isFollowing(String targetUsername) async {
    try {
      // Get current user profile to get username
      final myProfile = await _followService.getMyProfile();
      final currentUsername = myProfile['username'];

      if (currentUsername == null) {
        print('❌ Cannot get current username');
        return false;
      }

      final cacheKey = _getCacheKey(currentUsername, targetUsername);

      // Return from cache if available
      if (_followStatusCache.containsKey(cacheKey)) {
        print('📋 Using cached follow status: ${_followStatusCache[cacheKey]}');
        return _followStatusCache[cacheKey]!;
      }

      // Fetch from server if not in cache
      final isFollowing = await _followService.isFollowing(targetUsername);
      _followStatusCache[cacheKey] = isFollowing;
      print('🌐 Fetched and cached follow status: $isFollowing');
      return isFollowing;
    } catch (e) {
      print('❌ Error checking follow status: $e');
      return false;
    }
  }

  // ✅ UPDATED: Follow user using username
  Future<bool> followUser(String targetUsername) async {
    try {
      final success = await _followService.followUser(targetUsername);

      if (success) {
        // Get current user profile to update cache
        final myProfile = await _followService.getMyProfile();
        final currentUsername = myProfile['username'];

        if (currentUsername != null) {
          // Update cache
          final cacheKey = _getCacheKey(currentUsername, targetUsername);
          _followStatusCache[cacheKey] = true;

          // Update follow counts cache
          await _updateFollowCountsCache(targetUsername, true);

          // Broadcast event
          _followEventController.add(FollowEvent(
            currentUsername: currentUsername,
            targetUsername: targetUsername,
            isFollowing: true,
            action: FollowAction.follow,
          ));

          print('✅ Follow successful and cached');
        }
      }

      return success;
    } catch (e) {
      print('❌ Follow error: $e');
      return false;
    }
  }

  // ✅ UPDATED: Unfollow user using username
  Future<bool> unfollowUser(String targetUsername) async {
    try {
      final success = await _followService.unfollowUser(targetUsername);

      if (success) {
        // Get current user profile to update cache
        final myProfile = await _followService.getMyProfile();
        final currentUsername = myProfile['username'];

        if (currentUsername != null) {
          // Update cache
          final cacheKey = _getCacheKey(currentUsername, targetUsername);
          _followStatusCache[cacheKey] = false;

          // Update follow counts cache
          await _updateFollowCountsCache(targetUsername, false);

          // Broadcast event
          _followEventController.add(FollowEvent(
            currentUsername: currentUsername,
            targetUsername: targetUsername,
            isFollowing: false,
            action: FollowAction.unfollow,
          ));

          print('✅ Unfollow successful and cached');
        }
      }

      return success;
    } catch (e) {
      print('❌ Unfollow error: $e');
      return false;
    }
  }

  // ✅ UPDATED: Toggle follow status using username
  Future<bool> toggleFollow(String targetUsername) async {
    final isCurrentlyFollowing = await isFollowing(targetUsername);

    if (isCurrentlyFollowing) {
      return await unfollowUser(targetUsername);
    } else {
      return await followUser(targetUsername);
    }
  }

  // ✅ NEW: Get follow counts with cache
  Future<Map<String, int>> getFollowCounts(String username) async {
    // Check cache first
    if (_followCountsCache.containsKey(username)) {
      print('📋 Using cached follow counts for $username');
      return _followCountsCache[username]!;
    }

    try {
      final counts = await _followService.getFollowCounts(username);
      _followCountsCache[username] = counts;
      print('🌐 Fetched and cached follow counts for $username: $counts');
      return counts;
    } catch (e) {
      print('❌ Error getting follow counts: $e');
      return {'followers': 0, 'following': 0};
    }
  }

  // ✅ NEW: Update follow counts cache after follow/unfollow
  Future<void> _updateFollowCountsCache(
      String targetUsername, bool isFollow) async {
    if (_followCountsCache.containsKey(targetUsername)) {
      final currentCounts =
          Map<String, int>.from(_followCountsCache[targetUsername]!);

      if (isFollow) {
        currentCounts['followers'] = (currentCounts['followers'] ?? 0) + 1;
      } else {
        currentCounts['followers'] = (currentCounts['followers'] ?? 0) > 0
            ? currentCounts['followers']! - 1
            : 0;
      }

      _followCountsCache[targetUsername] = currentCounts;
      print(
          '📝 Updated cached follow counts for $targetUsername: $currentCounts');
    }
  }

  // ✅ UPDATED: Update cache manually using username
  void updateCache(
      String currentUsername, String targetUsername, bool isFollowing) {
    final cacheKey = _getCacheKey(currentUsername, targetUsername);
    _followStatusCache[cacheKey] = isFollowing;
    print('📝 Cache manually updated: $cacheKey = $isFollowing');
  }

  // ✅ UPDATED: Clear specific cache entry using username
  void clearCache(String currentUsername, String targetUsername) {
    final cacheKey = _getCacheKey(currentUsername, targetUsername);
    _followStatusCache.remove(cacheKey);
    print('🗑️ Cache cleared for: $cacheKey');
  }

  // ✅ NEW: Clear follow counts cache for specific user
  void clearFollowCountsCache(String username) {
    _followCountsCache.remove(username);
    print('🗑️ Follow counts cache cleared for: $username');
  }

  // Clear all cache
  void clearAllCache() {
    _followStatusCache.clear();
    _followCountsCache.clear();
    print('🗑️ All follow cache cleared');
  }

  // ✅ UPDATED: Get cached status using username
  bool? getCachedStatus(String currentUsername, String targetUsername) {
    final cacheKey = _getCacheKey(currentUsername, targetUsername);
    return _followStatusCache[cacheKey];
  }

  // ✅ NEW: Get cached follow counts
  Map<String, int>? getCachedFollowCounts(String username) {
    return _followCountsCache[username];
  }

  // ✅ UPDATED: Preload follow status for multiple users using current user's following list
  Future<void> preloadFollowStatus(List<String> targetUsernames) async {
    try {
      // Get current user profile
      final myProfile = await _followService.getMyProfile();
      final currentUsername = myProfile['username'];
      final currentUserId = myProfile['id'];

      if (currentUsername == null || currentUserId == null) {
        print('❌ Cannot preload: missing current user data');
        return;
      }

      // Get following list
      final following = await _followService.getFollowing(currentUserId);
      final followingUsernames = following
          .map((user) => user['username']?.toString())
          .where((username) => username != null)
          .cast<String>()
          .toSet();

      // Update cache for all target usernames
      for (final targetUsername in targetUsernames) {
        final cacheKey = _getCacheKey(currentUsername, targetUsername);
        _followStatusCache[cacheKey] =
            followingUsernames.contains(targetUsername);
      }

      print('📚 Preloaded follow status for ${targetUsernames.length} users');
    } catch (e) {
      print('❌ Error preloading follow status: $e');
    }
  }

  // ✅ NEW: Preload follow counts for multiple users
  Future<void> preloadFollowCounts(List<String> usernames) async {
    try {
      final futures = usernames.map((username) => getFollowCounts(username));
      await Future.wait(futures);
      print('📚 Preloaded follow counts for ${usernames.length} users');
    } catch (e) {
      print('❌ Error preloading follow counts: $e');
    }
  }

  // ✅ NEW: Get follow status with detailed info
  Future<Map<String, dynamic>> getDetailedFollowStatus(
      String targetUsername) async {
    try {
      return await _followService.getFollowStatus(targetUsername);
    } catch (e) {
      print('❌ Error getting detailed follow status: $e');
      return {
        'isFollowing': false,
        'status': null,
        'followedAt': null,
      };
    }
  }

  // ✅ NEW: Refresh all cached data for a user
  Future<void> refreshUserData(String username) async {
    try {
      // Clear existing cache
      clearFollowCountsCache(username);

      // Get current username to clear follow status cache
      final myProfile = await _followService.getMyProfile();
      final currentUsername = myProfile['username'];
      if (currentUsername != null) {
        clearCache(currentUsername, username);
      }

      // Reload data
      await Future.wait([
        getFollowCounts(username),
        isFollowing(username),
      ]);

      print('🔄 Refreshed all cached data for $username');
    } catch (e) {
      print('❌ Error refreshing user data: $e');
    }
  }

  // Dispose
  void dispose() {
    _followEventController.close();
  }
}

// ✅ UPDATED: Event class untuk follow/unfollow events with username
class FollowEvent {
  final String currentUsername;
  final String targetUsername;
  final bool isFollowing;
  final FollowAction action;

  FollowEvent({
    required this.currentUsername,
    required this.targetUsername,
    required this.isFollowing,
    required this.action,
  });

  @override
  String toString() {
    return 'FollowEvent(currentUsername: $currentUsername, targetUsername: $targetUsername, isFollowing: $isFollowing, action: $action)';
  }
}

enum FollowAction {
  follow,
  unfollow,
}
