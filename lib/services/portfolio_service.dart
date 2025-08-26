import 'dart:io';
import 'package:portal_si/models/portfolio_model.dart';
import 'package:portal_si/services/api_service.dart';

class PortfolioService extends ApiService {
  /// Mengambil daftar portofolio untuk user tertentu.
  Future<List<Portfolio>> getPortfolios(int userId) async {
    try {
      final data = await get(
        'portfolios',
        queryParams: {'user_id': userId.toString()},
      );

      final List portfolioList = data['portfolios'];
      return portfolioList.map((json) => Portfolio.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Membuat portofolio baru dengan mengunggah file.
  Future<void> createPortfolio({
    required int userId,
    required String title,
    required String description,
    required String year,
    required String aspect,
    required File mediaFile,
  }) async {
    try {
      final body = {
        'user_id': userId.toString(),
        'title': title,
        'description': description,
        'year': year,
        'aspect': aspect,
      };

      final files = {'media': mediaFile};

      await postMultipart(
        'portfolios',
        body: body,
        files: files,
      );
    } catch (e) {
      rethrow;
    }
  }
}