import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/mood_storage.dart';
import '../services/supabase_config.dart';
import 'login_screen.dart';
import 'root_screen.dart';

/// 로그인 상태에 따라 [LoginScreen] 또는 [RootScreen]을 보여준다.
///
/// 앱 시작 직후 세션을 복원하는 동안에는 스플래시를 띄워 로그인 화면이
/// 깜빡이지 않게 한다. 구글 로그인이 끝나면 (SIGNED_IN) 기기에 저장돼 있던
/// 기록을 클라우드로 올리는 동기화를 한 번 수행한다.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _synced = false;

  void _handleAuth(AuthState state) {
    final signedIn = state.session != null;
    if (signedIn && !_synced) {
      _synced = true;
      MoodStorage.syncToCloud();
    } else if (!signedIn) {
      _synced = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Supabase가 초기화되지 않은 환경(테스트, 미설정 상태)에서는
    // 기존처럼 로컬 전용으로 동작한다.
    if (!SupabaseConfig.isInitialized) return const RootScreen();

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 첫 세션 복원이 끝나기 전에는 로그인 화면이 잠깐 보이지 않도록 로딩을 띄운다.
        if (!snapshot.hasData) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final state = snapshot.data!;
        _handleAuth(state);
        if (state.session != null) return const RootScreen();
        return const LoginScreen();
      },
    );
  }
}
