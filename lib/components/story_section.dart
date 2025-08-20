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

  // late Future<List<UserWithStories>> _storiesFuture;
  // Map<String, dynamic>? _user;

  late Future<Map<String, dynamic>> _initialDataFuture;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _loadInitialData();
  }

// Hapus fungsi _loadUser() dan _loadStories() yang lama
// Ganti dengan fungsi baru ini:
  Future<Map<String, dynamic>> _loadInitialData() async {
    try {
      final results = await Future.wait([
        _storyService.getStoryFeed(),
        _authService.getUser(),
      ]);

      print('--- RAW API RESPONSE ---');
      print('Stories Data: ${results[0]}');
      print('User Data: ${results[1]}');

      final currentUserData = results[1] as Map<String, dynamic>;
      // --- PERBAIKI BARIS INI ---
      print('Current User ID: ${currentUserData['user_id']}');
      // -------------------------

      print('------------------------');

      return {
        'stories': results[0] as List<dynamic>,
        'user': results[1] as Map<String, dynamic>,
      };
    } catch (e) {
      print('Gagal memuat data awal di StorySection: $e');
      rethrow;
    }
  }

  // Future<void> _loadUser() async {
  //   try {
  //     final userData = await _authService.getUser();
  //     if (mounted) {
  //       setState(() {
  //         _user = userData;
  //       });
  //     }
  //   } catch (e) {
  //     print('Gagal memuat data pengguna di StorySection: $e');
  //   }
  // }

  // lib/widgets/story_section.dart

// ... (kode lainnya tetap sama)

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.transparent,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          // 1. Tampilkan loading indicator saat data sedang diambil
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Tampilkan pesan error jika terjadi kesalahan
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Pastikan data tidak null setelah future selesai
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Tidak ada data cerita.'));
          }

          // 4. JIKA SEMUA AMAN, baru proses datanya di sini
          final data = snapshot.data!; // Sekarang aman menggunakan '!'
          final userData = data['user'] as Map<String, dynamic>;
          final storiesData = data['stories'] as List<dynamic>;

          // ... Sisa logika Anda yang sebelumnya diletakkan di sini ...
          final allUsersWithStories = storiesData.map((json) => UserWithStories.fromJson(json)).toList();
          final String? profileUrl = userData['profile_picture_url'];
          final int? currentUserId = userData['user_id'];

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
              // ... sisa kode itemBuilder tidak berubah ...
              if (index == 0) {
                return StoryCircle(
                  name: 'Cerita Anda',
                  isAddStory: true,
                  hasStory: userHasStory,
                  userProfileUrl: profileUrl,
                  userStoryData: myStoryData,
                  previousStoriesQueue: const [],
                  nextStoriesQueue: otherUsersStories,
                );
              }

              final userStoryData = otherUsersStories[index - 1];
              final previousQueue = otherUsersStories.sublist(0, index - 1);
              final nextQueue = (index < otherUsersStories.length)
                  ? otherUsersStories.sublist(index)
                  : <UserWithStories>[];

              return StoryCircle(
                name: userStoryData.username,
                imageUrl: userStoryData.profilePictureUrl,
                userStoryData: userStoryData,
                previousStoriesQueue: previousQueue,
                nextStoriesQueue: nextQueue,
              );
            },
          );
        },
      ),
    );
  }
}