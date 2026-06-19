// lib/services/follow_service.dart

import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/api_endpoint.dart';
import '../utils/secure_storage.dart';

class FollowService {
  final String _baseUrl = ApiEndpoints.apiUrl;

  static final Map<String, Map<String, dynamic>> _profileCache = {};
  static final Map<String, Map<String, dynamic>> _followStatusCache = {};
  static final Map<String, Map<String, dynamic>> _followingCache = {};
  static final Map<String, Map<String, dynamic>> _followersCache = {};

  static const int _profileCacheExpiry = 15;
  static const int _followingCacheExpiry = 5;
  static const int _followStatusExpiry = 2;
  static const int _myProfileExpiry = 3;

  static int _cacheHits = 0;
  static int _totalRequests = 0;

  Future<String?> _getToken() async {
    return await SecureStorage.getToken();
  }

  Future<List<User>> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final token = await SecureStorage.getToken();
    final url = Uri.parse('$_baseUrl/users/search?username=$query&full_name=$query');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // Konversi langsung dari List<dynamic> ke List<User>
        final List<dynamic> data = json.decode(response.body);
        return data.map((userData) => User.fromJson(userData)).toList();
      } else {
        print('Gagal mencari pengguna: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Terjadi kesalahan saat mencari pengguna: $e');
      return [];
    }
  }

  Future<List<User>> getFollowingList(int userId) async {
    final token = await SecureStorage.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    // Gunakan endpoint yang sesuai dengan gambar Anda
    final url = Uri.parse('$_baseUrl/users/$userId/following');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ambil list mentah (List<dynamic>) dari JSON
        final List<dynamic> followingList = data['following'] ?? [];

        // 2. KONVERSI list mentah menjadi List<User> sebelum dikembalikan
        return followingList.map((userData) => User.fromJson(userData)).toList();
      } else {
        return []; // Kembalikan list kosong dengan tipe yang benar
      }
    } catch (e) {
      throw Exception('Error saat memuat daftar following: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  bool _isCacheValid(Map<String, dynamic> cached, int expiryMinutes) {
    final cachedTime = DateTime.parse(cached['_cached_at']);
    return DateTime.now().difference(cachedTime).inMinutes < expiryMinutes;
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    _totalRequests++;
    const cacheKey = '_my_profile';

    if (_profileCache.containsKey(cacheKey)) {
      final cached = _profileCache[cacheKey]!;
      if (_isCacheValid(cached, _myProfileExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: My profile (${_cacheHits}/$_totalRequests hits)');
        return Map<String, dynamic>.from(cached)..remove('_cached_at');
      }
    }
    try {
      print('🌐 API call: Getting my profile');
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/user'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        Map<String, dynamic> profile = (data['user'] != null) ? data['user'] : data;
        _profileCache[cacheKey] = {...profile, '_cached_at': DateTime.now().toIso8601String()};
        return profile;
      } else {
        throw Exception('Gagal memuat profil: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getMyProfile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(dynamic userIdentifier) async {
    _totalRequests++;
    final cacheKey = 'profile_$userIdentifier';
    if (_profileCache.containsKey(cacheKey)) {
      final cached = _profileCache[cacheKey]!;
      if (_isCacheValid(cached, _profileCacheExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: Profile $userIdentifier (${_cacheHits}/$_totalRequests hits)');
        return Map<String, dynamic>.from(cached)..remove('_cached_at');
      }
    }
    try {
      print('🌐 API call: Getting profile for $userIdentifier');
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/profile/$userIdentifier'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _profileCache[cacheKey] = {...data, '_cached_at': DateTime.now().toIso8601String()};
        return data;
      } else {
        throw Exception('Gagal memuat profil user: ${res.statusCode}');
      }
    } catch (e) {
      print('Error in getUserProfile: $e');
      rethrow;
    }
  }

  Future<int?> _getUserIdFromUsername(String username) async {
    try {
      final profile = await getUserProfile(username);
      final userId = (profile['user_id'] as num?)?.toInt() ?? (profile['id'] as num?)?.toInt();
      if (userId != null) {
        _profileCache['userid_$username'] = {'user_id': userId, '_cached_at': DateTime.now().toIso8601String()};
      }
      return userId;
    } catch (e) {
      print('Error getting user ID for username $username: $e');
      return null;
    }
  }

  int? _getCachedUserId(String username) {
    final cacheKey = 'userid_$username';
    if (_profileCache.containsKey(cacheKey)) {
      final cached = _profileCache[cacheKey]!;
      if (_isCacheValid(cached, _profileCacheExpiry)) {
        return cached['user_id'];
      }
    }
    return null;
  }

  Future<bool> followUser(dynamic userIdentifier) async {
    try {
      print('🔄 Attempting to follow user $userIdentifier');
      final headers = await _getHeaders();
      dynamic targetId = userIdentifier;
      if (userIdentifier is String && !RegExp(r'^\d+$').hasMatch(userIdentifier)) {
        final cachedUserId = _getCachedUserId(userIdentifier);
        if (cachedUserId != null) {
          targetId = cachedUserId;
          print('✅ Using cached user_id: $cachedUserId for $userIdentifier');
        }
      }
      bool success = await _tryFollowWithIdentifier(targetId, headers);
      if (success) {
        _invalidateUserCache(userIdentifier.toString());
        return true;
      }
      if (userIdentifier is String && !RegExp(r'^\d+$').hasMatch(userIdentifier) && targetId == userIdentifier) {
        print('🔍 Getting fresh user_id for $userIdentifier');
        final userId = await _getUserIdFromUsername(userIdentifier);
        if (userId != null) {
          print('✅ Found user_id: $userId for username: $userIdentifier');
          success = await _tryFollowWithIdentifier(userId, headers);
          if (success) {
            _invalidateUserCache(userIdentifier.toString());
            return true;
          }
        }
      }
      final alternativeEndpoints = ['users/$userIdentifier/follow', 'user/follow/$userIdentifier'];
      for (final endpoint in alternativeEndpoints) {
        try {
          final url = '$_baseUrl/$endpoint';
          print('🌐 Trying alternative endpoint: $url');
          final res = await http.post(Uri.parse(url), headers: headers);
          print('📥 Alternative response: ${res.statusCode} - ${res.body}');
          success = res.statusCode == 200 || res.statusCode == 201 || (res.statusCode == 409 && res.body.contains('Sudah di-follow'));
          if (success) {
            print('✅ Follow successful with endpoint: $endpoint');
            _invalidateUserCache(userIdentifier.toString());
            return true;
          }
        } catch (e) {
          continue;
        }
      }
      return false;
    } catch (e) {
      print('Error in followUser: $e');
      return false;
    }
  }

  Future<bool> _tryFollowWithIdentifier(dynamic identifier, Map<String, String> headers) async {
    try {
      final url = '$_baseUrl/follow/$identifier';
      print('🌐 Trying URL: $url');
      final res = await http.post(Uri.parse(url), headers: headers);
      print('📥 Follow response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200 || res.statusCode == 201 || (res.statusCode == 409 && res.body.contains('Sudah di-follow'));
    } catch (e) {
      print('❌ Follow attempt failed: $e');
      return false;
    }
  }

  Future<bool> unfollowUser(dynamic userIdentifier) async {
    try {
      print('🔄 Attempting to unfollow user $userIdentifier');
      final headers = await _getHeaders();
      dynamic targetId = userIdentifier;
      if (userIdentifier is String && !RegExp(r'^\d+$').hasMatch(userIdentifier)) {
        final cachedUserId = _getCachedUserId(userIdentifier);
        if (cachedUserId != null) {
          targetId = cachedUserId;
          print('✅ Using cached user_id: $cachedUserId for $userIdentifier');
        }
      }
      bool success = await _tryUnfollowWithIdentifier(targetId, headers);
      if (success) {
        _invalidateUserCache(userIdentifier.toString());
        return true;
      }
      if (userIdentifier is String && !RegExp(r'^\d+$').hasMatch(userIdentifier) && targetId == userIdentifier) {
        final userId = await _getUserIdFromUsername(userIdentifier);
        if (userId != null) {
          success = await _tryUnfollowWithIdentifier(userId, headers);
          if (success) {
            _invalidateUserCache(userIdentifier.toString());
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print('Error in unfollowUser: $e');
      return false;
    }
  }

  Future<bool> _tryUnfollowWithIdentifier(dynamic identifier, Map<String, String> headers) async {
    try {
      final url = '$_baseUrl/unfollow/$identifier';
      final res = await http.delete(Uri.parse(url), headers: headers);
      print('📥 Unfollow response: ${res.statusCode} - ${res.body}');
      return res.statusCode == 200 || res.statusCode == 204 || (res.statusCode == 404 && res.body.contains('tidak ditemukan'));
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getFollowStatus(String targetUsername) async {
    _totalRequests++;
    final cacheKey = 'follow_status_$targetUsername';
    if (_followStatusCache.containsKey(cacheKey)) {
      final cached = _followStatusCache[cacheKey]!;
      if (_isCacheValid(cached, _followStatusExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: Follow status $targetUsername (${_cacheHits}/$_totalRequests hits)');
        return Map<String, dynamic>.from(cached)..remove('_cached_at');
      }
    }
    try {
      print('🔍 Checking follow status for $targetUsername');
      final myProfile = await getMyProfile();
      final myUserId = myProfile['user_id'] ?? myProfile['id'];
      if (myUserId == null) throw Exception('Unable to get current user ID');
      final followingData = await _getMyFollowingCached(myUserId);
      final followingList = followingData['following'] ?? [];
      final followData = followingList.firstWhere((user) => user['username']?.toString() == targetUsername, orElse: () => null);
      Map<String, dynamic> result;
      if (followData != null) {
        final pivot = followData['pivot'] ?? {};
        result = {'isFollowing': true, 'status': pivot['status'] ?? 'accepted', 'followedAt': pivot['followed_at']};
        print('✅ Found follow relationship: ${result['status']}');
      } else {
        result = {'isFollowing': false, 'status': null, 'followedAt': null};
      }
      _followStatusCache[cacheKey] = {...result, '_cached_at': DateTime.now().toIso8601String()};
      return result;
    } catch (e) {
      print('Error getting follow status: $e');
      return {'isFollowing': false, 'status': null, 'followedAt': null};
    }
  }

  Future<Map<String, dynamic>> _getMyFollowingCached(int userId) async {
    _totalRequests++;
    final cacheKey = 'my_following_$userId';
    if (_followingCache.containsKey(cacheKey)) {
      final cached = _followingCache[cacheKey]!;
      if (_isCacheValid(cached, _followingCacheExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: Following list (${_cacheHits}/$_totalRequests hits)');
        return Map<String, dynamic>.from(cached)..remove('_cached_at');
      }
    }
    try {
      print('🌐 API call: Getting following list');
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/users/$userId/following'), headers: headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _followingCache[cacheKey] = {...data, '_cached_at': DateTime.now().toIso8601String()};
        return data;
      } else {
        return {'following': []};
      }
    } catch (e) {
      print('Error in _getMyFollowingCached: $e');
      return {'following': []};
    }
  }

  Future<List<dynamic>> getFollowers(dynamic userIdentifier, {bool forceRefresh = false}) async {
    _totalRequests++;
    final cacheKey = 'followers_$userIdentifier';
    if (!forceRefresh && _followersCache.containsKey(cacheKey)) {
      final cached = _followersCache[cacheKey]!;
      if (_isCacheValid(cached, _followingCacheExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: Followers $userIdentifier (${_cacheHits}/$_totalRequests hits)');
        final data = Map<String, dynamic>.from(cached)..remove('_cached_at');
        return data['followers'] ?? [];
      }
    }
    try {
      print('🌐 API call: Getting followers for $userIdentifier');
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/users/$userIdentifier/followers'), headers: headers).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _followersCache[cacheKey] = {...data, '_cached_at': DateTime.now().toIso8601String()};
        final List<dynamic> userList = data['followers'] ?? [];
        return userList.map((userData) => User.fromJson(userData)).toList();
        // return data['followers'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print('Error in getFollowers: $e');
      return [];
    }
  }

  // lib/services/follow_service.dart

  Future<List<User>> getFollowing(dynamic userIdentifier, {bool forceRefresh = false}) async {
    _totalRequests++;
    final cacheKey = 'following_$userIdentifier';
    if (!forceRefresh && _followingCache.containsKey(cacheKey)) {
      final cached = _followingCache[cacheKey]!;
      if (_isCacheValid(cached, _followingCacheExpiry)) {
        _cacheHits++;
        print('✅ Cache hit: Following $userIdentifier (${_cacheHits}/$_totalRequests hits)');
        final data = Map<String, dynamic>.from(cached)..remove('_cached_at');

        // Konversi dari cache
        final List<dynamic> userList = data['following'] ?? [];
        return userList.map((userData) => User.fromJson(userData)).toList();
      }
    }
    try {
      print('🌐 API call: Getting following for $userIdentifier');
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$_baseUrl/users/$userIdentifier/following'), headers: headers).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _followingCache[cacheKey] = {...data, '_cached_at': DateTime.now().toIso8601String()};

        // KUNCI PERBAIKAN: Konversi List<dynamic> menjadi List<User>
        final List<dynamic> userList = data['following'] ?? [];
        return userList.map((userData) => User.fromJson(userData)).toList();

      } else {
        return []; // Kembalikan list kosong dengan tipe yang benar
      }
    } catch (e) {
      print('Error in getFollowing: $e');
      return []; // Kembalikan list kosong jika error
    }
  }

  Future<bool> isFollowing(String targetUsername) async {
    final status = await getFollowStatus(targetUsername);
    return status['isFollowing'] ?? false;
  }

  Future<Map<String, int>> getFollowCounts(dynamic userIdentifier) async {
    try {
      final profile = await getUserProfile(userIdentifier);
      return <String, int>{
        'followers': (profile['followers_count'] as num?)?.toInt() ?? 0,
        'following': (profile['following_count'] as num?)?.toInt() ?? 0,
      };
    } catch (e) {
      print('Error getting follow counts: $e');
      return <String, int>{'followers': 0, 'following': 0};
    }
  }

  void _invalidateUserCache(String userIdentifier) {
    _followStatusCache.removeWhere((key, value) => key.contains(userIdentifier));
    _followingCache.clear();
    _profileCache.remove('_my_profile');
    _profileCache.remove('profile_$userIdentifier');
    print('🗑️ Smart cache invalidation for user $userIdentifier');
  }

  void clearCache() {
    _profileCache.clear();
    _followStatusCache.clear();
    _followingCache.clear();
    _followersCache.clear();
    _cacheHits = 0;
    _totalRequests = 0;
    print('🗑️ All cache cleared');
  }

  void clearFollowStatusCache() {
    _followStatusCache.clear();
    print('🗑️ Follow status cache cleared');
  }

  Future<void> preloadUserData(String username) async {
    print('🚀 Preloading data for $username');
    try {
      await Future.wait([getUserProfile(username), getFollowStatus(username)]);
      print('✅ Preload completed for $username');
    } catch (e) {
      print('❌ Preload failed for $username: $e');
    }
  }

  void printCacheStats() {
    final hitRate = _totalRequests > 0 ? (_cacheHits / _totalRequests * 100).toStringAsFixed(1) : '0.0';
    print('\n📊 CACHE STATISTICS');
    print('═' * 40);
    print('Total requests: $_totalRequests');
    print('Cache hits: $_cacheHits');
    print('Hit rate: $hitRate%');
    print('Profile cache size: ${_profileCache.length}');
    print('Following cache size: ${_followingCache.length}');
    print('Follow status cache size: ${_followStatusCache.length}');
    print('Followers cache size: ${_followersCache.length}');
    print('═' * 40);
  }

  void cleanExpiredCache() {
    final now = DateTime.now();
    int cleaned = 0;
    _profileCache.removeWhere((key, value) {
      if (value['_cached_at'] != null) {
        final cachedTime = DateTime.parse(value['_cached_at']);
        final isExpired = now.difference(cachedTime).inMinutes > _profileCacheExpiry;
        if (isExpired) cleaned++;
        return isExpired;
      }
      return false;
    });
    [_followStatusCache, _followingCache, _followersCache].forEach((cache) {
      cache.removeWhere((key, value) {
        if (value['_cached_at'] != null) {
          final cachedTime = DateTime.parse(value['_cached_at']);
          final isExpired = now.difference(cachedTime).inMinutes > _followingCacheExpiry;
          if (isExpired) cleaned++;
          return isExpired;
        }
        return false;
      });
    });
    print('🧹 Cleaned $cleaned expired cache entries');
  }

  Future<bool> userExists(String username) async {
    try {
      await getUserProfile(username);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getFollowStatusLegacy(int currentUserId, int targetUserId) async {
    try {
      final followingData = await _getMyFollowingCached(currentUserId);
      final followingList = followingData['following'] ?? [];
      final followData = followingList.firstWhere((user) => user['user_id'] == targetUserId, orElse: () => null);
      if (followData != null) {
        final pivot = followData['pivot'] ?? {};
        return {'isFollowing': true, 'status': pivot['status'] ?? 'accepted', 'followedAt': pivot['followed_at']};
      }
      return {'isFollowing': false, 'status': null, 'followedAt': null};
    } catch (e) {
      return {'isFollowing': false, 'status': null, 'followedAt': null};
    }
  }

  Future<bool> isFollowingLegacy(int currentUserId, int targetUserId) async {
    final status = await getFollowStatusLegacy(currentUserId, targetUserId);
    return status['isFollowing'] ?? false;
  }
}