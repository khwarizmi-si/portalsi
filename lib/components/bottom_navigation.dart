// lib/components/bottom_navigation.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- IMPORT BARU
import '../models/user_model.dart';
import '../pages/create_announcement_page.dart';
import '../pages/create_clips_page.dart';
import '../pages/create_post_page.dart';
import '../pages/create_story_page.dart';
import '../providers/scroll_provider.dart';
import '../utils/user_provider.dart';

class _FabMenuPopup extends StatelessWidget {
  final UserProvider userProvider;

  const _FabMenuPopup({required this.userProvider});

  void _showClipsPermissionDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool dontShowAgain = prefs.getBool('dont_show_clips_permission') ?? false;

    // Fungsi navigasi agar tidak duplikat kode
    // void navigateToCreatePost() {
    //   Navigator.of(context).pop(); // Tutup menu asal
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage(isClips: true)));
    // }

    void navigateToCreateClips() {
      Navigator.of(context).pop(); // Tutup menu asal
      Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateClipsPage()));
    }

    if (dontShowAgain) {
      navigateToCreateClips();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF0E9), Colors.white],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF03B293), Color(0xFF116C63)],
                    ),
                  ),
                  child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kreasi Clips',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memperkenalkan postingan Clips. Postingan video yang Anda Unggah akan menjadi postingan Clips. Anda dapat mengakses Clips Anda dan seluruh pengguna lainnya di halaman feed atau beranda Portal SI.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // PERUBAHAN: Mengganti layout tombol menjadi Column
                Column(
                  // crossAxisAlignment.stretch membuat widget di dalamnya (seperti ElevatedButton)
                  // meregang selebar mungkin secara horizontal.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tombol utama untuk melanjutkan
                    ElevatedButton(
                      // --- 👇 PERUBAHAN: Panggil fungsi yang benar 👇 ---
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        navigateToCreateClips();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF03B293), Color(0xFF116C63)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: const Text('Lanjutkan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8), // Jarak antar tombol

                    // Tombol teks untuk opsi "jangan tampilkan lagi"
                    TextButton(
                      onPressed: () async {
                        // Simpan preferensi terlebih dahulu
                        await prefs.setBool('dont_show_clips_permission', true);
                        // Baru lakukan navigasi
                        Navigator.of(dialogContext).pop();
                        navigateToCreateClips();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600, // Warna teks
                      ),
                      child: const Text('Jangan tampilkan lagi'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = userProvider.currentUser;
    final currentUserRole = currentUser?.role;

    List<Widget> menuItems = [
      _buildMenuItem(
        context,
        icon: Icons.grid_on,
        text: 'Buat Postingan',
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostPage()));
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.video_collection_outlined,
        text: 'Upload Clips',
        onTap: () {
          _showClipsPermissionDialog(context);
        },
      ),
      _buildMenuItem(
        context,
        icon: Icons.add_circle_outline,
        text: 'Upload Cerita Anda',
        onTap: () {
          Navigator.pop(context);
          if (currentUser != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CreateStoryPage(
              currentUser: currentUser,
              heroTag: 'story_create_avatar_${currentUser.id}',
            )));
          }
        },
      ),
    ];

    if (currentUserRole == 'dev' || currentUserRole == 'teacher') {
      menuItems.add(const Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey));
      menuItems.add(
        _buildMenuItem(
          context,
          icon: Icons.campaign_outlined,
          text: 'Buat Pengumuman',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAnnouncementPage()));
          },
        ),
      );
    }

    return Material(
      color: Colors.white.withOpacity(0.85),
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: menuItems,
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: text == 'Buat Pengumuman'
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade800),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _FabPopupRoute<T> extends PopupRoute<T> {
  final WidgetBuilder builder;
  final GlobalKey fabKey;

  _FabPopupRoute({required this.builder, required this.fabKey});

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.5);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Close';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final RenderBox fabRenderBox = fabKey.currentContext!.findRenderObject() as RenderBox;
    final fabCenter = fabRenderBox.localToGlobal(fabRenderBox.size.center(Offset.zero));

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - fabCenter.dy + 20,
          left: 24,
          right: 24,
        ),
        child: builder(context),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final RenderBox fabRenderBox = fabKey.currentContext!.findRenderObject() as RenderBox;
    final fabCenter = fabRenderBox.localToGlobal(fabRenderBox.size.center(Offset.zero));

    final screenHeight = MediaQuery.of(context).size.height;
    final alignmentY = (fabCenter.dy / screenHeight) * 2 - 1;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5 * animation.value, sigmaY: 5 * animation.value),
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          alignment: Alignment(0.0, alignmentY),
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic),
          child: child,
        ),
      ),
    );
  }
}

class CustomBottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool isDarkMode;

  const CustomBottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onTap,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation> with TickerProviderStateMixin {
  final GlobalKey _fabKey = GlobalKey();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabRotationAnimation;
  late List<AnimationController> _iconAnimationControllers;
  late List<Animation<double>> _iconScaleAnimations;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _iconAnimationControllers = List.generate(
      5,
          (index) => AnimationController(vsync: this, duration: const Duration(milliseconds: 100)),
    );

    _iconScaleAnimations = _iconAnimationControllers
        .map((controller) => Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)))
        .toList();

    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _fabRotationAnimation = Tween<double>(begin: 0, end: 0.125).animate(
        CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant CustomBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _playAnimationForIndex(widget.selectedIndex);
    }
  }

  void _playAnimationForIndex(int index) {
    if (index >= 0 && index < 5 && index != 2) {
      _iconAnimationControllers[index].forward(from: 0.0).then((_) {
        if (mounted) {
          _iconAnimationControllers[index].reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showCreateOptions(BuildContext context) {
    _fabAnimationController.forward();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Navigator.of(context).push(_FabPopupRoute(
      fabKey: _fabKey,
      builder: (context) {
        return _FabMenuPopup(userProvider: userProvider);
      },
    )).then((_) {
      _fabAnimationController.reverse();
    });
  }

  Future<bool> _onWillPop() async {
    if (widget.selectedIndex != 0) {
      return true;
    }

    final now = DateTime.now();
    final isExitConfirmed = _lastPressedAt != null &&
        now.difference(_lastPressedAt!) < const Duration(seconds: 2);

    if (isExitConfirmed) {
      return true;
    } else {
      _lastPressedAt = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekan kembali sekali lagi untuk keluar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color iconColor = widget.isDarkMode ? Colors.white70 : Colors.grey[500]!;
    final Color fabColor = widget.isDarkMode ? Colors.grey.shade800 : Colors.white;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIconItem(0, Icons.home_filled, isSelected: widget.selectedIndex == 0, iconColor: iconColor),
          _buildIconItem(1, Icons.explore, isSelected: widget.selectedIndex == 1, iconColor: iconColor),
          _buildFab(fabColor),
          _buildIconItem(3, Icons.store, isSelected: widget.selectedIndex == 3, iconColor: iconColor),
          _buildIconItem(4, Icons.person, isSelected: widget.selectedIndex == 4, iconColor: iconColor),
        ],
      ),
    );
  }

  Widget _buildFab(Color fabColor) {
    return GestureDetector(
      key: _fabKey,
      onTap: () {
        HapticFeedback.mediumImpact();
        HapticFeedback.mediumImpact();
        _showCreateOptions(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.orange.shade800],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ],
        ),
        child: Center(
          child: RotationTransition(
            turns: _fabRotationAnimation,
            child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 30
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconItem(int index, IconData icon, {required bool isSelected, required Color iconColor}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            if (index == 0 && widget.selectedIndex == 0) {
              HapticFeedback.lightImpact();
              Provider.of<ScrollProvider>(context, listen: false).scrollToTop();
            } else {
              HapticFeedback.mediumImpact();
              _playAnimationForIndex(index);
              widget.onTap(index);
            }
          },
          child: AnimatedBuilder(
            animation: _iconAnimationControllers[index],
            builder: (context, child) {
              return Transform.scale(
                scale: _iconScaleAnimations[index].value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isSelected ? 8 : 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orange.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.orange : iconColor,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}