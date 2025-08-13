import 'package:firebase_auth/firebase_auth.dart';

class KoreanAuthService {
  static final KoreanAuthService _instance = KoreanAuthService._internal();
  factory KoreanAuthService() => _instance;
  KoreanAuthService._internal();

  // Stub implementations that throw unsupported errors
  static Future<void> initialize({
    required String kakaoAppKey,
    String? nativeAppKey,
  }) async {
    throw UnsupportedError('Platform not supported');
  }

  Future<UserCredential?> signInWithKakao() async {
    throw UnsupportedError('Platform not supported');
  }

  Future<UserCredential?> signInWithKakaoDemo() async {
    throw UnsupportedError('Platform not supported');
  }

  Future<bool> isKakaoSignedIn() async {
    return false;
  }

  Future<String?> getStoredKakaoToken() async {
    return null;
  }

  Future<void> signOutKakaoServices() async {
    // No-op for unsupported platforms
  }

  Future<UserCredential?> handleOAuthCallbackOnly() async {
    return null;
  }

  Future<bool> checkBackendHealth() async {
    return false;
  }
}