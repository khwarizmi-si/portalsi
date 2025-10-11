// lib/models/song_model.dart

class Song {
  final int trackId; // <-- DITAMBAHKAN
  final String trackName;
  final String artistName;
  final String artworkUrl;
  final String previewUrl;
  final int trackTimeMillis;

  Song({
    required this.trackId, // <-- DITAMBAHKAN
    required this.trackName,
    required this.artistName,
    required this.artworkUrl,
    required this.previewUrl,
    required this.trackTimeMillis,
  });

  String get duration {
    final d = Duration(milliseconds: trackTimeMillis);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackId: json['trackId'] ?? 0, // <-- DITAMBAHKAN
      trackName: json['trackName'] ?? 'Unknown Track',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: (json['artworkUrl100'] ?? '').replaceAll('100x100', '400x400'),
      previewUrl: json['previewUrl'] ?? '',
      trackTimeMillis: json['trackTimeMillis'] ?? 0,
    );
  }

  // --- METHOD BARU DITAMBAHKAN UNTUK FITUR BOOKMARK ---
  Map<String, dynamic> toJson() {
    return {
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'artworkUrl100': artworkUrl.replaceAll('400x400', '100x100'),
      'previewUrl': previewUrl,
      'trackTimeMillis': trackTimeMillis,
    };
  }
}