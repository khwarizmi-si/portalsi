// Letakkan kode ini di file baru (misal: lib/pages/close_friends_page.dart)
// Jangan lupa import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class CloseFriendsPage extends StatefulWidget {
  const CloseFriendsPage({super.key});

  @override
  State<CloseFriendsPage> createState() => _CloseFriendsPageState();
}

class _CloseFriendsPageState extends State<CloseFriendsPage> {
  // Data dummy untuk contoh, sesuai dengan gambar Anda
  final List<Map<String, String>> _suggestedFriends = [
    {'username': 'darkxwolf17._.-', 'name': 'mra774r', 'avatar': 'https://i.pravatar.cc/150?u=darkxwolf17'},
    {'username': 'stockbabai1123', 'name': 'STOCK BABA', 'avatar': 'https://i.pravatar.cc/150?u=stockbabai1123'},
    {'username': 'Danzgocrazy', 'name': 'DanzAlone', 'avatar': 'https://i.pravatar.cc/150?u=Danzgocrazy'},
    {'username': 'farmumz', 'name': 'farmumz', 'avatar': 'https://i.pravatar.cc/150?u=farmumz'},
    {'username': 'jbriiiiil', 'name': 'جبريل', 'avatar': ''}, // Contoh tanpa avatar
    {'username': 'faadil_mubarok', 'name': 'fdlmbrk_', 'avatar': 'https://i.pravatar.cc/150?u=faadil_mubarok'},
    {'username': 'e.fawwaz', 'name': 'zarr', 'avatar': 'https://i.pravatar.cc/150?u=e.fawwaz'},
    {'username': 'iqbbaalmaulana', 'name': 'iqbal', 'avatar': 'https://i.pravatar.cc/150?u=iqbbaalmaulana'},
    {'username': 'andra_rawrr', 'name': 'Jefii', 'avatar': 'https://i.pravatar.cc/150?u=andra_rawrr'},
  ];

  // Untuk melacak teman yang dipilih
  final Set<String> _selectedFriends = {};

  @override
  Widget build(BuildContext context) {
    // Scaffold membungkus halaman baru
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Warna latar belakang gelap
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Close Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[800], height: 1.0),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[850],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Label "Suggested"
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('Suggested', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          // Daftar Teman
          Expanded(
            child: ListView.builder(
              itemCount: _suggestedFriends.length,
              itemBuilder: (context, index) {
                final friend = _suggestedFriends[index];
                final isSelected = _selectedFriends.contains(friend['username']);
                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: friend['avatar']!.isNotEmpty ? NetworkImage(friend['avatar']!) : null,
                    child: friend['avatar']!.isEmpty ? const Icon(Icons.person, color: Colors.white70) : null,
                  ),
                  title: Text(friend['username']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(friend['name']!, style: TextStyle(color: Colors.grey[400])),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFriends.add(friend['username']!);
                        } else {
                          _selectedFriends.remove(friend['username']!);
                        }
                      });
                    },
                    shape: const CircleBorder(),
                    activeColor: Colors.blue,
                    checkColor: const Color(0xFF1C1C1E),
                    side: BorderSide(color: Colors.grey[600]!, width: 2),
                  ),
                );
              },
            ),
          ),
          // Tombol "Done"
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}