import 'package:flutter/material.dart';

class PostActions extends StatelessWidget {
  final int likes;
  final int comments;

  const PostActions({Key? key, required this.likes, required this.comments})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[600],
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    comments.toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Spacer(),
          IconButton(
            onPressed: () {
              // aksi share
            },
            icon: SizedBox(
              width: 25,
              height: 25,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(Icons.send, size: 20, color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
