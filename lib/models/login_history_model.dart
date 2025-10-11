// lib/models/login_history_model.dart

class LoginHistory {
  final int id;
  final String device;
  final String? location;
  final DateTime loginAt;
  final bool isCurrentSession;

  LoginHistory({
    required this.id,
    required this.device,
    this.location,
    required this.loginAt,
    this.isCurrentSession = false,
  });

  factory LoginHistory.fromJson(Map<String, dynamic> json) {
    // API mungkin mengembalikan nama OS dan browser, kita gabungkan.
    String deviceName = json['user_agent'] ?? 'Perangkat Tidak Dikenal';

    return LoginHistory(
      id: json['id'],
      device: deviceName,
      location: json['location'],
      loginAt: DateTime.parse(json['login_at']),
      isCurrentSession: json['is_current_device'] ?? false,
    );
  }
}