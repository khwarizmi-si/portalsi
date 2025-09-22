import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:portal_si/components/bottom_navigation.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'package:portal_si/pages/feed_page.dart';
import 'package:portal_si/pages/portfolio_page.dart';
import 'package:portal_si/pages/profile_page.dart';
import 'package:portal_si/pages/store_page.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/scroll_provider.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late final PageController _pageController;
  int _pageViewIndex = 0;
  bool _isPortfolioButtonPressed = false;
  bool _isButtonVisible = true;
  Timer? _hideButtonTimer;

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
      Provider.of<NavigationProvider>(context, listen: false).navigateToTab =
          (int navIndex) {
        _onItemTapped(navIndex);
      };
      Provider.of<ScrollProvider>(context, listen: false)
          .addListener(_onScrollStateChanged);
    });
  }

  void _onScrollStateChanged() {
    final scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
    if (!_isButtonVisible) {
      setState(() {
        _isButtonVisible = true;
      });
    }
    _hideButtonTimer?.cancel();
    if (scrollProvider.isScrolled) {
      _hideButtonTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isButtonVisible = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    Provider.of<ScrollProvider>(context, listen: false)
        .removeListener(_onScrollStateChanged);
    _hideButtonTimer?.cancel();
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
    Provider.of<ScrollProvider>(context, listen: false).setScrolled(false);
    setState(() {
      _pageViewIndex = pageIndex;
    });
  }

  // --- 👇 FUNGSI INI TELAH DIPERBAIKI STRUKTURNYA 👇 ---
  Widget _buildPortfolioButton(double bottomInset) {
    // 1. Positioned sekarang menjadi widget terluar yang dikembalikan oleh fungsi ini.
    // Ini adalah struktur yang benar untuk sebuah Stack.
    return Positioned(
      bottom: 100.0 + bottomInset,
      right: 10.0,
      // 2. AnimatedOpacity, Consumer, dan sisa widget lainnya berada DI DALAM Positioned.
      child: AnimatedOpacity(
        opacity: _isButtonVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 100),
        child: Consumer<ScrollProvider>(
          builder: (context, scrollProvider, child) {
            final bool isTextVisible = !scrollProvider.isScrolled;

            // 3. Builder sekarang mengembalikan GestureDetector (tampilan tombolnya),
            // BUKAN Positioned lagi.
            return GestureDetector(
              onTapDown: (_) => setState(() => _isPortfolioButtonPressed = true),
              onTapUp: (_) {
                setState(() => _isPortfolioButtonPressed = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PortfolioPage()),
                );
              },
              onTapCancel: () => setState(() => _isPortfolioButtonPressed = false),
              child: AnimatedScale(
                scale: _isPortfolioButtonPressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeInOut,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.fastOutSlowIn,
                      padding: EdgeInsets.only(
                        left: 12.0,
                        right: isTextVisible ? 16.0 : 12.0,
                        top: 10.0,
                        bottom: 10.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withOpacity(0.3),
                            Colors.amber.withOpacity(0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                        // --- 👇 PERUBAHAN DI SINI 👇 ---
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1), // Warna bayangan
                            blurRadius: 20, // Seberapa menyebar bayangannya
                            spreadRadius: 2,  // Seberapa tebal bayangannya
                            offset: const Offset(0, 5), // Posisi bayangan (x, y)
                          ),
                        ],
                      ),

                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo_sekolah.png',
                            height: 32.0,
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(
                                  sizeFactor: animation,
                                  axis: Axis.horizontal,
                                  axisAlignment: -1.0,
                                  child: child,
                                ),
                              );
                            },
                            child: isTextVisible
                                ? Row(
                              key: const ValueKey('portfolio_text'),
                              children: [
                                const SizedBox(width: 8.0),
                                Text(
                                  'Portfolio Santri',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 15,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5.0,
                                        color:
                                        Colors.black.withOpacity(0.4),
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            )
                                : const SizedBox(
                                key: ValueKey('portfolio_empty')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
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
                          ? const AlwaysScrollableScrollPhysics()
                          : const NeverScrollableScrollPhysics(),
                      children: _swipeablePages,
                    )
                  else
                    navProvider.overlayPage!,
                  _buildPortfolioButton(bottomInset),
                  Positioned(
                    bottom: bottomInset,
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