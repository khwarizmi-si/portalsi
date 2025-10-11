class PaginatedFeedResponse {
  final List<dynamic> feedItems;
  final bool hasNextPage;

  PaginatedFeedResponse({
    required this.feedItems,
    required this.hasNextPage,
  });
}