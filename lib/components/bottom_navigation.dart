import 'package:flutter/material.dart';
import 'package:portal_si/pages/feed_page.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'package:portal_si/pages/profile_page.dart';
import 'package:portal_si/pages/notif_page.dart';

class CustomBottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  late Animation<Offset> _slideAnimation;

  List<AnimationController> _iconAnimationControllers = [];
  List<Animation<double>> _iconScaleAnimations = [];
  List<Animation<double>> _iconBounceAnimations = [];

  @override
  void initState() {
    super.initState();

    // FAB Animation Controller
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide Animation Controller
    _slideAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _fabRotationAnimation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset(0.0, 0.0), end: Offset(0.0, 0.0)).animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.elasticOut,
          ),
        );

    // Initialize icon animations
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      );
      _iconAnimationControllers.add(controller);

      _iconScaleAnimations.add(
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
      );

      _iconBounceAnimations.add(
        Tween<double>(begin: 0.0, end: -8.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
      );
    }

    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _slideAnimationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Animate the tapped icon
    _iconAnimationControllers[index].forward().then((_) {
      _iconAnimationControllers[index].reverse();
    });

    // Slide animation
    _slideAnimationController.reset();
    _slideAnimationController.forward();

    if (index == 0) {
      // Kembali ke HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else if (index == 1) {
      // Arahkan ke FeedPage
      Navigator.push(context, MaterialPageRoute(builder: (_) => FeedPage()));
    } else if (index == 3) {
      // Arahkan ke notif
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotificationPage()),
      );
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
    } else {
      widget.onTap(index); // tetap jalankan untuk icon lain
    }
  }

  void _onFabTapped() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
    widget.onTap(2);
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Bottom Navigation Items
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home, 0),
                  _buildNavItem(Icons.search, 1),
                  SizedBox(width: 56), // Space for FAB
                  _buildNavItem(Icons.favorite_border, 3),
                  _buildNavItem(Icons.person_outline, 4),
                ],
              ),
            ),

            // Floating Action Button dengan animasi
            Positioned(
              top: -24,
              child: GestureDetector(
                onTap: _onFabTapped,
                child: AnimatedBuilder(
                  animation: _fabAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _fabScaleAnimation.value,
                      child: Transform.rotate(
                        angle: _fabRotationAnimation.value * 2 * 3.14159,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.orangeAccent, Colors.deepOrange],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.selectedIndex == 2 ? Icons.close : Icons.add,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedBuilder(
        animation: _iconAnimationControllers[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _iconScaleAnimations[index].value,
            child: Transform.translate(
              offset: Offset(0, _iconBounceAnimations[index].value),
              child: Container(
                padding: EdgeInsets.all(12),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 8 : 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.orange : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
