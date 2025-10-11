// lib/pages/login_history_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml
import '../models/login_history_model.dart';
import '../services/history_service.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({Key? key}) : super(key: key);

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  late Future<List<LoginHistory>> _historiesFuture;
  final HistoryService _historyService = HistoryService();
  final Set<int> _selectedIds = {};
  bool _isLoggingOut = false;
  int _totalItems = 0; // Untuk 'Select All'

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

  void _onSelectAll(bool? selected) {
    if (selected == true) {
      _historiesFuture.then((histories) {
        setState(() {
          _selectedIds.addAll(histories.where((h) => !h.isCurrentSession).map((h) => h.id));
        });
      });
    } else {
      setState(() {
        _selectedIds.clear();
      });
    }
  }

  Future<void> _handleLogout() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoggingOut = true);

    try {
      final success = await _historyService.logoutSessions(_selectedIds.toList());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi yang dipilih berhasil dikeluarkan.'), backgroundColor: Colors.green),
        );
        _selectedIds.clear();
        _loadHistories(); // Muat ulang daftar
      } else {
        throw Exception('Gagal melakukan logout dari server.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Histori Login", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () => _onSelectAll(_selectedIds.length != _totalItems),
            child: const Text('Pilih Semua', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: FutureBuilder<List<LoginHistory>>(
        future: _historiesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada riwayat login.'));
          }

          final histories = snapshot.data!;
          _totalItems = histories.where((h) => !h.isCurrentSession).length;


          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Logins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    final isSelected = _selectedIds.contains(history.id);

                    return ListTile(
                      leading: Icon(
                          history.device.toLowerCase().contains('android')
                              ? Icons.phone_android_outlined
                              : Icons.desktop_windows_outlined,
                          size: 30
                      ),
                      title: Text(history.device, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (history.location != null) Text(history.location!),
                          Text(DateFormat('MMMM d \'at\' hh:mm a').format(history.loginAt)),
                          if (history.isCurrentSession)
                            const Text('Active now', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: history.isCurrentSession
                          ? null
                          : Checkbox(
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
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty || _isLoggingOut ? null : _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoggingOut
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Hapus Riwayat', style: TextStyle(fontSize: 16, color: Colors.white)),
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