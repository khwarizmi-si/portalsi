// lib/models/story_viewer_model.dart

import 'package:portal_si/utils/safe_parse.dart';

class StoryViewersInfo {
  final int storyId;
  final int totalViewers;
  final List<StoryViewer> viewers;

  StoryViewersInfo({
    required this.storyId,
    required this.totalViewers,
    required this.viewers,
  });

  factory StoryViewersInfo.fromJson(Map<String, dynamic> json) {
    var viewerList = json['viewers'] as List;
    List<StoryViewer> viewers = viewerList.map((v) => StoryViewer.fromJson(v)).toList();

    return StoryViewersInfo(
      storyId: json['story_id'],
      totalViewers: json['total_viewers'],
      viewers: viewers,
    );
  }
}

class StoryViewer {
  final int userId;
  final String username;
  final String profilePictureUrl;
  final bool isVerified;
  final DateTime viewedAt;

  StoryViewer({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
    required this.isVerified,
    required this.viewedAt,
  });

  factory StoryViewer.fromJson(Map<String, dynamic> json) {
    return StoryViewer(
      userId: json['user_id'],
      username: json['username'],
      profilePictureUrl: json['profile_picture_url'],
      // API mengirim 0 atau 1, kita ubah jadi boolean
      isVerified: json['is_verified'] == 1,
      // API mengirim string, kita ubah jadi DateTime
      viewedAt: safeParseDate(json['viewed_at']),
    );
  }
}