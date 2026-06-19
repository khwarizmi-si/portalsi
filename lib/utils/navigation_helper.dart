// lib/utils/navigation_helper.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../pages/post_detail.dart';
import '../pages/post_detail_page.dart';
import '../providers/navigation_provider.dart';
import 'secure_storage.dart';
import '../pages/other_profile_page.dart';

class NavigationHelper {
  /// Navigate ke profile berdasarkan user data
  /// Jika user_id sama dengan current user, navigate ke ProfilePage
  /// Jika berbeda, navigate ke OtherProfilePage

  static Future<void> navigateToProfile2(
      BuildContext context,
      User user, // <-- 2. UBAH DARI MAP MENJADI OBJEK USER
          {
        bool showHapticFeedback = true,
        bool debugMode = false,
      }) async {
    if (showHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    // 3. AKSES PROPERTI LANGSUNG, TIDAK PERLU MAP LAGI
    final username = user.username ?? 'Unknown User';
    final userId = user.id;

    if (debugMode) {
      debugPrint('🔍 NavigationHelper: Navigating to profile: $username (user_id: $userId)');
    }

    try {
      final currentUserId = await SecureStorage.getUserId();

      if (debugMode) {
        debugPrint('🔍 NavigationHelper: Current user_id: $currentUserId');
      }

      if (currentUserId != null && userId != null && userId == currentUserId) {
        if (debugMode) {
          debugPrint('✅ NavigationHelper: Navigating to own profile');
        }
        Provider.of<NavigationProvider>(context, listen: false).navigateToTab(4);
        return;
      }

      if (debugMode) {
        debugPrint('✅ NavigationHelper: Navigating to other profile');
      }

      // Web: use a real route so the URL becomes /username and survives refresh.
      if (kIsWeb) {
        Navigator.of(context).pushNamed('/$username');
        return;
      }

      Provider.of<NavigationProvider>(context, listen: false).showOverlay(
        OtherProfilePage(username: username),
      );
    } catch (e) {
      if (debugMode) {
        debugPrint('❌ NavigationHelper Error: $e');
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(
            username: username,
          ),
        ),
      );
    }
  }


  static Future<void> navigateToProfile(BuildContext context, User user) async {
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Cek apakah user yang dituju adalah user yang sedang login
    final currentUserId = await SecureStorage.getUserId();
    if (currentUserId != null && user.id != null && user.id == currentUserId) {
      navProvider.navigateToTab(4);
      return;
    }

    // Web: route to /username so the URL is shareable and refresh-safe.
    if (kIsWeb) {
      Navigator.of(context).pushNamed('/${user.username}');
      return;
    }

    final newPage = OtherProfilePage(username: user.username);

    // INI BAGIAN KUNCINYA
    if (navProvider.overlayPage != null) {
      navProvider.replaceOverlay(newPage); // Jika sudah ada, ganti
    } else {
      navProvider.showOverlay(newPage); // Jika belum ada, tampilkan
    }
  }

  static void navigateToPostDetail(BuildContext context, int postId, {Post? initialPost}) {
    // Web: route to /post/:id so the post URL is shareable and refresh-safe.
    if (kIsWeb) {
      Navigator.of(context).pushNamed('/post/$postId');
      return;
    }

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // Kirim postId dan juga initialPost ke halaman detail
    navProvider.showOverlay(PostDetailPage(postId: postId, initialPost: initialPost));
  }

  /// Navigate ke profile berdasarkan username (legacy method)
  static Future<void> navigateToProfileByUsername(
    BuildContext context,
    String targetUsername, {
    bool showHapticFeedback = true,
    bool debugMode = false,
  }) async {
    if (showHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (debugMode) {
      debugPrint('🔍 NavigationHelper: Navigating to profile: $targetUsername');
    }

    try {
      final currentUsername = await SecureStorage.getUsername();

      if (debugMode) {
        debugPrint('🔍 NavigationHelper: Current user: $currentUsername');
      }

      // Jika username sama dengan user yang login
      if (currentUsername != null &&
          targetUsername.toLowerCase() == currentUsername.toLowerCase()) {
        if (debugMode) {
          debugPrint('✅ NavigationHelper: Navigating to own profile');
        }

        Navigator.pushReplacementNamed(context, '/profile');
        return;
      }

      // Jika berbeda, navigate ke OtherProfilePage
      if (debugMode) {
        debugPrint('✅ NavigationHelper: Navigating to other profile');
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(
            username: targetUsername,
          ),
        ),
      );
    } catch (e) {
      if (debugMode) {
        debugPrint('❌ NavigationHelper Error: $e');
      }

      // Fallback: navigate ke OtherProfilePage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(
            username: targetUsername,
          ),
        ),
      );
    }
  }

  /// Check apakah user_id adalah current user
  static Future<bool> isCurrentUser(int? userId) async {
    try {
      if (userId == null) return false;

      final currentUserId = await SecureStorage.getUserId();
      if (currentUserId == null) return false;

      return userId == currentUserId;
    } catch (e) {
      debugPrint('Error checking current user: $e');
      return false;
    }
  }

  /// Check apakah username adalah current user (legacy)
  static Future<bool> isCurrentUserByUsername(String username) async {
    try {
      final currentUsername = await SecureStorage.getUsername();
      if (currentUsername == null) return false;

      return username.toLowerCase() == currentUsername.toLowerCase();
    } catch (e) {
      debugPrint('Error checking current user: $e');
      return false;
    }
  }

  /// Helper method untuk extract user_id dari berbagai struktur data
  static int? _extractUserId(Map<String, dynamic> user) {
    // Coba berbagai kemungkinan key untuk user_id
    final possibleKeys = ['user_id', 'id', 'userId'];

    for (final key in possibleKeys) {
      final value = user[key];
      if (value != null) {
        if (value is int) {
          return value;
        } else if (value is String) {
          return int.tryParse(value);
        }
      }
    }

    // Jika user data nested dalam 'user' object
    final nestedUser = user['user'];
    if (nestedUser is Map<String, dynamic>) {
      for (final key in possibleKeys) {
        final value = nestedUser[key];
        if (value != null) {
          if (value is int) {
            return value;
          } else if (value is String) {
            return int.tryParse(value);
          }
        }
      }
    }

    return null;
  }

  /// Get current user data
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final username = await SecureStorage.getUsername();
      final fullName = await SecureStorage.getFullName();
      final profilePicture = await SecureStorage.getProfilePicture();
      final userId = await SecureStorage.getUserId();

      if (username == null || userId == null) return null;

      return {
        'username': username,
        'full_name': fullName,
        'profile_picture_url': profilePicture,
        'user_id': userId,
      };
    } catch (e) {
      debugPrint('Error getting current user data: $e');
      return null;
    }
  }

  /// Navigate dengan custom page transition berdasarkan user data
  static Future<void> navigateToProfileWithTransition(
    BuildContext context,
    Map<String, dynamic> user, {
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    final userId = _extractUserId(user);
    final isOwn = await isCurrentUser(userId);

    if (isOwn) {
      Navigator.pushReplacementNamed(context, '/profile');
      return;
    }

    final username = user['username'] ?? 'Unknown User';

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OtherProfilePage(username: username),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: duration,
      ),
    );
  }
}
