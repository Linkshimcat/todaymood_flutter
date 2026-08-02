// 선택 표시 검증용 임시 진입점 — 확인 후 삭제할 것.
import 'package:flutter/cupertino.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/root_screen.dart';
import 'services/photo_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');
  await PhotoStorage.init();
  runApp(
    const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(primaryColor: Color.fromARGB(255, 192, 80, 80)),
      home: RootScreen(),
    ),
  );
}
