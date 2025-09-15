import 'user_model.dart';

class GroupMessage {
  final int id;
  final String content;
  final User sender;
  final DateTime sentAt;
  // tambahkan properti lain (status, mediaUrl, dll)

  GroupMessage(
      {required this.id,
      required this.content,
      required this.sender,
      required this.sentAt});

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      content: json['content'],
      sender: User.fromJson(
          json['sender']), // Asumsi ada objek 'sender' di dalam data
      sentAt: DateTime.parse(json['sent_at']),
    );
  }
}
