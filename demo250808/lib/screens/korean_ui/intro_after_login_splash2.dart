import 'dart:async';
import 'package:flutter/material.dart';

class AfterLoginSplashScreen extends StatefulWidget {
  const AfterLoginSplashScreen({super.key});

  @override
  State<AfterLoginSplashScreen> createState() => _AfterLoginSplashScreenState();
}

class _AfterLoginSplashScreenState extends State<AfterLoginSplashScreen> {
  @override
  void initState() {
    super.initState();
    print("screens/korean_ui/intro_after_login_splash2.dart is currently showing");
    // 3초 후에 홈 화면으로 이동합니다.
    // pushReplacementNamed를 사용하여 이 화면이 네비게이션 스택에서 제거되도록 합니다.
    Timer(const Duration(seconds: 3), () {
      if (mounted) { // 위젯이 여전히 화면에 있는지 확인합니다.
        Navigator.of(context).pushReplacementNamed('/mvp_community');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // login_screen.dart에서 사용된 반응형 UI 계산 방식을 동일하게 적용합니다.
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Positioned(
            // 위치와 크기를 화면 비율에 맞게 동적으로 조절합니다.
            left: 16 * widthRatio,
            top: 199 * heightRatio,
            child: Text(
              '로그인이 \n완료되었어요!',
              style: TextStyle(
                color: const Color(0xFF5F37CF),
                // 폰트 크기도 비율에 맞게 조절하여 일관성을 유지합니다.
                fontSize: 24 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}