import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import '../services/auth_service.dart';
import '../services/live_activity_service.dart';
import '../services/mood_storage.dart';
import '../services/mood_sync_service.dart';
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

  Future<void> _signIn() async {
    try {
      final signedIn = await AuthService.instance.signInWithGoogle();
      if (!signedIn || !mounted) return;
      HapticFeedback.selectionClick();
      // 로그인 직후 로컬 기록과 클라우드를 한 번 합쳐 준다.
      await MoodSyncService.instance.mergeAfterLogin();
    } catch (e, st) {
      debugPrint('Google sign-in failed: $e\n$st');
      if (!mounted) return;
      showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('로그인에 실패했어요'),
          content: Text('원인: $e\n네트워크나 Firebase 설정을 확인해주세요.'),
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
  }

  Future<void> _signOut() async {
    // 로그아웃 전에 아직 못 올린 로컬 변경을 클라우드로 올린다.
    final entries = await MoodStorage().load();
    await MoodSyncService.instance.push(entries);
    await AuthService.instance.signOut();
  }

  Widget _buildAccountSection(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      header: const Text('계정'),
      children: [
        AnimatedBuilder(
          animation: AuthService.instance,
          builder: (context, _) {
            final user = AuthService.instance.user;
            if (user == null) {
              return CupertinoListTile(
                leading: const Icon(
                  CupertinoIcons.person_crop_circle,
                  size: 30,
                ),
                title: const Text('Google로 로그인'),
                subtitle: const Text('기분 기록을 클라우드에 동기화해요'),
                trailing: const Icon(CupertinoIcons.chevron_right, size: 18),
                onTap: _signIn,
              );
            }
            return Column(
              children: [
                CupertinoListTile(
                  leading: _UserAvatar(photoUrl: user.photoURL),
                  title: Text(user.displayName ?? '로그인됨'),
                  subtitle: Text(user.email ?? ''),
                  trailing: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoTheme.of(context).primaryColor,
                  ),
                ),
                CupertinoListTile(
                  title: const Text('로그아웃'),
                  onTap: _signOut,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
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
                  _buildAccountSection(context),
                  CupertinoListSection.insetGrouped(
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

/// Google 프로필 사진을 동그랗게 자른다. 없거나 로딩에 실패하면 기본 아이콘.
class _UserAvatar extends StatelessWidget {
  final String? photoUrl;

  const _UserAvatar({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipOval(
      child: SizedBox(
        width: 30,
        height: 30,
        child: url == null
            ? Icon(
                CupertinoIcons.person_fill,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  CupertinoIcons.person_fill,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
      ),
    );
  }
}
