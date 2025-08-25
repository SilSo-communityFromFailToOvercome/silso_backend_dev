import 'package:flutter/material.dart';
import 'dart:math';
// import 'package:rive/rive.dart'; // Rive 애니메이션을 사용하는 경우
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용 시
import 'package:firebase_auth/firebase_auth.dart';     // Firebase Auth 사용 시
import '../login/after_signup_splash.dart'; 

// 1. UI 상태를 enum으로 정의합니다.
enum PetCreationStep {
  intro,
  revealPet,
  startNaming,
  keyboardActive,
  namingDone,
}

class PetCreationScreen extends StatefulWidget {
  const PetCreationScreen({super.key});

  @override
  State<PetCreationScreen> createState() => _PetCreationScreenState();
}

class _PetCreationScreenState extends State<PetCreationScreen> {
  // 2. 현재 UI 상태를 관리하는 변수
  PetCreationStep _currentStep = PetCreationStep.intro;

  // 닉네임 입력을 위한 컨트롤러와 포커스 노드
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _nicknameFocusNode = FocusNode();

  // 랜덤 펫 이미지 번호와 최종 닉네임 저장 변수
  int _petImageNumber = 1;
  
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
  
  // 펫 이미지 경로를 생성하는 함수
  String _buildPetImagePath(int petNumber) {
    final folderName = _getPetFolderName(petNumber);
    return 'assets/images/silpets/$folderName/$petNumber.0.png';
  }
  
  // 애니메이션 효과를 위한 투명도 값
  double _splashAnimationOpacity = 1.0;
 // mypet_select.dart

@override
void initState() {
  super.initState();
  _petImageNumber = Random().nextInt(11) + 1;

  _nicknameController.addListener(() {
    setState(() {});
  });

  // ✅ 수정된 FocusNode 리스너
  _nicknameFocusNode.addListener(() {
    // 포커스를 잃었을 때만 (키보드가 내려갔을 때) 상태를 변경하도록 처리합니다.
    if (!_nicknameFocusNode.hasFocus) {
      // 텍스트 필드에 내용이 있으면 'namingDone' 상태로 변경합니다.
      if (_nicknameController.text.isNotEmpty) {
        // _handleNicknameSubmit() 함수가 내부적으로 setState를 호출하여
        // _currentStep = PetCreationStep.namingDone 으로 변경합니다.
        _handleNicknameSubmit();
      } 
      // 텍스트 필드가 비어있으면 'startNaming' 상태로 되돌아갑니다.
      else {
        setState(() {
          _currentStep = PetCreationStep.startNaming;
        });
      }
    }
  });
}

  // ✅ dispose에서 리스너를 제거해야 메모리 누수가 발생하지 않습니다.
  @override
  void dispose() {
    // 리스너를 제거할 때는 아래와 같이 addListener에 전달했던 함수를 그대로 넣어주어야 합니다.
    // 여기서는 익명 함수를 썼으므로 컨트롤러를 dispose 하는 것만으로 충분합니다.
    _nicknameController.dispose();
    _nicknameFocusNode.dispose();
    super.dispose();
  }

  // 3. 상태 변경 로직을 함수로 관리
  void _handleScreenTap() {
    if (_currentStep == PetCreationStep.intro) {
      setState(() {
        _splashAnimationOpacity = 0.0; // 스플래시 애니메이션 숨기기
        _currentStep = PetCreationStep.revealPet;
      });
    }
  }

  void _handleBottomButtonTap() {
    switch (_currentStep) {
      case PetCreationStep.revealPet:
        setState(() => _currentStep = PetCreationStep.startNaming);
        break;
      case PetCreationStep.startNaming:
        // 입력 필드에 포커스를 주어 키보드를 활성화
        setState(() {
          _currentStep = PetCreationStep.keyboardActive;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _nicknameFocusNode.requestFocus();
        });        
        break;
      case PetCreationStep.keyboardActive:
        // 키보드 활성 상태에서 버튼을 누르면 닉네임 제출
        if (_nicknameController.text.isNotEmpty) {
          _handleNicknameSubmit();
        }
        break;
      case PetCreationStep.namingDone:
        _navigateToNextScreen();
        break;
      default:
        break;
    }
  }

  void _handleNicknameSubmit() {
    // 키보드의 '완료' 버튼을 누르거나 포커스를 잃었을 때 호출
    if (_nicknameController.text.isNotEmpty) {
      setState(() {
        _currentStep = PetCreationStep.namingDone;
      });
      _nicknameFocusNode.unfocus(); // 키보드 숨기기
    }
  }
  
