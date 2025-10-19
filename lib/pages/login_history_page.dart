// lib/pages/login_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/login_history_model.dart';
import '../services/history_service.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key});

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  late Future<List<LoginHistory>> _historiesFuture;
  final HistoryService _historyService = HistoryService();
  final Set<int> _selectedIds = {};
  bool _isLoggingOut = false;
  int _totalSelectableItems = 0;

  // Definisikan warna gradien Anda di sini
  final List<Color> _gradientColors = [
    Colors.orangeAccent.shade200, // Warna awal gradien
    Colors.deepOrange , // Warna akhir gradien
  ];

  @override
  void initState() {
    super.initState();
    _loadHistories();
  }

  void _loadHistories() {
    setState(() {
      _historiesFuture = _historyService.fetchLoginHistories();
    });
  }

  void _onSelectAll(bool? selected, List<LoginHistory> histories) {
    setState(() {
      if (selected == true) {
        _selectedIds.addAll(
            histories.where((h) => !h.isCurrentSession).map((h) => h.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  Future<void> _handleLogout() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoggingOut = true);

    try {
      final success =
      await _historyService.logoutSessions(_selectedIds.toList());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi yang dipilih berhasil dikeluarkan.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _selectedIds.clear();
        _loadHistories(); // Muat ulang daftar
      } else {
        throw Exception('Gagal melakukan logout dari server.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  // Helper untuk membangun UI per item riwayat
  Widget _buildHistoryItem(LoginHistory history) {
    final isSelected = _selectedIds.contains(history.id);
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      // Latar belakang Card menjadi putih
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Colors.teal.shade400, width: 2) // Border teal
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (!history.isCurrentSession) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(history.id);
              } else {
                _selectedIds.add(history.id);
              }
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                history.device.toLowerCase().contains('android') || history.device.toLowerCase().contains('ios')
                    ? Icons.phone_android_rounded
                    : Icons.desktop_windows_rounded,
                size: 40,
                color: Colors.teal.shade700, // Ikon menjadi teal
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.device,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (history.location != null)
                      Text(
                        history.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    Text(
                      DateFormat('MMMM d, yyyy \'at\' hh:mm a')
                          .format(history.loginAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (history.isCurrentSession)
                Chip(
                  label: const Text('Aktif'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                  labelStyle: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                  side: BorderSide.none,
                )
              else
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedIds.add(history.id);
                      } else {
                        _selectedIds.remove(history.id);
                      }
                    });
                  },
                  activeColor: Colors.teal.shade500, // Checkbox menjadi teal
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Riwayat Login"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<LoginHistory>>(
        future: _historiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Gagal memuat data: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat login.'));
          }

          final histories = snapshot.data!;

          LoginHistory? currentSession;
          try {
            currentSession = histories.firstWhere((h) => h.isCurrentSession);
          } catch (e) {
            // Biarkan currentSession null jika tidak ada
          }

          final otherSessions =
          histories.where((h) => !h.isCurrentSession).toList();
          _totalSelectableItems = otherSessions.length;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    if (currentSession != null) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text(
                            'Sesi Saat Ini',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                          child: _buildHistoryItem(currentSession)),
                    ],
                    if (otherSessions.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentSession == null
                                    ? 'Semua Sesi Login'
                                    : 'Sesi Lainnya',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              // Tombol 'Pilih Semua' dengan gradien
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: _gradientColors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ).createShader(bounds),
                                child: TextButton(
                                  onPressed: () => _onSelectAll(
                                      _selectedIds.length !=
                                          _totalSelectableItems,
                                      histories),
                                  child: Text(
                                    _selectedIds.length != _totalSelectableItems
                                        ? 'Pilih Semua'
                                        : 'Batal Pilih',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white, // Warna teks putih agar kontras dengan gradien
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return _buildHistoryItem(otherSessions[index]);
                        },
                        childCount: otherSessions.length,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  // Menggunakan Container untuk memberikan gradien ke tombol
                  child: Container(
                    width: double.infinity, // Membuat lebar penuh
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _gradientColors, // Gradien oranye
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      icon: _isLoggingOut
                          ? Container()
                          : const Icon(Icons.logout_rounded,
                          size: 20, color: Colors.white),
                      label: _isLoggingOut
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        'Keluarkan ${_selectedIds.length} Sesi',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _handleLogout,
                      // Styling ElevatedButton agar transparan untuk menampilkan gradien Container
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Sangat penting!
                        shadowColor: Colors.transparent, // Hilangkan shadow bawaan
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}