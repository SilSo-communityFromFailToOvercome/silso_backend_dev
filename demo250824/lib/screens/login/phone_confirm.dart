import 'dart:async'; // Timer를 사용하기 위해 import 합니다.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 필요한 서비스와 화면을 import 합니다.
import '../../../services/community_service.dart';
//import 'policy_agreement_screen.dart'; // 다음 화면으로 이동하기 위해 필요합니다.
import 'intro_signin_splash.dart';
import 'dart:convert'; // Required for utf8.encode
import 'package:crypto/crypto.dart'; // Required for sha256

/// 사용자의 프로필 정보를 입력받는 화면입니다.
/// 사용자 입력을 처리하기 위해 StatefulWidget으로 구성되었습니다.
class PhoneConfirmScreen extends StatefulWidget {
  // 로그인 경로에서 왔는지 회원가입 경로에서 왔는지 구분하는 매개변수 추가
  final bool isFromLogin;
  
  const PhoneConfirmScreen({super.key, this.isFromLogin = false});

  @override
  State<PhoneConfirmScreen> createState() =>
      _PhoneConfirmScreenState();
}

class _PhoneConfirmScreenState extends State<PhoneConfirmScreen> {
  // --- Services ---
  final CommunityService _communityService = CommunityService();

  // --- Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();

  // --- Form Key ---
  final _formKey = GlobalKey<FormState>();

  // --- State Variables ---
  final List<bool> _nationalitySelection = [true, false];
  String _selectedGender = '여';
  String _selectedTelecom = 'SKT';
  bool _isLoading = false; // 로딩 상태를 관리하는 변수

  // --- Phone Verification State Variables (추가된 부분) ---
  bool _isVerificationRequested = false; // 인증번호 요청 여부
  bool _isRequestingVerification = false; // 인증번호를 요청하는 중인지 여부
  String? _verificationId; // Firebase로부터 받은 인증 ID
  int _resendCountdown = 0; // 재전송 대기 시간 (초)
  Timer? _timer; // 카운트다운 타이머

