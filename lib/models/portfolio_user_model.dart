class PortfolioUser {
  final String username;
  final String? profilePictureUrl;

  PortfolioUser({
    required this.username,
    this.profilePictureUrl,
  });

  factory PortfolioUser.fromJson(Map<String, dynamic> json) {
    return PortfolioUser(
      username: json['name'] ?? json['username'], // Ambil 'name' atau 'username'
      profilePictureUrl: json['profile_picture_url'],
    );
  }
}