import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:portal_si/models/portfolio_model.dart';
import 'package:portal_si/services/api_service.dart';

import '../models/portfolio_item_model.dart';
import '../utils/secure_storage.dart';

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

  Future<List<PortfolioItem>> getPortfoliosByAspect(String aspect) async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan. Silakan login kembali.');
    }

    final url = Uri.parse('$baseUrl/portfolios?aspect=$aspect');

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // --- 👇 PERUBAHAN DI SINI 👇 ---
      // 1. Decode JSON menjadi sebuah Map
      final Map<String, dynamic> data = json.decode(response.body);
      // 2. Ambil list dari dalam key 'portfolios'
      final List<dynamic> portfolioJson = data['portfolios'];

      return portfolioJson.map((json) => PortfolioItem.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data portofolio: ${response.body}');
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