// class Comment {
//   final int id;
//   final int postId;
//   final int userId;
//   final String content;
//   final int? parentCommentId;
//   final DateTime createdAt;
//   final DateTime updatedAt;
//   final String username;
//   final String? profilePictureUrl;
//   bool liked;
//   int likes;

//   Comment({
//     required this.id,
//     required this.postId,
//     required this.userId,
//     required this.content,
//     this.parentCommentId,
//     required this.createdAt,
//     required this.updatedAt,
//     required this.username,
//     this.profilePictureUrl,
//     this.liked = false,
//     this.likes = 0,
//   });

//   factory Comment.fromJson(Map<String, dynamic> json) {
//     try {
//       print('=== PARSING COMMENT JSON ===');
//       print('JSON: $json');
//       print('JSON Keys: ${json.keys.toList()}');

//       // Coba berbagai kemungkinan key untuk ID
//       int commentId;
//       if (json.containsKey('comment_id')) {
//         commentId = int.tryParse(json['comment_id'].toString()) ?? 0;
//       } else if (json.containsKey('id')) {
//         commentId = int.tryParse(json['id'].toString()) ?? 0;
//       } else {
//         throw Exception('Comment ID tidak ditemukan');
//       }

//       // Parse post_id
//       int postId = int.tryParse(json['post_id'].toString()) ?? 0;

//       // Parse user_id
//       int userId;
//       if (json.containsKey('user_id')) {
//         userId = int.tryParse(json['user_id'].toString()) ?? 0;
//       } else if (json.containsKey('user') && json['user'] is Map) {
//         userId = int.tryParse(json['user']['user_id'].toString()) ??
//             int.tryParse(json['user']['id'].toString()) ??
//             0;
//       } else {
//         userId = 0;
//       }

//       // Parse content
//       String content = json['content']?.toString() ?? '';

//       // Parse parent_comment_id
//       int? parentCommentId;
//       if (json['parent_comment_id'] != null) {
//         parentCommentId = int.tryParse(json['parent_comment_id'].toString());
//       }

//       // Parse dates dengan berbagai format
//       DateTime createdAt;
//       DateTime updatedAt;

//       try {
//         createdAt = DateTime.parse(json['created_at'].toString());
//       } catch (e) {
//         print('Error parsing created_at: ${json['created_at']}');
//         createdAt = DateTime.now();
//       }

//       try {
//         updatedAt = DateTime.parse(json['updated_at'].toString());
//       } catch (e) {
//         print('Error parsing updated_at: ${json['updated_at']}');
//         updatedAt = createdAt;
//       }

//       // Parse username dengan prioritas yang benar untuk setiap commenter
//       String username = 'Anonymous';

//       print('🔍 Parsing username for user_id: $userId');
//       print('🔍 Available JSON keys: ${json.keys.toList()}');

//       // Prioritas 1: Cek 'username' langsung
//       if (json.containsKey('username') &&
//           json['username'] != null &&
//           json['username'].toString().trim().isNotEmpty) {
//         username = json['username'].toString().trim();
//         print('✅ Username found in "username" field: "$username"');
//       }
//       // Prioritas 2: Cek dalam nested 'user' object
//       else if (json.containsKey('user') && json['user'] is Map) {
//         Map<String, dynamic> userObj = json['user'];
//         print('🔍 User object keys: ${userObj.keys.toList()}');

