// cache/cache_manager.dart
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

class CacheManager {
  static late Box _cacheBox;
  static late Box _metadataBox;
  static late Box _imageCache;

  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('portal_si_cache');
    _metadataBox = await Hive.openBox('portal_si_metadata');
    _imageCache = await Hive.openBox('portal_si_images');
  }

  // ========== POST CACHE METHODS ==========

  /// Cache feed posts dengan smart pagination
  static Future<void> cacheFeedPosts(List<dynamic> posts) async {
    try {
      // Simpan setiap post dengan key unik
      for (var post in posts) {
        final postId = post['id'] ?? post['post_id'];
        if (postId != null) {
          await _cacheBox.put('post_$postId', post);
        }
      }

      // Simpan metadata feed
      final feedMetadata = {
        'post_ids': posts
            .map((p) => p['id'] ?? p['post_id'])
            .where((id) => id != null)
            .toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'type': 'feed'
      };
      await _metadataBox.put('feed_posts', feedMetadata);

      print('✅ Cached ${posts.length} feed posts');
    } catch (e) {
      print('❌ Error caching feed posts: $e');
    }
  }

  /// Get cached feed posts
  static List<dynamic> getCachedFeedPosts({int maxAgeMinutes = 30}) {
    try {
      final metadata = _metadataBox.get('feed_posts');
      if (metadata == null) return [];

      // Check cache age
      final cachedAt = metadata['cached_at'] as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageMinutes = age / (1000 * 60);

        if (ageMinutes > maxAgeMinutes) {
          print('⏰ Feed cache expired (${ageMinutes.toInt()} minutes old)');
          return [];
        }
      }

      // Retrieve cached posts
      final postIds = List<dynamic>.from(metadata['post_ids'] ?? []);
      final cachedPosts = <dynamic>[];

      for (var postId in postIds) {
        final post = _cacheBox.get('post_$postId');
        if (post != null) {
          cachedPosts.add(post);
        }
      }

      print('📱 Using ${cachedPosts.length} cached feed posts');
      return cachedPosts;
    } catch (e) {
      print('❌ Error getting cached feed posts: $e');
      return [];
    }
  }

  /// Cache explore posts
  static Future<void> cacheExplorePosts(List<dynamic> posts) async {
    try {
      // Simpan explore posts terpisah dari feed
      for (var post in posts) {
        final postId = post['id'] ?? post['post_id'];
        if (postId != null) {
          await _cacheBox.put('explore_post_$postId', post);
        }
      }

      final exploreMetadata = {
        'post_ids': posts
            .map((p) => p['id'] ?? p['post_id'])
            .where((id) => id != null)
            .toList(),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
        'type': 'explore'
      };
      await _metadataBox.put('explore_posts', exploreMetadata);

      print('✅ Cached ${posts.length} explore posts');
    } catch (e) {
      print('❌ Error caching explore posts: $e');
    }
  }

  /// Get cached explore posts
  static List<dynamic> getCachedExplorePosts({int maxAgeHours = 2}) {
    try {
      final metadata = _metadataBox.get('explore_posts');
      if (metadata == null) return [];

      // Check cache age (explore posts dapat lebih lama)
      final cachedAt = metadata['cached_at'] as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageHours = age / (1000 * 60 * 60);

        if (ageHours > maxAgeHours) {
          print('⏰ Explore cache expired (${ageHours.toInt()} hours old)');
          return [];
        }
      }

      final postIds = List<dynamic>.from(metadata['post_ids'] ?? []);
      final cachedPosts = <dynamic>[];

      for (var postId in postIds) {
        final post = _cacheBox.get('explore_post_$postId');
        if (post != null) {
          cachedPosts.add(post);
        }
      }

      print('📱 Using ${cachedPosts.length} cached explore posts');
      return cachedPosts;
    } catch (e) {
      print('❌ Error getting cached explore posts: $e');
      return [];
    }
  }

  /// Cache single post detail
  static Future<void> cachePostDetail(
      int postId, Map<String, dynamic> postData) async {
    try {
      await _cacheBox.put('post_detail_$postId', postData);
      await _metadataBox.put(
          'post_detail_${postId}_time', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached post detail $postId');
    } catch (e) {
      print('❌ Error caching post detail: $e');
    }
  }

  /// Get cached post detail
  static Map<String, dynamic>? getCachedPostDetail(int postId,
      {int maxAgeHours = 6}) {
    try {
      final cachedAt = _metadataBox.get('post_detail_${postId}_time') as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageHours = age / (1000 * 60 * 60);

        if (ageHours > maxAgeHours) {
          return null;
        }
      }

      final postDetail = _cacheBox.get('post_detail_$postId');
      if (postDetail is Map<String, dynamic>) {
        print('📱 Using cached post detail $postId');
        return postDetail;
      }
      return null;
    } catch (e) {
      print('❌ Error getting cached post detail: $e');
      return null;
    }
  }

  // ========== USER PROFILE CACHE ==========

  /// Cache user profile
  static Future<void> cacheUserProfile(
      String identifier, Map<String, dynamic> profile) async {
    try {
      await _cacheBox.put('profile_$identifier', profile);
      await _metadataBox.put(
          'profile_${identifier}_time', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached profile for $identifier');
    } catch (e) {
      print('❌ Error caching profile: $e');
    }
  }

  /// Get cached user profile
  static Map<String, dynamic>? getCachedUserProfile(String identifier,
      {int maxAgeHours = 12}) {
    try {
      final cachedAt = _metadataBox.get('profile_${identifier}_time') as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageHours = age / (1000 * 60 * 60);

        if (ageHours > maxAgeHours) {
          return null;
        }
      }

      final profile = _cacheBox.get('profile_$identifier');
      if (profile is Map<String, dynamic>) {
        print('📱 Using cached profile for $identifier');
        return profile;
      }
      return null;
    } catch (e) {
      print('❌ Error getting cached profile: $e');
      return null;
    }
  }

  // ========== COMMENTS CACHE (Enhanced dari CommentService existing) ==========

  /// Cache comments for post
  static Future<void> cacheComments(int postId, List<dynamic> comments) async {
    try {
      await _cacheBox.put('comments_$postId', comments);
      await _metadataBox.put(
          'comments_${postId}_time', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached ${comments.length} comments for post $postId');
    } catch (e) {
      print('❌ Error caching comments: $e');
    }
  }

  /// Get cached comments
  static List<dynamic> getCachedComments(int postId, {int maxAgeMinutes = 5}) {
    try {
      final cachedAt = _metadataBox.get('comments_${postId}_time') as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageMinutes = age / (1000 * 60);

        if (ageMinutes > maxAgeMinutes) {
          return [];
        }
      }

      final comments = _cacheBox.get('comments_$postId');
      if (comments is List<dynamic>) {
        print('📱 Using ${comments.length} cached comments for post $postId');
        return comments;
      }
      return [];
    } catch (e) {
      print('❌ Error getting cached comments: $e');
      return [];
    }
  }

  // ========== FOLLOWERS/FOLLOWING CACHE ==========

  /// Cache followers list
  static Future<void> cacheFollowers(
      String userId, List<dynamic> followers) async {
    try {
      await _cacheBox.put('followers_$userId', followers);
      await _metadataBox.put(
          'followers_${userId}_time', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached ${followers.length} followers for user $userId');
    } catch (e) {
      print('❌ Error caching followers: $e');
    }
  }

  /// Cache following list
  static Future<void> cacheFollowing(
      String userId, List<dynamic> following) async {
    try {
      await _cacheBox.put('following_$userId', following);
      await _metadataBox.put(
          'following_${userId}_time', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached ${following.length} following for user $userId');
    } catch (e) {
      print('❌ Error caching following: $e');
    }
  }

  /// Get cached followers
  static List<dynamic> getCachedFollowers(String userId,
      {int maxAgeHours = 6}) {
    try {
      final cachedAt = _metadataBox.get('followers_${userId}_time') as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageHours = age / (1000 * 60 * 60);

        if (ageHours > maxAgeHours) return [];
      }

      final followers = _cacheBox.get('followers_$userId');
      return followers is List<dynamic> ? followers : [];
    } catch (e) {
      return [];
    }
  }

  /// Get cached following
  static List<dynamic> getCachedFollowing(String userId,
      {int maxAgeHours = 6}) {
    try {
      final cachedAt = _metadataBox.get('following_${userId}_time') as int?;
      if (cachedAt != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
        final ageHours = age / (1000 * 60 * 60);

        if (ageHours > maxAgeHours) return [];
      }

      final following = _cacheBox.get('following_$userId');
      return following is List<dynamic> ? following : [];
    } catch (e) {
      return [];
    }
  }

  // ========== LIKES CACHE ==========

  /// Cache post likes data (count dan status)
  static Future<void> cacheLikesData(
    int postId, {
    int? likesCount,
    bool? isLiked,
    List<dynamic>? likesList,
  }) async {
    try {
      final likesData = {
        'count': likesCount,
        'is_liked': isLiked,
        'likes_list': likesList,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      await _cacheBox.put('likes_$postId', likesData);
      print(
          '✅ Cached likes data for post $postId (count: $likesCount, liked: $isLiked)');
    } catch (e) {
      print('❌ Error caching likes data: $e');
    }
  }

  /// Get cached likes data
  static Map<String, dynamic>? getCachedLikesData(int postId,
      {int maxAgeMinutes = 10}) {
    try {
      final likesData = _cacheBox.get('likes_$postId');
      if (likesData is Map<String, dynamic>) {
        final cachedAt = likesData['cached_at'] as int?;
        if (cachedAt != null) {
          final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
          final ageMinutes = age / (1000 * 60);

          if (ageMinutes > maxAgeMinutes) {
            return null;
          }
        }

        print('📱 Using cached likes data for post $postId');
        return likesData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update like status optimistically (untuk instant UI update)
  static Future<void> updateLikeStatusOptimistic(
      int postId, bool isLiked, int newCount) async {
    try {
      final existingData = getCachedLikesData(postId) ?? {};

      final updatedData = {
        ...existingData,
        'count': newCount,
        'is_liked': isLiked,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      };

      await _cacheBox.put('likes_$postId', updatedData);

      // Juga update di feed/explore posts cache
      await _updatePostLikesInFeedCache(postId, isLiked, newCount);

      print('✅ Updated like status optimistically for post $postId');
    } catch (e) {
      print('❌ Error updating like status: $e');
    }
  }

  /// Helper untuk update likes di feed cache
  static Future<void> _updatePostLikesInFeedCache(
      int postId, bool isLiked, int newCount) async {
    try {
      // Update di feed posts
      final feedPost = _cacheBox.get('post_$postId');
      if (feedPost != null && feedPost is Map<String, dynamic>) {
        feedPost['likes_count'] = newCount;
        feedPost['is_liked'] = isLiked;
        await _cacheBox.put('post_$postId', feedPost);
      }

      // Update di explore posts
      final explorePost = _cacheBox.get('explore_post_$postId');
      if (explorePost != null && explorePost is Map<String, dynamic>) {
        explorePost['likes_count'] = newCount;
        explorePost['is_liked'] = isLiked;
        await _cacheBox.put('explore_post_$postId', explorePost);
      }

      // Update di post detail
      final postDetail = _cacheBox.get('post_detail_$postId');
      if (postDetail != null && postDetail is Map<String, dynamic>) {
        postDetail['likes_count'] = newCount;
        postDetail['is_liked'] = isLiked;
        await _cacheBox.put('post_detail_$postId', postDetail);
      }
    } catch (e) {
      print('❌ Error updating posts in feed cache: $e');
    }
  }

  // ========== IMAGE CACHE ==========

  /// Cache image URL dengan expiry
  static Future<void> cacheImage(String url, String localPath) async {
    try {
      await _imageCache.put(url, {
        'local_path': localPath,
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('❌ Error caching image: $e');
    }
  }

  /// Get cached image path
  static String? getCachedImagePath(String url, {int maxAgeDays = 7}) {
    try {
      final imageData = _imageCache.get(url);
      if (imageData is Map<String, dynamic>) {
        final cachedAt = imageData['cached_at'] as int?;
        if (cachedAt != null) {
          final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
          final ageDays = age / (1000 * 60 * 60 * 24);

          if (ageDays > maxAgeDays) {
            return null;
          }
        }

        return imageData['local_path'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== UTILITY METHODS ==========

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final keysToDelete = <String>[];

      // Check and mark expired entries
      for (final key in _metadataBox.keys) {
        if (key.toString().endsWith('_time')) {
          final timestamp = _metadataBox.get(key) as int?;
          if (timestamp != null) {
            final age = now - timestamp;
            final ageDays = age / (1000 * 60 * 60 * 24);

            // Remove entries older than 7 days
            if (ageDays > 7) {
              keysToDelete.add(key.toString());
            }
          }
        }
      }

      // Delete expired entries
      for (final key in keysToDelete) {
        await _metadataBox.delete(key);
        // Also delete corresponding data
        final dataKey = key.replaceAll('_time', '');
        await _cacheBox.delete(dataKey);
      }

      print('🧹 Cleared ${keysToDelete.length} expired cache entries');
    } catch (e) {
      print('❌ Error clearing expired cache: $e');
    }
  }

  /// Clear specific cache type
  static Future<void> clearCacheType(String type) async {
    try {
      final keysToDelete = <String>[];

      for (final key in _cacheBox.keys) {
        if (key.toString().startsWith(type)) {
          keysToDelete.add(key.toString());
        }
      }

      for (final key in keysToDelete) {
        await _cacheBox.delete(key);
        await _metadataBox.delete('${key}_time');
      }

      print('🧹 Cleared $type cache (${keysToDelete.length} entries)');
    } catch (e) {
      print('❌ Error clearing $type cache: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      await _cacheBox.clear();
      await _metadataBox.clear();
      await _imageCache.clear();
      print('🧹 Cleared all cache');
    } catch (e) {
      print('❌ Error clearing all cache: $e');
    }
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    try {
      return {
        'total_entries': _cacheBox.length,
        'metadata_entries': _metadataBox.length,
        'image_entries': _imageCache.length,
      };
    } catch (e) {
      return {'total_entries': 0, 'metadata_entries': 0, 'image_entries': 0};
    }
  }

  /// Check if cache is healthy
  static Future<bool> isHealthy() async {
    try {
      await _cacheBox.put(
          'health_check', DateTime.now().millisecondsSinceEpoch);
      final healthCheck = _cacheBox.get('health_check');
      await _cacheBox.delete('health_check');
      return healthCheck != null;
    } catch (e) {
      return false;
    }
  }
}
