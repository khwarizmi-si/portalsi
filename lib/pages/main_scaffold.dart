// lib/pages/main_scaffold.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:move_to_background/move_to_background.dart'; // <-- 1. TAMBAHKAN IMPORT INI
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'package:portal_si/pages/feed_page.dart';
import 'package:portal_si/pages/profile_page.dart';
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
  int _pageViewIndex = 0;

  final List<Widget> _swipeablePages = [
    const DashboardPage(),
    const FeedPage(),
    const StorePage(),
    const ProfilePage(),
  ];

  int _mapNavToPageViewIndex(int navIndex) {
    if (navIndex > 2) {
      return navIndex - 1;
    }
    return navIndex;
  }

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

  void _onItemTapped(int navIndex) {
    if (navIndex == 2) return;

    final navProvider = Provider.of<NavigationProvider>(context, listen: false);

    if (navProvider.overlayPage != null) {
      navProvider.hideOverlay();
    }
    _pageController.jumpToPage(
      _mapNavToPageViewIndex(navIndex),
    );
  }

  void _onPageChanged(int pageIndex) {
    setState(() {
      _pageViewIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. BUNGKUS WIDGET PALING ATAS DENGAN WILLPOPSCOPE ---
    return WillPopScope(
      onWillPop: () async {
        // Panggil fungsi ini untuk memindahkan aplikasi ke background
        MoveToBackground.moveTaskToBack();
        // Return false agar aplikasi tidak ditutup
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: Consumer<NavigationProvider>(
            builder: (context, navProvider, child) {
              return Stack(
                children: [
                Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
              if (navProvider.overlayPage == null)
              PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: navProvider.overlayPage == null
              ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
              children: _swipeablePages,
              )
              else
              navProvider.overlayPage!,
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
      ),
    );
  }
}