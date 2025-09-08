class ApiEndpoints {
  // Ganti dengan base URL API Anda
  static const String baseUrl = 'https://api-new.portalsi.com';

  // Endpoint Autentikasi Standar Laravel untuk Private Channel
  static const String broadcastAuth = '/broadcasting/auth';

  // Endpoint kustom Anda untuk WebSocket
  static const String wsAuthenticate = '/api/websocket/authenticate';
  static const String wsUpdateActivity = '/api/websocket/update-activity';
  static const String wsDisconnect = '/api/websocket/disconnect';
  static const String wsOnlineStatus =
      '/api/websocket/online-status'; // e.g., /online-status/{userId}
  static const String wsOnlineCount = '/api/websocket/online-count';
  static const String wsOnlineFollowers = '/api/websocket/online-followers';

  /// Mengembalikan URL WebSocket (WSS untuk HTTPS, WS untuk HTTP)
  static String getWebSocketUrl() {
    String url = baseUrl;
    if (url.startsWith('https')) {
      return url.replaceFirst('https', 'wss') + '/ws';
    }
    return url.replaceFirst('http', 'ws') + '/ws';
  }
}
