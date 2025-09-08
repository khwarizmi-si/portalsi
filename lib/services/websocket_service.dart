import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:portal_si/config/api_endpoint.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:http/http.dart' as http;

class WebSocketService {
  // Singleton pattern
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // WebSocket connection & state
  WebSocketChannel? _channel;
  String? _socketId;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _authToken;
  String? _baseUrl;

  // Stream controllers
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<Map<String, dynamic>>? _notificationController;
  StreamController<Map<String, dynamic>>? _messageUpdateController;
  StreamController<Map<String, dynamic>>? _storyController;
  StreamController<Map<String, dynamic>>? _likeController;
  StreamController<Map<String, dynamic>>? _commentController;
  StreamController<Map<String, dynamic>>? _userStatusController;
  StreamController<bool>? _connectionStatusController;

  // Timers and reconnect logic
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 25);
  static const Duration _connectionTimeout = Duration(seconds: 15);

  // Getters for streams and state
  Stream<Map<String, dynamic>> get messageStream =>
      _messageController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get messageUpdateStream =>
      _messageUpdateController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get storyStream =>
      _storyController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get likeStream =>
      _likeController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get commentStream =>
      _commentController?.stream ?? const Stream.empty();
  Stream<Map<String, dynamic>> get userStatusStream =>
      _userStatusController?.stream ?? const Stream.empty();
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;
  String? get socketId => _socketId;

  void initialize(String baseUrl, String authToken) {
    _baseUrl = baseUrl;
    _authToken = authToken;
    _initializeControllers();
    print('WebSocketService initialized.');
  }

  void _initializeControllers() {
    _messageController = StreamController<Map<String, dynamic>>.broadcast();
    _notificationController =
        StreamController<Map<String, dynamic>>.broadcast();
    _messageUpdateController =
        StreamController<Map<String, dynamic>>.broadcast();
    _storyController = StreamController<Map<String, dynamic>>.broadcast();
    _likeController = StreamController<Map<String, dynamic>>.broadcast();
    _commentController = StreamController<Map<String, dynamic>>.broadcast();
    _userStatusController = StreamController<Map<String, dynamic>>.broadcast();
    _connectionStatusController = StreamController<bool>.broadcast();
  }

  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;
    if (_baseUrl == null || _authToken == null) {
      throw Exception('WebSocket service not initialized.');
    }

    _isConnecting = true;
    _connectionStatusController?.add(false);
    print('Connecting to WebSocket...');

    try {
      final wsUrl = ApiEndpoints.getWebSocketUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      await _channel!.ready.timeout(_connectionTimeout);

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: true,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionStatusController?.add(true);
      _startHeartbeat();
      print('✅ WebSocket connected successfully.');
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionStatusController?.add(false);
      print('❌ WebSocket connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final event = data['event'] as String?;
      final channel = data['channel'] as String?;
      final payload = data['data'];

      if (event == null) return;

      if (event == 'pusher:connection_established') {
        _socketId = jsonDecode(payload as String)['socket_id'];
        print('✅ Connection established with socket_id: $_socketId');
        return;
      }

      if (event == 'pusher_internal:subscription_succeeded') {
        print('✅ Subscribed to channel: $channel');
        return;
      }

      if (event == 'pusher:pong') return; // Heartbeat response

      if (payload != null) {
        Map<String, dynamic> payloadData =
            (payload is String) ? jsonDecode(payload) : payload;
        _routeEvent(event, payloadData);
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  void _routeEvent(String event, Map<String, dynamic> payload) {
    switch (event) {
      case 'NotificationCreated':
      case 'notification.created':
        _notificationController?.add(payload);
        break;
      // Add cases for new events
      case 'user.online':
      case 'user.offline':
        _userStatusController?.add({'event': event, 'data': payload});
        break;
      case 'story.created':
        _storyController?.add(payload);
        break;
      case 'like.created':
        _likeController?.add(payload);
        break;
      case 'comment.created':
        _commentController?.add(payload);
        break;
      // ... tambahkan case untuk event-event lain
      default:
        print('ℹ️ Unhandled event: $event');
    }
  }

  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    if (_isConnected) _handleDisconnection();
  }

  void _handleDisconnection() {
    print('🔌 WebSocket disconnected.');
    if (!_isConnected) return; // Mencegah pemanggilan ganda

    _isConnected = false;
    _isConnecting = false;
    _socketId = null;
    _connectionStatusController?.add(false);
    _stopHeartbeat();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('⛔ Max reconnection attempts reached.');
      return;
    }

    final delay = Duration(
        seconds: math.min(
            30,
            _reconnectDelay.inSeconds *
                math.pow(2, _reconnectAttempts).toInt()));
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      print('🔄 Attempting to reconnect... (attempt $_reconnectAttempts)');
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        _channel?.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  /// Subscribe to a channel. Auth signature is required for private/presence channels.
  void subscribeToChannel(String channelName, {String? authSignature}) {
    if (!_isConnected || _channel == null) {
      print('❌ Cannot subscribe: WebSocket not connected.');
      return;
    }

    final data = {'channel': channelName};
    if (authSignature != null) {
      data['auth'] = authSignature;
    }

    try {
      _channel!.sink
          .add(jsonEncode({'event': 'pusher:subscribe', 'data': data}));
      print('📡 Subscribing to channel: $channelName');
    } catch (e) {
      print('❌ Error subscribing to channel: $e');
    }
  }

  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    _reconnectAttempts = _maxReconnectAttempts; // Mencegah auto-reconnect
    await _channel?.sink.close(status.goingAway);
    _channel = null;
    if (_isConnected) _handleDisconnection();
  }

  void dispose() {
    disconnect();
    _messageController?.close();
    _notificationController?.close();
    _messageUpdateController?.close();
    _storyController?.close();
    _likeController?.close();
    _commentController?.close();
    _userStatusController?.close();
    _connectionStatusController?.close();
    print('✅ WebSocketService disposed.');
  }
}
