import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:portal_si/pages/notif_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/feed_page.dart';
import 'pages/other_profile_page.dart';
import 'pages/message_list_page.dart';
import 'pages/story_page.dart';
import 'utils/secure_storage.dart';
import 'managers/cache_manager.dart'; // 🚀 Cache management
import 'services/follow_service.dart'; // For debug functionality

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasToken = await SecureStorage.hasToken();

  // 🚀 Initialize cache management system
  if (hasToken) {
    print('🚀 User logged in - initializing cache system...');
    CacheManager.initialize();
  }

  runApp(MyApp(
    startPage: hasToken ? '/dashboard' : '/login',
    hasToken: hasToken,
  ));
}

class MyApp extends StatefulWidget {
  final String startPage;
  final bool hasToken;

  const MyApp({
    super.key,
    required this.startPage,
    required this.hasToken,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // 🔄 Add app lifecycle observer for cache management
    WidgetsBinding.instance.addObserver(this);

    // 🚀 Preload critical data if user is logged in
    if (widget.hasToken) {
      _initializeAppData();
    }
  }

  @override
  void dispose() {
    // 🧹 Cleanup when app is disposed
    WidgetsBinding.instance.removeObserver(this);
    CacheManager.dispose();
    super.dispose();
  }

  // 🔄 Handle app lifecycle changes for better cache management
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        print('⏸️ App paused - optimizing cache...');
        CacheManager.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        print('▶️ App resumed - refreshing data...');
        CacheManager.onAppResumed();
        break;
      case AppLifecycleState.detached:
        print('🛑 App detached - cleaning up...');
        CacheManager.dispose();
        break;
      default:
        break;
    }
  }

  // 🚨 Handle memory pressure
  @override
  void didHaveMemoryPressure() {
    print('⚠️ Memory pressure detected - clearing cache...');
    CacheManager.onMemoryPressure();
  }

  // 🚀 Initialize app data in background
  Future<void> _initializeAppData() async {
    try {
      print('🚀 Preloading critical app data...');

      // Preload critical data in background
      await CacheManager.preloadCriticalData();

      print('✅ App initialization completed');
    } catch (e) {
      print('❌ App initialization failed: $e');
      // Don't block app startup if preloading fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal SI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        // 🎨 Add app-wide performance optimizations
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      // 🚀 Add global navigation observer for cache warming
      navigatorObservers: [
        CacheNavigationObserver(),
      ],

      initialRoute: widget.startPage,

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => HomePage(),
        '/feed': (context) => FeedPage(),
        '/profile': (context) => const ProfilePage(),
        '/story': (context) => InstagramStoryPage(),
        '/notif': (context) => const NotificationPage(),
        '/message': (context) => MessageListPage(),

        // Tambahkan ini
        '/other-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return OtherProfilePage(
            username: args['username'],
          );
        },

        if (kDebugMode) '/debug_cache': (context) => const CacheDebugPage(),
      },

      // 🐛 Add debug banner for cache status
      debugShowCheckedModeBanner: kDebugMode,
    );
  }
}

// 🚀 Navigation observer for intelligent cache warming
class CacheNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    // Warm cache based on destination
    _warmCacheForRoute(route.settings.name);
  }

  void _warmCacheForRoute(String? routeName) {
    switch (routeName) {
      case '/feed':
        if (kDebugMode) print('🔥 Warming cache for feed...');
        // Cache will be warmed when FeedPage loads posts
        break;
      case '/profile':
        if (kDebugMode) print('🔥 Warming cache for profile...');
        // Preload my profile data
        CacheManager.preloadCriticalData();
        break;
      default:
        break;
    }
  }
}

// 🐛 Debug page for cache monitoring (debug only)
class CacheDebugPage extends StatefulWidget {
  const CacheDebugPage({Key? key}) : super(key: key);

  @override
  State<CacheDebugPage> createState() => _CacheDebugPageState();
}

class _CacheDebugPageState extends State<CacheDebugPage> {
  final FollowService _followService = FollowService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐛 Cache Debug'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚀 Cache Management Debug',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Simple cache monitor buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _followService.printCacheStats();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📊 Cache stats printed to console'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Print Stats'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _followService.cleanExpiredCache();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🧹 Expired cache cleaned'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('Clean Cache'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _followService.clearCache();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🗑️ All cache cleared'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      CacheManager.analyzeCachePerformance();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📈 Analysis printed to console'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Analyze'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text(
              '📊 Performance Tips:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Check console for cache statistics\n'
              '• High hit rate (>70%) = good performance\n'
              '• Clean cache regularly\n'
              '• Monitor memory usage\n'
              '• Remove this page in production',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔧 Extension untuk easy debugging
extension AppDebug on BuildContext {
  // Navigate to debug page
  void showCacheDebug() {
    if (kDebugMode) {
      Navigator.pushNamed(this, '/debug_cache');
    }
  }

  // Show cache stats in snackbar
  void showCacheStats() {
    if (kDebugMode) {
      final followService = FollowService();
      followService.printCacheStats();

      ScaffoldMessenger.of(this).showSnackBar(
        const SnackBar(
          content: Text('📊 Cache stats printed to console'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