//         if (userObj.containsKey('username') &&
//             userObj['username'] != null &&
//             userObj['username'].toString().trim().isNotEmpty) {
//           username = userObj['username'].toString().trim();
//           print('✅ Username found in "user.username": "$username"');
//         } else if (userObj.containsKey('name') &&
//             userObj['name'] != null &&
//             userObj['name'].toString().trim().isNotEmpty) {
//           username = userObj['name'].toString().trim();
//           print('✅ Username found in "user.name": "$username"');
//         } else if (userObj.containsKey('full_name') &&
//             userObj['full_name'] != null &&
//             userObj['full_name'].toString().trim().isNotEmpty) {
//           username = userObj['full_name'].toString().trim();
//           print('✅ Username found in "user.full_name": "$username"');
//         } else if (userObj.containsKey('display_name') &&
//             userObj['display_name'] != null &&
//             userObj['display_name'].toString().trim().isNotEmpty) {
//           username = userObj['display_name'].toString().trim();
//           print('✅ Username found in "user.display_name": "$username"');
//         }
//       }
//       // Prioritas 3: Cek 'user_name'
//       else if (json.containsKey('user_name') &&
//           json['user_name'] != null &&
//           json['user_name'].toString().trim().isNotEmpty) {
//         username = json['user_name'].toString().trim();
//         print('✅ Username found in "user_name": "$username"');
//       }
//       // Prioritas 4: Cek 'author_name'
//       else if (json.containsKey('author_name') &&
//           json['author_name'] != null &&
//           json['author_name'].toString().trim().isNotEmpty) {
//         username = json['author_name'].toString().trim();
//         print('✅ Username found in "author_name": "$username"');
//       }
//       // Prioritas 5: Cek 'commenter_name'
//       else if (json.containsKey('commenter_name') &&
//           json['commenter_name'] != null &&
//           json['commenter_name'].toString().trim().isNotEmpty) {
//         username = json['commenter_name'].toString().trim();
//         print('✅ Username found in "commenter_name": "$username"');
//       }
//       // Prioritas 6: Cek 'name'
//       else if (json.containsKey('name') &&
//           json['name'] != null &&
//           json['name'].toString().trim().isNotEmpty) {
//         username = json['name'].toString().trim();
//         print('✅ Username found in "name": "$username"');
//       }

//       // Validasi final - jika masih kosong atau 'user', buat default berdasarkan user_id
//       if (username.isEmpty ||
//           username.toLowerCase() == 'user' ||
//           username.toLowerCase() == 'anonymous') {
//         username = 'User-$userId';
//         print('⚠️ Using fallback username: "$username"');
//       }

//       print('🎯 Final username for user_id $userId: "$username"');

//       // Parse likes
//       int likes = int.tryParse(json['likes']?.toString() ?? '0') ?? 0;
//       bool liked = json['liked'] == true || json['is_liked'] == true;

//       // Parse profile picture URL
//       String? profilePictureUrl;
//       if (json.containsKey('profile_picture_url')) {
//         profilePictureUrl = json['profile_picture_url']?.toString();
//       } else if (json.containsKey('user') && json['user'] is Map) {
//         profilePictureUrl = json['user']['profile_picture_url']?.toString();
//       }

//       print(
//           'Parsed Comment - ID: $commentId, User: $username, Content: $content');
//       print('==========================');

//       return Comment(
//         id: commentId,
//         postId: postId,
//         userId: userId,
//         content: content,
//         parentCommentId: parentCommentId,
//         createdAt: createdAt,
//         updatedAt: updatedAt,
//         username: username,
//         profilePictureUrl: profilePictureUrl,
//         likes: likes,
//         liked: liked,
//       );
//     } catch (e, stackTrace) {
//       print('Error parsing comment JSON: $e');
//       print('StackTrace: $stackTrace');
//       print('JSON yang error: $json');
//       rethrow;
//     }
//   }

//   // Method untuk convert ke JSON (untuk debugging)
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'post_id': postId,
//       'user_id': userId,
//       'content': content,
//       'parent_comment_id': parentCommentId,
//       'created_at': createdAt.toIso8601String(),
//       'updated_at': updatedAt.toIso8601String(),
//       'username': username,
//       'profile_picture_url': profilePictureUrl,
//       'likes': likes,
//       'liked': liked,
//     };
//   }

//   @override
//   String toString() {
//     return 'Comment{id: $id, username: $username, content: $content, likes: $likes}';
//   }
// }
