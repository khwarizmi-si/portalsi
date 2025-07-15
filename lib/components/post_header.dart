import 'package:flutter/material.dart';

class PostHeader extends StatelessWidget {
  final String username;
  final String timeAgo;

  const PostHeader({Key? key, required this.username, required this.timeAgo})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(
              'https://i.pinimg.com/736x/ec/8a/3f/ec8a3f6e345ac819a00ba54bc393f276.jpg',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
