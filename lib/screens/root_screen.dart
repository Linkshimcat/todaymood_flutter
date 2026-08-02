import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../services/mood_editor.dart';
import '../theme.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'reminder_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  static const _barHeight = 58.0;
  static const _addButtonSize = 52.0;
  // ⊕ 버튼은 바 정중앙에 놓는다.
  static const _addButtonX = 0.0;

  int _index = 0;
  // 값이 바뀌면 화면이 새로 만들어지면서 저장소를 다시 읽는다.
  int _refreshToken = 0;

  Widget get _currentScreen {
    switch (_index) {
      case 0:
        return HomeScreen(key: ValueKey('home-$_refreshToken'));
      case 1:
        return CalendarScreen(key: ValueKey('calendar-$_refreshToken'));
      default:
        return const ReminderScreen();
    }
  }

  void _selectTab(int index) {
    if (index == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = index);
  }

  Future<void> _addMood() async {
    if (!await createMoodEntry(context)) return;
    // 기록하면 목록으로 돌아가 방금 쓴 카드를 보여준다.
    setState(() {
      _index = 0;
      _refreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: _currentScreen),
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.paddingOf(context).bottom + 8,
          child: _buildBar(context),
        ),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        // ⊕ 버튼이 바 위로 솟기 때문에 그만큼 높이를 더 잡는다.
        height: _barHeight + 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: _barHeight,
                    decoration: BoxDecoration(
                      color: kNavBarBackground.resolveFrom(context),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: CupertinoColors.separator.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                    // 양쪽을 같은 너비로 나눠야 가운데 빈칸이 정확히 바 중앙에
                    // 오고, ⊕ 버튼도 거기에 맞아떨어진다.
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              _buildTab(
                                context,
                                0,
                                CupertinoIcons.house_fill,
                                '홈',
                              ),
                              _buildTab(
                                context,
                                1,
                                CupertinoIcons.calendar,
                                '달력',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 64), // ⊕ 자리
                        Expanded(
                          child: Row(
                            children: [
                              _buildTab(
                                context,
                                2,
                                CupertinoIcons.gear_alt_fill,
                                '설정',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(_addButtonX, -1),
              child: _buildAddButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final selected = _index == index;
    final color = selected
        ? CupertinoTheme.of(context).primaryColor
        : CupertinoColors.secondaryLabel.resolveFrom(context);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: _addMood,
      child: Container(
        width: _addButtonSize,
        height: _addButtonSize,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          CupertinoIcons.add,
          color: CupertinoColors.white,
          size: 26,
        ),
      ),
    );
  }
}
