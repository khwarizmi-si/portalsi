import 'package:flutter/material.dart';
import 'package:portal_si/pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/feed_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/post_detail_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginPage(),
  '/register': (context) => RegisterPage(),
  '/feed': (context) => FeedPage(),
  '/home': (context) => HomePage(),
  '/welcome': (context) => WelcomePage(),
  // PostDetailPage biasanya butuh parameter, jadi jangan didaftarkan langsung kecuali pakai onGenerateRoute
};
