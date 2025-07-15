import 'package:flutter/material.dart';

class StoryCircle extends StatelessWidget {
  final String name;
  final bool isAddStory;

  const StoryCircle({Key? key, required this.name, this.isAddStory = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isAddStory
                  ? null
                  : LinearGradient(
                      colors: [Colors.orange, Colors.pink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: isAddStory ? Border.all(color: Colors.grey[300]!) : null,
            ),
            child: Container(
              margin: EdgeInsets.all(isAddStory ? 0 : 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isAddStory ? Colors.grey[100] : Colors.white,
                image: isAddStory
                    ? null
                    : DecorationImage(
                        image: NetworkImage(
                          'https://i.pinimg.com/736x/a7/3c/46/a73c46dc586bee96b914730531b9827d.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
              ),
              child: isAddStory
                  ? Icon(Icons.add, color: Colors.grey[600], size: 24)
                  : null,
            ),
          ),
          SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
