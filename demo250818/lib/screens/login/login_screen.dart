import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _isSignUp = false;

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

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await _authService.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed( '/after-login-splash');
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
        Navigator.of(context).pushReplacementNamed( '/after-login-splash');
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
            '가장 편한 방법으로\n시작해 보세요!',
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
          top: 269 * heightRatio,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '1분 ',
                  style: TextStyle(
                    color: const Color(0xFF5F37CF),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    height: 2.14,
                  ),
                ),
                TextSpan(
                  text: '이면 회원가입이 가능해요',
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

        // 로그인 버튼 그룹
        Positioned(
          left: 17 * widthRatio,
          top: 337 * heightRatio,
          child: Container(
            width: 360 * widthRatio,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16 * widthRatio,
              children: [
                // 카카오 로그인 버튼
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleKakaoSignInWithImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 52, // 일관된 버튼 높이
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/kakao_signin/kakao_login_large_wide.png',
                          fit: BoxFit.cover, // 높이에 맞춰 이미지 조정
                          width: double.infinity,
                          height: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                // 구글 로그인 버튼
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _handleGoogleSignInWithImage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 52, // 일관된 버튼 높이
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/google_signin/web_neutral_sq_ctn@4x.png',
                           fit: BoxFit.cover, // 높이에 맞춰 이미지 조정
                          width: double.infinity,
                          height: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                // Apple 로그인 버튼 (더미)
                _buildAppleButton(widthRatio),
              ],
            ),
          ),
        ),
        
        // 전화번호로 계속하기 버튼
        Positioned(
          left: 17 * widthRatio,
          top: 590 * heightRatio,
          child: Container(
            width: 360 * widthRatio,
            height: 52 * heightRatio,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {}, // 전화번호 로그인 로직으로 연결 필요
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5F37CF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * widthRatio),
                ),
                padding: EdgeInsets.symmetric(vertical: 14 * heightRatio),
              ),
              child: Text(
                '전화번호로 계속하기',
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
          ),
        ),

        // 비회원으로 구경하기 버튼
        Positioned(
          left: 136 * widthRatio,
          top: 672 * heightRatio,
          child: GestureDetector(
            onTap: _isLoading ? null : _signInAnonymously,
            child: Column(
              children: [
                Text(
                  '비회원으로 구경하기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    height: 1.58,
                  ),
                ),
                Container(
                  width: 113 * widthRatio,
                  height: 1 * widthRatio, // underline
                  color: const Color(0xFF8E8E8E),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


// 애플 로그인 버튼을 위한 더미 위젯
Widget _buildAppleButton(double widthRatio) {
  return Container(
    width: double.infinity,
    height: 52 * widthRatio,
    child: ElevatedButton(
      onPressed: () {}, // 애플 로그인 로직으로 연결 필요
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * widthRatio),
        ),
        padding: EdgeInsets.symmetric(vertical: 14 * widthRatio),
      ),
      child: Text(
        'Apple로 계속하기',
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

  Future<void> _handleKakaoSignInWithImage() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithKakao();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed( '/after-login-splash');
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
        Navigator.of(context).pushReplacementNamed('/after-login-splash');
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

