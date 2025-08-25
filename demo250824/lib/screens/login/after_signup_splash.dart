import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../community/community_main.dart';

class AfterSignupSplash extends StatefulWidget {
  const AfterSignupSplash({super.key});

  @override
  State<AfterSignupSplash> createState() => _AfterSignupSplashState();
}

class _AfterSignupSplashState extends State<AfterSignupSplash> {
  // Firestore에서 가져온 펫 이미지 번호를 저장할 변수
  int? _petImageNumber;
  
  // 펫 번호를 폴더명으로 매핑하는 함수
  String _getPetFolderName(int petNumber) {
    const folderNames = {
      1: '1_red',
      2: '2_blue', 
      3: '3_green',
      4: '4_cyan',
      5: '5_yellow',
      6: '6_green',
      7: '7_pink',
      8: '8_orange',
      9: '9_grey',
      10: '10_purple',
      11: '11_purplish'
    };
    return folderNames[petNumber] ?? '1_red';
  }
  
  // 펫 이미지 경로를 생성하는 함수 (기본 아웃핏 0번 사용)
  String _buildPetImagePath(int petNumber) {
    final folderName = _getPetFolderName(petNumber);
    return 'assets/images/silpets/$folderName/$petNumber.0.png';
  }

  @override
  void initState() {
    super.initState();
    print("screens/korean_ui/intro_community_splash2.dart is currently showing");

    // 사용자 펫 정보를 가져오는 함수 호출
    _fetchUserPet();

    // 3초 후에 다음 화면으로 이동
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const CommunityMainTabScreenMycom()),
        );
      }
    });
  }

  /// Firestore에서 현재 사용자의 'selectedPet' 정보를 가져오는 함수
  Future<void> _fetchUserPet() async {
    // 현재 로그인된 사용자 정보 가져오기
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        // 'users' 컬렉션에서 현재 사용자 uid에 해당하는 문서 가져오기
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // 문서가 존재하고 위젯이 아직 화면에 있다면
        if (userDoc.exists && mounted) {
          // 'selectedPet' 필드 값을 _petImageNumber에 저장하고 화면 갱신
          setState(() {
            _petImageNumber = userDoc.get('selectedPet') ?? 1;
          });
        }
      } catch (e) {
        print("사용자 펫 정보를 가져오는 중 오류 발생: $e");
        // 오류 발생 시 기본 이미지 번호 설정 (예: 1)
        if (mounted) {
          setState(() {
            _petImageNumber = 1;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 환영 메시지 텍스트
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

          // 캐릭터 이미지
          Positioned(
            right: -60 * widthRatio,
            bottom: 40 * heightRatio,
            child: Container(
              width: 252 * widthRatio,
              height: 252 * heightRatio,
              // _petImageNumber가 있으면 이미지를, 없으면 로딩 인디케이터를 표시
              child: _petImageNumber != null
                  ? Image.asset(
                      // 새로운 silpets 구조로 이미지 경로 생성
                      _buildPetImagePath(_petImageNumber!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Colors.white,
                            size: 80,
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}