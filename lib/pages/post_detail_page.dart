import 'package:flutter/material.dart';
import '../components/post_card.dart';
import '../components/bottom_navigation.dart';

class PostDetailPage extends StatefulWidget {
  final String username;
  final String timeAgo;
  final String imageUrl;
  final String content;
  final int likes;
  final int comments;

  const PostDetailPage({
    Key? key,
    required this.username,
    required this.timeAgo,
    required this.imageUrl,
    required this.content,
    required this.likes,
    required this.comments,
  }) : super(key: key);

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  int _selectedIndex = 1;

  final List<Map<String, dynamic>> allPosts = const [
    {
      'image':
          'https://i.pinimg.com/736x/e5/b2/e2/e5b2e25471789ef3d4fe8b9657a16d27.jpg',
      'title': 'HUT',
      'subtitle': 'Design Collection',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
      'title': 'LORD',
      'subtitle': 'Game UI Design',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=400',
      'title': 'JONAS',
      'subtitle': 'Character Design',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1551650975-87deedd944c3?w=400',
      'title': 'SQUIDWARD',
      'subtitle': 'Animation',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?w=400',
      'title': 'PRO SKYLAR',
      'subtitle': 'Sports Design',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1566492031773-4f4e44671d66?w=400',
      'title': 'NINJA',
      'subtitle': 'Game Interface',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1558655146-9f40138edfeb?w=400',
      'title': 'GRADIENT',
      'subtitle': 'Color Palette',
    },
  ];

  void _onBottomNavTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _showPostPreview(Map<String, dynamic> item) {
    showDialog(
      context: context, // ini perlu akses context dari class
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                item['image'],
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item['subtitle'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0E0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Detail Postingan', style: TextStyle(color: Colors.black)),
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView(
        children: [
          PostCard(
            username: widget.username,
            timeAgo: widget.timeAgo,
            imageUrl: widget.imageUrl,
            content: widget.content,
            likes: widget.likes,
            comments: widget.comments,
          ),

          // Tampilkan semua postingan dan tambahkan gesture untuk preview
          ...allPosts.map((item) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onLongPress: () => _showPostPreview(item),
                child: PostCard(
                  username: 'randomuser',
                  timeAgo: 'Baru saja',
                  imageUrl: item['image'],
                  content: item['subtitle'],
                  likes: 0,
                  comments: 0,
                ),
              ),
            );
          }).toList(),

          SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }
}
