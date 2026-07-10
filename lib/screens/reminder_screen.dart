import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../models/reminder_settings.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  ReminderSettings? _settings;
  Timer? _timeDebounce;

  @override
  void initState() {
    super.initState();
    ReminderSettings.load().then((s) => setState(() => _settings = s));
  }

  @override
  void dispose() {
    // 시간 휠을 돌리다 바로 화면을 나가도 마지막 값이 저장되도록 한다.
    if (_timeDebounce?.isActive ?? false) {
      _timeDebounce!.cancel();
      _persist(_settings!);
    }
    super.dispose();
  }

  Future<void> _persist(ReminderSettings settings) async {
    await settings.save();
    await NotificationService.instance.apply(settings);
  }

  Future<void> _update(ReminderSettings next) async {
    setState(() => _settings = next);
    await _persist(next);
  }

  void _onTimeChanged(DateTime dateTime) {
    final next = _settings!.copyWith(
      hour: dateTime.hour,
      minute: dateTime.minute,
    );
    setState(() => _settings = next);
    _timeDebounce?.cancel();
    _timeDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _persist(next),
    );
  }

  Future<void> _toggleEnabled(bool value) async {
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          showCupertinoDialog<void>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('알림 권한이 필요해요'),
              content: const Text('설정 앱에서 이 앱의 알림을 허용해주세요.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }
    await _update(_settings!.copyWith(enabled: value));
  }

  Future<void> _toggleWeekday(int weekday) async {
    final days = Set<int>.from(_settings!.weekdays);
    if (days.contains(weekday)) {
      if (days.length == 1) return; // 최소 한 요일은 유지
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    await _update(_settings!.copyWith(weekdays: days));
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('기록 알림'),
      ),
      child: settings == null
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView(
                children: [
                  CupertinoListSection.insetGrouped(
                    children: [
                      CupertinoListTile(
                        title: const Text('알림 받기'),
                        trailing: CupertinoSwitch(
                          value: settings.enabled,
                          onChanged: _toggleEnabled,
                        ),
                      ),
                    ],
                  ),
                  if (settings.enabled) ...[
                    CupertinoListSection.insetGrouped(
                      header: const Text('요일'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(7, (i) {
                              final weekday = i + 1;
                              final selected =
                                  settings.weekdays.contains(weekday);
                              return GestureDetector(
                                onTap: () => _toggleWeekday(weekday),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 38,
                                  height: 38,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? CupertinoTheme.of(context)
                                            .primaryColor
                                        : CupertinoColors.tertiarySystemFill
                                            .resolveFrom(context),
                                  ),
                                  child: Text(
                                    _dayLabels[i],
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? CupertinoColors.white
                                          : CupertinoColors.label
                                              .resolveFrom(context),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    CupertinoListSection.insetGrouped(
                      header: const Text('시간'),
                      children: [
                        SizedBox(
                          height: 200,
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            initialDateTime: DateTime(
                              2000,
                              1,
                              1,
                              settings.hour,
                              settings.minute,
                            ),
                            onDateTimeChanged: _onTimeChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
