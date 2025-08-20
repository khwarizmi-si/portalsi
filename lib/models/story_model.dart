// lib/models/story_model.dart

class StoryDetail {
  final int storyId;
  final String type; // Tipe cerita: 'image', 'video', atau 'music'
  final String? mediaUrl; // Dibuat nullable karena bisa kosong
  final String caption;
  final DateTime createdAt;
  final int? musicReelsCount;

  final String? musicTrackName;
  final String? musicArtistName;
  final String? musicPreviewUrl;
  final int? musicStartPositionMs;
  final String? musicDisplayStyle;

  // --- BARU: Kolom khusus untuk album art ---
  final String? musicAlbumArtUrl;

  // [DIKOMBINAŠIKAN] Menambahkan field dari saran sebelumnya
  final int? musicClipDurationMs;
  final double? musicStickerPositionX;
  final double? musicStickerPositionY;

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
    // [DIKOMBINAŠIKAN] Menambahkan field ke constructor
    this.musicClipDurationMs,
    this.musicStickerPositionX,
    this.musicStickerPositionY,
    this.musicReelsCount,
  });

  bool get isVideo => type == 'video';
  bool get isMusicStory => type == 'music';

  factory StoryDetail.fromJson(Map<String, dynamic> json) {
    return StoryDetail(
      storyId: json['story_id'],
      type: json['type'] ?? 'image',
      mediaUrl: json['media_url'],
      caption: json['caption'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      musicTrackName: json['music_track_name'],
      musicArtistName: json['music_artist_name'],
      musicPreviewUrl: json['music_preview_url'],
      musicStartPositionMs: json['music_start_position_ms'],
      musicDisplayStyle: json['music_display_style'],
      musicReelsCount: json['music_reels_count'],

      // [PERBAIKAN] Logika dibalik agar memprioritaskan cover album asli
      musicAlbumArtUrl: json['music_album_art_url'] ?? json['media_url'],

      // [DIKOMBINAŠIKAN] Menambahkan parsing JSON untuk field baru
      musicClipDurationMs: json['music_clip_duration_ms'],
      musicStickerPositionX: json['music_sticker_position_x']?.toDouble(),
      musicStickerPositionY: json['music_sticker_position_y']?.toDouble(),
    );
  }
}

class UserWithStories {
  final int userId;
  final String username;
  final String profilePictureUrl;
  final List<StoryDetail> stories;

  UserWithStories({
    required this.userId,
    required this.username,
    required this.profilePictureUrl,
    required this.stories,
  });

  factory UserWithStories.fromJson(Map<String, dynamic> json) {
    var storyList = json['stories'] as List;
    List<StoryDetail> stories = storyList.map((storyJson) => StoryDetail.fromJson(storyJson)).toList();

    stories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return UserWithStories(
      userId: json['user_id'],
      username: json['username'],
      profilePictureUrl: json['profile_picture_url'] ?? 'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
      stories: stories,
    );
  }
}