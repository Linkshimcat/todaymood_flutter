class MoodEntry {
  final String id;
  final DateTime date;
  final List<String> emojis;
  final String note;
  final String? imageFileName;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.emojis,
    this.note = '',
    this.imageFileName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'emojis': emojis,
    'note': note,
    'imageFileName': imageFileName,
  };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    // 'emoji'(단일)는 복수 선택 이전에 저장된 기록의 형식이다.
    emojis: json['emojis'] != null
        ? (json['emojis'] as List).cast<String>()
        : [json['emoji'] as String],
    note: json['note'] as String? ?? '',
    imageFileName: json['imageFileName'] as String?,
  );
}
