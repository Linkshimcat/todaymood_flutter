import 'package:flutter/cupertino.dart';

class Mood {
  final String emoji;
  final String label;
  final Color color;

  const Mood({required this.emoji, required this.label, required this.color});

  static const List<Mood> all = [
    Mood(emoji: '😄', label: '행복', color: Color(0xFFFFD54F)),
    Mood(emoji: '🙂', label: '좋음', color: Color(0xFFAED581)),
    Mood(emoji: '😐', label: '보통', color: Color(0xFF90A4AE)),
    Mood(emoji: '😢', label: '슬픔', color: Color(0xFF64B5F6)),
    Mood(emoji: '😠', label: '화남', color: Color(0xFFE57373)),
    Mood(emoji: '😴', label: '피곤', color: Color(0xFFB39DDB)),
    Mood(emoji: '🤨', label: '의아', color: Color.fromARGB(255, 0, 0, 0)),
  ];

  static Mood fromEmoji(String emoji) {
    return all.firstWhere((m) => m.emoji == emoji, orElse: () => all[2]);
  }
}
