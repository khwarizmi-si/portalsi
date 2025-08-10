// lib/widgets/story_section.dart

import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Impor package collection
import '../models/story_model.dart';
import '../services/auth_service.dart';
import '../services/story_service.dart';
import 'story_circle.dart';
import 'package:collection/collection.dart';

class StorySection extends StatefulWidget {
  const StorySection({Key? key}) : super(key: key);

  @override
  _StorySectionState createState() => _StorySectionState();
}

class _StorySectionState extends State<StorySection> {
  // ... (kode initState, _loadUser, _loadStories tidak berubah)
  final StoryService _storyService = StoryService();
  final AuthService _authService = AuthService();

  late Future<List<UserWithStories>> _storiesFuture;
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _storiesFuture = _loadStories();
    _loadUser();
  }

  Future<List<UserWithStories>> _loadStories() async {
    try {
      final List<dynamic> responseData = await _storyService.getStoryFeed();
      return responseData.map((json) => UserWithStories.fromJson(json)).toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> _loadUser() async {
    try {
      final userData = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = userData;
        });
      }
    } catch (e) {
      print('Gagal memuat data pengguna di StorySection: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? profileUrl = _user?['user']?['profile_picture_url'];
    final int? currentUserId = _user?['user']?['user_id'];

    return Container(
      height: 100,
      color: Colors.transparent,
      child: FutureBuilder<List<UserWithStories>>(
        future: _storiesFuture,
        builder: (context, snapshot) {
          // ... (kode builder bagian atas tidak berubah)

          final allUsersWithStories = snapshot.data ?? [];

          UserWithStories? myStoryData;
          if (currentUserId != null) {
            myStoryData = allUsersWithStories
                .firstWhereOrNull((storyUser) => storyUser.userId == currentUserId);
          }
          final bool userHasStory = myStoryData != null;

          final List<UserWithStories> otherUsersStories = allUsersWithStories
              .where((storyUser) => storyUser.userId != currentUserId)
              .toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: otherUsersStories.length + 1,
            itemBuilder: (context, index) {
              // --- ITEM PERTAMA: "CERITA ANDA" ---
              if (index == 0) {
                return StoryCircle(
                  name: 'Cerita Anda',
                  isAddStory: true,
                  hasStory: userHasStory,
                  userProfileUrl: profileUrl,
                  userStoryData: myStoryData,
                  // Cerita Anda tidak punya cerita sebelumnya
                  previousStoriesQueue: const [],
                  // Antrean berikutnya adalah semua cerita pengguna lain
                  nextStoriesQueue: otherUsersStories,
                );
              }

              // --- ITEM SELANJUTNYA: CERITA PENGGUNA LAIN ---
              final userStoryData = otherUsersStories[index - 1];

              // Siapkan antrean cerita SEBELUM item ini
              final previousQueue = otherUsersStories.sublist(0, index - 1);

              // Siapkan antrean cerita SETELAH item ini
              final nextQueue = (index < otherUsersStories.length)
                  ? otherUsersStories.sublist(index)
                  : <UserWithStories>[];

              return StoryCircle(
                name: userStoryData.username,
                imageUrl: userStoryData.profilePictureUrl,
                userStoryData: userStoryData,
                previousStoriesQueue: previousQueue, // Teruskan antrean sebelumnya
                nextStoriesQueue: nextQueue, // Teruskan antrean berikutnya
              );
            },
          );
        },
      ),
    );
  }
}