import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/mood_entry.dart';
import 'mood_storage.dart';
import 'photo_storage.dart';

/// 로그인한 사용자의 기분 기록을 클라우드에 동기화한다.
///
/// - 기록(JSON)은 Firestore의 `users/{uid}/moods` 한 문서에 통째로 저장한다.
///   기분 기록은 전부 목록으로 읽는 규모라 문서 하나가 충분히 가볍다.
/// - 첨부 사진은 Storage의 `users/{uid}/photos`에 올리고, Firestore에는
///   파일명만 남긴다. 내려받을 때 로컬에 없는 사진만 받는다.
class MoodSyncService {
  static final MoodSyncService instance = MoodSyncService._();
  MoodSyncService._();

  static const _uploadedPhotosKey = 'uploaded_photos';

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  bool get isLoggedIn => _uid != null;

  DocumentReference<Map<String, dynamic>> get _moodsRef =>
      FirebaseFirestore.instance.doc('users/$_uid/moods');

  Reference get _photoRoot =>
      FirebaseStorage.instance.ref('users/$_uid/photos');

  /// 기기 기록을 클라우드로 올린다. 사진 중 아직 안 올린 것만 새로 올린다.
  Future<void> push(List<MoodEntry> entries) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _uploadNewPhotos(entries);
      await _moodsRef.set({
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } catch (_) {
      // 오프라인 등으로 실패해도 기기 저장본은 남아 있으니 조용히 넘어간다.
    }
  }

  /// 클라우드 기록을 읽어온다. 클라우드에 아직 아무것도 없으면 null.
  Future<List<MoodEntry>?> pull() async {
    if (!isLoggedIn) return null;
    try {
      final snapshot = await _moodsRef.get();
      final data = snapshot.data();
      if (data == null) return null;
      final raw = (data['entries'] as List).cast<Map<String, dynamic>>();
      final entries = raw.map(MoodEntry.fromJson).toList();
      await _downloadMissingPhotos(entries);
      return entries;
    } catch (_) {
      return null;
    }
  }

  /// 로그인 직후 로컬과 클라우드를 합쳐 양쪽에 저장한다.
  ///
  /// 같은 id의 기록은 클라우드 쪽이 최신이라고 보고 덮어 쓴다.
  Future<void> mergeAfterLogin() async {
    final cloud = await pull();
    final local = await MoodStorage().load();
    if (cloud == null) {
      // 첫 로그인: 기기에 있는 기록을 클라우드로 올린다.
      await push(local);
      return;
    }
    final byId = <String, MoodEntry>{for (final e in local) e.id: e};
    for (final e in cloud) {
      byId[e.id] = e;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    await MoodStorage().save(merged);
    await push(merged);
  }

  Future<void> _uploadNewPhotos(List<MoodEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final uploaded =
        (prefs.getStringList(_uploadedPhotosKey) ?? []).toSet();
    for (final entry in entries) {
      final fileName = entry.imageFileName;
      if (fileName == null || uploaded.contains(fileName)) continue;
      final file = File(PhotoStorage.pathFor(fileName));
      if (!file.existsSync()) continue;
      await _photoRoot.child(fileName).putFile(file);
      uploaded.add(fileName);
    }
    await prefs.setStringList(_uploadedPhotosKey, uploaded.toList());
  }

  Future<void> _downloadMissingPhotos(List<MoodEntry> entries) async {
    for (final entry in entries) {
      final fileName = entry.imageFileName;
      if (fileName == null) continue;
      final local = File(PhotoStorage.pathFor(fileName));
      if (local.existsSync()) continue;
      try {
        await _photoRoot.child(fileName).writeToFile(local);
      } catch (_) {
        // 클라우드에 없는 사진이면 건너뛴다.
      }
    }
  }
}
