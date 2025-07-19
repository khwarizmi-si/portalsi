import 'package:flutter/material.dart';
import 'story_circle.dart';

class StorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.transparent, // Membuat background transparan
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          StoryCircle(name: 'Cerita Anda', isAddStory: true),
          StoryCircle(name: 'r_herdians'),
          StoryCircle(name: 'azzamhaer'),
          StoryCircle(name: 'jiwanya'),
          StoryCircle(name: 'kiantza'),
        ],
      ),
    );
  }
}
