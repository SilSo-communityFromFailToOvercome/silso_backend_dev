import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KoreanAuthService {
  static final KoreanAuthService _instance = KoreanAuthService._internal();
  factory KoreanAuthService() => _instance;
  KoreanAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isSignInInProgress = false;

  // Backend server URL - update this with your actual backend URL
  static const String _backendUrl = 'http://172.18.142.109:3001';  // Real device (your computer's IP)

  // Initialize Kakao SDK
  static Future<void> initialize({
    required String kakaoAppKey, // JavaScript key for web
    String? nativeAppKey, // Native app key for mobile
  }) async {
    try {
      // Initialize Kakao SDK for mobile
      if (nativeAppKey != null) {
        KakaoSdk.init(nativeAppKey: nativeAppKey);
        print('✅ Kakao configuration set for mobile (Native key: ${nativeAppKey.substring(0, 8)}...)');
      } else {
        throw 'Native app key is required for mobile platforms';
      }
    } catch (e) {
      print('❌ Kakao SDK initialization failed: $e');
      rethrow;
    }
  }

  // Kakao Login for Mobile
  Future<UserCredential?> signInWithKakao() async {
    if (_isSignInInProgress) {
      print('⚠️ Kakao sign-in already in progress');
      return null;
    }
    
    _isSignInInProgress = true;

    try {
      print('🟡 Starting Kakao login process...');

      // Mobile implementation using Flutter SDK
      String accessToken = await _signInWithKakaoMobile();
      
      if (accessToken.isEmpty) {
        throw 'Failed to get Kakao access token';
      }

      print('✅ Kakao token obtained successfully');

      // Create custom token using backend server
      String customToken = await _createCustomTokenForKakao(accessToken);
      print('✅ Firebase custom token created');
      
      // Sign in to Firebase with custom token
      UserCredential credential = await _auth.signInWithCustomToken(customToken);
      print('✅ Firebase authentication successful');
      
      return credential;
    } catch (e) {
      print('❌ Kakao login failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw 'Cannot connect to backend server. Make sure the server is running and accessible from your device.';
      }
      throw 'Kakao login failed: ${e.toString()}';
    } finally {
      _isSignInInProgress = false;
    }
  }

  // Mobile Kakao login using Flutter SDK
  Future<String> _signInWithKakaoMobile() async {
    try {
      print('🟡 Starting mobile Kakao login...');
      
      // Check if Kakao Talk is installed and login via Kakao Talk
      bool isKakaoTalkAvailable = await isKakaoTalkInstalled();
      
      OAuthToken token;
      if (isKakaoTalkAvailable) {
        print('🟡 Logging in via Kakao Talk...');
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        print('🟡 Logging in via Kakao Account...');
        token = await UserApi.instance.loginWithKakaoAccount();
      }
      
      print('✅ Mobile Kakao login successful');
      return token.accessToken;
      
    } catch (e) {
      print('❌ Mobile Kakao login error: $e');
      rethrow;
    }
  }

  // Create custom token for Kakao using backend server
  Future<String> _createCustomTokenForKakao(String accessToken) async {
    try {
      print('🟡 Creating Firebase custom token via backend...');
      
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/kakao/custom-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'kakao_access_token': accessToken,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Backend server timeout. Please check if the server is running.';
        },
      );

      print('📡 Backend response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['firebase_custom_token'] != null) {
          print('✅ Custom token created successfully');
          print('⏱️ Processing time: ${data['processing_time_ms']}ms');
          return data['firebase_custom_token'];
        } else {
          throw 'Invalid response from backend server: ${data['message'] ?? 'Unknown error'}';
        }
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        throw 'Kakao access token is invalid or expired: ${data['message']}';
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        throw 'Bad request to backend server: ${data['message']}';
      } else if (response.statusCode >= 500) {
        final data = jsonDecode(response.body);
        throw 'Backend server error: ${data['message'] ?? 'Internal server error'}';
      } else {
        throw 'Backend server returned status ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      print('❌ Backend communication error: $e');
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('timeout')) {
        throw 'Cannot connect to authentication server. Please check your internet connection and ensure the backend server is running.';
      }
      
      rethrow;
    }
  }

  // Demo/Test login method for development
  Future<UserCredential?> signInWithKakaoDemo() async {
    if (_isSignInInProgress) return null;
    
    _isSignInInProgress = true;

    try {
      print('🟡 Starting Kakao DEMO login...');
      
      // Simulate getting a test token (in real app, this comes from Kakao OAuth)
      const String demoAccessToken = 'demo_kakao_access_token_for_testing';
      
      // Create custom token using backend server
      String customToken = await _createCustomTokenForKakao(demoAccessToken);
      print('✅ Firebase custom token created');
      
      // Sign in to Firebase with custom token
      UserCredential credential = await _auth.signInWithCustomToken(customToken);
      print('✅ Firebase authentication successful');
      
      return credential;
    } catch (e) {
      print('❌ Kakao demo login failed: $e');
      throw 'Kakao demo login failed: ${e.toString()}';
    } finally {
      _isSignInInProgress = false;
    }
  }

  // Check if user is already signed in with Kakao
  Future<bool> isKakaoSignedIn() async {
    try {
      // Check both Firebase and Kakao SDK
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if Kakao token is still valid
      try {
        await UserApi.instance.accessTokenInfo();
        return true;
      } catch (e) {
        // Kakao token expired or invalid
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Get stored Kakao access token
  Future<String?> getStoredKakaoToken() async {
    try {
      // Try to get the current access token from Kakao SDK
      final token = await TokenManagerProvider.instance.manager.getToken();
      return token?.accessToken;
    } catch (e) {
      return null;
    }
  }

  // Logout from Kakao services
  Future<void> signOutKakaoServices() async {
    try {
      print('🟡 Signing out from Kakao services...');
      
      // Logout from Kakao SDK
      await UserApi.instance.logout();
      
      print('✅ Kakao logout completed');
    } catch (e) {
      print('⚠️ Kakao services logout error: $e');
      // Don't throw error for logout - it's not critical
    }
  }

  // Handle OAuth callback - not needed for mobile
  Future<UserCredential?> handleOAuthCallbackOnly() async {
    // Not applicable for mobile - OAuth callbacks are handled differently
    return null;
  }

  // Check backend server health
  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_backendUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Backend server health check: ${data['status']}');
        return data['status'] == 'OK';
      }
      return false;
    } catch (e) {
      print('❌ Backend health check failed: $e');
      return false;
    }
  }
}