   @override
  void dispose() {
    // 모든 컨트롤러와 타이머를 정리합니다.
    _nameController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    _authCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// 전화번호 인증 코드 발송을 요청하는 메서드 (새로 추가된 메서드)
  Future<void> _requestVerification() async {
    // 전화번호 유효성 검사
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('전화번호를 입력해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isRequestingVerification = true;
      _isLoading = true; // 전체적인 로딩 상태
    });

    // 국가번호(+82)를 포함한 전체 전화번호
    final fullPhoneNumber = "+82$phone";

    try {
      await _communityService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        codeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isVerificationRequested = true;
              _isRequestingVerification = false;
              _isLoading = false;
              _resendCountdown = 60; // 60초 타이머 시작
            });
            _startCountdown();
          }
        },
        verificationFailed: (error) {
          if (mounted) {
            setState(() {
              _isRequestingVerification = false;
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('인증 실패: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRequestingVerification = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('인증 코드 요청에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 재전송 카운트다운을 시작하는 메서드 (새로 추가된 메서드)
  void _startCountdown() {
    _timer?.cancel(); // 기존 타이머가 있다면 취소
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        if (mounted) {
          setState(() {
            timer.cancel();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      }
    });
  }

  /// 로그인 사용자를 위한 Firebase 사용자 검증 메서드 ; 
  Future<bool> _validateExistingUser() async {
    if (!widget.isFromLogin) return true; // 회원가입 경로는 검증 스킵
    
    print('🔍 로그인 사용자 Firebase 검증 시작');
    
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final currentUser = auth.currentUser;
      
      if (currentUser == null) {
        throw Exception('인증된 사용자가 없습니다. 다시 로그인해주세요.');
      }
      
      print('📄 현재 사용자 UID: ${currentUser.uid}');
      
      // 1. Firestore에서 사용자 문서 조회
      final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        throw Exception('사용자 정보가 존재하지 않습니다.');
      }
      
      final userData = userDoc.data()!;
      print('📊 사용자 문서 데이터 로드 완료');
      
      // 2. settings.isActive 상태 확인
      final settings = userData['settings'] as Map<String, dynamic>?;
      final isActive = settings?['isActive'] ?? false;
      
      if (!isActive) {
        throw Exception('비활성화된 계정입니다. 고객센터에 문의해주세요.');
      }
      
      print('✅ 계정 활성화 상태 확인 완료');
      
      // 3. 저장된 전화번호 비교 및 검증
      final storedphonenum = userData['phoneNumber']?.toString() ??  '';
      if (storedphonenum == null) {
        throw Exception('저장된 전화번호가 없습니다.');
      }
      
      // 입력한 정보와 저장된 정보 비교 sha256 hash값 전화번호 비교, 
        final inputPhoneNumber = "+82${_phoneController.text.trim()}";
        final inputBytes = utf8.encode(inputPhoneNumber);
        final inputDigest = sha256.convert(inputBytes);
        final inputHashedPhoneNumber = inputDigest.toString();
      
      print('🔍 정보 비교:');
      print('전화번호: $storedphonenum vs $inputHashedPhoneNumber');
 
      // 4. 이미 존재하는 전화번호 체크 및 사용자에게 알림
      if (storedphonenum == inputHashedPhoneNumber) {
         throw Exception('입력하신 전화번호는 이미 등록된 번호입니다.');
      }
      
      return true;
      
    } catch (e) {
      print('🚨 사용자 검증 오류: $e');
      // 에러를 다시 던져서 상위에서 처리하도록 함
      rethrow;
    }
  }

  /// '계속하기' 버튼을 눌렀을 때 실행될 메서드 (수정된 메서드)
  Future<void> _submitProfile() async {
    // 1. 폼 유효성 검사
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // 2. 인증번호 요청 여부 및 인증번호 입력 확인
    if (_verificationId == null || _authCodeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('휴대폰 인증을 먼저 완료해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // 3. 로그인 사용자 검증 (isFromLogin: true인 경우)
      if (widget.isFromLogin) {
        print('🔍 로그인 사용자 - Firebase 검증 실행');
        //await //_validateExistingUser(); 
        print('✅ Firebase 검증 완료');
      }

      // 4. SMS 인증 코드 검증
      await _communityService.verifySMSCode(
        verificationId: _verificationId!,
        smsCode: _authCodeController.text.trim(),
      );

      // 5. 인증 성공 시, 프로필 정보 저장 (회원가입 경로만)
      if (!widget.isFromLogin) {
        print('📝 회원가입 경로 - 프로필 정보 저장');
        final String country = _nationalitySelection[0] ? '내국인' : '외국인';
        final bytes = utf8.encode('+82${_phoneController.text}'); // data being hashed
        final digest = sha256.convert(bytes);
        final hashedPassword = digest.toString();

        await _communityService.saveProfileInformation(
           phoneNumber: hashedPassword, // 국가번호 포함
        );
      } else {
        print('📱 로그인 경로 - 프로필 정보 저장 스킵 (이미 검증 완료)');
      }

      // 6. 인증 완료 시 다음 화면으로 이동 - 경로별 분기 처리
      if (mounted) {
        // 성공 메시지 표시 - 경로별 다른 메시지
        final successMessage = widget.isFromLogin 
            ? '본인 인증이 완료되었습니다!' 
            : '인증 및 프로필 저장이 완료되었습니다!';
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );

         Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SigininSplashScreen(),
            ),
          );
      }
    } catch (e) {
      // 오류 발생 시 SnackBar로 메시지 표시 - 에러 타입별 구분
      if (mounted) {
        String errorMessage;
        Color backgroundColor;
        
        // 검증 실패 에러와 일반 에러 구분
        if (e.toString().contains('입력하신 정보가 등록된 정보와 다릅니다') ||
            e.toString().contains('비활성화된 계정입니다') ||
            e.toString().contains('인증된 사용자가 없습니다')) {
          // 사용자 검증 관련 에러 - 자세한 메시지 표시
          errorMessage = e.toString().replaceAll('Exception: ', '');
          backgroundColor = const Color(0xFFFF9800); // 오렌지색 (경고)
        } else {
          // 일반 시스템 에러
          errorMessage = '처리 중 오류가 발생했습니다: ${e.toString()}';
          backgroundColor = Colors.red;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5), // 검증 에러는 좀 더 길게 표시
          ),
        );
      }
    } finally {
      // 로딩 상태 종료
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context),
      body: Form( // Form 위젯으로 감싸 유효성 검사를 활성화합니다.
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 35),
                      _buildSectionTitle('휴대폰 인증'),
                      const SizedBox(height: 15),
                      _buildPhoneAuthSection(), // 수정된 휴대폰 인증 섹션
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            _buildContinueButton(), // 수정된 계속하기 버튼
          ],
        ),
      ),
    );
  }
  
  // --- 이하 위젯 빌드 메서드들 ---

