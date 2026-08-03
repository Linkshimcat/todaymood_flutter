import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google 로그인 상태를 들고 있는 싱글턴.
///
/// Firebase를 초기화한 뒤 [listen]을 호출해야 상태가 흐른다.
/// 설정 화면은 [ChangeNotifier]를 구독해 로그인/로그아웃을 반영한다.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._();
  AuthService._();

  bool _googleReady = false;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  void listen() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Google 로그인 준비(플랫폼별 clientId 로딩)는 한 번만 한다.
  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      // iOS에서 ID token을 받으려면 Firebase 서버 클라이언트 ID(웹 클라이언트 ID)가 필요하다.
      serverClientId:
          '1022845229279-edgmk43raspd3o7bf27ucdnccvaa6fc8.apps.googleusercontent.com',
    );
    _googleReady = true;
  }

  /// Google 로그인. 사용자가 취소하면 false.
  Future<bool> signInWithGoogle() async {
    await _ensureGoogleReady();
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return false;
        default:
          rethrow;
      }
    }
    final credential = GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    return true;
  }

  Future<void> signOut() async {
    if (_googleReady) {
      await GoogleSignIn.instance.signOut();
    }
    await FirebaseAuth.instance.signOut();
  }
}
