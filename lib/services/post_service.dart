// lib/services/post_service.dart
import 'api_service.dart';
import '../models/post_model.dart';

class PostService extends ApiService {
  // Singleton Pattern untuk memastikan hanya ada satu instance.
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  /// Mengambil semua post untuk feed utama.
  /// Mengembalikan List dari Model Post, bukan dynamic.
  Future<List<Post>> fetchAllPosts() async {
    final List<dynamic> data = await get('posts');
    return data.map((item) => Post.fromJson(item)).toList();
  }

  /// Mengambil post untuk halaman Explore dengan filter.
  Future<List<Post>> fetchExplorePosts(
      {String? tag, String sort = 'random'}) async {
    final queryParams = <String, String>{'sort': sort};
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }

    final dynamic data = await get('explore', queryParams: queryParams);

    // API explore bisa mengembalikan format berbeda, jadi kita tangani
    if (data is Map<String, dynamic> && data.containsKey('posts')) {
      final List<dynamic> postList = data['posts'];
      return postList.map((item) => Post.fromJson(item)).toList();
    } else if (data is List) {
      return data.map((item) => Post.fromJson(item)).toList();
    } else {
      throw Exception('Format respons Explore tidak dikenali');
    }
  }

  /// Mengambil detail satu post.
  Future<Post> getPostDetail(int id) async {
    final Map<String, dynamic> data = await get('posts/$id');
    return Post.fromJson(data);
  }

  /// Membuat post baru.
  Future<bool> createPost(Map<String, String> fields,
      {String? filePath}) async {
    // Note: Upload file (multipart request) lebih kompleks dan tidak dicakup
    // oleh helper `post` standar. Ini contoh untuk post berbasis JSON.
    await post('posts', body: fields);
    return true; // Sukses jika tidak ada exception
  }

  /// Memperbarui post yang ada.
  Future<bool> updatePost(int id, Map<String, dynamic> data) async {
    await put('posts/$id', body: data);
    return true;
  }

  /// Menghapus post.
  Future<bool> deletePost(int id) async {
    await delete('posts/$id');
    return true;
  }
}
