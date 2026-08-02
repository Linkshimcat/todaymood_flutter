import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// iOS에서는 네이티브 Liquid Glass 머티리얼을, 그 밖에서는 블러로 대체한 배경.
///
/// Flutter는 자체 렌더러로 그리기 때문에 유리 재질을 직접 만들 수 없다.
/// iOS에서는 플랫폼 뷰를 깔고 그 위에 Flutter 위젯을 얹는다.
class GlassSurface extends StatelessWidget {
  /// 캡슐(양끝이 완전히 둥근) 모양인지. false면 [radius]를 쓴다.
  final bool capsule;
  final double radius;
  final Widget child;

  const GlassSurface({
    super.key,
    this.capsule = true,
    this.radius = 26,
    required this.child,
  });

  BorderRadius get _borderRadius => capsule
      ? BorderRadius.circular(999)
      : BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) return _fallback(context);

    return Stack(
      // 유리와 그 위 내용이 모두 부모 크기를 그대로 채우게 한다.
      fit: StackFit.expand,
      children: [
        UiKitView(
          viewType: 'today_mood/glass',
          creationParams: {
            'capsule': capsule,
            'radius': radius,
            'interactive': true,
          },
          creationParamsCodec: const StandardMessageCodec(),
          // 유리는 배경일 뿐이고 탭은 위에 얹힌 Flutter 위젯이 받는다.
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        ),
        child,
      ],
    );
  }

  /// iOS가 아니거나 플랫폼 뷰를 못 쓸 때의 근사치.
  Widget _fallback(BuildContext context) {
    return ClipRRect(
      borderRadius: _borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground
                .resolveFrom(context)
                .withValues(alpha: 0.7),
            borderRadius: _borderRadius,
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
