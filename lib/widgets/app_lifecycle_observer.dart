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
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Pastikan hanya berjalan jika user sudah login (ada instance websocket)
    if (AuthService.webSocketService == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        print("App is resumed (online)");
        // PERBAIKAN 1: Panggil method baru untuk notifikasi online
        AuthService.notifyBackendOnline();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        print("App is inactive/paused/detached (offline)");
        // PERBAIKAN 2: Panggil method baru untuk notifikasi offline
        AuthService.notifyBackendOffline();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