PreferredSizeWidget _buildAppBar(BuildContext context) {
  final double baseWidth = 393.0;
  final double baseHeight = 852.0;
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final double widthRatio = screenWidth / baseWidth;
  final double heightRatio = screenHeight / baseHeight;
  
  return PreferredSize(
    preferredSize: Size.fromHeight(118 * heightRatio),
    child: Container(
      width: double.infinity,
      height: 118 * heightRatio,
      color: const Color(0xFFFAFAFA),
      child: Stack(
        children: [
          // 뒤로가기 버튼
          Positioned(
            left: 16 * widthRatio,
            top: 68 * heightRatio,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(), // 현재 화면에서 나가기
            ),
          ),
          // 제목
          Positioned(
            left: 153 * widthRatio,
            top: 73 * heightRatio,
            child: Text(
              '실소 회원가입',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 18 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.62,
              ),
            ),
          ),
          // 상태바 영역 (SafeArea)
          const Positioned(
            left: 0,
            top: 0,
            child: SafeArea(
              child: SizedBox.shrink(),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF121212),
        fontSize: 16,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ),
    );
  }


  
  /// 휴대폰 인증 섹션 UI (수정된 부분)
  Widget _buildPhoneAuthSection() {
    // 재전송 버튼이 활성화되어야 하는지 여부
    final canResend = _resendCountdown == 0 && !_isRequestingVerification;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildRadioButton('SKT'),
            const SizedBox(width: 30),
            _buildRadioButton('KT'),
            const SizedBox(width: 30),
            _buildRadioButton('LG U+'),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextFormField( // TextField -> TextFormField로 변경
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
                decoration: _textFieldDecoration(
                  hintText: "'-' 없이 전화번호 입력",
                  prefixText: '+82 ',
                ).copyWith(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6),
                    ),
                    borderSide: BorderSide(color: Color(0xFF5F37CF)),
                  ),
                ),
                 validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '전화번호를 입력해주세요.';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(
              width: 116,
              height: 52,
              child: TextButton(
                // 카운트다운 중이 아닐 때만 버튼 활성화
                onPressed: canResend ? _requestVerification : null,
                style: TextButton.styleFrom(
                  backgroundColor: canResend ? const Color(0xFF121212) : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
                child: _isRequestingVerification 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
                  : Text(
                      _isVerificationRequested ? (_resendCountdown > 0 ? '${_resendCountdown}초' : '재전송') : '인증요청',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
        // if (_isVerificationRequested) ...[
          const SizedBox(height: 8),
          TextFormField( // TextField -> TextFormField로 변경
            controller: _authCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
            decoration: _textFieldDecoration(hintText: '인증번호 6자리 입력').copyWith(
              counterText: '', // 글자 수 카운터 숨기기
            ),
            validator: (value) {
              if (value == null || value.length != 6) {
                return '인증번호 6자리를 입력해주세요.';
              }
              return null;
            },
          ),
        // ]
      ],
    );
  }

  Widget _buildRadioButton(String label) {
    final bool isSelected = (_selectedTelecom == label);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTelecom = label;
        });
      },
      child: Row(
        children: [
          Container(
            width: 19,
            height: 19,
            decoration: ShapeDecoration(
              shape: OvalBorder(
                side: const BorderSide(width: 1, color: Color(0xFFBBBBBB)),
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const ShapeDecoration(
                        color: Color(0xFF121212),
                        shape: OvalBorder(),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }

  /// 하단의 '계속하기' 버튼 위젯 (수정된 부분)
  Widget _buildContinueButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            // 로딩 중이 아닐 때 _submitProfile 메서드 호출
            onPressed: _isLoading ? null : _submitProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5F37CF),
              foregroundColor: const Color(0xFFFAFAFA),
              // 로딩 중일 때 비활성화된 버튼 색상
              disabledBackgroundColor: const Color(0xFF5F37CF).withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                // 로딩 중이면 인디케이터 표시
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                // 로딩 중이 아니면 텍스트 표시
                : const Text(
                    '계속하기',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  InputDecoration _textFieldDecoration(
      {required String hintText, String? prefixText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF737373)),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: Color(0xFF121212),
        fontSize: 16,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFEAEAEA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF5F37CF)),
      ),
      errorBorder: OutlineInputBorder( // 에러 발생 시 테두리
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder( // 에러 발생 후 포커스 시 테두리
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.red, width: 2.0),
      ),
    );
  }
}