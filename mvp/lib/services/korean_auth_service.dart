import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:js' as js;

class KoreanAuthService {
  static final KoreanAuthService _instance = KoreanAuthService._internal();
  factory KoreanAuthService() => _instance;
  KoreanAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isSignInInProgress = false;
  String? _kakaoAppKey; // JavaScript key for web
  String? _nativeAppKey; // Native app key for mobile

  // Backend server URL - update this with your actual backend URL
  static const String _backendUrl = kIsWeb 
      ? 'http://localhost:3001'  // Development
      : 'http://10.0.2.2:3001';  // Android emulator

  // Initialize Kakao SDK
  static Future<void> initialize({
    required String kakaoAppKey, // JavaScript key for web
    String? nativeAppKey, // Native app key for mobile
  }) async {
    try {
      final service = KoreanAuthService();
      service._kakaoAppKey = kakaoAppKey;
      service._nativeAppKey = nativeAppKey;
      
      if (kIsWeb) {
        print('✅ Kakao configuration set for web (JavaScript key: ${kakaoAppKey.substring(0, 8)}...)');
      } else {
        print('✅ Kakao configuration set for mobile (Native key: ${nativeAppKey?.substring(0, 8) ?? 'not provided'}...)');
      }
    } catch (e) {
      print('❌ Kakao SDK initialization failed: $e');
      rethrow;
    }
  }

