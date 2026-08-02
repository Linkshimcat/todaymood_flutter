import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// 선택된 탭 뒤로 미끄러지는 표시.
///
/// 탭이 바뀌면 자리로 흐르듯 미끄러지는데, 지나가는 동안 앞으로 늘어났다가
/// (scaleX 확대) 목적지에서 살짝 지나쳤다 돌아오는(오버슛) 액체 느낌을 준다.
class LiquidIndicator extends StatefulWidget {
  const LiquidIndicator({
    super.key,
    required this.index,
    required this.tabCount,
  });

  /// 현재 선택된 탭 번호.
  final int index;

  /// 탭 개수. 탭 칸이 모두 같은 너비라고 가정한다.
  final int tabCount;

  @override
  State<LiquidIndicator> createState() => LiquidIndicatorState();
}

class LiquidIndicatorState extends State<LiquidIndicator>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 600);

  late final AnimationController _controller;
  double _start = 0;
  double _end = 0;

  /// 현재 표시가 가리키는 위치(Alignment.x 좌표). 테스트가 읽는다.
  double get alignment => _end;

  /// 폭 1/tabCount 박스의 중심이 i번째 칸 중심 (i+0.5)/tabCount에 오려면
  /// Align은 (부모-자식) × (alignment+1)/2 만큼 밀어 놓으므로 alignment가
  /// i - (tabCount-1)/2 이어야 한다.
  double _targetFor(int index) => (index - (widget.tabCount - 1) / 2).toDouble();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _end = _targetFor(widget.index);
    _start = _end;
  }

  @override
  void didUpdateWidget(covariant LiquidIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _animateTo(widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 흐르던 지점에서 [index] 탭으로 다시 흐르게 한다.
  void _animateTo(int index) {
    final t = _controller.value;
    final eased = Curves.easeOutBack.transform(t);
    _start = _start + (_end - _start) * eased;
    _end = _targetFor(index);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final x = _start + (_end - _start) * Curves.easeOutBack.transform(t);
        // 속도가 가장 빠른 중간 지점에서 늘어났다가 자리에 오면 돌아온다.
        final flow = math.sin(math.pi * t);

        return Align(
          alignment: Alignment(x, 0),
          child: FractionallySizedBox(
            widthFactor: 1 / widget.tabCount,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Transform.scale(
                scaleX: 1 + 0.16 * flow,
                scaleY: 1 - 0.08 * flow,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kTabIndicator.resolveFrom(context),
                    borderRadius: BorderRadius.circular(999),
                    // 살짝 떠 있는 느낌을 줘야 유리 위에 얹힌 것처럼 보인다.
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
