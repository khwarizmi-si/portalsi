// lib/models/notification_model.dart
import 'user_model.dart';
import 'package:portal_si/utils/safe_parse.dart';

class NotificationModel {
  final int id;
  final String type;
  final String message;
  final User sender;
  final int? relatedPostId;
  final DateTime createdAt;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.sender,
    this.relatedPostId,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'],
      type: json['type'],
      message: json['message'] ?? '', // Fallback jika message null
      sender: User.fromJson(json['sender']),
      relatedPostId: json['related_post_id'],
      createdAt: safeParseDate(json['created_at']),
      isRead: json['is_read'] ?? false,
    );
  }
}
