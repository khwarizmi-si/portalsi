// lib/models/story_model.dart

class StoryDetail {
  final int storyId;
  final String mediaUrl;
  final String caption;
  final DateTime createdAt;
  final bool isVideo;
  final String? musicDisplayStyle;

  // --- PROPERTI BARU UNTUK MUSIK (BISA NULL) ---
  final String? musicTrackName;
  final String? musicArtistName;
  final String? musicPreviewUrl;
  final int? musicStartPositionMs; // Posisi awal klip dalam milidetik

  StoryDetail({
    required this.storyId,
    required this.mediaUrl,
    required this.caption,
    this.musicDisplayStyle,
    required this.createdAt,
    required this.isVideo,
    this.musicTrackName,
    this.musicArtistName,
    this.musicPreviewUrl,
    this.musicStartPositionMs,
  });

  // Getter untuk dengan mudah memeriksa apakah ini cerita musik
  bool get isMusicStory => musicPreviewUrl != null;

  factory StoryDetail.fromJson(Map<String, dynamic> json) {
    final String mediaUrl = json['media_url'];
    return StoryDetail(
      storyId: json['story_id'],
      mediaUrl: mediaUrl,
      caption: json['caption'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isVideo: mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov'),
      // Ambil data musik dari JSON jika ada
      musicTrackName: json['music_track_name'],
      musicArtistName: json['music_artist_name'],
      musicPreviewUrl: json['music_preview_url'],
      musicStartPositionMs: json['music_start_position_ms'],
      musicDisplayStyle: json['music_display_style'],
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
      // --- PERUBAHAN DI SINI ---
      // Jika 'profile_picture_url' null, gunakan URL default
      profilePictureUrl: json['profile_picture_url'] ?? 'https://i.pinimg.com/736x/19/5c/15/195c15bc600ba3e50ff5ac3be08c3667.jpg',
      stories: stories,
    );
  }
}