// lib/widgets/feed/search_results.dart - Versi Simple
import 'package:flutter/material.dart';
import 'user_search_item.dart';
import '../../pages/other_profile_page.dart';
import '../../utils/secure_storage.dart';

class SearchResults extends StatelessWidget {
  final bool isSearching;
  final List<dynamic> searchResults;
  final Function(Map<String, dynamic>) onUserTap;

  const SearchResults({
    Key? key,
    required this.isSearching,
    required this.searchResults,
    required this.onUserTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSearching) {
      return _buildLoadingState(context);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }

        final currentUserData = snapshot.data;
        final currentUsername = currentUserData?['username'];
        final currentUserId = currentUserData?['userId'];

        // Filter out current user from search results
        final filteredResults = searchResults.where((user) {
          final userUsername = user['username']?.toString();
          final userId = user['user_id'] ?? user['id'];

          // Filter by both user_id and username to exclude current user
          return userId != currentUserId &&
              userUsername != currentUsername &&
              userUsername != null &&
              userUsername.isNotEmpty;
        }).toList();

        if (filteredResults.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: filteredResults.length,
          itemBuilder: (context, index) {
            final user = filteredResults[index];
            return UserSearchItem(
              user: user,
              onTap: () => _navigateToProfile(context, user),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    try {
      final username = await SecureStorage.getUsername();
      final userId = await SecureStorage.getUserId();
      return {
        'username': username,
        'userId': userId,
      };
    } catch (e) {
      print('Error loading current user data: $e');
      return {};
    }
  }

  void _navigateToProfile(BuildContext context, Map<String, dynamic> user) {
    // Call the original onUserTap if needed for additional functionality
    onUserTap(user);

    // Navigate to OtherProfilePage using the username
    final username = user['username']?.toString();
    if (username != null && username.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherProfilePage(username: username),
        ),
      );
    } else {
      // Show error if username is not available
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username tidak tersedia'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Searching users...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No users found',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Try searching with different keywords',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
