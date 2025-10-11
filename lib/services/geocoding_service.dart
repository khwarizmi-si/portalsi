import 'dart:convert';
import 'package:http/http.dart' as http;

// Model sederhana untuk menampung hasil sugesti lokasi
class PlaceSuggestion {
  final String displayName;

  PlaceSuggestion({required this.displayName});

  @override
  String toString() {
    return 'PlaceSuggestion(displayName: $displayName)';
  }
}

class GeocodingService {
  final String _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    if (query.length < 3) {
      return [];
    }

    // URL Encode query untuk menangani spasi dan karakter spesial
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('$_baseUrl/search?q=$encodedQuery&format=json&addressdetails=1&limit=5');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept-Language': 'id-ID,id;q=0.9', // Prioritaskan hasil dalam Bahasa Indonesia
        },
      );

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        return results.map((place) {
          return PlaceSuggestion(
            displayName: place['display_name'] ?? 'Lokasi tidak dikenal',
          );
        }).toList();
      } else {
        throw Exception('Gagal mencari lokasi: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error di GeocodingService: $e');
      throw Exception('Terjadi kesalahan saat menghubungi server lokasi.');
    }
  }
}