  // 6. Firestore에 닉네임 저장 및 다음 화면으로 이동
  Future<void> _saveNicknameToFirestore() async {
    // Firestore 및 FirebaseAuth 설정이 필요합니다.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nicknameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'NicknamePet': _nicknameController.text,
        'selectedPet': _petImageNumber, // 펫 번호 저장 (1-11)
        'selectedPetFolder': _getPetFolderName(_petImageNumber), // 펫 폴더명 저장 (예: '5_yellow')
        'selectedPetOutfit': 0, // 기본 아웃핏 (0번)
        'selectedPetImagePath': _buildPetImagePath(_petImageNumber), // 전체 이미지 경로 저장
      });
    }
    print('닉네임 "${_nicknameController.text}" 저장 완료!');
  }
  
  void _navigateToNextScreen() async {
    await _saveNicknameToFirestore();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AfterSignupSplash()));
     print('다음 화면으로 이동합니다.');
  }


  @override
  Widget build(BuildContext context) {
    // 4. 반응형 UI를 위해 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: GestureDetector(
        onTap: _handleScreenTap,
        child: Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.00, -0.7),
              end: Alignment(1.00, 1.00),
              colors: [Color(0xFF5F37CF), Color(0xFF160C32)],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 스플래시 애니메이션 위젯
              _buildSplashAnimation(),
              
              // 상단 텍스트 위젯
              _buildTopText(screenHeight),

              // 펫 이미지 위젯
              _buildPetImage(screenHeight),

              // 닉네임 입력 필드 위젯
              _buildInitialNicknameField(screenHeight),
              
              // 닉네임 표시 박스 (키보드 올라왔을 때)
              _buildNicknameDisplayBox(screenHeight),

              _buildNicknameField(screenHeight),

              // 하단 버튼 위젯
              _buildBottomButton(screenWidth, screenHeight),
            ],
          ),
        ),
      ),
    );
  }

  // 5. 각 UI 요소를 별도의 함수로 분리하여 관리
  
  Widget _buildSplashAnimation() {
    // TODO: 애니메이션 팀에서 받은 실제 애니메이션 위젯으로 교체하세요. (예: Rive)
    return AnimatedOpacity(
      opacity: _splashAnimationOpacity,
      duration: const Duration(milliseconds: 300),
      child: const Center(
        // child: RiveAnimation.asset('assets/animations/splash.riv'),
        child: Icon(Icons.animation, color: Colors.white, size: 150), // 임시 아이콘
      ),
    );
  }

  Widget _buildTopText(double screenHeight) {
    String text = '';
    switch (_currentStep) {
      case PetCreationStep.intro:
        text = '캡슐을 열어주세요!';
        break;
      case PetCreationStep.revealPet:
        text = '당신의 실팻이에요!';
        break;
      case PetCreationStep.startNaming:
        text = '이름을 지어주세요!'; // 
        break;
      case PetCreationStep.keyboardActive:
        break;
      case PetCreationStep.namingDone:
        text = '${_nicknameController.text} 멋진 이름이네요';
        break;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      top: screenHeight * 0.18, // 화면 높이의 18% 위치
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _currentStep != PetCreationStep.intro ? 1.0 : 0.0,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFAFAFA),
            fontSize: 20,
            fontFamily: 'DungGeunMo',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
  
  Widget _buildPetImage(double screenHeight) {
    bool isVisible = _currentStep != PetCreationStep.intro;
    bool isEnlarged = _currentStep == PetCreationStep.startNaming ||
                      _currentStep == PetCreationStep.keyboardActive ||
                      _currentStep == PetCreationStep.namingDone;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut, // 통통 튀는 효과
      top: _currentStep == PetCreationStep.keyboardActive ? screenHeight * 0.21 : screenHeight * 0.3,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: isEnlarged ? 110 : 64,
          height: isEnlarged ? 288 : 169,
          child: Image.asset(
            _buildPetImagePath(_petImageNumber), // 새로운 silpets 구조 사용 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: isEnlarged ? 110 : 64,
                height: isEnlarged ? 288 : 169,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pets,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

// mypet_select.dart

// 초기 상태('이름을 입력해주세요')를 표시하는 위젯
Widget _buildInitialNicknameField(double screenHeight) {
  bool isVisible = _currentStep == PetCreationStep.startNaming;
  return AnimatedPositioned(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    top: screenHeight * 0.7,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isVisible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !isVisible,
        // ✅ 1. GestureDetector를 추가하여 탭 이벤트를 감지합니다.
        child: GestureDetector(
          // ✅ 2. 탭하면 FocusNode에 포커스를 요청하여 키보드를 활성화합니다.
            onTap: () {
              setState(() {
                _currentStep = PetCreationStep.keyboardActive;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _nicknameFocusNode.requestFocus();
              });
            }, 
            child: Container(
            width: 224,
            height: 40,
            decoration: ShapeDecoration(
              color: const Color(0xFFF7F4FF),
              shape: RoundedRectangleBorder(
                side: const BorderSide(width: 1, color: Color(0xFF5F37CF)),
                borderRadius: BorderRadius.circular(400),
              ),
            ),
            child: const Center(
              child: Text(
                '이름을 입력해주세요',
                style: TextStyle(
                  color: Color(0xFFD0C5ED),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// 닉네임 입력 필드 (실제 입력은 여기서, 하지만 화면엔 보이지 않음)
Widget _buildNicknameField(double screenHeight) {
  if (_currentStep != PetCreationStep.keyboardActive) {
    return const SizedBox.shrink();
  }

  return Positioned(
    // ✅ DisplayBox와 동일하게 상단 텍스트 위치로 이동합니다.
    top: screenHeight * 0.18,
    child: SizedBox(
      width: 224,
      height: 40,
      child: TextField(
        controller: _nicknameController,
        focusNode: _nicknameFocusNode,
        textAlign: TextAlign.center,
        onSubmitted: (_) => _handleNicknameSubmit(),
        autofocus: true,
        style: const TextStyle(color: Colors.transparent),
        decoration: const InputDecoration(
          border: InputBorder.none,
          fillColor: Colors.transparent,
          filled: true,
        ),
        cursorColor: Colors.transparent,
      ),
    ),
  );
}

// 닉네임 표시 박스 (실시간 업데이트 및 수정 기능 추가)
Widget _buildNicknameDisplayBox(double screenHeight) {
  bool isVisible = _currentStep == PetCreationStep.keyboardActive || _currentStep == PetCreationStep.namingDone;

  return AnimatedPositioned(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOut,
    // ✅ keyboardActive 상태일 때 상단 텍스트 위치(0.18)로 이동합니다.
    top: _currentStep == PetCreationStep.keyboardActive
        ? screenHeight * 0.18
        : screenHeight * 0.25,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isVisible && _nicknameController.text.isNotEmpty ? 1.0 : 0.0,
      child: GestureDetector(
        onTap: () {
          if (_currentStep == PetCreationStep.namingDone) {
            setState(() {
              _currentStep = PetCreationStep.keyboardActive;
            });
            _nicknameFocusNode.requestFocus();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          constraints: const BoxConstraints(minHeight: 30),
          decoration: ShapeDecoration(
            color: const Color(0xFFFAFAFA),
            shape: RoundedRectangleBorder(
              side: const BorderSide(width: 2, color: Color(0xFF121212)),
              borderRadius: BorderRadius.circular(400),
            ),
          ),
          child: Center(
            child: Text(
              _nicknameController.text,
              style: const TextStyle(
                color: Color(0xFF121212),
                fontSize: 16,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildBottomButton(double screenWidth, double screenHeight) {
    bool isVisible = _currentStep != PetCreationStep.intro;
    bool isButtonActive = _currentStep == PetCreationStep.revealPet ||
                          _currentStep == PetCreationStep.startNaming ||
                          _currentStep == PetCreationStep.namingDone ||
                          (_currentStep == PetCreationStep.keyboardActive && _nicknameController.text.isNotEmpty);
    
    String buttonText = '';
    switch(_currentStep) {
      case PetCreationStep.revealPet:
      case PetCreationStep.startNaming:
        buttonText = '닉네임 만들기';
        break;
      case PetCreationStep.namingDone:
        buttonText = '시작하기';
        break;
      case PetCreationStep.keyboardActive:
        buttonText = '완료'; // 키보드 활성 시 '완료' 텍스트 (비활성화)
        break;
      default:
        buttonText = '터치해주세요';
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      bottom: _currentStep == PetCreationStep.keyboardActive ? screenHeight - (screenHeight * 0.92) + MediaQuery.of(context).viewInsets.bottom : screenHeight * 0.1,
      // 키보드가 올라왔을 때 키보드 바로 위에 위치하도록 조정
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isVisible ? 1.0 : 0.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: GestureDetector(
            onTap: isButtonActive ? _handleBottomButtonTap : null,
            child: Container(
              height: 52,
              decoration: ShapeDecoration(
                color: isButtonActive ? const Color(0xFF5F37CF) : const Color(0xFF44307A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isButtonActive ? const Color(0xFFFAFAFA) : const Color(0xFF896ADD),
                    fontSize: 18,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Legacy compatibility - keeping old class names for any existing references
class MyPetSelect extends StatelessWidget {
  const MyPetSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return const PetCreationScreen();
  }
}