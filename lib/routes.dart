import 'package:flutter/material.dart';
import 'package:portal_si/pages/main_scaffold.dart';
import 'package:portal_si/pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/feed_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/post_detail_page.dart';
import 'pages/update_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginPage(),
  '/register': (context) => RegisterPage(),
  '/feed': (context) => FeedPage(),
  '/home': (context) => MainScaffold(),
  '/welcome': (context) => WelcomePage(),
  '/updater': (context) => UpdateScreenPage(onUpdateNow: () {  }, onUpdateLater: () {  },),
  // PostDetailPage biasanya butuh parameter, jadi jangan didaftarkan langsung kecuali pakai onGenerateRoute
};
