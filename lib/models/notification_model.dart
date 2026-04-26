// lib/models/notification_model.dart
import 'user_model.dart';

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
    // Support both 'notification_id' and 'id' field names
    final id = json['notification_id'] ?? json['id'] ?? 0;

    // Support nested or flat sender data
    final senderData = json['sender'] is Map<String, dynamic>
        ? json['sender'] as Map<String, dynamic>
        : <String, dynamic>{
            'user_id': json['sender_id'] ?? json['from_user_id'],
            'username': json['sender_username'] ?? 'unknown',
            'full_name': json['sender_full_name'] ?? '',
            'profile_picture_url': json['sender_avatar'] ?? json['sender_profile_picture_url'],
          };

    // Support both 'related_post_id' and 'post_id'
    final relatedPostId = json['related_post_id'] ?? json['post_id'];

    // Parse date safely
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'] ?? json['date'] ?? DateTime.now().toIso8601String());
    } catch (_) {
      createdAt = DateTime.now();
    }

    // is_read can be bool or int (0/1) depending on backend
    final isReadRaw = json['is_read'] ?? json['read'] ?? false;
    final isRead = isReadRaw == true || isReadRaw == 1;

    return NotificationModel(
      id: id is int ? id : int.tryParse(id.toString()) ?? 0,
      type: json['type'] ?? 'unknown',
      message: json['message'] ?? json['body'] ?? '',
      sender: User.fromJson(senderData),
      relatedPostId: relatedPostId is int
          ? relatedPostId
          : int.tryParse(relatedPostId?.toString() ?? ''),
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}
