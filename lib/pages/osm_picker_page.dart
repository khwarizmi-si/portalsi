import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class OsmPickerPage extends StatefulWidget {
  const OsmPickerPage({super.key});

  @override
  State<OsmPickerPage> createState() => _OsmPickerPageState();
}

class _OsmPickerPageState extends State<OsmPickerPage> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(-6.2088, 106.8456);
  bool _isLoading = false;

  Future<void> _reverseGeocodeAndSelect() async {
    setState(() => _isLoading = true);
    try {
      final lat = _currentCenter.latitude;
      final lon = _currentCenter.longitude;
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=id');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String? ?? 'Lokasi tidak dikenal';
        if (mounted) {
          Navigator.pop(context, displayName);
        }
      } else {
        throw Exception('Gagal mendapatkan nama lokasi.');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geser Peta untuk Memilih'),
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 13.0,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // --- ✨ PERBAIKAN DI SINI ✨ ---
                userAgentPackageName: 'com.portalsi.app', // GANTI DENGAN PACKAGE NAME ANDA
              ),
            ],
          ),
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 50,
            right: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _reverseGeocodeAndSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text(
                'Pilih Lokasi Ini',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}