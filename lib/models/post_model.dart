import 'comment_model.dart';
import 'user_model.dart';

class Post {
  final int id;
  final String? caption;
  final String? mediaUrl;
  final String? location;
  final bool isVideo;
  final DateTime createdAt;
  final User user;
  final int? mediaWidth;
  final int? mediaHeight;
  final List<Comment> comments;

  // Properti untuk data musik (SUDAH ADA)
  final String? musicTrackName;
  final String? musicArtistName;
  final String? musicPreviewUrl;
  final String? musicAlbumArtUrl;

  int likesCount;
  int commentsCount;
  bool isLikedByUser;
  bool isBookmarked;

  Post({
    required this.id,
    this.caption,
    this.mediaUrl,
    required this.isVideo,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
    this.location,
    required this.user,
    this.mediaWidth,
    this.mediaHeight,
    required this.isBookmarked,
    this.comments = const [],
    // Tambahkan properti musik di konstruktor (SUDAH ADA)
    this.musicTrackName,
    this.musicArtistName,
    this.musicPreviewUrl,
    this.musicAlbumArtUrl,
  });

  double get aspectRatio {
    if (mediaWidth != null && mediaHeight != null && mediaWidth! > 0 && mediaHeight! > 0) {
      return mediaWidth! / mediaHeight!;
    }
    return 1.0;
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    var commentsFromJson = json['comments'] as List? ?? [];
    List<Comment> commentList =
    commentsFromJson.map((c) => Comment.fromJson(c)).toList();

    final postData = json['post'] is Map<String, dynamic> ? json['post'] : json;

    final User postUser;
    if (postData['user'] != null && postData['user'] is Map<String, dynamic>) {
      postUser = User.fromJson(postData['user']);
    } else {
      postUser = User(
          id: postData['user_id'],
          username: ''
      );
    }

    return Post(
      id: int.tryParse(postData['post_id']?.toString() ?? postData['id']?.toString() ?? '0') ?? 0,
      caption: postData['caption'], // Perubahan: Hapus ?? '' agar bisa null
      mediaUrl: postData['media_url'],
      isVideo: postData['is_video'] == 1 || postData['is_video'].toString() == '1',
      createdAt: DateTime.parse(postData['created_at']),
      likesCount: postData['likes_count'] ?? 0,
      commentsCount: postData['comments_count'] ?? 0,
      isLikedByUser: postData['is_liked'] ?? false,
      location: postData['location'], // Perubahan: Hapus ?? '' agar bisa null
      isBookmarked: postData['is_bookmarked'] ?? false,
      user: postUser,
      mediaWidth: postData['media_width'],
      mediaHeight: postData['media_height'],
      comments: commentList,
      // --- 👇 PASTIKAN BAGIAN INI ADA 👇 ---
      musicTrackName: postData['music_track_name'],
      musicArtistName: postData['music_artist_name'],
      musicPreviewUrl: postData['music_preview_url'],
      musicAlbumArtUrl: postData['music_album_art_url'],
    );
  }

  // ... sisa kode lainnya tidak berubah ...
  Map<String, dynamic> toJson() {
    return {
      'post_id': id,
      'caption': caption,
      'media_url': mediaUrl,
      'is_video': isVideo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLikedByUser,
      'user': user.toJson(),
      'media_width': mediaWidth,
      'media_height': mediaHeight,
    };
  }
  Post copyWith({
    int? id,
    String? caption,
    String? mediaUrl,
    bool? isVideo,
    bool? isBookmarked,
    DateTime? createdAt,
    User? user,
    int? likesCount,
    int? commentsCount,
    bool? isLikedByUser,
    int? mediaWidth,
    int? mediaHeight,
    List<Comment>? comments,
  }) {
    return Post(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      isVideo: isVideo ?? this.isVideo,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      mediaWidth: mediaWidth ?? this.mediaWidth,
      mediaHeight: mediaHeight ?? this.mediaHeight,
      comments: comments ?? this.comments,
    );
  }
}