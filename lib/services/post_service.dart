// lib/services/post_service.dart
import 'api_service.dart';
import '../models/post_model.dart';

class PostService extends ApiService {
  PostService._internal();
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;

  /// Mengambil semua post untuk feed utama.
  Future<List<Post>> fetchAllPosts() async {
    // 1. Simpan hasil ke 'dynamic' terlebih dahulu
    final dynamic data = await get('posts');

    // 2. Lakukan pengecekan tipe data yang aman
    if (data is List) {
      return data.map((item) => Post.fromJson(item)).toList();
    } else {
      // Jika data null atau bukan list, kembalikan list kosong
      print(
          '⚠️ Peringatan: Endpoint /posts tidak mengembalikan List. Data: $data');
      return [];
    }
  }

  /// Mengambil post untuk halaman Explore dengan filter.
  Future<List<Post>> fetchExplorePosts(
      {String? tag, String sort = 'random'}) async {
    final queryParams = <String, String>{'sort': sort};
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }

    final dynamic data = await get('explore', queryParams: queryParams);

    if (data is List) {
      return data.map((item) => Post.fromJson(item)).toList();
    }

    // Kalau API kadang balikin Map dengan key 'posts'
    if (data is Map<String, dynamic> && data is List) {
      return (data as List).map((item) => Post.fromJson(item)).toList();
    }

    print("⚠️ Unexpected /explore response format: $data");
    return [];
  }

  /// Mengambil detail satu post.
  Future<Post> getPostDetail(int id) async {
    // 1. Simpan hasil ke 'dynamic' terlebih dahulu
    final dynamic data = await get('posts/$id');

    // 2. Lakukan pengecekan tipe data yang aman
    if (data is Map<String, dynamic>) {
      return Post.fromJson(data);
    } else {
      // Jika data null atau bukan Map, lempar error
      throw Exception('Format data untuk post #$id tidak valid.');
    }
  }

  /// Membuat post baru.
  Future<bool> createPost(Map<String, String> fields,
      {String? filePath}) async {
    await post('posts', body: fields);
    return true;
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
