import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import package

import 'package:portal_si/pages/student_detail_page.dart';

class Student {
  final String id;
  final String name;
  final String photo;
  final int averageScore;

  Student({
    required this.id,
    required this.name,
    required this.photo,
    required this.averageScore,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['studentId'],
      name: json['name'],
      photo: json['photo'],
      averageScore: (json['averageScore'] as num).toInt(),
    );
  }
}


class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _selectedPlpFilter = 'Sepanjang Masa';

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Student>> _leaderboardFuture;
  List<Student> _fetchedStudents = [];
  List<Student> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });

    // Panggil fetchLeaderboard tanpa forceRefresh saat pertama kali load
    _leaderboardFuture = fetchLeaderboard();
  }

  // --- PERUBAHAN 1: Logika Fetching dengan Sistem Cache ---
  Future<List<Student>> fetchLeaderboard({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'leaderboardCache';

    // 1. Jika tidak dipaksa refresh, coba ambil dari cache dulu
    if (!forceRefresh && prefs.containsKey(cacheKey)) {
      final cachedData = prefs.getString(cacheKey);
      if (cachedData != null) {
        print("Data dimuat dari CACHE.");
        List<dynamic> body = jsonDecode(cachedData);
        List<Student> students = body.map((dynamic item) => Student.fromJson(item)).toList();
        // Update state untuk search
        if(mounted) setState(() => _fetchedStudents = students);
        return students;
      }
    }

    // 2. Jika dipaksa refresh atau cache kosong, ambil dari API
    print("Data dimuat dari API.");
    final response = await http.get(Uri.parse('https://santriboard.vercel.app/api/student/leaderboard'));

    if (response.statusCode == 200) {
      // Simpan hasil API ke cache
      await prefs.setString(cacheKey, response.body);

      List<dynamic> body = jsonDecode(response.body);
      List<Student> students = body.map((dynamic item) => Student.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _fetchedStudents = students;
        });
      }
      return students;
    } else {
      // Jika API gagal, coba fallback ke cache jika ada
      if (prefs.containsKey(cacheKey)) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null) {
          print("API Gagal, fallback ke CACHE.");
          List<dynamic> body = jsonDecode(cachedData);
          return body.map((dynamic item) => Student.fromJson(item)).toList();
        }
      }
      throw Exception('Failed to load leaderboard from API and no cache available.');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // --- PERUBAHAN 2: Fungsi reload sekarang memaksa refresh ---
  void _reloadData() {
    setState(() {
      _leaderboardFuture = fetchLeaderboard(forceRefresh: true);
    });
  }

  void _filterStudents(String query) {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    final List<Student> results = _fetchedStudents
        .where((student) => student.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (mounted) setState(() => _searchResults = results);
  }

  void _toggleSearch() {
    if (mounted) {
      setState(() {
        _isSearching = !_isSearching;
        if (!_isSearching) {
          _searchController.clear();
        }
      });
    }
  }

  void _navigateToDetail(String studentId) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeft,
        // child: StudentDetailPage(studentId: studentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                if (!_isSearching) _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    physics: _isSearching ? const NeverScrollableScrollPhysics() : null,
                    controller: _tabController,
                    children: [
                      _buildWeeklyRankingContent(),
                      _buildPlpRankingContent(),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSearching && _searchController.text.isNotEmpty && _searchResults.isNotEmpty)
              _buildSearchResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.1, 0.0),
              end: Offset.zero
          ).animate(animation);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _isSearching
            ? _buildSearchAppBar()
            : _buildDefaultAppBar(),
      ),
    );
  }

  Widget _buildDefaultAppBar() {
    return Row(
      key: const ValueKey('defaultAppBar'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'SI Board',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.grey[800]),
              onPressed: _toggleSearch,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey[800]),
              onPressed: _reloadData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAppBar() {
    return Row(
      key: const ValueKey('searchAppBar'),
      children: [
        Expanded(
          child: Container(
            height: 48,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari nama santri...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.close, color: Colors.grey[800]),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: const Color(0xFFFFFBF0),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final student = _searchResults[index];
            final photoUrl = 'https://api-new.portalsi.com/storage/photo/${student.photo}';

            return ListTile(
              leading: _buildProfileImage(photoUrl, radius: 20),
              title: Text(student.name),
              subtitle: Text('${student.averageScore} Poin'),
              onTap: () => _navigateToDetail(student.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalMargin = 24.0;
    const double innerPadding = 4.0;
    final double tabWidth = (screenWidth - (horizontalMargin * 2) - (innerPadding * 2)) / 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 16),
      padding: const EdgeInsets.all(innerPadding),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: AnimatedBuilder(
        animation: _tabController.animation!,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned(
                left: _tabController.animation!.value * tabWidth,
                child: Container(
                  width: tabWidth,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFC87B),
                    borderRadius: BorderRadius.circular(21),boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildTabItem('Poin Terbaik', 0),
                  _buildTabItem('Setiap PLP', 1),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              final Color selectedColor = Colors.white;
              final Color unselectedColor = Colors.grey[700]!;

              if (index == 0) {
                return Text(
                  title,
                  style: TextStyle(
                    color: Color.lerp(selectedColor, unselectedColor, _tabController.animation!.value),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              else {
                return Text(
                  title,
                  style: TextStyle(
                    color: Color.lerp(unselectedColor, selectedColor, _tabController.animation!.value),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyRankingContent() {
    return FutureBuilder<List<Student>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                Text('Gagal memuat data: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  onPressed: _reloadData,
                )
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final students = snapshot.data!.take(30).toList();

          if (students.isEmpty) {
            return const Center(child: Text('Tidak ada data peringkat.'));
          }

          final topThree = students.take(3).toList();
          final remaining = students.skip(3).toList();

          return RefreshIndicator(
            onRefresh: () async => _reloadData(),
            child: ListView(
              children: [
                _buildHeader(),
                _buildPodium(topThree),
                const SizedBox(height: 24),
                _buildRankingList(remaining),
              ],
            ),
          );
        } else {
          return const Center(child: Text('Tidak ada data.'));
        }
      },
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    String semesterText;
    String schoolYearText;
    DateTime semesterEndDate;

    if (now.month >= 7 && now.month <= 12) {
      semesterText = 'Semester 1';
      schoolYearText = '${now.year}-${now.year + 1}';
      semesterEndDate = DateTime(now.year, 12, 31);
    } else {
      semesterText = 'Semester 2';
      schoolYearText = '${now.year - 1}-${now.year}';
      semesterEndDate = DateTime(now.year, 6, 30);
    }

    final difference = semesterEndDate.difference(now);
    final daysRemaining = difference.inDays + 1;

    String countdownText;
    if (daysRemaining > 0) {
      countdownText = '$daysRemaining hari lagi';
    } else {
      countdownText = 'Semester telah berakhir';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$semesterText $schoolYearText',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            countdownText,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Student> topThree) {
    if (topThree.length < 3) {
      return const SizedBox(
          height: 150,
          child: Center(child: Text("Data tidak cukup untuk podium"))
      );
    }

    final studentRank1 = topThree[0];
    final studentRank2 = topThree[1];
    final studentRank3 = topThree[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumCard(studentRank2, 2),
          _buildPodiumCard(studentRank1, 1),
          _buildPodiumCard(studentRank3, 3),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String url, {double radius = 24.0}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: radius * 2,
          height: radius * 2,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.0),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Gagal memuat gambar: $url, Error: $error');
            return Icon(Icons.person, color: Colors.grey[400], size: radius * 1.5);
          },
        ),
      ),
    );
  }


  Widget _buildPodiumCard(Student student, int rank) {
    final bool isFirstPlace = rank == 1;
    final double elevation = isFirstPlace ? 20.0 : 10.0;
    final double height = isFirstPlace ? 140.0 : 120.0;

    final photoUrl = 'https://api-new.portalsi.com/storage/photo/${student.photo}';

    return GestureDetector(
      onTap: () => _navigateToDetail(student.id),
      child: Transform.translate(
        offset: Offset(0, isFirstPlace ? -20 : 0),
        child: Container(
          height: height,
          width: 100,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -10,
                top: -0,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.withOpacity(0.15),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileImage(photoUrl, radius: 24),
                    const SizedBox(height: 8),
                    Text(
                      student.name.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${student.averageScore} Poin',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingList(List<Student> remainingStudents) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(remainingStudents.length, (index) {
          final user = remainingStudents[index];
          final rank = index + 4;
          final photoUrl = 'https://api-new.portalsi.com/storage/photo/${user.photo}';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      fontSize: 16,
                    )
                ),
                const SizedBox(width: 16),
                _buildProfileImage(photoUrl, radius: 20),
              ],
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
                '${user.averageScore} Poin',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xA31060D1), fontSize: 14)
            ),
            onTap: () => _navigateToDetail(user.id),
          );
        }),
      ),
    );
  }

  Widget _buildPlpFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedPlpFilter,
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
            items: [
              'Sepanjang Masa',
              'Tahun Ini',
              'Terbaik QBS saat ini',
              'Terbaik FQ saat ini',
              'Terbaik Alumni'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (mounted) setState(() => _selectedPlpFilter = newValue!);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPlpRankingContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        _buildPlpFilterDropdown(),
        const SizedBox(height: 16),

        if (_selectedPlpFilter == 'Sepanjang Masa')
          _buildDefaultPlpContent()
        else
          _buildFilteredPlpContent(),
      ],
    );
  }

  Widget _buildDefaultPlpContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildRankingCategory(
            title: 'Terbaik Tahfidz',
            rankings: [
              {'name': 'Mark Rober', 'detail1': '30 Juz Ziyadah', 'detail2': '20 Juz Sanad'},
              {'name': 'Joseph Setiawan', 'detail1': '30 Juz Ziyadah', 'detail2': '20 Juz Sanad'},
              {'name': 'Mehmed', 'detail1': '30 Juz Ziyadah', 'detail2': '20 Juz Sanad'},
            ],
          ),
          const SizedBox(height: 24),
          _buildRankingCategory(title: 'Terbaik IT', rankings: [
            {'name': 'Linus Torvalds', 'detail1': 'Flutter Expert', 'detail2': 'Backend Pro'},
          ]),
          const SizedBox(height: 24),
          _buildRankingCategory(title: 'Terbaik Karakter', rankings: [
            {'name': 'Jane Doe', 'detail1': 'Disiplin', 'detail2': 'Kepemimpinan'},
          ]),
          const SizedBox(height: 24),
          _buildRankingCategory(title: 'Terbaik Bahasa', rankings: [
            {'name': 'Alex', 'detail1': 'English Master', 'detail2': 'Arabic Fluent'},
          ]),
        ],
      ),
    );
  }

  Widget _buildFilteredPlpContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.filter_list, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Menampilkan Peringkat Untuk',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedPlpFilter,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              '(Data untuk filter ini akan ditampilkan di sini)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingCategory({required String title, required List<Map<String, String>> rankings}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              ...List.generate(rankings.length, (index) {
                return _buildPlpRankItem(
                  rank: index + 1,
                  name: rankings[index]['name']!,
                  detail1: rankings[index]['detail1'] ?? '',
                  detail2: rankings[index]['detail2'] ?? '',
                );
              }),
              const Divider(height: 24),
              const Text(
                'Lihat Data Selengkapnya',
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlpRankItem({
    required int rank,
    required String name,
    required String detail1,
    required String detail2,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeft,
            // child: StudentDetailPage(studentId: '1'), // Placeholder ID
          ),
        );
        HapticFeedback.lightImpact();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            _buildProfileImage('https://i.pravatar.cc/150?img=$rank', radius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: '$rank. ',
                          style: TextStyle(color: Colors.brown.shade300),
                        ),
                        TextSpan(text: name),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if(detail1.isNotEmpty) _buildDetailChip(detail1, Colors.blue),
                      if(detail1.isNotEmpty) const SizedBox(width: 8),
                      if(detail2.isNotEmpty) _buildDetailChip(detail2, Colors.orange),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}