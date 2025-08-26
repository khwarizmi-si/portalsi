// // lib/services/websocket_service.dart

// import 'dart:convert';
// import 'package:web_socket_channel/web_socket_channel.dart';

// class WebSocketService {
//   WebSocketChannel? _channel;
//   Stream? get stream => _channel?.stream;

//   final String _userId;

//   WebSocketService(this._userId);

//   void connect() {
//     try {
//       final uri = Uri.parse('wss://ws.portalsi.com?userId=$_userId');
//       _channel = WebSocketChannel.connect(uri);

//       print('✅ Berhasil terhubung ke WebSocket sebagai userId: $_userId');

//       // Dengarkan stream
//       _channel!.stream.listen(
//         (data) {
//           final message = parseMessage(data);
//           print('📥 Pesan diterima: $message');
//         },
//         onError: (error) {
//           print('❗ WebSocket error: $error');
//         },
//         onDone: () {
//           print('❌ Koneksi WebSocket selesai/diputus');
//         },
//       );
//     } catch (e) {
//       print('❌ Gagal terhubung ke WebSocket: $e');
//     }
//   }

//   void disconnect() {
//     _channel?.sink.close();
//     print('🔌 Koneksi WebSocket ditutup.');
//   }

//   Map<String, dynamic> parseMessage(String data) {
//     try {
//       final message = jsonDecode(data);
//       return message as Map<String, dynamic>;
//     } catch (e) {
//       print('Error parsing message: $e');
//       return {};
//     }
//   }
// }
