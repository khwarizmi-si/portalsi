// lib/models/story_model.dart

import 'user_model.dart';

class StoryDetail {
  final int storyId;
  final String type;
  final String? mediaUrl;
  final String caption;
  final DateTime createdAt;
  final int? musicReelsCount;
  final String? musicTrackName;
  final String? musicArtistName;
  final String? musicPreviewUrl;
  final int? musicStartPositionMs;
  final String? musicDisplayStyle;
  final String? musicAlbumArtUrl;
  final int? musicClipDurationMs;
  final double? musicStickerPositionX;
  final double? musicStickerPositionY;
  bool get isVideo => type == 'video';
  bool get isMusicStory => type == 'music';

  StoryDetail({
    required this.storyId,
    required this.type,
    this.mediaUrl,
    required this.caption,
    required this.createdAt,
    this.musicTrackName,
    this.musicArtistName,
    this.musicPreviewUrl,
    this.musicStartPositionMs,
    this.musicDisplayStyle,
    this.musicAlbumArtUrl,
    this.musicClipDurationMs,
    this.musicStickerPositionX,
    this.musicStickerPositionY,
    this.musicReelsCount,
  });

  factory StoryDetail.fromJson(Map<String, dynamic> json) {
    return StoryDetail(
      storyId: json['story_id'],
      type: json['type'],
      mediaUrl: json['media_url'],
      caption: json['caption'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      musicTrackName: json['music_track_name'],
      musicArtistName: json['music_artist_name'],
      musicPreviewUrl: json['music_preview_url'],
      musicStartPositionMs: json['music_start_position_ms'],
      musicDisplayStyle: json['music_display_style'],
      musicReelsCount: json['music_reels_count'],
      musicAlbumArtUrl: json['music_album_art_url'] ?? json['media_url'],
      musicClipDurationMs: json['music_clip_duration_ms'],
      musicStickerPositionX: json['music_sticker_position_x']?.toDouble(),
      musicStickerPositionY: json['music_sticker_position_y']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'type': type,
      'media_url': mediaUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'music_track_name': musicTrackName,
      'music_artist_name': musicArtistName,
      'music_preview_url': musicPreviewUrl,
      'music_start_position_ms': musicStartPositionMs,
      'music_display_style': musicDisplayStyle,
      'music_album_art_url': musicAlbumArtUrl,
      'music_clip_duration_ms': musicClipDurationMs,
      'music_sticker_position_x': musicStickerPositionX,
      'music_sticker_position_y': musicStickerPositionY,
      'music_reels_count': musicReelsCount,
    };
  }
}

class UserWithStories {
  final int userId;
  final String username;
  final String profilePictureUrl;
  final List<StoryDetail> stories;
  final bool isViewed;
  final bool isVerified;

  UserWithStories({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
    this.isVerified = false,
    required this.stories,
    this.isViewed = false,
  });

  factory UserWithStories.fromJson(Map<String, dynamic> json) {
    var storyList = json['stories'] as List;
    List<StoryDetail> stories = storyList.map((storyJson) => StoryDetail.fromJson(storyJson)).toList();
    stories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return UserWithStories(
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      username: json['username'],
      profilePictureUrl: json['profile_picture_url'],
      isVerified: json['is_verified'] ?? false,
      stories: stories,
      // 3. PARSING DARI JSON (ASUMSI NAMA FIELD DARI API ADALAH 'is_all_viewed')
      isViewed: json['is_all_viewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'profile_picture_url': profilePictureUrl,
      'stories': stories.map((s) => s.toJson()).toList(),
      'is_all_viewed': isViewed,
    };
  }
}