import 'dart:async';
import 'package:flutter/material.dart';
// 1. Import the new destination screen.
//    Ensure the path is correct for your project structure.
import 'community_tab_mycom2.dart'; 

class IntroCommunitySplash extends StatefulWidget {
  const IntroCommunitySplash({super.key});

  @override
  State<IntroCommunitySplash> createState() => _IntroCommunitySplashState();
}

class _IntroCommunitySplashState extends State<IntroCommunitySplash> {
  @override
  void initState() {
    super.initState();
    // Keep the 3-second timer.
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // 2. Change the navigation destination to CommunityMainTabScreenMycom.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CommunityMainTabScreenMycom()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive UI calculations remain the same.
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF5F37CF),
      body: Stack(
        children: [
          // Welcome message text
          Positioned(
            left: 16 * widthRatio,
            top: 141 * heightRatio,
            child: Text(
              '실소 커뮤니티에\n오신 것을 환영합니다!',
              style: TextStyle(
                color: const Color(0xFFFAFAFA),
                fontSize: 24 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.21,
              ),
            ),
          ),

          // Character image
          Positioned(
            right: -80 * widthRatio,
            bottom: 40 * heightRatio,
            child: Container(
              width: 252 * widthRatio,
              height: 252 * heightRatio,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/splash/character.png"),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          
          // Loading indicator
          Positioned(
            left: 0,
            right: 0,
            bottom: screenHeight * 0.25,
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