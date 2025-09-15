// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:portal_si/pages/main_scaffold.dart';
import 'package:portal_si/pages/splash_screen.dart'; // [DIUBAH] Import SplashScreen
import 'package:portal_si/pages/welcome_page.dart';
import 'package:portal_si/providers/navigation_provider.dart';
import 'package:portal_si/services/notification_system_service.dart';
import 'package:portal_si/utils/app_lifecycle_manager.dart';
import 'package:portal_si/widgets/app_lifecycle_observer.dart';
import 'package:provider/provider.dart';
import 'package:portal_si/controllers/home_controller.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/utils/user_provider.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/feed_page.dart';
import 'pages/other_profile_page.dart';
import 'pages/message_list_page.dart';
import 'pages/story_page.dart';
import 'managers/cache_manager.dart';
import 'services/follow_service.dart';

// [DIUBAH] Fungsi main menjadi lebih sederhana
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationSystemService.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(), // MyApp tidak lagi butuh parameter
    ),
  );
}

// [DIUBAH] MyApp menjadi lebih sederhana
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // [DIHAPUS] Logika inisialisasi dipindah ke SplashScreen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CacheManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ... (kode ini tetap sama)
    switch (state) {
      case AppLifecycleState.resumed:
        AppLifecycleManager.isAppInForeground = true;
        print('▶️ App resumed - now in foreground.');
        CacheManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
        AppLifecycleManager.isAppInForeground = false;
        print('⏸️ App paused - now in background.');
        CacheManager.onAppPaused();
        break;
      case AppLifecycleState.detached:
        print('🛑 App detached - cleaning up...');
        CacheManager.dispose();
        break;
      default:
        break;
    }
  }

  @override
  void didHaveMemoryPressure() {
    // ... (kode ini tetap sama)
    print('⚠️ Memory pressure detected - clearing cache...');
    CacheManager.onMemoryPressure();
  }

  // [DIHAPUS] Fungsi _initializeAppData sudah dipindah ke SplashScreen

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MaterialApp(
        title: 'Portal SI',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        navigatorObservers: [
          CacheNavigationObserver(),
        ],
        // [DIUBAH] Halaman awal aplikasi sekarang SELALU SplashScreen
        home: const SplashScreen(),
        // [DIUBAH] initialRoute dihapus dan diganti 'home'
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => RegisterPage(),
          '/home': (context) => const MainScaffold(),
          '/feed': (context) => FeedPage(),
          '/profile': (context) => const ProfilePage(),
          '/story': (context) => InstagramStoryPage(),
          '/notif': (context) => const NotificationPage(),
          '/message': (context) => MessageListPage(),
          '/welcome': (context) => WelcomePage(),
          '/other-profile': (context) {
            final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return OtherProfilePage(
              username: args['username'],
            );
          },
          if (kDebugMode) '/debug_cache': (context) => const CacheDebugPage(),
        },
        debugShowCheckedModeBanner: kDebugMode,
      ),
    );
  }
}

// 🚀 Navigation observer for intelligent cache warming
class CacheNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _warmCacheForRoute(route.settings.name);
  }

  void _warmCacheForRoute(String? routeName) {
    switch (routeName) {
      case '/feed':
        if (kDebugMode) print('🔥 Warming cache for feed...');
        break;
      case '/profile':
        if (kDebugMode) print('🔥 Warming cache for profile...');
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
  void showCacheDebug() {
    if (kDebugMode) {
      Navigator.pushNamed(this, '/debug_cache');
    }
  }

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