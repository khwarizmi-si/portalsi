import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portal SI',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