  // Kakao Login for Web and Mobile
  Future<UserCredential?> signInWithKakao() async {
    if (_isSignInInProgress) {
      print('⚠️ Kakao sign-in already in progress');
      return null;
    }
    
    _isSignInInProgress = true;

    try {
      print('🟡 Starting Kakao login process...');

      String? accessToken;
      
      if (kIsWeb) {
        // Check if we're returning from OAuth callback first
        accessToken = await _handleOAuthCallback();
        
        // If no callback, start OAuth flow
        if (accessToken == null) {
          accessToken = await _signInWithKakaoWeb();
        }
      } else {
        // Mobile implementation using Flutter SDK
        accessToken = await _signInWithKakaoMobile();
      }

      if (accessToken == null) {
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
      throw 'Kakao login failed: ${e.toString()}';
    } finally {
      _isSignInInProgress = false;
    }
  }

  // Web-based Kakao login using JavaScript SDK
  Future<String?> _signInWithKakaoWeb() async {
    if (!kIsWeb) return null;
    
    try {
      print('🟡 Initializing Kakao JavaScript SDK...');
      
      // Initialize Kakao SDK with your app key
      await _initializeKakaoSDK();
      
      print('🟡 Starting Kakao OAuth login...');
      
      // Use JavaScript interop to call Kakao.Auth.login
      final String? accessToken = await _callKakaoLogin();
      
      if (accessToken == null || accessToken.isEmpty) {
        throw 'Failed to get access token from Kakao';
      }
      
      print('✅ Kakao web login successful');
      return accessToken;
      
    } catch (e) {
      print('❌ Web Kakao login error: $e');
      rethrow;
    }
  }

  // Mobile Kakao login using Flutter SDK
  Future<String?> _signInWithKakaoMobile() async {
    if (kIsWeb) return null;
    
    try {
      print('🟡 Starting mobile Kakao login...');
      
      // This would use the kakao_flutter_sdk package
      // For now, we'll throw an error to indicate it needs implementation
      throw 'Mobile Kakao login implementation needed. Install Kakao Flutter SDK properly.';
      
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
      // For demo, just check if Firebase user exists and has custom claims
      final user = _auth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }

  // Get stored Kakao access token
  Future<String?> getStoredKakaoToken() async {
    try {
      // For demo, return null as we don't store tokens yet
      return null;
    } catch (e) {
      return null;
    }
  }

  // Logout from Kakao services
  Future<void> signOutKakaoServices() async {
    try {
      print('🟡 Signing out from Kakao services...');
      // For demo, just log the action
      print('✅ Kakao logout completed (demo mode)');
    } catch (e) {
      print('⚠️ Kakao services logout error: $e');
      // Don't throw error for logout - it's not critical
    }
  }

  // Handle OAuth callback when returning from Kakao login
  Future<String?> _handleOAuthCallback() async {
    if (!kIsWeb) return null;
    
    try {
      // Check if current URL has authorization code
      final currentUrl = js.context['location']['href'].toString();
      final uri = Uri.parse(currentUrl);
      
      print('🟡 Checking OAuth callback URL: ${uri.toString()}');
      
      final authCode = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      
      if (error != null) {
        throw 'OAuth error: $error - ${uri.queryParameters['error_description'] ?? ''}';
      }
      
      if (authCode != null && authCode.isNotEmpty) {
        print('✅ Authorization code received: ${authCode.substring(0, 10)}...');
        
        // Exchange authorization code for access token
        final accessToken = await _exchangeCodeForToken(authCode);
        
        // Clean up URL by removing query parameters
        js.context.callMethod('eval', ['history.replaceState({}, document.title, window.location.pathname);']);
        
        return accessToken;
      }
      
      print('🟡 No authorization code found in URL');
      return null;
    } catch (e) {
      print('❌ OAuth callback handling failed: $e');
      rethrow;
    }
  }
  
  // Exchange authorization code for access token via backend
  Future<String> _exchangeCodeForToken(String authorizationCode) async {
    try {
      print('🟡 Exchanging authorization code for access token...');
      
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/kakao/exchange-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'authorization_code': authorizationCode,
          'redirect_uri': js.context['location']['origin'].toString(),
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw 'Backend server timeout during code exchange';
        },
      );

      print('📡 Code exchange response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['access_token'] != null) {
          print('✅ Access token obtained successfully');
          return data['access_token'];
        } else {
          throw 'Invalid response from backend: ${data['message'] ?? 'Unknown error'}';
        }
      } else {
        final data = jsonDecode(response.body);
        throw 'Backend error: ${data['message'] ?? 'HTTP ${response.statusCode}'}';
      }
    } catch (e) {
      print('❌ Code exchange failed: $e');
      rethrow;
    }
  }

  // Handle OAuth callback only (for app initialization)
  Future<UserCredential?> handleOAuthCallbackOnly() async {
    if (!kIsWeb) return null;
    
    try {
      // Only handle callback if there's an authorization code
      final accessToken = await _handleOAuthCallback();
      
      if (accessToken != null) {
        print('🟡 Processing OAuth callback...');
        
        // Create custom token using backend server
        String customToken = await _createCustomTokenForKakao(accessToken);
        print('✅ Firebase custom token created');
        
        // Sign in to Firebase with custom token
        UserCredential credential = await _auth.signInWithCustomToken(customToken);
        print('✅ Firebase authentication successful via OAuth callback');
        
        return credential;
      }
      
      return null;
    } catch (e) {
      print('❌ OAuth callback handling failed: $e');
      return null; // Don't throw errors during app initialization
    }
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

  // JavaScript interop methods for web
  Future<void> _initializeKakaoSDK() async {
    if (!kIsWeb || _kakaoAppKey == null) return;
    
    try {
      // Wait for Kakao SDK to be loaded
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if Kakao SDK is available
      if (js.context['Kakao'] == null) {
        throw 'Kakao JavaScript SDK not loaded. Make sure to include the script tag.';
      }
      
      // Initialize Kakao SDK
      js.context.callMethod('eval', ['''
        if (!Kakao.isInitialized()) {
          Kakao.init('$_kakaoAppKey');
        }
      ''']);
      
      print('✅ Kakao JavaScript SDK initialized');
    } catch (e) {
      print('❌ Kakao SDK initialization failed: $e');
      rethrow;
    }
  }

  Future<String?> _callKakaoLogin() async {
    if (!kIsWeb) return null;
    
    try {
      // Create a completer to handle the async JavaScript callback
      final completer = Completer<String?>();
      
      // Define global callback functions
      js.context['flutterKakaoSuccess'] = js.allowInterop((dynamic authObj) {
        try {
          print('🟡 Kakao login success callback received');
          final accessToken = authObj['access_token'];
          if (accessToken != null) {
            print('✅ Access token received: ${accessToken.toString().substring(0, 10)}...');
            completer.complete(accessToken.toString());
          } else {
            print('❌ No access token in response');
            completer.completeError('No access token received');
          }
        } catch (e) {
          print('❌ Error processing login result: $e');
          completer.completeError('Error processing login result: $e');
        }
      });
      
      js.context['flutterKakaoError'] = js.allowInterop((dynamic error) {
        print('❌ Kakao login error callback received: $error');
        completer.completeError('Kakao login failed: ${error.toString()}');
      });
      
      // Use eval to execute the Kakao login with proper error handling
      print('🟡 Calling Kakao.Auth.login via eval...');
      js.context.callMethod('eval', ['''
        (function() {
          try {
            console.log('Kakao object available:', typeof Kakao !== 'undefined');
            console.log('Kakao.Auth available:', typeof Kakao.Auth !== 'undefined');
            console.log('Kakao.Auth.login available:', typeof Kakao.Auth.login === 'function');
            
            if (typeof Kakao === 'undefined') {
              flutterKakaoError('Kakao SDK not loaded');
              return;
            }
            
            if (typeof Kakao.Auth === 'undefined') {
              flutterKakaoError('Kakao.Auth not available');
              return;
            }
            
            // Try multiple possible Kakao login methods
            console.log('Available Kakao.Auth methods:', Object.getOwnPropertyNames(Kakao.Auth));
            
            // Use the authorize method to redirect to Kakao login
            if (typeof Kakao.Auth.authorize === 'function') {
              console.log('Using Kakao.Auth.authorize - redirecting to Kakao login...');
              console.log('Redirect URI:', window.location.origin);
              console.log('Current URL:', window.location.href);
              
              try {
                // This will redirect the entire page to Kakao OAuth
                var result = Kakao.Auth.authorize({
                  redirectUri: window.location.origin,
                  scope: 'profile_nickname,profile_image'
                });
                console.log('Authorize result:', result);
              } catch (e) {
                console.error('Authorize error:', e);
                flutterKakaoError('Authorize failed: ' + e.message);
                return;
              }
              
              // This line won't execute if redirect works
              setTimeout(function() {
                console.log('Warning: Redirect did not occur after 1 second');
                flutterKakaoError('Redirect failed - check Kakao Console redirect URI settings');
              }, 1000);
            } else if (typeof Kakao.Auth.login === 'function') {
              console.log('Using Kakao.Auth.login method');
              Kakao.Auth.login({
                success: function(authObj) {
                  console.log('Kakao login success:', authObj);
                  flutterKakaoSuccess(authObj);
                },
                fail: function(err) {
                  console.log('Kakao login error:', err);
                  flutterKakaoError(err);
                },
                scope: 'profile_nickname,profile_image'
              });
            } else {
              // Fallback: try direct OAuth redirect
              console.log('Using direct OAuth redirect');
              var authUrl = 'https://kauth.kakao.com/oauth/authorize' +
                '?client_id=3d1ed1dc6cd2c4797f2dfd65ee48c8e8' +
                '&redirect_uri=' + encodeURIComponent(window.location.origin) +
                '&response_type=code' +
                '&scope=profile_nickname,profile_image,account_email';
              window.location.href = authUrl;
            }
          } catch (e) {
            console.error('JavaScript error in Kakao login:', e);
            flutterKakaoError('JavaScript error: ' + e.message);
          }
        })();
      ''']);
      
      // Wait for the result
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw 'Kakao login timeout',
      );
    } catch (e) {
      print('❌ Kakao login JavaScript call failed: $e');
      rethrow;
    }
  }
}