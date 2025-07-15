import 'package:flutter/material.dart';
import '../components/story_section.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Portal SI',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stories Section
            StorySection(),

            SizedBox(height: 8),

            // Posts Section
            PostCard(
              username: 'uwangraph',
              timeAgo: '10 jam',

              imageUrl:
                  'https://i.pinimg.com/736x/e5/b2/e2/e5b2e25471789ef3d4fe8b9657a16d27.jpg',
              likes: 99,
              comments: 66,
              content:
                  'Bingung cari font buat desain Ramadhan? Tenang, kita udah siapin rekomendasi terbaik buat kalian! 😊\n\nSwipe buat lihat lebih banyak pilihan! 📱',
            ),

            SizedBox(height: 8),

            // Additional post example
            PostCard(
              username: 'uwangraph',
              timeAgo: '11 jam',

              imageUrl:
                  'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=400&h=400&fit=crop',
              likes: 45,
              comments: 23,
              content: 'Tips desain yang mudah dipahami untuk pemula! 🎨',
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
