// lib/models/like_model.dart
import 'user_model.dart';

class Like {
  final int likeId;
  final User user;

  Like({required this.likeId, required this.user});

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      likeId: json['like_id'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
