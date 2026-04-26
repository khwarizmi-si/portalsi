// lib/main_scaffold.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../app_state.dart';

final mainScaffoldKey = GlobalKey<_MainScaffoldState>();

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  late final PageController _pageController;
  int _pageViewIndex = 0;
  bool _isPortfolioButtonPressed = false;
  bool _isButtonVisible = true;
  Timer? _hideButtonTimer;

  ScrollProvider? _scrollProvider;

  late AnimationController _overlayAnimationController;
  late Animation<Offset> _pageViewSlideAnimation;
  late Animation<Offset> _overlaySlideAnimation;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // State untuk konfirmasi keluar
  DateTime? _lastPressedAt;

  final List<Widget> _swipeablePages = [
    const DashboardPage(),
    const FeedPage(),
    const StorePage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageViewIndex);

    // Faster on web for snappier feel, native keeps the 350ms
    final overlayDuration = kIsWeb
        ? const Duration(milliseconds: 260)
        : const Duration(milliseconds: 320);

    _overlayAnimationController = AnimationController(
      vsync: this,
      duration: overlayDuration,
    );

    // On web: fade+scale overlay (no slide — avoids jank from large layout shifts)
    // On native: slide in from right
    if (kIsWeb) {
      _pageViewSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero, // no slide on web
      ).animate(_overlayAnimationController);

      _overlaySlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset.zero, // handled by FadeTransition in build()
      ).animate(_overlayAnimationController);
    } else {
      _pageViewSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.0, 0.0),
      ).animate(CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeOutCubic,
      ));

      _overlaySlideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeOutCubic,
      ));
    }

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));


    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);

      navProvider.navigateToTab = (int navIndex) {
        _onItemTapped(navIndex);
      };

      navProvider.registerAnimationTriggers(
        showAnimation: () => _overlayAnimationController.forward(),
        hideAnimation: () => _overlayAnimationController.reverse(),
      );

      _overlayAnimationController.addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          navProvider.clearOverlayPage();
        }
      });

      _scrollProvider = Provider.of<ScrollProvider>(context, listen: false);
      _scrollProvider?.addListener(_onScrollStateChanged);
    });
  }

  void triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  Widget _buildPageView(NavigationProvider navProvider) {
    return PageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      // Disable swipe while overlay is showing to prevent accidental tab changes
      physics: navProvider.overlayPage != null
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      children: _swipeablePages,
    );
  }

  int _mapNavToPageViewIndex(int navIndex) {
    if (navIndex >= 3) {
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
    _overlayAnimationController.dispose();
    _shakeController.dispose();
    _scrollProvider?.removeListener(_onScrollStateChanged);
    _hideButtonTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Maps nav index → URL path for web address bar
  static const _tabPaths = {
    0: '/home',
    1: '/explore',
    3: '/store',
    4: '/profile',
  };

  void _onItemTapped(int navIndex) {
    FocusManager.instance.primaryFocus?.unfocus();

    if (navIndex == 2) return;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    if (navProvider.overlayPage != null) {
      navProvider.forceHideOverlay();
    }
    final pageIndex = _mapNavToPageViewIndex(navIndex);
    _pageController.jumpToPage(pageIndex);

    // Update browser URL bar on web
    if (kIsWeb) {
      final path = _tabPaths[navIndex] ?? '/home';
      SystemNavigator.routeInformationUpdated(location: path);
    }
  }

  void _onPageChanged(int pageIndex) {
    Provider.of<ScrollProvider>(context, listen: false).setScrolled(false);
    setState(() {
      _pageViewIndex = pageIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive: batasi lebar maksimum untuk layar besar (web/tablet)
    final bool isWideScreen = screenWidth > 600;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: PopScope(
        canPop: false, // Never allow MainScaffold itself to be popped — prevents blank screen
        onPopInvoked: (bool didPop) async {
          if (didPop) return;

          if (navProvider.overlayPage != null) {
            navProvider.forceHideOverlay();
            return;
          }

          if (_pageViewIndex != 0) {
            _onItemTapped(0);
            return;
          }

          // On web: the browser back button is handled by the browser itself
          // (go to previous history entry). On native, show exit confirmation.
          if (kIsWeb) return;

          final now = DateTime.now();
          final isExitConfirmed = _lastPressedAt != null &&
              now.difference(_lastPressedAt!) < const Duration(seconds: 2);

          if (isExitConfirmed) {
            MoveToBackground.moveTaskToBack();
          } else {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Tekan kembali sekali lagi untuk keluar.'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.only(
                  bottom: 80 + bottomInset,
                  left: 20,
                  right: 20,
                ),
              ),
            );
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            systemNavigationBarColor: Color(0xFFFFFFFF),
            systemNavigationBarIconBrightness: Brightness.dark,
            statusBarColor: Color(0xFFFFFFFF),
            statusBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            body: Consumer<NavigationProvider>(
              builder: (context, navProvider, child) {
                Widget mainContent = Stack(
                  children: [
                    // Background — solid white avoids any flash between repaints
                    Container(color: Colors.white),
                    // Main tab pages
                    if (!kIsWeb)
                      SlideTransition(
                        position: _pageViewSlideAnimation,
                        child: _buildPageView(navProvider),
                      )
                    else
                      _buildPageView(navProvider),
                    // Overlay page (native: slide, web: fade+scale)
                    if (navProvider.overlayPage != null)
                      kIsWeb
                          ? FadeTransition(
                              opacity: CurvedAnimation(
                                parent: _overlayAnimationController,
                                curve: Curves.easeOut,
                              ),
                              child: navProvider.overlayPage!,
                            )
                          : SlideTransition(
                              position: _overlaySlideAnimation,
                              child: navProvider.overlayPage!,
                            ),
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

                // Untuk layar lebar, batasi lebar konten
                if (isWideScreen) {
                  mainContent = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: mainContent,
                    ),
                  );
                }

                return mainContent;
              },
            ),
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}