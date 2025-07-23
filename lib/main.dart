import 'package:flutter/material.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/feed_page.dart';
import 'pages/other_profile_page.dart';
import 'pages/message_list_page.dart';
import 'pages/story_page.dart';
import 'utils/secure_storage.dart'; // pastikan path-nya benar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasToken = await SecureStorage.hasToken();

  // runApp(MyApp(startPage: hasToken ? '/notif' : '/notif'));
  runApp(MyApp(startPage: hasToken ? '/dashboard' : '/login'));
}

class MyApp extends StatelessWidget {
  final String startPage;

  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal SI',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      initialRoute: startPage,
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => HomePage(),
        '/feed': (context) => FeedPage(),
        '/profile': (context) => const ProfilePage(),
        '/story': (context) => InstagramStoryPage(),
        '/notif': (context) => const NotificationPage(),
        '/message': (context) => MessageListPage(),
        // Jika ingin lihat profil orang lain secara manual:
      },
    );
  }
}
