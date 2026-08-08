import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../services/mood_editor.dart';
import '../services/platform_info.dart';
import '../widgets/glass_surface.dart';
import '../widgets/native_tab_bar.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'reminder_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  // 네이티브 UITabBar의 자연 높이(intrinsicContentSize = 83pt). [+]도 캡슐
  // 안의 4번째 아이템이므로 별도 정렬은 필요 없다.
  static const _barHeight = 83.0;

  int _index = 0;
  // 값이 바뀌면 화면이 새로 만들어지면서 저장소를 다시 읽는다.
  int _refreshToken = 0;
  // null이면 아직 판별 전. iOS가 아니면 항상 Flutter 바를 쓴다.
  bool? _useNativeBar;

  @override
  void initState() {
    super.initState();
    _initNativeBar();
  }

  Future<void> _initNativeBar() async {
    final native = await PlatformInfo.supportsNativeLiquidGlass;
    if (!mounted) return;
    setState(() => _useNativeBar = native);
  }

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
    // 바텀 시트 같은 모달이 떠 있으면 유리 바가 위로 새어 보인다.
    // (iOS 플랫폼 뷰는 Flutter의 반투명 배리어에 가려지지 않는다)
    final coveredByModal = !(ModalRoute.of(context)?.isCurrent ?? true);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final useNativeBar = _useNativeBar ?? false;

    return Stack(
      children: [
        Positioned.fill(child: _currentScreen),
        if (!coveredByModal && useNativeBar)
          if (!keyboardUp)
            _buildNativeBar(bottomInset)
          else
            const SizedBox.shrink(),
        if (!coveredByModal && !useNativeBar)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            child: _buildBar(context),
          ),
      ],
    );
  }

  Widget _buildNativeBar(double bottomInset) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomInset -30,
      height: _barHeight,
      child: NativeTabBar(
        selectedIndex: _index,
        onSelect: _selectTab,
        onAdd: _addMood,
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: _barHeight,
        child: Row(
          children: [
            // 탭 세 개를 담은 캡슐.
            Expanded(
              child: GlassSurface(
                child: Row(
                  children: [
                    _buildTab(context, 0, CupertinoIcons.house_fill, '홈'),
                    _buildTab(context, 1, CupertinoIcons.calendar, '달력'),
                    _buildTab(
                      context,
                      2,
                      CupertinoIcons.gear_alt_fill,
                      '설정',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 캡슐에서 떨어져 나온 원형 기록 버튼.
            SizedBox(
              width: _barHeight,
              height: _barHeight,
              child: GlassSurface(child: _buildAddButton(context)),
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

  /// 유리 위에 아이콘만 올린다 — 배경은 GlassSurface가 그린다.
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _addMood,
      child: Center(
        child: Icon(
          CupertinoIcons.add,
          size: 26,
          color: CupertinoTheme.of(context).primaryColor,
        ),
      ),
    );
  }
}
