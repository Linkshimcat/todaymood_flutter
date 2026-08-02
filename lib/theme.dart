import 'package:flutter/cupertino.dart';

/// 네비게이션 바 배경.
///
/// Cupertino 기본값(0xF0F9F9F9)은 알파가 94%라 블러가 거의 드러나지 않고,
/// 라이트 모드에서는 그룹 배경색과 색이 겹쳐 경계가 보이지 않는다.
/// 알파를 70%로 낮춰 스크롤한 내용이 비치는 프로스티드 글래스로 만든다.
const kNavBarBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xB3FFFFFF),
  darkColor: Color(0xB31D1D1D),
);

/// 떠 있는 바텀 네비게이션이 가리는 높이. 각 화면은 스크롤 끝에 이만큼을
/// 비워둬야 마지막 카드가 바 뒤에 숨지 않는다.
const kBottomNavSpace = 108.0;
