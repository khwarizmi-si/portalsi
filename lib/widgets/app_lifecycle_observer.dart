// lib/widgets/app_lifecycle_observer.dart

import 'package:flutter/material.dart';
import 'package:portal_si/services/auth_service.dart'; // Sesuaikan path import

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Daftarkan observer
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Hapus observer untuk mencegah memory leak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        print("App is resumed (online)");
        AuthService.updateUserActivity();
        break;

    // [PERBAIKAN] Gabungkan semua case saat aplikasi tidak aktif
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print("App is inactive/paused/detached (offline)");
        AuthService.disconnectWebSocket();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Widget ini hanya bertugas sebagai pengamat,
    // dan menampilkan child yang diberikan padanya.
    return widget.child;
  }
}