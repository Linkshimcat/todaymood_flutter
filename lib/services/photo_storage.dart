import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// 첨부 사진을 앱 문서 폴더에 보관한다.
///
/// iOS는 앱을 다시 설치하면 문서 폴더의 절대 경로가 바뀌므로 파일명만 저장하고,
/// 실제 경로는 실행할 때마다 다시 만든다. 로그인 상태에서는 같은 파일을
/// Supabase Storage(`mood-photos` 버킷)에도 올려 다른 기기와 동기화한다.
class PhotoStorage {
  static late final Directory _dir;
  static const _bucket = 'mood-photos';

  static Future<void> init() async {
    _dir = await getApplicationDocumentsDirectory();
  }

  static String pathFor(String fileName) => '${_dir.path}/$fileName';

  /// 고른 사진을 문서 폴더로 복사하고 저장된 파일명을 돌려준다.
  /// (클라우드 업로드는 저장 흐름을 마친 뒤 [upload]로 별도 수행한다)
  static Future<String> save(String sourcePath) async {
    final extension = sourcePath.split('.').last;
    final fileName = 'mood_${DateTime.now().microsecondsSinceEpoch}.$extension';
    await File(sourcePath).copy(pathFor(fileName));
    return fileName;
  }

  static Future<void> delete(String fileName) async {
    final file = File(pathFor(fileName));
    if (file.existsSync()) await file.delete();
    await _removeRemote(fileName);
  }

  /// 로컬 파일을 클라우드로 올린다. 로그인 상태가 아니면 아무것도 하지 않는다.
  static Future<void> upload(String fileName) async {
    final path = _remotePath(fileName);
    if (path == null) return;
    final file = File(pathFor(fileName));
    if (!file.existsSync()) return;
    try {
      await Supabase.instance.client.storage.from(_bucket).upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );
    } catch (_) {
      // 오프라인 — 다음 동기화 때 다시 올린다.
    }
  }

  /// 클라우드 기록의 사진을 로컬 캐시로 받아온다. 이미 있으면 그대로 둔다.
  static Future<void> ensureLocal(String fileName) async {
    final path = _remotePath(fileName);
    if (path == null) return;
    final local = File(pathFor(fileName));
    if (local.existsSync()) return;
    try {
      final bytes = await Supabase.instance.client.storage
          .from(_bucket)
          .download(path);
      await local.writeAsBytes(bytes, flush: true);
    } catch (_) {
      // 아직 클라우드에 없거나 오프라인 — 표시만 누락될 뿐 문제되지 않는다.
    }
  }

  static Future<void> _removeRemote(String fileName) async {
    final path = _remotePath(fileName);
    if (path == null) return;
    try {
      await Supabase.instance.client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // 클라우드에서 지우지 못해도 로컬 기록 삭제는 이미 끝났다.
    }
  }

  /// `{userId}/{fileName}` 형태의 스토리지 경로. 로그인 전이면 null.
  static String? _remotePath(String fileName) {
    if (!SupabaseConfig.isInitialized) return null;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return '${user.id}/$fileName';
  }
}
