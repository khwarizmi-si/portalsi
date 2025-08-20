import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:page_transition/page_transition.dart';
import 'package:portal_si/pages/portfolio_pages.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';


// --- MODEL DATA DIPERBARUI UNTUK LEBIH ROBUST ---
class StudentDetail {
  final String id;
  final String name;
  final String? nickname;
  final String photo;
  final String? birthDate;
  final String level;
  final String pondok;
  final List<dynamic> projects;
  final List<StudentClass> classes;

  StudentDetail({
    required this.id,
    required this.name,
    this.nickname,
    required this.photo,
    this.birthDate,
    required this.level,
    required this.pondok,
    required this.projects,
    required this.classes,
  });

  factory StudentDetail.fromJson(Map<String, dynamic> json) {
    return StudentDetail(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Tidak ada data',
      nickname: json['nickname'],
      photo: json['photo'] ?? '',
      birthDate: json['birth_date'],

      // --- PERBAIKAN KUNCI DI SINI ---
      // Mengonversi semua kemungkinan tipe data (int, String, null) ke String
      level: json['level']?.toString() ?? '-',
      pondok: json['Pondok']?.toString() ?? '-',

      projects: json['projects'] ?? [],

      // Menggunakan kunci 'class' (lowercase)
      classes: (json['classes'] as List? ?? [])
          .map((c) => StudentClass.fromJson(c['class'] ?? {}))
          .toList(),
    );
  }
}

class StudentClass {
  final String name;
  final String division;

  StudentClass({required this.name, required this.division});

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    // --- PERBAIKAN KEDUA DI SINI ---
    // Mengambil nama divisi dari dalam objek 'division'
    final divisionData = json['division'] as Map<String, dynamic>?;

    return StudentClass(
      name: json['name'] ?? 'Tidak ada nama kelas',
      division: divisionData?['name'] ?? 'Tidak ada divisi',
    );
  }
}

// --- WIDGET UTAMA (TIDAK ADA PERUBAHAN SIGNIFIKAN) ---
class StudentDetailPage extends StatefulWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarCollapsed = false;
  late Future<StudentDetail> _studentDetailFuture;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    _studentDetailFuture = _fetchStudentDetail();

    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = true);
      } else if (_scrollController.offset <= 200 && _isAppBarCollapsed) {
        setState(() => _isAppBarCollapsed = false);
      }
    });
  }

  Future<StudentDetail> _fetchStudentDetail() async {
    final url = 'https://santriboard.vercel.app/api/student/${widget.studentId}';
    final response = await http.get(Uri.parse(url));

    print('Respons API Detail Santri: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];
      return StudentDetail.fromJson(data);
    } else {
      throw Exception('Gagal memuat detail santri');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFBF0),
      body: FutureBuilder<StudentDetail>(
        future: _studentDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final student = snapshot.data!;
            final photoUrl = 'https://api.portalsi.com/storage/photo/${student.photo}';

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(student, photoUrl),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoSantriCard(student),
                        const SizedBox(height: 20),
                        _buildPlpCard(student),
                        const SizedBox(height: 20),
                        _buildPortfolioCard(context, student),
                        const SizedBox(height: 20),
                        _buildTahfidzCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text("Tidak ada data"));
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(StudentDetail student, String photoUrl) {
    return SliverAppBar(
      expandedHeight: 280.0,
      backgroundColor: Color(0xFFFFFBF0),
      elevation: _isAppBarCollapsed ? 2.0 : 0.0,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _isAppBarCollapsed ? 1.0 : 0.0,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(photoUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                student.name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(photoUrl),
            ),
            const SizedBox(height: 16),
            Text(
              student.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(String? tgl) {
    if (tgl == null || tgl.isEmpty) return 'Tidak ada data';
    try {
      final parts = tgl.split('/');
      final formattedDateString = '${parts[2]}-${parts[1]}-${parts[0]}';
      final date = DateTime.parse(formattedDateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return tgl;
    }
  }

  Widget _buildInfoSantriCard(StudentDetail student) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Info Santri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, 'Nama Lengkap', student.name),
          _buildInfoRow(Icons.school_outlined, 'Kelas', 'Pondok ${student.pondok}, Level ${student.level}'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Lahir', _formatTanggal(student.birthDate)),
          _buildInfoRow(Icons.phone_outlined, 'Nomor Telepon', 'Tidak ada data'),
          _buildInfoRow(Icons.email_outlined, 'Email', 'Tidak ada data'),
        ],
      ),
    );
  }

  Widget _buildPlpCard(StudentDetail student) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.layers_outlined, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('PLP yang diikuti', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          if (student.classes.isEmpty)
            const Text('Santri tidak mengikuti PLP apapun saat ini.')
          else
            ...student.classes.map((kelas) => _buildPlpRow(Icons.computer, '${kelas.name} (${kelas.division})', isCurrent: true)).toList(),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(BuildContext context, StudentDetail student) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Portofolio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(student.projects.length.toString(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Portofolio yang dimiliki oleh santri ini.'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: PortfolioPage(studentName: student.name),
                          ),
                        );
                        HapticFeedback.lightImpact();
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                      child: const Text('lihat portofolio'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.orange.shade800, size: 20),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildPlpRow(IconData icon, String title, {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
          if (isCurrent) ... [
            const SizedBox(width: 8),
            Text('(saat ini)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget _buildTahfidzCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.menu_book, color: Colors.orange.shade800, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Tahfidz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
                'Data progres tahfidz tidak tersedia.',
                style: TextStyle(color: Colors.grey.shade600)
            ),
          )
        ],
      ),
    );
  }
}