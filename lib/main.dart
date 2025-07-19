import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/feed_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal SI',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: ProfilePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => HomePage(),
        '/feed': (context) => FeedPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
