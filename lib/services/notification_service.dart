import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  /// 설정된 요일들에 매주 반복되는 알림을 예약한다.
  /// 요일 값(1=월 ~ 7=일)을 알림 id로 사용한다.
  Future<void> apply(ReminderSettings settings) async {
    await _plugin.cancelAll();
    if (!settings.enabled) return;

    if (settings.mode == ReminderMode.once) {
      await _scheduleOnce(settings);
    } else {
      await _scheduleRepeating(settings);
    }
  }

  Future<void> _scheduleOnce(ReminderSettings settings) async {
    const details = _details;
    for (final weekday in settings.weekdays) {
      await _plugin.zonedSchedule(
        id: weekday,
        title: '오늘 기분이 어떠세요? 🙂',
        body: '오늘의 기분을 카드로 기록해보세요',
        scheduledDate: _nextInstanceOf(weekday, settings.hour, settings.minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  /// 시작~종료 구간을 주기 간격으로 나눠 알림을 예약한다.
  /// 각 알림은 같은 요일·시간에 매주 반복된다.
  Future<void> _scheduleRepeating(ReminderSettings settings) async {
    if (!settings.endAfterStart) return;

    var id = 1000;
    final endMinuteOfDay = settings.endHour * 60 + settings.endMinute;
    for (final weekday in settings.weekdays) {
      var scheduled = _nextInstanceOf(
        weekday,
        settings.startHour,
        settings.startMinute,
      );
      while (scheduled.hour * 60 + scheduled.minute < endMinuteOfDay) {
        await _plugin.zonedSchedule(
          id: id++,
          title: '오늘도 기록해볼까요? 🙂',
          body: '오늘의 기분을 카드로 기록해보세요',
          scheduledDate: scheduled,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        scheduled = scheduled.add(
          Duration(minutes: settings.intervalMinutes),
        );
      }
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'mood_reminder',
      '기분 기록 알림',
      channelDescription: '설정한 시간에 기분 기록을 알려줍니다',
    ),
    iOS: DarwinNotificationDetails(),
  );

  tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
