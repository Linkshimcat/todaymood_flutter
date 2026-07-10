import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;
  final Set<int> weekdays; // DateTime.monday(1) ~ DateTime.sunday(7)

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.weekdays,
  });

  static const defaults = ReminderSettings(
    enabled: false,
    hour: 21,
    minute: 0,
    weekdays: {1, 2, 3, 4, 5, 6, 7},
  );

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    Set<int>? weekdays,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
    );
  }

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool('reminder_enabled') ?? defaults.enabled,
      hour: prefs.getInt('reminder_hour') ?? defaults.hour,
      minute: prefs.getInt('reminder_minute') ?? defaults.minute,
      weekdays:
          prefs
              .getStringList('reminder_weekdays')
              ?.map(int.parse)
              .toSet() ??
          defaults.weekdays,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
    await prefs.setStringList(
      'reminder_weekdays',
      weekdays.map((d) => d.toString()).toList(),
    );
  }
}
