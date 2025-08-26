class Portfolio {
  final int id;
  final int userId;
  final String userName;
  final String aspect;
  final String title;
  final String description;
  final String mediaUrl;
  final String year;

  const Portfolio({
    required this.id,
    required this.userId,
    required this.userName,
    required this.aspect,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.year,
  });

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      aspect: json['aspect'],
      title: json['title'],
      description: json['description'],
      mediaUrl: json['media_url'],
      year: json['year'],
    );
  }
}
