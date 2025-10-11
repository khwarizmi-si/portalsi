// lib/models/paginated_story_feed.dart

import 'story_model.dart';

// Model ini merepresentasikan keseluruhan respons dari endpoint baru Anda
class PaginatedStoryFeed {
  // Ini adalah data utama: user dan daftar ceritanya
  final UserWithStories userWithStories;
  // ID user sebelumnya di dalam antrian
  final int? prevUserId;
  // ID user berikutnya di dalam antrian
  final int? nextUserId;

  PaginatedStoryFeed({
    required this.userWithStories,
    this.prevUserId,
    this.nextUserId,
  });

  factory PaginatedStoryFeed.fromJson(Map<String, dynamic> json) {
    final userData = json['current_user'] as Map<String, dynamic>;
    final storyListData = json['stories'] as List;

    // --- 👇 PERBAIKAN UTAMA ADA DI SINI 👇 ---
    final combinedUserWithStories = UserWithStories(
      userId: userData['user_id'] as int, // Langsung cast ke int
      username: userData['username'] ?? 'Pengguna',
      profilePictureUrl: userData['profile_picture_url'] ?? '',
      stories: storyListData.map((s) => StoryDetail.fromJson(s)).toList(),
      isVerified: userData['is_verified'] ?? false,

      // Cek 'is_viewed' dari setiap item Map di dalam storyListData,
      // bukan dari objek yang belum jadi.
      isViewed: storyListData.every((s) => (s as Map<String, dynamic>)['is_viewed'] == true),
    );

    return PaginatedStoryFeed(
      userWithStories: combinedUserWithStories,
      prevUserId: json['prev_user_id'],
      nextUserId: json['next_user_id'],
    );
  }
}