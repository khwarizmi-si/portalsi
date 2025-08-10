import 'dart:async';
import '../services/follow_service.dart';
import 'package:flutter/foundation.dart';

class CacheManager {
  static Timer? _cleanupTimer;
  static Timer? _optimizationTimer;
  static final FollowService _followService = FollowService();
  static bool _isInitialized = false;

  // Start automatic cache management
  static void startAutoCleanup() {
    if (_cleanupTimer?.isActive == true) return;

    // Clean expired cache every 10 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (kDebugMode) {
        print('🧹 Auto cleaning expired cache...');
      }
      _followService.cleanExpiredCache();

      if (kDebugMode) {
        _followService.printCacheStats();
      }
    });

    if (kDebugMode) {
      print('✅ Auto cache cleanup started');
    }
  }

  // Stop automatic cleanup
  static void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    if (kDebugMode) {
      print('⏹️ Auto cache cleanup stopped');
    }
  }

  // Preload critical data for better UX
  static Future<void> preloadCriticalData() async {
    try {
      if (kDebugMode) {
        print('🚀 Preloading critical data...');
      }

      // Get my profile first (most important)
      await _followService.getMyProfile();

      if (kDebugMode) {
        print('✅ My profile cached');
        print('✅ Critical data preloading completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Critical data preloading failed: $e');
      }
    }
  }

  // Smart preload based on user behavior
  static Future<void> smartPreload(List<String> usernames) async {
    if (usernames.isEmpty) return;

    if (kDebugMode) {
      print('🧠 Smart preloading for ${usernames.length} users...');
    }

    // Limit to prevent too many API calls
    final limitedUsernames = usernames.take(5).toList();

    try {
      // Preload in parallel but with controlled concurrency
      await Future.wait(
        limitedUsernames
            .map((username) => _followService.preloadUserData(username)),
        eagerError: false,
      );

      if (kDebugMode) {
        print('✅ Smart preloading completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Smart preloading failed: $e');
      }
    }
  }

  // Cache warming for specific scenarios
  static Future<void> warmCacheForFeed(List<Map<String, dynamic>> posts) async {
    final usernames = posts
        .map((post) => post['username'] as String?)
        .where((username) => username != null && username.isNotEmpty)
        .cast<String>()
        .toSet() // Remove duplicates
        .take(10) // Limit to prevent overload
        .toList();

    if (usernames.isEmpty) return;

    if (kDebugMode) {
      print('🔥 Warming cache for ${usernames.length} feed users...');
    }

    try {
      // Warm cache for feed users in background
      unawaited(smartPreload(usernames));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Cache warming failed: $e');
      }
    }
  }

  // Intelligent cache management based on app lifecycle
  static void onAppPaused() {
    if (kDebugMode) {
      print('⏸️ App paused - cleaning cache...');
    }
    _followService.cleanExpiredCache();
  }

  static void onAppResumed() {
    if (kDebugMode) {
      print('▶️ App resumed - starting preload...');
    }
    unawaited(preloadCriticalData());
  }

  static void onMemoryPressure() {
    if (kDebugMode) {
      print('⚠️ Memory pressure - aggressive cache cleanup...');
    }
    _followService.clearCache();
  }

  // Cache optimization suggestions
  static void analyzeCachePerformance() {
    if (!kDebugMode) return;

    print('\n🎯 CACHE PERFORMANCE ANALYSIS');
    print('═' * 50);

    _followService.printCacheStats();

    // Add recommendations based on usage patterns
    print('\n💡 OPTIMIZATION RECOMMENDATIONS:');
    print('• If hit rate < 60%: Consider increasing cache expiry times');
    print('• If cache size > 1000 items: Implement LRU eviction');
    print('• If memory usage high: Reduce cache expiry times');
    print('• Monitor network calls in production');
    print('═' * 50);
  }

  // Background tasks for cache optimization
  static void startBackgroundOptimization() {
    if (_optimizationTimer?.isActive == true) return;

    // Run optimization every 30 minutes
    _optimizationTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _followService.cleanExpiredCache();

      // In debug mode, show analytics
      if (kDebugMode) {
        analyzeCachePerformance();
      }
    });
  }

  // Initialize cache management system
  static void initialize() {
    if (_isInitialized) {
      if (kDebugMode) {
        print('⚠️ Cache manager already initialized');
      }
      return;
    }

    if (kDebugMode) {
      print('🚀 Initializing cache management system...');
    }

    startAutoCleanup();
    startBackgroundOptimization();

    // Preload critical data
    unawaited(preloadCriticalData());

    _isInitialized = true;

    if (kDebugMode) {
      print('✅ Cache management system initialized');
    }
  }

  // Cleanup when app is disposed
  static void dispose() {
    if (!_isInitialized) return;

    stopAutoCleanup();
    _optimizationTimer?.cancel();
    _optimizationTimer = null;

    _followService.clearCache();
    _isInitialized = false;

    if (kDebugMode) {
      print('🧹 Cache management system disposed');
    }
  }

  // Additional utility methods
  static void clearAllCache() {
    _followService.clearCache();
    if (kDebugMode) {
      print('🗑️ All cache manually cleared');
    }
  }

  static void printStats() {
    _followService.printCacheStats();
  }

  static bool get isInitialized => _isInitialized;
}

// Helper for fire-and-forget operations
void unawaited(Future<void> future) {
  future.catchError((error) {
    if (kDebugMode) {
      print('Background task error: $error');
    }
  });
}
