// lib/components/story_section.dart

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:portal_si/components/story_circle.dart';
import '../controllers/home_controller.dart';
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
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    if (currentUser == null) {
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

    otherUsersStories.sort((a, b) {
      if (!a.isViewed && b.isViewed) return -1;
      if (a.isViewed && !b.isViewed) return 1;
      return 0;
    });

    const double storyCircleRadius = 37.0;
    final double sectionHeight = storyCircleRadius * 3.5;

    return Container(
      height: sectionHeight,
      color: Colors.transparent,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: otherUsersStories.length + 1,
        itemBuilder: (context, index) {
          final VoidCallback onStoryCloseCallback = () {
            // Panggil HomeController untuk memuat ulang semua data dashboard
            Provider.of<HomeController>(context, listen: false).refreshDashboardData();
          };
          if (index == 0) {
            return StoryCircle(
              key: const ValueKey('add_story_circle'),
              name: 'Cerita Kamu',
              isAddStory: true,
              hasStory: userHasStory,
              userProfileUrl: profileUrl,
              userStoryData: myStoryData,
              previousStoriesQueue: const [],
              nextStoriesQueue: otherUsersStories,
              currentUserData: currentUser,
              radius: storyCircleRadius,
              // --- 👇 PERUBAHAN 1: Teruskan ID pengguna saat ini 👇 ---
              currentUserId: currentUserId,
              onStoryClosed: onStoryCloseCallback,
            );
          }

          final userStoryData = otherUsersStories[index - 1];
          final previousQueue = [if (userHasStory) myStoryData!, ...otherUsersStories.sublist(0, index - 1)];
          final nextQueue = (index < otherUsersStories.length)
              ? otherUsersStories.sublist(index)
              : <UserWithStories>[];

          return StoryCircle(
            key: ValueKey(userStoryData.userId),
            name: userStoryData.username,
            imageUrl: userStoryData.profilePictureUrl,
            userStoryData: userStoryData,
            previousStoriesQueue: previousQueue,
            nextStoriesQueue: nextQueue,
            radius: storyCircleRadius,
            // --- 👇 PERUBAHAN 2: Teruskan ID pengguna saat ini 👇 ---
            currentUserId: currentUserId,
            onStoryClosed: onStoryCloseCallback,
          );
        },
      ),
    );
  }
}