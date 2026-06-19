class ApiEndpoints {
  /// Base URL for REST API calls.
  /// Override at build time via --dart-define API_BASE_URL=...
  /// to point at a local backend (e.g. http://127.0.0.1:8000).
  static const String baseUrl = bool.hasEnvironment('API_BASE_URL')
      ? String.fromEnvironment('API_BASE_URL')
      : 'https://api-new.portalsi.com';

  /// Convenience: baseUrl + /api suffix used by every service.
  static const String apiUrl = '$baseUrl/api';

  /// Convenience: baseUrl + /storage prefix for media files.
  static const String storageUrl = '$baseUrl/storage';

  /// Laravel Reverb / Pusher public app key (single source of truth).
  static const String reverbAppKey = 'fiouy3umnruqcwdsoxni';

  /// Single canonical WebSocket endpoint used by [WebSocketService].
  /// Reverb runs on a dedicated host, separate from the REST [baseUrl].
  static const String wsBaseUrl =
      'wss://ws.portalsi.com:443/app/$reverbAppKey';

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
