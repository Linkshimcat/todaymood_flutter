import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 첨부 사진을 앱 문서 폴더에 보관한다.
///
/// iOS는 앱을 다시 설치하면 문서 폴더의 절대 경로가 바뀌므로 파일명만 저장하고,
/// 실제 경로는 실행할 때마다 다시 만든다.
class PhotoStorage {
  static late final Directory _dir;

  static Future<void> init() async {
    _dir = await getApplicationDocumentsDirectory();
  }

  static String pathFor(String fileName) => '${_dir.path}/$fileName';

  /// 고른 사진을 문서 폴더로 복사하고 저장된 파일명을 돌려준다.
  static Future<String> save(String sourcePath) async {
    final extension = sourcePath.split('.').last;
    final fileName = 'mood_${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(sourcePath).copy(pathFor(fileName));
    return fileName;
  }

  static Future<void> delete(String fileName) async {
    final file = File(pathFor(fileName));
    if (file.existsSync()) await file.delete();
  }
}
