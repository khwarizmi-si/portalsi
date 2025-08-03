// lib/widgets/feed/feed_grid.dart
import 'package:flutter/material.dart';
import 'post_grid_item.dart';

class FeedGrid extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> posts;
  final Map<int, int> likeCounts;
  final Map<int, bool> likedPosts;
  final ScrollController scrollController;
  final Animation<double> fadeAnimation;
  final Future<void> Function() onRefresh;
  final Future<void> Function(Map, int) onLikePost;
  final Function(dynamic) onPostTap;

  const FeedGrid({
    Key? key,
    required this.isLoading,
    required this.posts,
    required this.likeCounts,
    required this.likedPosts,
    required this.scrollController,
    required this.fadeAnimation,
    required this.onRefresh,
    required this.onLikePost,
    required this.onPostTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState(context);
    }

    if (posts.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: fadeAnimation,
      child: CustomScrollView(
        controller: scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => PostGridItem(
                  item: posts[index],
                  index: index,
                  likeCounts: likeCounts,
                  likedPosts: likedPosts,
                  onLikePost: onLikePost,
                  onPostTap: onPostTap,
                ),
                childCount: posts.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
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
            'Loading amazing content...',
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
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No posts yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Posts will appear here when available',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
