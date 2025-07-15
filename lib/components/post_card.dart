import 'package:flutter/material.dart';
import 'post_header.dart';
import 'post_action.dart';

class PostCard extends StatelessWidget {
  final String username;
  final String timeAgo;
  final String content;
  final String imageUrl;
  final int likes;
  final int comments;

  const PostCard({
    Key? key,
    required this.username,
    required this.timeAgo,
    required this.content,
    required this.imageUrl,
    required this.likes,
    required this.comments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          PostHeader(username: username, timeAgo: timeAgo),

          // Image
          Container(
            width: double.infinity,
            height: 300,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          PostActions(likes: likes, comments: comments),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$username ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: content,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 8),
          // Actions
        ],
      ),
    );
  }
}
