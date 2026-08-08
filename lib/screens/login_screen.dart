import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_config.dart';
import '../theme.dart';

/// 구글 계정으로 로그인하는 화면.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _signInWithGoogle() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: supabaseRedirectUrl,
        // 인앱 브라우저(ASWebAuthenticationSession)는 시뮬레이터에서 안 열리거나
        // todaymood:// 리다이렉트를 가로채 세션을 못 받는다.
        // 외부 Safari로 열어야 딥링크로 돌아와 세션이 저장된다.
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // 로그인 성공 여부는 AuthGate가 onAuthStateChange로 감지해 화면을 바꾼다.
    } on PlatformException catch (e) {
      if (mounted) _showError('브라우저를 열지 못했습니다.', e.message);
    } on AuthException catch (e) {
      if (mounted) _showError('로그인에 실패했습니다.', e.message);
    } catch (_) {
      if (mounted) _showError('로그인에 실패했습니다.', null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String title, String? message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: kAppBackground,
      child: Stack(
        children: [
          // const Positioned.fill(child: _GlowBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _buildTitle(context),
                  const Spacer(flex: 2),
                  if (_loading)
                    const CupertinoActivityIndicator()
                  else
                    _buildGoogleButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    const violet = Color(0xFF9B7BFF);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, violet],
      ).createShader(bounds),
      child: Text(
        'TodayMood',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          height: 1.1,
          color: Color(0xFFFFFFFF),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _signInWithGoogle,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(27),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GoogleG(size: 22),
            const SizedBox(width: 12),
            Text(
              'Google로 계속하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 구글 로고의 색상 분할 G 아이콘 (Google 공식 브랜드 경로 사용).
class _GoogleG extends StatelessWidget {
  final double size;

  const _GoogleG({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _GoogleGPainter());
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);

    Path path(String d) => parseSvgPathData(d);

    void fill(String d, int color) {
      canvas.drawPath(path(d), Paint()..color = Color(color));
    }

    // 공식 Google "G"의 색상별 분할 경로.
    fill(
      'M23.49 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.47c-.29 1.48-1.14 2.73-2.4 3.58v3h3.86c2.26-2.09 3.56-5.17 3.56-8.82z',
      0xFF4285F4,
    );
    fill(
      'M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.86-3c-1.08.72-2.45 1.16-4.07 1.16-3.13 0-5.78-2.11-6.73-4.96H1.29v3.09C3.26 21.3 7.31 24 12 24z',
      0xFF34A853,
    );
    fill(
      'M5.27 14.29c-.25-.72-.38-1.49-.38-2.29s.14-1.57.38-2.29V6.62H1.29C.47 8.24 0 10.06 0 12s.47 3.76 1.29 5.38l3.98-3.09z',
      0xFFFBBC05,
    );
    fill(
      'M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.31 0 3.26 2.7 1.29 6.62l3.98 3.09C6.22 6.86 8.87 4.75 12 4.75z',
      0xFFEA4335,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleGPainter oldDelegate) => false;
}

/// 은은한 글로우가 감도는 배경.
// class _GlowBackground extends StatelessWidget {
//   const _GlowBackground();

//   @override
//   Widget build(BuildContext context) {
//     final primary = CupertinoTheme.of(context).primaryColor;
//     final background = kAppBackground.resolveFrom(context);
//     return DecoratedBox(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color.lerp(background, primary, 0.14)!,
//             background,
//           ],
//           stops: const [0.0, 0.6],
//         ),
//       ),
//       child: ClipRect(
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: Align(
//                 alignment: const Alignment(0, -1.8),
//                 child: _GlowBlob(
//                   color: primary.withValues(alpha: 0.16),
//                   size: 320,
//                 ),
//               ),
//             ),
//             Positioned.fill(
//               child: Align(
//                 alignment: const Alignment(0, 1.6),
//                 child: _GlowBlob(
//                   color: CupertinoColors.systemBlue
//                       .resolveFrom(context)
//                       .withValues(alpha: 0.10),
//                   size: 280,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
