class ApiEndpoints {
  static const String baseUrl = 'https://api-new.portalsi.com';

  // Laravel Broadcast + Reverb Endpoints
  static const String broadcastAuth = '/broadcasting/auth';
  static const String wsAuthenticate = '/api/websocket/authenticate';
  static const String wsUpdateActivity = '/api/websocket/update-activity';
  static const String wsDisconnect = '/api/websocket/disconnect';
  static const String wsOnlineStatus = '/api/websocket/online-status';
  static const String wsOnlineCount = '/api/websocket/online-count';
  static const String wsOnlineFollowers = '/api/websocket/online-followers';

  /// Build WebSocket URL (Laravel Reverb / Pusher protocol)
  static String getWebSocketUrl(String appKey, {int? port}) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;

    final portPart = (port != null) ? ':$port' : '';

    return '$scheme://$host$portPart/app/$appKey'
        '?protocol=7&client=js&version=7.0.0&flash=false';
  }
}
