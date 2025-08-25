import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/authentication/korean_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 애니메이션에 사용할 이미지 목록
  final List<String> _splashImages = [
    'assets/images/splash/stat1.png',
    'assets/images/splash/stat2.png',
    'assets/images/splash/stat3.png',
    'assets/images/splash/silso_logo.png',
  ];

  int _currentIndex = 0; // 현재 보여줄 이미지의 인덱스
  // 배경색을 상태 변수로 관리하여 변경 가능하도록 함
  Color _backgroundColor = const Color(0xFF6037D0);

  @override
  void initState() {
    super.initState();
    print("screens/splash_screen.dart is showing");

    // Start animation sequence
    _startAnimationSequence();
    
    // Check authentication and handle OAuth callback
    _checkAuthenticationState();
  }

  void _checkAuthenticationState() async {
    try {
      // First, try to handle OAuth callback if present
      final koreanAuth = KoreanAuthService();
      final callbackResult = await koreanAuth.handleOAuthCallbackOnly();
      
      if (callbackResult != null) {
        // OAuth callback successful, immediately go to login success page
        print('✅ OAuth callback handled successfully');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/after-login-splash');
        }
        return;
      }
      
      // Check if user is already signed in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        print('✅ User already signed in: ${currentUser.uid}');
        // User already logged in, skip animation and go to home immediately
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/after-login-splash');
        }
      } else {
        // No user signed in, show animation then go to login
        print('🟡 No user signed in, going to login');
        Future.delayed(const Duration(seconds: 9), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      }
    } catch (e) {
      print('❌ Error checking authentication state: $e');
      // On error, default to login screen
      Future.delayed(const Duration(seconds: 9), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      });
    }
  }

  void _startAnimationSequence() {
    // stat1, 2, 3 이미지가 7초 동안 표시되므로 각 이미지는 약 2.33초 동안 표시됩니다.
    const statDuration = Duration(milliseconds: 7000 ~/ 3);

    // statDuration 후 stat2.png 표시
    Future.delayed(statDuration, () {
      if (mounted) {
        setState(() {
          _currentIndex = 1;
        });
      }
    });

    // statDuration * 2 후 stat3.png 표시
    Future.delayed(statDuration * 2, () {
      if (mounted) {
        setState(() {
          _currentIndex = 2;
        });
      }
    });

    // 7초 후 silso_logo.png를 표시하고 배경색을 변경
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        setState(() {
          _currentIndex = 3;
          _backgroundColor = const Color(0xFFFAFAFA); // 배경색을 #FAFAFA로 변경
        });
      }
    });
  }

  // Timer를 사용하지 않으므로 dispose에서 처리할 내용이 없습니다.
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedContainer를 사용하여 배경색 변경 시 부드러운 전환 효과를 줌
    return AnimatedContainer(
      duration: const Duration(milliseconds: 700), // 배경색 전환 속도
      color: _backgroundColor,
      child: Scaffold(
        // Scaffold의 배경색은 투명하게 하여 AnimatedContainer의 색이 보이도록 함
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700), // 이미지 전환 속도
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child); // Fade 효과
            },
            child: Image.asset(
              _splashImages[_currentIndex],
              key: ValueKey<int>(_currentIndex), // 위젯 변경 감지를 위한 Key
              width: 150,
            ),
          ),
        ),
      ),
    );
  }
}