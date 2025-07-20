import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';
import '../utils/secure_storage.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;
  Map<String, dynamic>? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await AuthService().getUser();
    if (userData == null) {
      // Token hilang/invalid → langsung logout
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    setState(() {
      _user = userData;
      _isLoadingUser = false;
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    if (index == 1) Navigator.pushReplacementNamed(context, '/feed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Center(
          child: Text(
            _isLoadingUser
                ? 'Memuat...'
                : _user?['user']?['username'] ?? 'Nama tidak tersedia',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black, // ganti jadi putih karena background gelap
              letterSpacing: 0.2,
            ),
          ),
        ),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.black),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().logout(); // gunakan service yang konsisten
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },

            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Profile Info
            _buildProfileSection(),
            const SizedBox(height: 8),
            // Grid Posts
            _buildPostGrid(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(
            'https://i.pinimg.com/1200x/8c/56/c4/8c56c483afc07fbbc8d1c937c53c26b1.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Text(
              _isLoadingUser
                  ? 'Memuat...'
                  : _user?['user']?['username'] ?? 'Nama tidak tersedia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Profile picture with enhanced styling
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                            spreadRadius: -1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(), // Better spacing distribution
            ],
          ),

          const SizedBox(height: 16),

          // Bio dan Statistik with improved spacing
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bio section with better typography
                Text(
                  _isLoadingUser
                      ? 'Memuat...'
                      : _user?['user']?['full_name'] ?? 'Nama tidak tersedia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[900],
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Bio items with consistent spacing
                ...{
                      '📱 Bantu kamu bisa ngedit cuma dari HP',
                      '💡 Tips & trik seputar Pixellab dan Figma',
                      '📱 Lensplay → @wannshoot.id',
                      '💌 DM for business/collaboration',
                    }
                    .map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ),
                    )
                    .toList(),

                const SizedBox(height: 16),

                // Enhanced statistics section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('7', 'postingan'),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildStatItem('2.594', 'pengikut'),
                      Container(height: 40, width: 1, color: Colors.grey[300]),
                      _buildStatItem('2.229', 'mengikuti'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Enhanced Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Edit profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        offset: const Offset(0, 3),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        offset: const Offset(0, 1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Bagikan Profile',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced stat item widget
  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey[900],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildPostGrid() {
    final List<Map<String, dynamic>> posts = [
      {
        'image':
            'https://i.pinimg.com/736x/81/db/7c/81db7ca9eb93133ee8d1091936d80625.jpg',
        'title': 'KAMPUHAN',
      },
      {
        'image':
            'https://i.pinimg.com/736x/1d/1a/3f/1d1a3fff2183b264ad00ee507101fd1e.jpg',
        'title': 'NEXTRO',
      },
      {
        'image':
            'https://i.pinimg.com/736x/d9/d8/c6/d9d8c67d96e15ab6a17442fc55024cc7.jpg',
        'title': 'JAPANROOM',
      },
      {
        'image':
            'https://i.pinimg.com/736x/d6/e5/0d/d6e50d10fc39a3b47cfa23b58afaf148.jpg',
        'title': 'WAITING',
      },
      {
        'image':
            'https://i.pinimg.com/736x/a8/13/08/a81308cbf1a607ad22def295c86cd6b6.jpg',
        'title': 'KAMPUHAN',
      },
      {
        'image':
            'https://i.pinimg.com/736x/63/f8/41/63f84192f01fb809ddf39982a144c5c3.jpg',
        'title': 'NEXTRO',
      },
      {
        'image':
            'https://i.pinimg.com/736x/e3/48/ef/e348ef87342010f1e2ac21cca1d0b27a.jpg',
        'title': 'JAPANROOM',
      },
      {
        'image':
            'https://i.pinimg.com/736x/ab/7d/34/ab7d34778833e71e575bbe4100d9d272.jpg',
        'title': 'WAITING',
      },
      {
        'image':
            'https://i.pinimg.com/736x/94/74/24/947424a08a621e3a1414f43ccab82eb0.jpg',
        'title': 'KAMPUHAN',
      },
    ];

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ), // Margin kiri & kanan
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6, // Bisa kamu atur supaya ada jarak antar item
            mainAxisSpacing: 8,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(80, 0, 0, 0),

                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(post['image'], fit: BoxFit.cover),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          post['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
