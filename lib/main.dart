
// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'pages/post_detail_page.dart';
// --- [TAMBAHAN] Import untuk Firebase ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:portal_si/services/fcm_service.dart';
import 'firebase_options.dart';
// --- Batas Import Firebase ---
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:portal_si/pages/video_intro_screen.dart';
import 'package:portal_si/providers/feed_provider.dart';
import 'package:portal_si/providers/scroll_provider.dart';
import 'package:portal_si/providers/shake_provider.dart';
import 'package:portal_si/providers/upload_provider.dart';
import 'package:portal_si/services/auth_service.dart';
import 'package:portal_si/services/message_service.dart';
import 'package:portal_si/utils/secure_storage.dart';
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
import 'package:intl/date_symbol_data_local.dart';

// ===================================================================
// --- [TAMBAHAN BARU] LOGIKA UNTUK BACKGROUND SERVICE & FCM ---
// ===================================================================

// / Fungsi ini harus berada di level atas (di luar class).
/// Ini adalah pintu masuk untuk kode yang akan dijalankan di latar belakang.
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('✅ Background Service Dimulai.');

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
    debugPrint("🔥 FATAL ERROR di Background Service: $e");
    debugPrint("Stack Trace: $s");
  }

  Timer.periodic(const Duration(minutes: 1), (timer) {
    debugPrint("⚙️ Background service heartbeat... ${DateTime.now()}");
  });
}

/// Fungsi helper untuk mengkonfigurasi dan mendaftarkan service.
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground_service_channel',
    'Notifikasi Penting',
    description: 'Dapatkan notifikasi penting dari Aplikasi.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      autoStartOnBoot: true,
      notificationChannelId: 'my_foreground_service_channel',
      initialNotificationTitle: 'Portal SI Service',
      initialNotificationContent: 'App is running in background to keep you updated.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
    ),
  );
  service.startService();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Clean path URLs on web (/username, /post/1) instead of /#/...
  if (kIsWeb) usePathUrlStrategy();

  // Inisialisasi Firebase di awal
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Daftarkan handler notifikasi background FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await initializeBackgroundService();
    // Inisialisasi FCM service
    await FcmService.instance.initialize();
  } else {
    debugPrint('ℹ️ Background Service & FCM tidak diinisialisasi pada platform ini (kIsWeb: $kIsWeb, platform: $defaultTargetPlatform).');
  }

  if (!kIsWeb) {
    await NotificationSystemService.instance.initialize();
  } else {
    debugPrint('ℹ️ NotificationSystemService tidak diinisialisasi pada platform web.');
  }

  await initializeDateFormatting('id_ID', null);

  // Inisialisasi AppLifecycleManager
  AppLifecycleManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ScrollProvider()),
        ChangeNotifierProvider(create: (_) => ShakeProvider()),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CacheManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        AppLifecycleManager.isAppInForeground = true;
        print('▶️ App resumed - now in foreground.');
        // Aplikasi kembali ke foreground, batalkan notifikasi tidak aktif
        NotificationSystemService.instance.cancelNotification(999);
        CacheManager.onAppResumed();
        break;
      case AppLifecycleState.paused:
        AppLifecycleManager.isAppInForeground = false;
        print('⏸️ App paused - now in background.');
        // Aplikasi masuk ke background, jadwalkan notifikasi tidak aktif
        NotificationSystemService.instance.scheduleInactiveUserNotification();
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
    print('⚠️ Memory pressure detected - clearing cache...');
    CacheManager.onMemoryPressure();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycleObserver(
      child: MaterialApp(
        title: 'Portal SI',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          fontFamily: 'AlanSans',
          visualDensity: VisualDensity.adaptivePlatformDensity,
          // Mendefinisikan tema khusus untuk ProgressIndicator
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Colors.orange, // Semua indikator akan berwarna oranye
          ),
        ),
        navigatorObservers: [
          CacheNavigationObserver(),
        ],
        // Desktop web: this is a phone-first UI, so present it as an intentional
        // centered "app" panel (rounded, elevated, on a soft backdrop) instead
        // of stretching it full-width. MediaQuery is overridden to the panel
        // width so layouts never overflow.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          if (!kIsWeb || mq.size.width <= 600) return child!;
          const panelWidth = 460.0;
          final panelHeight =
              mq.size.height.clamp(0.0, 940.0).toDouble();
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEDEFF3), Color(0xFFDFE3EA)],
              ),
            ),
            child: Center(
              child: Container(
                width: panelWidth,
                height: panelHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: MediaQuery(
                  data: mq.copyWith(size: Size(panelWidth, panelHeight)),
                  child: Material(color: Colors.white, child: child),
                ),
              ),
            ),
          );
        },
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => RegisterPage(),
          '/home': (context) => const MainScaffold(),
          '/feed': (context) => FeedPage(),
          '/story': (context) {
            final user = ModalRoute.of(context)!.settings.arguments as User;
            return InstagramStoryPage(user: user);
          },
          '/notif': (context) => const NotificationPage(),
          '/message': (context) => MessageListPage(),
          '/welcome': (context) => WelcomePage(),
          '/updater': (context) => UpdateScreenPage(onUpdateNow: () {}, onUpdateLater: () {}),
          '/other-profile': (context) {
            final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return OtherProfilePage(
              username: args['username'],
            );
          },
          if (kDebugMode) '/debug_cache': (context) => const CacheDebugPage(),
        },
        // Web deep links: /post/:id -> a post, /:username -> a profile.
        // Lets profile/post URLs be shared and survive a page refresh.
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          final uri = Uri.parse(name);
          final segments = uri.pathSegments;
          if (segments.length == 2 && segments.first == 'post') {
            final id = int.tryParse(segments[1]);
            if (id != null) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => PostDetailPage(postId: id),
              );
            }
          }
          if (segments.length == 1 && segments.first.isNotEmpty) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => OtherProfilePage(username: segments.first),
            );
          }
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

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
              '• Check console for cache statistics'
                  '• High hit rate (>70%) = good performance'
                  '• Clean cache regularly'
                  '• Monitor memory usage'
                  '• Remove this page in production',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

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
