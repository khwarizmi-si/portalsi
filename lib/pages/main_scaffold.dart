import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'package:portal_si/pages/feed_page.dart';
import 'package:portal_si/pages/profile_page.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/pages/settings_page.dart';
import 'package:portal_si/pages/store_page.dart';
import 'package:provider/provider.dart';

import '../providers/navigation_provider.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final PageController _pageController;
  int _pageViewIndex = 0; // State sekarang melacak indeks PageView, bukan Navigasi

  // Daftar halaman yang BISA digeser (tanpa placeholder FAB)
  final List<Widget> _swipeablePages = [
    const DashboardPage(),
    const FeedPage(),
    const StorePage(),
    const ProfilePage(),
  ];

  // --- 👇 LOGIKA BARU UNTUK MENGATASI MASALAH INDEKS ---

  // Mengubah indeks BottomNav (0,1,3,4) menjadi indeks PageView (0,1,2,3)
  int _mapNavToPageViewIndex(int navIndex) {
    if (navIndex > 2) {
      return navIndex - 1;
    }
    return navIndex;
  }

  // Mengubah indeks PageView (0,1,2,3) menjadi indeks BottomNav (0,1,3,4)
  int _mapPageViewToNavIndex(int pageIndex) {
    if (pageIndex >= 2) {
      return pageIndex + 1;
    }
    return pageIndex;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageViewIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NavigationProvider>(context, listen: false).navigateToTab = (int navIndex) {
        _onItemTapped(navIndex);
      };
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi ini dipanggil saat ikon navigasi DIKLIK
  void _onItemTapped(int navIndex) {
    // Abaikan klik pada FAB (indeks 2) untuk navigasi halaman
    if (navIndex == 2) return;

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    // 1. Periksa apakah ada overlay yang sedang aktif
    if (navProvider.overlayPage != null) {
      // Jika ada, sembunyikan dulu
      navProvider.hideOverlay();
    }
    // 2. Lanjutkan untuk berpindah ke halaman yang dituju
    _pageController.jumpToPage(
      _mapNavToPageViewIndex(navIndex),
    );
    // --- Batas Perubahan ---
  }

  // Fungsi ini dipanggil saat halaman di-GESER
  void _onPageChanged(int pageIndex) {
    setState(() {
      _pageViewIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold sekarang tidak lagi memiliki properti bottomNavigationBar
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        // --- Batas Penambahan ---
        child: Scaffold(
          body: Consumer<NavigationProvider>(
            builder: (context, navProvider, child) {
              return Stack(
                children: [
                  // Latar Belakang Global (tetap ada)
                  Image.asset(
                    'assets/images/background.png',
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),

                  // Tampilkan PageView ATAU Halaman Overlay secara kondisional
                  if (navProvider.overlayPage == null)
                  // Jika tidak ada overlay, tampilkan PageView
                    PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: navProvider.overlayPage == null
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      children: _swipeablePages,
                    )
                  else
                  // Jika ada overlay, tampilkan halaman tersebut
                    navProvider.overlayPage!,

                  // Navigasi Bawah (selalu tampil di lapisan paling atas)
                  Positioned(
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: CustomBottomNavigation(
                      selectedIndex: _mapPageViewToNavIndex(_pageViewIndex),
                      onTap: _onItemTapped,
                    ),
                  ),
                ],
              );
            },
          ),
      backgroundColor: Colors.white,
      ),
    );
  }
}