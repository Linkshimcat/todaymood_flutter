import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:today_mood/main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ko_KR');
  });

  testWidgets('shows empty state, then records and lists a mood', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('아직 기록된 기분이 없어요.\n오늘의 기분을 기록해보세요!'), findsOneWidget);

    await tester.tap(find.text('기분 기록하기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('😄'));
    await tester.pump();

    await tester.enterText(find.byType(CupertinoTextField), '좋은 하루였다');
    await tester.tap(find.text('기록하기'));
    await tester.pumpAndSettle();

    expect(find.text('행복'), findsOneWidget);
    expect(find.text('좋은 하루였다'), findsOneWidget);
    expect(find.text('아직 기록된 기분이 없어요.\n오늘의 기분을 기록해보세요!'), findsNothing);
  });

  testWidgets('dragging the sheet down dismisses it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('기분 기록하기'));
    await tester.pumpAndSettle();

    expect(find.text('오늘 기분이 어떠세요?'), findsOneWidget);

    await tester.drag(find.text('오늘 기분이 어떠세요?'), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.text('오늘 기분이 어떠세요?'), findsNothing);
  });

  testWidgets('bell button opens reminder settings screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CupertinoIcons.bell));
    await tester.pumpAndSettle();

    expect(find.text('기록 알림'), findsOneWidget);
    expect(find.text('알림 받기'), findsOneWidget);
    // 알림이 꺼진 상태에서는 요일/시간 섹션이 보이지 않아야 한다.
    expect(find.text('요일'), findsNothing);
  });
}
