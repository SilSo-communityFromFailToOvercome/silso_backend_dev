import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/authentication/auth_service.dart';
import 'phone_confirm.dart';
import 'mypet_select.dart';
import 'after_signup_splash.dart'; 
import 'id_password_signup.dart';
import 'package:firebase_auth/firebase_auth.dart'; // for privacy password, using auth firebase

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late double widthRatio;
  late double heightRatio;

  Future<bool> _checkUserExists(String uid) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.exists;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widthRatio = MediaQuery.of(context).size.width / 393.0;
    heightRatio = MediaQuery.of(context).size.height / 852.0;

  }

  @override
  void initState() {
    super.initState();
    print("screens/korean_ui/login_screen.dart is currently showing");
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithIdAndPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // 사용자가 입력한 ID에 도메인을 추가하여 Firebase Auth가 인식하는 이메일 형식으로 변환합니다.
    final email = '${_idController.text.trim()}@silso.com';
    final password = _passwordController.text.trim();

    try {
      // Firebase Authentication을 사용하여 이메일과 비밀번호로 로그인을 시도합니다.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 로그인 성공 시, 다음 화면으로 이동합니다.
      // mounted 체크를 통해 위젯이 여전히 화면에 있는지 확인합니다.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AfterSignupSplash(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // FirebaseAuth에서 발생하는 예외를 처리합니다.
      String errorMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
      print('FirebaseAuthException code: ${e.code}'); // 디버깅을 위해 에러 코드 출력

      // 에러 코드에 따라 사용자에게 더 친절한 메시지를 보여줍니다.
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = '존재하지 않는 아이디입니다.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = '비밀번호가 일치하지 않습니다.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // 그 외 일반적인 예외를 처리합니다.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 중 오류가 발생했습니다: ${e.toString()}')),
        );
      }
    } finally {
      // 작업이 성공하든 실패하든 로딩 상태를 해제합니다.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInAnonymously();
      if (mounted) {
        // 익명 로그인 시에도 PhoneConfirmScreen으로 이동 (회원가입 플로우)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const  MyPetSelect(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

 Widget _buildCircularButton({
  required VoidCallback? onTap,
  required Color backgroundColor,
  String? imagePath,
  IconData? iconData,
  Color? iconColor,
}) {
  // 에러 방지: 두 매개변수 중 하나만 제공되었는지 확인
  assert(imagePath != null || iconData != null, 'Either imagePath or iconData must be provided.');
  assert(imagePath == null || iconData == null, 'Cannot provide both imagePath and iconData.');

  // 버튼 내부에 표시할 위젯을 결정
  Widget content;
  if (imagePath != null) {
    // 이미지 경로가 제공된 경우 Image 위젯 사용
    content = ClipOval(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: 72 * widthRatio,
        height: 72 * widthRatio,
      ),
    );
  } else {
    // 아이콘 데이터가 제공된 경우 Icon 위젯 사용
    content = Center(
      child: Icon(
        iconData,
        color: iconColor,
        size: 32 * widthRatio,
      ),
    );
  }

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(400),
      child: Container(
        width: 72 * widthRatio,
        height: 72 * widthRatio,
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: const CircleBorder(),
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content, // 동적으로 결정된 위젯(content) 사용
      ),
    ),
  );
}

Widget _buildInputField({
  required TextEditingController controller,
  required String hintText,
  bool isPassword = false,
  String? Function(String?)? validator,
}) {
  return Container(
    width: 360 * widthRatio,
    height: 65 * heightRatio,
    decoration: ShapeDecoration(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          width: 1,
          color: const Color(0xFFBDBDBD),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    child: TextFormField(
      controller: controller,
      obscureText: isPassword, // 비밀번호 필드일 경우 텍스트를 가립니다.
      validator: validator,
      style: TextStyle(
        color: const Color(0xFF121212),
        fontSize: 18 * widthRatio,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        border: InputBorder.none, // 컨테이너에 이미 테두리가 있어 기본 테두리를 제거합니다.
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFBDBDBD),
          fontSize: 18 * widthRatio,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 15 * heightRatio,
        ),
      ),
    ),
  );
}

// 기본 버튼 위젯을 만드는 함수
Widget _buildPrimaryButton({
  required String text,
  required VoidCallback? onPressed,
}) {
  return Container(
    width: 360 * widthRatio,
    height: 52 * heightRatio,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5F37CF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * widthRatio),
        ),
        padding: EdgeInsets.symmetric(vertical: 14 * heightRatio),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * widthRatio,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          height: 1.23,
        ),
      ),
    ),
  );
}

// lib/screens/login_screen.dart 파일의 build 메서드

