// lib/utils/follow_state_manager.dart
//
// Global singleton that broadcasts follow/unfollow events so every page
// showing a user's follow button stays in sync — without prop-drilling or
// requiring a full rebuild of the widget tree.

import 'dart:async';

class FollowStateManager {
  // ── Singleton ────────────────────────────────────────────────────────
  static final FollowStateManager _instance = FollowStateManager._internal();
  factory FollowStateManager() => _instance;
  FollowStateManager._internal();

  // ── Internal state ───────────────────────────────────────────────────
  final _controller = StreamController<MapEntry<int, bool>>.broadcast();

  /// Local cache: userId → isFollowing.
  /// Pages can read this for an instant initial value before the stream fires.
  final Map<int, bool> _followingMap = {};

  // ── Public API ───────────────────────────────────────────────────────

  /// Stream of follow-state changes. Each event is (userId, isFollowing).
  Stream<MapEntry<int, bool>> get changes => _controller.stream;

  /// Call this after a successful follow or unfollow action.
  void setFollowing(int userId, bool isFollowing) {
    _followingMap[userId] = isFollowing;
    _controller.add(MapEntry(userId, isFollowing));
  }

  /// Returns the cached follow state for [userId], or `null` if unknown.
  bool? isFollowing(int userId) => _followingMap[userId];

  /// Seed the cache from a bulk list (e.g. after fetching a profile).
  /// Does NOT broadcast — just warms the cache silently.
  void seed(Map<int, bool> entries) {
    _followingMap.addAll(entries);
  }
}
