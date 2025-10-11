// lib/models/emoji_model.dart
class Emoji {
  final String emoji;
  final String label;
  final int group;

  Emoji({required this.emoji, required this.label, required this.group});

  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      emoji: json['emoji'] as String,
      label: json['label'] as String,
      group: json['group'] as int,
    );
  }
}