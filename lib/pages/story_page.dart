import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_model.dart';
import '../utils/navigation_helper.dart';

class InstagramStoryPage extends StatefulWidget {
  final User user; // Tambahkan properti untuk menampung data user

  const InstagramStoryPage({super.key, required this.user});

  @override
  _InstagramStoryPageState createState() => _InstagramStoryPageState();
}

class _InstagramStoryPageState extends State<InstagramStoryPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _backgroundController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        // Dengan Stack, kita bisa menumpuk widget dengan presisi
        children: [
          // Lapisan 1: Background (paling bawah)
          _buildBackgroundLayer(),

          // Lapisan 2: Konten Cerita (di tengah)
          // Kita gunakan Positioned.fill agar mengisi semua ruang
          // di antara top dan bottom section
          Positioned.fill(
            top: 100, // Beri jarak dari atas
            bottom: 100, // Beri jarak dari bawah
            child: _buildStoryContent(),
          ),

          // Lapisan 3: Tombol interaksi bawah
          // Diletakkan di bagian bawah layar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSection(),
          ),

          // Lapisan 4: Bagian Atas (DIJAMIN PALING ATAS & BISA DIKLIK)
          // Diletakkan di bagian atas layar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea( // SafeArea dipindah ke sini
              child: _buildTopSection(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundLayer() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a1a2e).withOpacity(0.9),
                Color(0xFF16213e).withOpacity(0.8),
                Color(0xFF0f3460).withOpacity(0.9),
                Color(0xFF1a1a2e).withOpacity(0.8),
              ],
              stops: [
                0.0 + _backgroundAnimation.value * 0.1,
                0.3 + _backgroundAnimation.value * 0.1,
                0.7 + _backgroundAnimation.value * 0.1,
                1.0,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.overlay,
              gradient: RadialGradient(
                center: Alignment(
                  -0.5 + _backgroundAnimation.value * 0.3,
                  -0.8 + _backgroundAnimation.value * 0.2,
                ),
                radius: 1.2,
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Progress indicator
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              return Container(
                height: 2,
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressController.value,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          // User info
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Material(
                color: Colors.transparent, // Wajib transparan
                child: InkWell(
                  splashColor: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20), // Bentuk splash saat diklik
                  onTap: () {
                    // --- Logika Navigasi ---
                    print("✅ Profile picture tapped! (FIXED)");
                    print("Navigating to profile for user: ${widget.user.username}");

                    HapticFeedback.lightImpact();
                    Navigator.pop(context); // Tutup story

                    Navigator.pushNamed(
                      context,
                      '/other-profile',
                      arguments: {'username': widget.user.username},
                    );
                  },
                  child: Container(
                    width: 35,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: DecorationImage(
                        image: NetworkImage(
                            widget.user.profilePictureUrl ?? 'https://via.placeholder.com/150'
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'r_herdians',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '20 menit yang lalu',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.white, size: 28),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Coding screen mockup
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: Color(0xFF1e1e1e),
                child: Column(
                  children: [
                    // Title bar
                    Container(
                      height: 30,
                      color: Color(0xFF2d2d30),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(width: 6),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.yellow,
                            ),
                          ),
                          SizedBox(width: 6),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Code content
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCodeLine(
                              'import "./assets/icons/arrow.svg";',
                              Colors.purple,
                            ),
                            _buildCodeLine(
                              'import "./assets/icons/bolt.svg";',
                              Colors.purple,
                            ),
                            _buildCodeLine(
                              'import { Icon } from "./assets/icons/right-arrow.svg";',
                              Colors.purple,
                            ),
                            SizedBox(height: 8),
                            _buildCodeLine('const Ref = {', Colors.yellow),
                            _buildCodeLine('  "eslintConfig": {', Colors.cyan),
                            _buildCodeLine('    "extends": [', Colors.orange),
                            _buildCodeLine('      "react-app"', Colors.green),
                            _buildCodeLine('    ]', Colors.orange),
                            _buildCodeLine('  }', Colors.cyan),
                            _buildCodeLine('}', Colors.yellow),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Code snippets floating around
          Positioned(
            right: 20,
            child: _buildFloatingCode('"eslintConfig"', Colors.cyan),
          ),
          Positioned(
            right: 40,
            top: 100,
            child: _buildFloatingCode('"extends": [', Colors.orange),
          ),
          Positioned(
            right: 60,
            top: 140,
            child: _buildFloatingCode('"react-app"', Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeLine(String code, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(
        code,
        style: TextStyle(color: color, fontSize: 11, fontFamily: 'Courier'),
      ),
    );
  }

  Widget _buildFloatingCode(String code, Color color) {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _backgroundAnimation.value * 10,
            _backgroundAnimation.value * 5,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(
              code,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'Courier',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kirim pesan..',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Add like animation
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Icon(Icons.favorite_border, color: Colors.white, size: 20),
            ),
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              // Add send action
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Usage in main app
