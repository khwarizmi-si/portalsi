// lib/components/story_section.dart

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:portal_si/components/story_circle.dart';
import '../models/story_model.dart';
import '../utils/user_provider.dart';
import 'package:provider/provider.dart';

class StorySection extends StatelessWidget {
  final List<UserWithStories> stories;

  const StorySection({
    super.key,
    required this.stories,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil data pengguna yang sedang login dari UserProvider
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    if (currentUser == null) {
      // Jika karena suatu alasan data user belum ada, tampilkan loading
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    final allUsersWithStories = stories;
    final String? profileUrl = currentUser.profilePictureUrl;
    final int? currentUserId = currentUser.id;

    UserWithStories? myStoryData;
    if (currentUserId != null) {
      myStoryData = allUsersWithStories
          .firstWhereOrNull((storyUser) => storyUser.userId == currentUserId);
    }
    final bool userHasStory = myStoryData != null;

    final List<UserWithStories> otherUsersStories = allUsersWithStories
        .where((storyUser) => storyUser.userId != currentUserId)
        .toList();

    // Urutkan cerita: yang belum dilihat tampil lebih dulu
    otherUsersStories.sort((a, b) {
      if (!a.isViewed && b.isViewed) return -1; // a (belum dilihat) sebelum b (sudah dilihat)
      if (a.isViewed && !b.isViewed) return 1;  // b sebelum a
      return 0; // Jaga urutan asli jika status sama
    });

    // TINGKATKAN RADIUS DI SINI
    const double storyCircleRadius = 40.0;

    // TINGKATKAN KETINGGIAN SECTION AGAR MUAT
    // (Avatar Full Size 74.0) + (SizedBox 6.0) + (Text Height ~14.0) + (Padding Vertikal ListView 16.0)
    final double sectionHeight = storyCircleRadius * 3.5;

    return Container(
      height: sectionHeight,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: otherUsersStories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // Beri key konstan untuk item "Cerita Anda"
            return StoryCircle(
              key: const ValueKey('add_story_circle'), // TAMBAHKAN KEY
              name: 'Cerita Anda',
              isAddStory: true,
              hasStory: userHasStory,
              userProfileUrl: profileUrl,
              userStoryData: myStoryData,
              previousStoriesQueue: const [],
              nextStoriesQueue: otherUsersStories,
              currentUserData: currentUser,
              radius: storyCircleRadius,
            );
          }

          final userStoryData = otherUsersStories[index - 1];
          final previousQueue = [if (userHasStory) myStoryData!, ...otherUsersStories.sublist(0, index - 1)];
          final nextQueue = (index < otherUsersStories.length)
              ? otherUsersStories.sublist(index)
              : <UserWithStories>[];

          // Gunakan userId yang unik sebagai Key untuk setiap StoryCircle lainnya
          return StoryCircle(
            key: ValueKey(userStoryData.userId), // TAMBAHKAN KEY UNIK
            name: userStoryData.username,
            imageUrl: userStoryData.profilePictureUrl,
            userStoryData: userStoryData,
            previousStoriesQueue: previousQueue,
            nextStoriesQueue: nextQueue,
            radius: storyCircleRadius,
          );
        },
      ),
    );
  }
}