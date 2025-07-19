import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 4;

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    HapticFeedback.lightImpact();
    if (index == 0) Navigator.pushReplacementNamed(context, '/home');
    if (index == 1) Navigator.pushReplacementNamed(context, '/feed');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'uwangraph',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
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
            'https://via.placeholder.com/400x200/4A90E2/FFFFFF?text=UWANGRAPH',
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
          const Center(
            child: Text(
              'UWANGRAPH',
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
              // Profile picture
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://via.placeholder.com/80x80/333333/FFFFFF?text=U',
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
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Stats
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('7', 'postingan'),
                    _buildStatItem('2.594', 'pengikut'),
                    _buildStatItem('2.229', 'mengikuti'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bio
          const Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uwan | Visual Creator',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  '📱 Bantu kamu bisa ngedit cuma dari HP',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '💡 Tips & trik seputar Pixellab dan Figma',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '📱 Lensplay → @wannshoot.id',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  '💌 DM for business/collaboration',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit profile'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Bagikan Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPostGrid() {
    final List<Map<String, dynamic>> posts = [
      {
        'image':
            'https://via.placeholder.com/200x200/2E86AB/FFFFFF?text=KAMPUHAN',
        'title': 'KAMPUHAN',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/F18F01/FFFFFF?text=NEXTRO',
        'title': 'NEXTRO',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/8B4513/FFFFFF?text=JAPANROOM',
        'title': 'JAPANROOM',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/708090/FFFFFF?text=WAITING',
        'title': 'WAITING',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/4682B4/FFFFFF?text=KAMPUHAN',
        'title': 'KAMPUHAN',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/DAA520/FFFFFF?text=NEXTRO',
        'title': 'NEXTRO',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/A0522D/FFFFFF?text=JAPANROOM',
        'title': 'JAPANROOM',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/778899/FFFFFF?text=WAITING',
        'title': 'WAITING',
      },
      {
        'image':
            'https://via.placeholder.com/200x200/5F9EA0/FFFFFF?text=KAMPUHAN',
        'title': 'KAMPUHAN',
      },
    ];

    return Container(
      color: Colors.white,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(post['image']),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Align(
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
            ),
          );
        },
      ),
    );
  }
}
