import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'korean_auth_service.dart';

class AuthService {
  // Singleton pattern implementation
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Sign-in progress tracking to prevent race conditions
  bool _isSignInInProgress = false;
  DateTime? _lastSignInAttempt;
  
  // Korean authentication service
  final KoreanAuthService _koreanAuth = KoreanAuthService();
  
  // Configure GoogleSignIn with web client ID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // For web, you need to provide the web client ID
    clientId: kIsWeb ? '337349884372-k47h7h11pfuljssvug8bbfgjopkt5c39.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'openid',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is anonymous
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;


  // Get user display name
  String getUserDisplayName() {
    final user = _auth.currentUser;
    if (user?.isAnonymous == true) {
      return 'Guest User';
    }
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to sign in anonymously. Please try again.';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSignInInProgress) return null;
    
    _isSignInInProgress = true;
    _lastSignInAttempt = DateTime.now();
    
    try {
      if (kIsWeb) {
        // For web, use Firebase Auth popup directly to avoid deprecated signIn method
        return await _signInWithGoogleWeb();
      } else {
        // For mobile platforms, use the standard GoogleSignIn flow
        return await _signInWithGoogleStandard();
      }
    } catch (e) {
      throw 'Google sign in failed: ${e.toString()}';
    } finally {
      _isSignInInProgress = false;
    }
  }

  // Standard Google Sign-In flow (for mobile)
  Future<UserCredential?> _signInWithGoogleStandard() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      // User canceled the sign-in
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    return await _auth.signInWithCredential(credential);
  }

  // Web Google Sign-In flow with popup and redirect fallback
  Future<UserCredential?> _signInWithGoogleWeb() async {
    try {
      // Try popup first (works on desktop)
      return await _signInWithGooglePopup();
    } catch (e) {
      print('Popup sign-in failed: ${e.toString()}');
      // Fallback to redirect (better for mobile browsers)
      return await _signInWithGoogleRedirect();
    }
  }

  // Mobile-friendly popup sign-in
  Future<UserCredential?> _signInWithGooglePopup() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes (use full URLs for People API compatibility)
      googleProvider.addScope('email');
      googleProvider.addScope('openid');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
      
      // Set custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      // Sign in with popup
      final UserCredential result = await _auth.signInWithPopup(googleProvider);
      return result;
    } catch (e) {
      throw 'Popup sign-in failed: ${e.toString()}';
    }
  }

  // Fallback: Redirect method for mobile browsers
  Future<UserCredential?> _signInWithGoogleRedirect() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Add scopes
      googleProvider.addScope('email');
      googleProvider.addScope('openid');
      googleProvider.addScope('https://www.googleapis.com/auth/userinfo.profile');
      
      // Set custom parameters
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
      });

      // Use redirect for mobile browsers
      await _auth.signInWithRedirect(googleProvider);
      
      // Note: The result will be handled by getRedirectResult() after page reload
      return null;
    } catch (e) {
      throw 'Redirect sign-in failed: ${e.toString()}';
    }
  }

  // Check for redirect result (call this in app initialization)
  Future<UserCredential?> checkRedirectResult() async {
    if (!kIsWeb) return null;
    
    // Don't check redirect if manual sign-in happened recently (within 5 seconds)
    if (_lastSignInAttempt != null && 
        DateTime.now().difference(_lastSignInAttempt!).inSeconds < 5) {
      return null;
    }
    
    // Don't check redirect if sign-in is already in progress
    if (_isSignInInProgress) return null;
    
    try {
      return await _auth.getRedirectResult();
    } catch (e) {
      return null;
    }
  }

  // Kakao login wrapper
  Future<UserCredential?> signInWithKakao() async {
    try {
      return await _koreanAuth.signInWithKakao();
    } catch (e) {
      throw 'Kakao sign in failed: ${e.toString()}';
    }
  }

  // Kakao demo login for testing
  Future<UserCredential?> signInWithKakaoDemo() async {
    try {
      return await _koreanAuth.signInWithKakaoDemo();
    } catch (e) {
      throw 'Kakao demo sign in failed: ${e.toString()}';
    }
  }

  // Check if Kakao is signed in
  Future<bool> isKakaoSignedIn() async {
    return await _koreanAuth.isKakaoSignedIn();
  }

  // Check backend server health
  Future<bool> checkBackendHealth() async {
    return await _koreanAuth.checkBackendHealth();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
        await user.reload();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Korean services (Kakao)
      await _koreanAuth.signOutKakaoServices();
      
      // Check if user signed in with Google before attempting Google sign out
      final user = _auth.currentUser;
      
      if (user != null) {
        // Check if any of the user's providers is Google
        bool hasGoogleProvider = user.providerData.any(
          (provider) => provider.providerId == 'google.com'
        );
        
        if (hasGoogleProvider) {
          await _googleSignIn.signOut();
        }
      }
      
      // Always sign out from Firebase
      await _auth.signOut();
    } catch (e) {
      throw 'Sign out failed: ${e.toString()}';
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  // Convert anonymous account to permanent account
  Future<UserCredential?> linkWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.isAnonymous) {
        final credential = EmailAuthProvider.credential(
          email: email.trim(),
          password: password,
        );
        UserCredential result = await user.linkWithCredential(credential);
        return result;
      }
      throw 'No anonymous user to link.';
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw 'Failed to link account. Please try again.';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email address.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The email address is already in use by another account.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'invalid-credential':
        return 'The provided credentials are invalid.';
      case 'credential-already-in-use':
        return 'This credential is already associated with a different user account.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }

  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter your email';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Please enter your password';
    }
    if (!isValidPassword(password)) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Get username from email (part before @)
  String getUsernameFromEmail(String? email) {
    if (email == null) return 'User';
    return email.split('@')[0];
  }
}