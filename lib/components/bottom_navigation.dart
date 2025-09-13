import 'package:flutter/material.dart';
import 'package:portal_si/pages/feed_page.dart';
import 'package:portal_si/pages/dashboard_page.dart';
import 'package:portal_si/pages/profile_page.dart';
import 'package:portal_si/pages/notif_page.dart';
import 'package:portal_si/pages/create_post_page.dart';
import 'package:flutter/services.dart';
import 'package:portal_si/services/notification_service.dart';
import 'package:provider/provider.dart';

import '../utils/user_provider.dart';

import '../pages/create_announcement_page.dart'; // Import service API Anda

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
  bool _isFabPressed = false;
  bool isAdmin = false;

  List<AnimationController> _iconAnimationControllers = [];
  List<Animation<double>> _iconScaleAnimations = [];
  List<Animation<double>> _iconBounceAnimations = [];
  // Variabel untuk menampung jumlah notifikasi yang belum dibaca
  int _unreadNotificationCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 💡 Asumsi Anda menggunakan Provider atau state management serupa.
    // Jika tidak, sesuaikan cara mendapatkan instance UserProvider
    // Anda dengan metode yang Anda gunakan.
    final userProvider = Provider.of<UserProvider>(context);

    // Perbarui nilai isAdmin dengan data dari provider
    setState(() {
      isAdmin = userProvider.currentUser?.isVerified == true;
    });
  }

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
        // Durasi sedikit lebih lama untuk gerakan yang lebih halus
        duration: const Duration(milliseconds: 250), // Diubah dari 200
        vsync: this,
      );
      _iconAnimationControllers.add(controller);

      // Animasi skala yang lebih lembut
      _iconScaleAnimations.add(
        Tween<double>(begin: 1.0, end: 1.15).animate( // Diubah dari 1.2
          // Gunakan kurva yang lebih halus, tidak memantul
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic), // Diubah dari elasticOut
        ),
      );
      // Animasi pantulan (bounce) yang lebih rendah
      _iconBounceAnimations.add(
        Tween<double>(begin: 0.0, end: -5.0).animate( // Diubah dari -8.0
          // Gunakan kurva yang sama untuk konsistensi
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic), // Diubah dari elasticOut
        ),
      );
    }

    _slideAnimationController.forward();
    _loadNotificationCount();
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

  // Fungsi untuk memuat jumlah notifikasi yang belum dibaca
  Future<void> _loadNotificationCount() async {
    try {
      final notifications = await NotificationService()
          .getNotifications(); // Ganti dengan service Anda
      final unreadCount = notifications
          .where((notif) => notif['is_read'] == false || notif['is_read'] == 0)
          .length;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  // Fungsi untuk refresh notification count (bisa dipanggil dari luar)
  void refreshNotificationCount() {
    _loadNotificationCount();
  }

  void _onItemTapped(int index) {
    // Hapus semua logika Navigator.push dari sini

    // Animate the tapped icon
    _iconAnimationControllers[index].forward().then((_) {
      _iconAnimationControllers[index].reverse();
    });

    // Slide animation
    _slideAnimationController.reset();
    _slideAnimationController.forward();

    // Panggil callback onTap yang diberikan oleh parent (MainScaffold)
    widget.onTap(index);
  }

  void _showCreateOptions() {
    // Memberikan efek getaran realistis
    HapticFeedback.mediumImpact();

    // Menjalankan animasi rotasi dan skala yang sudah ada
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });

    // Menampilkan modal bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Buat Baru",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.article_outlined, color: Colors.deepOrange),
                title: Text("Buat Postingan"),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context); // Tutup bottom sheet
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreatePostPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.campaign_outlined, color: Colors.deepOrange),
                title: Text("Buat Pengumuman"),
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context); // Tutup bottom sheet
                  // Arahkan ke halaman baru
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateAnnouncementPage()),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          // --- PERUBAHAN DI SINI ---
          color: Colors.white, // Diubah dari Colors.white.withOpacity(0.95)
          // --- Batas Perubahan ---
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(0), bottomRight: Radius.circular(0)), // Dibuat sama semua sisinya untuk estetika
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Sedikit pudar agar lebih soft
              blurRadius: 12,
              offset: const Offset(0, 2),
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
                  Expanded(child: _buildNavItem(Icons.home, 0)),
                  Expanded(child: _buildNavItem(Icons.search, 1)),
                  const SizedBox(width: 53), // Spasi untuk FAB tetap sama
                  Expanded(child: _buildNavItem(Icons.shopping_cart, 3)), // Ganti ikon & indeks jika perlu
                  Expanded(child: _buildNavItem(Icons.person_outline, 4)),
                ],
              ),
            ),

            // Floating Action Button dengan animasi
            Positioned(
              top: -24,
              // Widget yang memberikan efek visual "turun" saat ditekan
              child: Transform.translate(
                offset: Offset(0, _isFabPressed ? 2.0 : 0.0), // <-- EFEK 3D
                child: GestureDetector(
                  // Mendeteksi saat jari mulai menekan tombol
                  onTapDown: (_) => setState(() => _isFabPressed = true),
                  // Mendeteksi saat jari diangkat dari tombol
                  onTapUp: (_) {
                    setState(() => _isFabPressed = false);
                    if(isAdmin) {
                      _showCreateOptions();
                      // Panggil fungsi bottom sheet
                    } else {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context); // Tutup bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatePostPage()),
                      );
                    }
                  },
                  // Mendeteksi jika sentuhan dibatalkan
                  onTapCancel: () => setState(() => _isFabPressed = false),
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
                              // Bayangan (shadow) berubah saat ditekan untuk efek 3D
                              boxShadow: _isFabPressed
                                  ? [ // Efek saat ditekan
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ]
                                  : [ // Efek normal
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.add, // Icon tetap add
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
            ),
          ],
        ),
      ),
    );
  }

  // Widget khusus untuk item navigasi notifikasi dengan badge
  Widget _buildNotificationNavItem() {
    final isSelected = widget.selectedIndex == 3;

    return GestureDetector(
      onTap: () => _onItemTapped(3),
      child: AnimatedBuilder(
        animation: _iconAnimationControllers[3],
        builder: (context, child) {
          return Transform.scale(
            scale: _iconScaleAnimations[3].value,
            child: Transform.translate(
              offset: Offset(0, _iconBounceAnimations[3].value),
              child: Container(
                padding: EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Container icon notifikasi
                    AnimatedContainer(
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
                        Icons.favorite_border,
                        color: isSelected ? Colors.orange : Colors.grey[500],
                        size: 24,
                      ),
                    ),

                    // Badge notifikasi
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _unreadNotificationCount > 9 ? 6 : 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            _unreadNotificationCount > 99
                                ? '99+'
                                : _unreadNotificationCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _unreadNotificationCount > 9 ? 10 : 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => {
        HapticFeedback.mediumImpact(),
        _onItemTapped(index),
      },
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
