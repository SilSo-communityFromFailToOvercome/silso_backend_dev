import 'dart:async';
import 'package:flutter/material.dart';
import 'community/community_mvp/community_main.dart'; // CommunityMainScreen 경로

class  IntroCommunitySplash extends StatefulWidget {
  const  IntroCommunitySplash({super.key});

  @override
  State< IntroCommunitySplash> createState() => _IntroCommunitySplashState();
}

class _IntroCommunitySplashState extends State< IntroCommunitySplash> {
  @override
  void initState() {
    super.initState();
    // 3초 후에 CommunityScreen으로 이동하는 로직은 그대로 유지합니다.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CommunityMainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 반응형 UI를 위한 기준 해상도 및 비율 계산
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF5F37CF), // 요청된 배경색으로 변경
      body: Stack( // Positioned 위젯을 사용하기 위해 Stack을 최상위에 배치
        children: [
          // 환영 메시지 텍스트
          Positioned(
            left: 16 * widthRatio,
            top: 141 * heightRatio,
            child: Text(
              '실소 커뮤니티에\n오신 것을 환영합니다!',
              style: TextStyle(
                color: const Color(0xFFFAFAFA),
                fontSize: 24 * widthRatio, // 폰트 크기도 비율에 맞게 조절
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.21,
              ),
            ),
          ),

          // 캐릭터 이미지 (위치 조정)
          Positioned(
            // right, bottom 속성을 사용하여 우측 하단에 자연스럽게 배치
            right: -80 * widthRatio,
            bottom: 40 * heightRatio,
            child: Container(
              width: 252 * widthRatio,
              height: 252 * heightRatio,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  // TODO: 'assets/images/your_image.png' 와 같이 실제 에셋 경로로 교체해주세요.
                  image: AssetImage("assets/images/splash/character.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // 로딩 인디케이터 추가
          Positioned(
            // 화면의 가로 중앙, 세로 하단에 배치
            left: 0,
            right: 0,
            bottom: screenHeight * 0.25, // 화면 높이의 25% 지점
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}