@override
Widget build(BuildContext context) {
  // 기준 해상도 (iPhone 16)
  const double baseWidth = 393.0;
  const double baseHeight = 852.0;

  // 현재 화면의 너비와 높이를 가져와 비율 계산
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final double widthRatio = screenWidth / baseWidth;
  final double heightRatio = screenHeight / baseHeight;

  // 새로운 디자인에서는 어두운 배경 대신 밝은 배경을 사용
  return Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    body: Stack(
      children: [

        // 로고 이미지
        // silso-logo
        Positioned(
        left: 16 * widthRatio,
        top: 145 * heightRatio,
        child: SizedBox(
        width: 90 * widthRatio,
        height: 37 * heightRatio,
        child: Image.asset(
        'assets/images/silso_logo/login_logo.png', // 확장자를 .svg에서 .png로 변경
        fit: BoxFit.contain, // 또는 BoxFit.fill 등 필요에 따라 조절
        ),
        ),
        ),

        // 메인 제목
        Positioned(
          left: 16 * widthRatio,
          top: 199 * heightRatio,
          child: Text(
            '로그인을 시작합니다!',
            style: TextStyle(
              color: const Color(0xFF121212),
              fontSize: 24 * widthRatio,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),

        // 서브 텍스트
        Positioned(
          left: 16 * widthRatio,
          top: 235 * heightRatio,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '실소의 맴버가 되어주세요!',
                  style: TextStyle(
                    color: const Color(0xFFC7C7C7),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    height: 2.14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 로그인 폼 -> custom id (email 응용)
        Positioned(
          left: 17 * widthRatio,
          top: 295 * heightRatio, // 적절한 위치에 배치
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 이메일 입력 필드
                _buildInputField(
                  controller: _idController,
                  hintText: '아이디',
                ),
                SizedBox(height: 16 * heightRatio),
                // 비밀번호 입력 필드
                _buildInputField(
                  controller: _passwordController,
                  hintText: '비밀번호',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해 주세요.';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32 * heightRatio), // 입력 필드와 버튼 사이 간격 추가


                // 로그인 버튼
                   _buildPrimaryButton(
                    text: '로그인',
                    onPressed: _isLoading ? null : _signInWithIdAndPassword,
                  ),

              ],
            ),
          ),
        ),


        // 로그인 버튼 그룹
        Positioned(
          left: (393 * widthRatio - 328) / 2,
          top: 580 * heightRatio,
          child: Container(
            width: 360 * widthRatio,
            child: Row( // Column 대신 Row를 사용하여 버튼들을 가로로 배치합니다.
              mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
              children: [
                // 카카오 로그인 원형 버튼
                _buildCircularButton(
                  onTap: _isLoading ? null : _handleKakaoSignInWithImage,
                  backgroundColor: const Color(0xFFFFE600),
                  imagePath: 'assets/button/kakao_login_circular.png', // 카카오 원형 로고 이미지 경로
                ),
                SizedBox(width: 40 * widthRatio), // 버튼 간 간격
                // 구글 로그인 원형 버튼
                _buildCircularButton(
                  onTap: _isLoading ? null : _handleGoogleSignInWithImage,
                  backgroundColor: Colors.white,
                  imagePath: 'assets/button/google_login_circular.png', // 구글 원형 로고 이미지 경로
                ),
                
                // SizedBox(width: 40 * widthRatio), // 버튼 간 간격
                // // 전화번호 로그인 
                // _buildCircularButton(
                // onTap: _isLoading ? null : () {
                //   Navigator.of(context).pushReplacement(
                //     MaterialPageRoute(
                //       builder: (context) => const PhoneConfirmScreen(isFromLogin: false),
                //     ),
                //   );
                // },
                //   backgroundColor: Color(0xFFE0E0E0),
                //   iconData: Icons.phone, // 전화 로고 이미지 경로
                //   iconColor: Color(0xFF8E8E8E)
                // ),
              ],
            ),
          ),
        ),

         // 회원가입 버튼
          Positioned(
            left: (393 * widthRatio - 80) / 2,
            top: 712 * heightRatio,
            child:                  
                 TextButton(
                  child: Text(
                    '회원가입',
                    style: TextStyle(
                      color: Color(0xFF5F37CF),
                      fontSize: 15 * widthRatio,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: _isLoading ? null :  () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const IDPasswordSignUpScreen(isIdAndPasswordShortCut: true),
                      ),
                    );
                  },
                ),
            ), 

         // 비회원으로 구경하기 버튼
          Positioned(
            left: (393 * widthRatio - 128) / 2,
            top: 770 * heightRatio, // 새로운 위치로 조정 (기존 570에서 672로 변경)
            child: GestureDetector(
              onTap: _isLoading ? null : _signInAnonymously,
              child: Container(
                width: 138 * widthRatio,
                height: 26 * heightRatio,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: const Color(0xFF5F37CF), // 보라색 테두리
                    ),
                    borderRadius: BorderRadius.circular(400), // 충분히 둥근 모서리
                  ),
                ),
                child: Center(
                  child: Text(
                    '비회원으로 구경하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF5F37CF), // 텍스트 색상을 테두리 색상과 맞춤
                      fontSize: 14 * widthRatio,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
 



      ],
    ),
  );
}



  Future<void> _handleKakaoSignInWithImage() async {
    setState(() => _isLoading = true);

    try {
      // 1. Kakao OAuth 로그인 실행
      final userCredential = await _authService.signInWithKakao();

      if (userCredential?.user != null && mounted) {
        // 2. Firebase Auth UID 가져오기
        final String uid = userCredential!.user!.uid;

        // 3. Firestore에서 해당 UID로 사용자 문서 존재 확인
        final bool isExistingUser = await _checkUserExists(uid);

        // 4. 기존 회원 여부에 따라 플로우 분기
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => //PhoneConfirmScreen(isFromLogin: isExistingUser),
            isExistingUser ?  AfterSignupSplash() :  IDPasswordSignUpScreen(isIdAndPasswordShortCut: false), 
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인 오류: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  Future<void> _handleGoogleSignInWithImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Google OAuth 로그인 실행
      final userCredential = await _authService.signInWithGoogle();       

      if (userCredential?.user != null && mounted) {
        // 2. Firebase Auth UID 가져오기
        final String uid = userCredential!.user!.uid;

        // 3. Firestore에서 해당 UID로 사용자 문서 존재 확인
        final bool isExistingUser = await _checkUserExists(uid);

        // 4. 기존 회원 여부에 따라 플로우 분기
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => // PhoneConfirmScreen(isFromLogin: isExistingUser), //   [need modify]
            isExistingUser ? AfterSignupSplash() :  IDPasswordSignUpScreen(isIdAndPasswordShortCut: false), 
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구글 로그인 오류: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}

