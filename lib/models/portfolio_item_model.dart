
import 'package:portal_si/models/portfolio_user_model.dart';
import 'package:portal_si/utils/safe_parse.dart';

class PortfolioItem {
  final int id;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final PortfolioUser user; // <-- TAMBAHKAN INFORMASI USER

  PortfolioItem({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.user, // <-- TAMBAHKAN DI KONSTRUKTOR
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['media_url'],
      createdAt: safeParseDate(json['created_at']),
      // Asumsi API mengembalikan objek 'user' di dalam setiap item portofolio
      user: PortfolioUser.fromJson(json['user'] ?? {'username': json['user_name']}),
    );
  }
}