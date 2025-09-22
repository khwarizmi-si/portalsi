// lib/main.dart

import 'dart:async'; // <-- [TAMBAHAN]
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// --- [TAMBAHAN] Import untuk Background Service & Service lainnya ---
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // <-- ADDED IMPORT
import 'package:portal_si/providers/scroll_provider.dart';

import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/services/message_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
// --- Batas Import Tambahan ---
import 'package:portal_si/pages/main_scaffold.dart';
import 'package:portal_si/pages/splash_screen.dart';
import 'package:portal_si/pages/update_screen.dart';
import 'package:portal_si/pages/welcome_page.dart';
import 'package:portal_si/providers/navigation_provider.dart';
import 'package:portal_si/services/notification_system_service.dart';
import 'package:portal_si/utils/app_lifecycle_manager.dart';
import 'package:portal_si/widgets/app_lifecycle_observer.dart';
import 'package:provider/provider.dart';
import 'package:portal_si/controllers/home_controller.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/utils/user_provider.dart';
import 'models/user_model.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/feed_page.dart';
import 'pages/other_profile_page.dart';
import 'pages/message_list_page.dart';
import 'pages/story_page.dart';
import 'managers/cache_manager.dart';
import 'services/follow_service.dart';


// ===================================================================
// --- [TAMBAHAN BARU] LOGIKA UNTUK BACKGROUND SERVICE ---
// ===================================================================

/// Fungsi ini harus berada di level atas (di luar class).
/// Ini adalah pintu masuk untuk kode yang akan dijalankan di latar belakang.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ Background Service Dimulai.');

  // --- [WAJIB] BUNGKUS SEMUA DENGAN TRY-CATCH ---
  try {
    final token = await SecureStorage.getToken();
    if (token != null) {
      await AuthService.initializeWebSocket(token);

      final chatService = ChatService();
      final channels = await chatService.getActiveConversationChannels();
      if (channels.isNotEmpty && AuthService.webSocketService != null) {
        for (final channelName in channels) {
          AuthService.webSocketService!.subscribeToChannel(channelName);
        }
        debugPrint('✅ Background Service: Berhasil subscribe ke ${channels.length} channel.');
      } else {
        debugPrint('ℹ️ Background Service: Tidak ada channel percakapan aktif ditemukan.');
      }
    } else {
      debugPrint('❌ Background Service: Token tidak ditemukan, tidak bisa memulai WebSocket.');
    }
  } catch (e, s) {
    // Jika terjadi error, kita akan mencetaknya di log, BUKAN membuat aplikasi crash
    debugPrint("🔥 FATAL ERROR di Background Service: $e");
    debugPrint("Stack Trace: $s");
  }
  // --- BATAS TRY-CATCH ---


  Timer.periodic(const Duration(minutes: 1), (timer) {
    debugPrint("⚙️ Background service heartbeat... ${DateTime.now()}");
  });
}

/// Fungsi helper untuk mengkonfigurasi dan mendaftarkan service.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // --- [TAMBAHAN] Buat Channel Notifikasi ---
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground_service_channel', // id
    'Notifikasi Penting', // title
    description: 'Dapatkan notifikasi penting dari Aplikasi.', // description
    importance: Importance.low, // Sesuaikan importance
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  // --- Batas Tambahan Channel Notifikasi ---

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true, // Wajib oleh Android untuk menampilkan notifikasi persisten
      autoStart: true,
      autoStartOnBoot: true, // Kunci utama agar bisa berjalan saat ponsel dinyalakan
      notificationChannelId: 'my_foreground_service_channel', 
      initialNotificationTitle: 'Portal SI Service',
      initialNotificationContent: 'App is running in background to keep you updated.',
      foregroundServiceNotificationId: 888, // --- [TAMBAHAN KRUSIAL DARI AI] (1 untuk FOREGROUND_SERVICE_TYPE_DATA_SYNC) ---
      // Optional: Anda bisa menambahkan ikon notifikasi di sini jika ada
      // notificationIcon: 'mipmap/ic_launcher', // Pastikan ikon ini ada di android/app/src/main/res/mipmap
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      // Catatan: autoStartOnBoot tidak didukung di iOS
    ),
  );
  // Mulai service-nya
  service.startService();
}

// ===================================================================
// --- BATAS AKHIR LOGIKA BACKGROUND SERVICE ---
// ===================================================================


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- [TAMBAHAN BARU] Panggil inisialisasi service di sini ---
  await initializeBackgroundService();

  await NotificationSystemService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ScrollProvider()),
      ],
      child: const MyApp(),
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

          '/story': (context) {
            // Ambil data 'user' yang dikirim melalui argumen navigasi
            final user = ModalRoute.of(context)!.settings.arguments as User;

            // Kirim data 'user' tersebut ke InstagramStoryPage
            return InstagramStoryPage(user: user);
          },
          '/notif': (context) => const NotificationPage(),
          '/message': (context) => MessageListPage(),
          '/welcome': (context) => WelcomePage(),
          '/updater': (context) => UpdateScreenPage(onUpdateNow: () {  }, onUpdateLater: () {  },),
          '/other-profile': (context) {
            final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return OtherProfilePage(
              username: args['username'],
            );
          },
          if (kDebugMode) '/debug_cache': (context) => const CacheDebugPage(),
        },
        // home: DownloadAppPromptPage(playStoreUrl: 'https://ds.cs', onContinueToWeb: () {}),
        debugShowCheckedModeBanner: false,
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
