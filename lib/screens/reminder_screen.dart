import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import '../services/live_activity_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/glass_switch.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  static const _dayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  ReminderSettings? _settings;
  Timer? _timeDebounce;
  bool _liveActivitySupported = false;
  bool _liveActivityOn = false;

  @override
  void initState() {
    super.initState();
    ReminderSettings.load().then((s) => setState(() => _settings = s));
    _loadLiveActivity();
  }

  Future<void> _loadLiveActivity() async {
    final supported = await LiveActivityService.isSupported();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _liveActivitySupported = supported;
      _liveActivityOn = prefs.getBool('live_activity_enabled') ?? false;
    });
  }

  Future<void> _toggleLiveActivity(bool value) async {
    HapticFeedback.selectionClick();
    setState(() => _liveActivityOn = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('live_activity_enabled', value);
    if (value) {
      await LiveActivityService.start();
    } else {
      await LiveActivityService.end();
    }
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

  void _schedulePersist(ReminderSettings next) {
    setState(() => _settings = next);
    _timeDebounce?.cancel();
    _timeDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _persist(next),
    );
  }

  void _onTimeChanged(DateTime dateTime) {
    _schedulePersist(
      _settings!.copyWith(hour: dateTime.hour, minute: dateTime.minute),
    );
  }

  void _onStartTimeChanged(DateTime dateTime) {
    _schedulePersist(
      _settings!.copyWith(
        startHour: dateTime.hour,
        startMinute: dateTime.minute,
      ),
    );
  }

  void _onEndTimeChanged(DateTime dateTime) {
    _schedulePersist(
      _settings!.copyWith(endHour: dateTime.hour, endMinute: dateTime.minute),
    );
  }

  Future<void> _toggleEnabled(bool value) async {
    HapticFeedback.selectionClick();
    if (value) {
      final granted = await NotificationService.instance.requestPermission();
      if (!granted) {
        if (mounted) {
          await showCupertinoDialog<void>(
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
          // 네이티브 스위치는 이미 켜졌으니 화면 상태대로 되돌려 맞춘다.
          if (mounted) setState(() {});
        }
        return;
      }
    }
    await _update(_settings!.copyWith(enabled: value));
  }

  Future<void> _toggleWeekday(int weekday) async {
    final days = Set<int>.from(_settings!.weekdays);
    if (days.contains(weekday)) {
      // 최소 한 요일은 유지 — 해제할 수 없다는 걸 진동으로 알린다.
      if (days.length == 1) {
        HapticFeedback.heavyImpact();
        return;
      }
      days.remove(weekday);
    } else {
      days.add(weekday);
    }
    HapticFeedback.selectionClick();
    await _update(_settings!.copyWith(weekdays: days));
  }

  Widget _modeChip({
    required ReminderMode mode,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    final foreground = selected
        ? CupertinoColors.white
        : CupertinoColors.label.resolveFrom(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _update(_settings!.copyWith(mode: mode));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? CupertinoTheme.of(context).primaryColor
                : CupertinoColors.tertiarySystemFill.resolveFrom(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intervalChip({
    required int interval,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 58,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? CupertinoTheme.of(context).primaryColor
              : CupertinoColors.tertiarySystemFill.resolveFrom(context),
        ),
        child: Text(
          '$interval분',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected
                ? CupertinoColors.white
                : CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return CupertinoPageScaffold(
      backgroundColor: kAppBackground,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: kNavBarBackground,
        middle: Text('설정'),
      ),
      child: settings == null
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.only(bottom: kBottomNavSpace),
                children: [
                  CupertinoListSection.insetGrouped(
                    backgroundColor: kListSectionBackground,
                    header: const Text('알림'),
                    children: [
                      CupertinoListTile(
                        title: const Text('알림 받기'),
                        trailing: GlassSwitch(
                          value: settings.enabled,
                          onChanged: _toggleEnabled,
                        ),
                      ),
                    ],
                  ),
                  if (_liveActivitySupported)
                    CupertinoListSection.insetGrouped(
                      backgroundColor: kListSectionBackground,
                      header: const Text('실시간 활동'),
                      footer: const Text(
                        '잠금화면과 다이나믹 아일랜드에 오늘 기분을 기록했는지 보여줍니다.',
                      ),
                      children: [
                        CupertinoListTile(
                          title: const Text('잠금화면에 표시'),
                          trailing: GlassSwitch(
                            value: _liveActivityOn,
                            onChanged: _toggleLiveActivity,
                          ),
                        ),
                      ],
                    ),
                  if (settings.enabled) ...[
                    CupertinoListSection.insetGrouped(
                      backgroundColor: kListSectionBackground,
                      header: const Text('방식'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _modeChip(
                                mode: ReminderMode.once,
                                icon: CupertinoIcons.bell,
                                label: '하루 한 번',
                                selected: settings.mode == ReminderMode.once,
                              ),
                              const SizedBox(width: 8),
                              _modeChip(
                                mode: ReminderMode.repeat,
                                icon: CupertinoIcons.repeat,
                                label: '반복',
                                selected: settings.mode == ReminderMode.repeat,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    CupertinoListSection.insetGrouped(
                      backgroundColor: kListSectionBackground,
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
                              final selected = settings.weekdays.contains(
                                weekday,
                              );
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
                                        ? CupertinoTheme.of(
                                            context,
                                          ).primaryColor
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
                                          : CupertinoColors.label.resolveFrom(
                                              context,
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (settings.mode == ReminderMode.once)
                      CupertinoListSection.insetGrouped(
                        backgroundColor: kListSectionBackground,
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
                      )
                    else
                      CupertinoListSection.insetGrouped(
                        backgroundColor: kListSectionBackground,
                        header: const Text('시간'),
                        footer: settings.endAfterStart
                            ? null
                            : const Text('종료 시간은 시작 시간보다 늦게 설정해주세요.'),
                        children: [
                          _TimePickerTile(
                            label: '시작',
                            initialDateTime: DateTime(
                              2000,
                              1,
                              1,
                              settings.startHour,
                              settings.startMinute,
                            ),
                            onDateTimeChanged: _onStartTimeChanged,
                          ),
                          _TimePickerTile(
                            label: '종료',
                            initialDateTime: DateTime(
                              2000,
                              1,
                              1,
                              settings.endHour,
                              settings.endMinute,
                            ),
                            onDateTimeChanged: _onEndTimeChanged,
                          ),
                        ],
                      ),
                    if (settings.mode == ReminderMode.repeat)
                      CupertinoListSection.insetGrouped(
                        backgroundColor: kListSectionBackground,
                        header: const Text('주기'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [10, 20, 30, 60]
                                  .map(
                                    (interval) => _intervalChip(
                                      interval: interval,
                                      selected:
                                          settings.intervalMinutes == interval,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _update(
                                          settings.copyWith(
                                            intervalMinutes: interval,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  .toList(),
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

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.initialDateTime,
    required this.onDateTimeChanged,
  });

  final String label;
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onDateTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: initialDateTime,
            onDateTimeChanged: onDateTimeChanged,
          ),
        ),
      ],
    );
  }
}
