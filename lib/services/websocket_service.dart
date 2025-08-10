import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  late WebSocketChannel _channel;

  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void connect(String chatId) {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://your-websocket-url.com/ws?chat_id=$chatId'),
      );
      _channel.stream.listen(
        (data) {
          _controller.sink.add(json.decode(data));
        },
        onError: (error) {
          _controller.sink.addError('WebSocket error: $error');
        },
        onDone: () {
          _controller.sink.addError('WebSocket disconnected');
        },
      );
    } catch (e) {
      _controller.sink.addError('Could not connect to WebSocket: $e');
    }
  }

  void dispose() {
    _channel.sink.close();
    _controller.close();
  }

  void sendTypingStatus(String chatId, bool isTyping) {
    final message = json.encode({
      'type': 'typing',
      'chat_id': chatId,
      'is_typing': isTyping,
    });
    _channel.sink.add(message);
  }
}
