class MoodEntry {
  final String id;
  final DateTime date;
  final String emoji;
  final String note;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.emoji,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'emoji': emoji,
        'note': note,
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        emoji: json['emoji'] as String,
        note: json['note'] as String? ?? '',
      );
}
