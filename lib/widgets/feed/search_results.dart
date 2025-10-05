// lib/widgets/feed/search_results.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- 1. IMPORT PROVIDER
import 'package:portal_si/controllers/home_controller.dart'; // <-- 2. IMPORT CONTROLLER
import '../../models/user_model.dart';
import '../../utils/navigation_helper.dart';
import '../../utils/user_provider.dart';
import 'user_search_item.dart';
import '../../pages/other_profile_page.dart';

class SearchResults extends StatelessWidget {
  final bool isSearching;
  final List<User> searchResults;
  final Function(User)? onUserTap;

  const SearchResults({
    Key? key,
    required this.isSearching,
    required this.searchResults,
    this.onUserTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSearching && searchResults.isEmpty) {
      return _buildLoadingState(context);
    }

    // [PERBAIKAN] Ambil data user langsung dari HomeController, tidak perlu FutureBuilder
    final currentUser =
    // Panggil UserProvider, bukan HomeController
    Provider.of<UserProvider>(context, listen: false).currentUser;

    // Filter langsung di sini, lebih sederhana
    final filteredResults = searchResults.where((user) {
      // Akses properti .id langsung dari objek User
      return user.id != currentUser?.id;
    }).toList();

    // Tampilkan pesan jika setelah difilter hasilnya kosong
    if (filteredResults.isEmpty && !isSearching) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 106),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        // `user` sudah merupakan objek User, tidak perlu konversi
        final user = filteredResults[index];
        return UserSearchItem(
          user: user, // Kirim objek User langsung ke UserSearchItem
          onTap: () => NavigationHelper.navigateToProfile(context, user),
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context, User user) {
    // Panggil callback jika ada
    onUserTap?.call(user);

    // Akses properti .username langsung
    final username = user.username;
    if (username.isNotEmpty) {
      Navigator.pushNamed(context, '/other-profile',
          arguments: {'username': username});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username tidak tersedia')),
      );
    }
  }

  // Helper widget untuk loading state (tidak berubah)
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: CircularProgressIndicator(
                strokeWidth: 3, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 24),
          Text('Mencari pengguna...',
              style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helper widget untuk empty state (tidak berubah)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.person_search_rounded,
                    size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Pengguna Tidak Ditemukan',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text('Coba cari dengan kata kunci lain',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
