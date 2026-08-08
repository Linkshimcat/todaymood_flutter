import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/auth_gate.dart';
import 'services/notification_service.dart';
import 'services/photo_storage.dart';
import 'services/supabase_config.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 세로 모드 고정 — 플랫폼 설정과 함께 가로 회전을 막는다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SupabaseConfig.initialize();
  await initializeDateFormatting('ko_KR');
  await PhotoStorage.init();
  await NotificationService.instance.init();
  // 앱을 껐다 켜는 사이 기록이 바뀌었을 수 있으니 위젯을 한 번 맞춰둔다.
  await WidgetService.refresh();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: '오늘의 기분은?',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: Color.fromARGB(255, 192, 80, 80),
      ),
      home: AuthGate(),
    );
  }
}
