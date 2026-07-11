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
    Mood(emoji: '😮‍💨', label: '무기력', color: Color.fromARGB(255, 56, 14, 14)),
    Mood(emoji: '😜', label: '활발', color: Color.fromARGB(255, 0, 213, 255)),
    Mood(emoji: '🫩', label: '예민', color: Color.fromARGB(255, 114, 71, 152)),
  ];

  static Mood fromEmoji(String emoji) {
    return all.firstWhere((m) => m.emoji == emoji, orElse: () => all[2]);
  }
}
