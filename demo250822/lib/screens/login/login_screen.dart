import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'phone_confirm.dart';
import 'mypet_select.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  // bool _isSignUp = false;
  late double widthRatio;
  late double heightRatio;

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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      
      if (mounted) {
        // 로그인 성공 시 PhoneConfirmScreen으로 이동 (isFromLogin: true)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PhoneConfirmScreen(isFromLogin: true),
          ),
        );
      }

      if (!mounted) {
        // 로그인  실패 시 PhoneConfirmScreen으로 이동 (isFromLogin: true)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PhoneConfirmScreen(isFromLogin: false),
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
                  controller: _emailController,
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

                // // 회원가입 버튼
                // if (_isSignUp) // _isSignUp이 true일 때만 이 버튼을 표시
                //   _buildPrimaryButton(
                //     text: '회원가입',
                //     onPressed: _isLoading ? null : _signInWithPhone,
                //   ),

                // 로그인 버튼
                   _buildPrimaryButton(
                    text: '로그인',
                    onPressed: _isLoading ? null : _signInWithPhone,
                  ),

              ],
            ),
          ),
        ),


        // 로그인 버튼 그룹
        Positioned(
          left: 17 * widthRatio,
          top: 600 * heightRatio,
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
                
                SizedBox(width: 40 * widthRatio), // 버튼 간 간격
                // 전화번호 로그인 
                _buildCircularButton(
                onTap: _isLoading ? null : () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const PhoneConfirmScreen(isFromLogin: false),
                    ),
                  );
                },
                  backgroundColor: Color(0xFFE0E0E0),
                  iconData: Icons.phone, // 전화 로고 이미지 경로
                  iconColor: Color(0xFF8E8E8E)
                ),
              ],
            ),
          ),
        ),


         // 비회원으로 구경하기 버튼
          Positioned(
            left: 130 * widthRatio,
            top: 760 * heightRatio, // 새로운 위치로 조정 (기존 570에서 672로 변경)
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
      await _authService.signInWithKakao();
      if (mounted) {
        // 카카오 로그인 시 PhoneConfirmScreen으로 이동 (회원가입 플로우)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PhoneConfirmScreen(isFromLogin: false),
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

    Future<void> _handleGoogleSignInWithImage() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        // 구글 로그인 시 PhoneConfirmScreen으로 이동 (회원가입 플로우)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const PhoneConfirmScreen(isFromLogin: false),
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

}

