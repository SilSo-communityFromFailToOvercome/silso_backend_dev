// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IDPasswordSignUpScreen extends StatefulWidget {
  const IDPasswordSignUpScreen({super.key});

  @override
  State<IDPasswordSignUpScreen> createState() => _IDPasswordSignUpScreenState();
}

class _IDPasswordSignUpScreenState extends State<IDPasswordSignUpScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isIdAvailable = false; // 아이디 중복 확인 상태
  bool _isIdAvailableInitial = true; // 아이디 중복 확인 처음 상태
  bool _isPasswordValid = false; // 비밀번호 유효성 상태

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  // 아이디 중복 확인 로직 - 현재 사용자 제외  
  void _checkIdAvailability() async {
    final id = _idController.text;

    // 1) 로컬 유효성 검사 (정규식 사용)
    final idRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9]{3,11}$');
    _isIdAvailableInitial = false; // 최초 상태 false 

    if (!idRegex.hasMatch(id)) {
      setState(() {
        _isIdAvailable = false;
      });
      return;
    }

    // 2) Firebase Firestore 탐색 및 중복 확인
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final currentUser = auth.currentUser;
      
      // 'users' 컬렉션에서 해당 아이디를 사용하는 문서 검색
      final result = await firestore.collection('users').where('authentication.id', isEqualTo: id).limit(1).get();

      if (result.docs.isEmpty) {
        // 중복되는 ID가 없으면 사용 가능
        setState(() {
          _isIdAvailable = true;
        });
      } else {
        // 문서가 존재하는 경우, 현재 사용자의 문서인지 확인
        final existingDoc = result.docs.first;
        final isCurrentUserDoc = (currentUser != null && existingDoc.id == currentUser.uid);
        
        if (isCurrentUserDoc) {
          // 현재 사용자의 기존 문서라면 사용 가능
          setState(() {
            _isIdAvailable = true;
          });
          print('💡 현재 사용자의 기존 아이디입니다. 사용 가능합니다.');
        } else {
          // 다른 사용자가 사용 중인 아이디
          setState(() {
            _isIdAvailable = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 사용 중인 아이디입니다. 다른 아이디를 사용해주세요.')),
          );
        }
      }
    } catch (e) {
      print('아이디 중복 확인 중 오류 발생: $e');
      setState(() {
        _isIdAvailable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
      );
    }
  }

  // 비밀번호 유효성 검사 로직
  void _validatePassword() {
    final password = _passwordController.text;
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    final meetsTwoCriteria = (hasLetters && hasNumbers) ||
                             (hasLetters && hasSpecial) ||
                             (hasNumbers && hasSpecial);
    
    final isLengthValid = password.length >= 6 && password.length <= 20;
    final isValid = isLengthValid && meetsTwoCriteria;

    setState(() {
      _isPasswordValid = isValid;
    });
  }

// '다음' 버튼 로직 - 기존 사용자 계정에 이메일/비밀번호 추가
void _onNext() async {
  // 1. 기본 유효성 검사
  if (!_isIdAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아이디 중복 확인을 완료해주세요.')),
    );
    return;
  }
  
  if (!_isPasswordValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('올바른 비밀번호를 입력해주세요.')),
    );
    return;
  }
  
  if (_passwordController.text != _confirmPasswordController.text) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
    );
    return;
  }

  // 2. 로딩 상태 표시
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  try {
    // 3. Firebase 초기화 확인
    await Firebase.initializeApp();
    
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    // 4. 현재 로그인된 사용자 확인 (phone_confirm에서 인증된 사용자)
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw Exception('사용자가 로그인되어 있지 않습니다. 다시 처음부터 진행해주세요.');
    }
    
    final currentUserId = currentUser.uid;
    print('🔄 기존 사용자 계정 사용. UID: $currentUserId');

    // 5. 기존 사용자에게 이메일/비밀번호 인증 정보 추가
    print('🔄 이메일/비밀번호 인증 정보 추가 중...');
    final credential = EmailAuthProvider.credential(
      email: _idController.text + '@silso.com',
      password: _passwordController.text,
    );
    
    // 기존 사용자 계정에 이메일/비밀번호 인증 방법 연결
    await currentUser.linkWithCredential(credential);
    print('✅ 이메일/비밀번호 인증 정보 추가 완료');

    // 6. Firestore의 기존 사용자 문서에 추가 정보 merge
    print('🔄 Firestore에 추가 사용자 정보 merge 중...');
    
    // 기존 문서 존재 여부 확인
    final existingDoc = await firestore.collection('users').doc(currentUserId).get();
    print('📄 기존 문서 존재: ${existingDoc.exists}');

    final additionalUserData = {
      'profile': {
        'uid': currentUserId,
       },
      'authentication': {
        'id': _idController.text + '@silso.com',  // email 형식 활용
        'password' : _passwordController.text, 
        'hasPhoneAuth': true,
        'hasEmailPassword': true,
        'emailPasswordSetupAt': FieldValue.serverTimestamp(),
      },
      'settings': {
        'isActive': true,
        'signUpCompleted': true,
        'emailPasswordCompleted': true,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 기존 문서와 merge
    await firestore.collection('users').doc(currentUserId).set(
      additionalUserData,
      SetOptions(merge: true)
    );

    // 7. 업데이트 확인 (재검증)
    print('🔄 Firestore 업데이트 확인 중...');
    final updatedDocSnapshot = await firestore.collection('users').doc(currentUserId).get();
    if (!updatedDocSnapshot.exists) {
      throw Exception('Firestore 문서 업데이트에 실패했습니다.');
    }
    
    final updatedData = updatedDocSnapshot.data()!;
    if (!updatedData.containsKey('authentication') || 
        !updatedData['authentication']['hasEmailPassword']) {
      throw Exception('이메일/비밀번호 정보 저장이 확인되지 않습니다.');
    }
    print('✅ Firestore 업데이트 확인 완료');
    print('📊 최종 사용자 데이터: ${updatedData.keys}');

    // 8. 로딩 다이얼로그 닫기
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }

    // 9. 성공 메시지 및 다음 페이지로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('아이디/비밀번호 설정이 완료되었습니다!'),
        backgroundColor: Color(0xFF03A20B),
      ),
    );
    
    Navigator.of(context).pushReplacementNamed('/login-splash');

  } on FirebaseAuthException catch (e) {
    // Firebase Auth 에러 처리
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    String errorMessage = '아이디/비밀번호 설정 중 오류가 발생했습니다.';
    print('🚨 FirebaseAuthException: ${e.code} - ${e.message}');
    
    switch (e.code) {
      case 'weak-password':
        errorMessage = '비밀번호가 너무 약합니다.';
        break;
      case 'email-already-in-use':
        errorMessage = '이미 사용 중인 아이디(이메일)입니다.';
        break;
      case 'invalid-email':
        errorMessage = '유효하지 않은 이메일 형식입니다.';
        break;
      case 'credential-already-in-use':
        errorMessage = '이미 다른 계정에서 사용 중인 이메일입니다.';
        break;
      case 'provider-already-linked':
        errorMessage = '이미 이메일/비밀번호가 설정된 계정입니다.';
        break;
      case 'network-request-failed':
        errorMessage = '네트워크 연결을 확인해주세요.';
        break;
      default:
        errorMessage = '인증 오류: ${e.message}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: const Color(0xFFC31A1A),
      ),
    );
    
  } on FirebaseException catch (e) {
    // Firestore 에러 처리
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    print('🚨 FirebaseException: ${e.code} - ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('데이터 저장 오류: ${e.message}'),
        backgroundColor: const Color(0xFFC31A1A),
      ),
    );
    
  } catch (e) {
    // 일반 에러 처리
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    print('🚨 일반 오류 발생: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('아이디/비밀번호 설정 중 예상치 못한 오류가 발생했습니다: $e'),
        backgroundColor: const Color(0xFFC31A1A),
      ),
    );
  }
}

// lib/screens/signup_screen.dart 파일의 build 메서드

  @override
  Widget build(BuildContext context) {
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = MediaQuery.of(context).size.height / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Form(
        key: _formKey,
        child: Stack(
        children: [
          // 상단 AppBar와 뒤로가기 버튼
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 393 * widthRatio,
              height: 118 * heightRatio,
              decoration: BoxDecoration(color: const Color(0xFFFAFAFA)),
              child: Stack(
                children: [
                  Positioned(
                    left: 16 * widthRatio,
                    top: 68 * heightRatio,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // '아이디' 텍스트
          Positioned(
            left: 16 * widthRatio,
            top: 125 * heightRatio,
            child: Text(
              '아이디',
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 아이디 입력 필드
          Positioned(
            left: 17 * widthRatio,
            top: 155 * heightRatio,
            child: Container(
              width: 245 * widthRatio,
              height: 52 * heightRatio,
              child: TextFormField(
                controller: _idController,
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 16 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEAEAEA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 17 * widthRatio),
                  hintText: '아이디를 입력하세요', // 디자인에 없지만, 사용자 편의를 위해 추가
                  hintStyle: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // 중복확인 버튼
          Positioned(
            left: 271 * widthRatio,
            top: 155 * heightRatio,
            child: ElevatedButton(
              onPressed: _checkIdAvailability,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF121212),
                fixedSize: Size(106 * widthRatio, 52 * heightRatio),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                '중복확인',
                style: TextStyle(
                  color: const Color(0xFFFAFAFA),
                  fontSize: 16 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // 아이디 사용 가능 메시지
          Positioned(
            left: 38 * widthRatio,
            top: 218 * heightRatio,
            child: SizedBox(
              width: 296 * widthRatio,
              child: Text(
                _isIdAvailableInitial ? (_isIdAvailable ? '사용 가능한 아이디!' : '영문과 숫자만 사용하여, 영문으로 시작되는 4-12자의 아이디를 입력해주세요.') : (_isIdAvailable ? '사용 가능한 아이디!' : '사용 불가한 아이디'),
                style: TextStyle(
                  color: _isIdAvailableInitial ? (_isIdAvailable ? const Color(0xFF03A20B) : const Color(0xFF5F37CF)) : (_isIdAvailable ? const Color(0xFF03A20B) : const Color(0xFFC31A1A)),
                  fontSize: 12 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // '비밀번호' 텍스트
          Positioned(
            left: 16 * widthRatio,
            top: 295 * heightRatio,
            child: Text(
              '비밀번호',
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 비밀번호 입력 필드
          Positioned(
            left: 17 * widthRatio,
            top: 329 * heightRatio,
            child: Container(
              width: 360 * widthRatio,
              height: 52 * heightRatio,
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                onChanged: (_) => _validatePassword(),
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 16 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEAEAEA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 17 * widthRatio),
                  hintText: '비밀번호를 입력하세요',
                  hintStyle: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),

                  suffix: Padding( // 메시지 좌우 여백을 위해 Padding 위젯 사용
                  padding: EdgeInsets.symmetric(horizontal: 10 * widthRatio),
                  child: Text(
                    _isPasswordValid ? '사용가능' : '사용불가',
                    style: TextStyle(
                      color: _isPasswordValid ? const Color(0xFF03A20B) : const Color(0xFFC31A1A),
                      fontSize: 12 * widthRatio,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ),
              ),
            ),
          ),

          // 비밀번호 확인 입력 필드
          Positioned(
            left: 17 * widthRatio,
            top: 392 * heightRatio,
            child: Container(
              width: 360 * widthRatio,
              height: 52 * heightRatio,
              child: TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                onChanged: (_) {
                  setState(() {}); // 텍스트가 변경될 때마다 화면을 다시 그리도록 합니다.
                },
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '비밀번호가 일치하지 않습니다.';
                  }
                  return null;
                },
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 16 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFEAEAEA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 17 * widthRatio),
                  hintText: '비밀번호를 다시 입력하세요',
                  hintStyle: TextStyle(
                    color: const Color(0xFFBBBBBB),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                  ),

                 suffix: Padding( // 메시지 좌우 여백을 위해 Padding 위젯 사용
                  padding: EdgeInsets.symmetric(horizontal: 10 * widthRatio),
                  child: (_confirmPasswordController.text.isEmpty) ? null : 
                    (_confirmPasswordController.text != _passwordController.text) ? 
                    const Icon(Icons.cancel_outlined, color: Color(0xFFC31A1A)) : 
                    const Icon(Icons.check_circle_outline_outlined, color: Color(0xFF03A20B)),
                ),

                ),
              ),
            ),
          ),

          // 비밀번호 유효성 메시지
          Positioned(
            left: 34 * widthRatio,
            top: 455 * heightRatio,
            child: SizedBox(
              width: 296 * widthRatio,
              child: Text(
                _isPasswordValid ? '' : '영문 대소문자, 숫자, 특수문자 중 2가지 이상을 조합하여 6-20자로 입력해주세요',
                style: TextStyle(
                  color: _isPasswordValid ? Colors.green : const Color(0xFF5F37CF),
                  fontSize: 12 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // '다음' 버튼
          Positioned(
            left: 18 * widthRatio,
            top: 732 * heightRatio, // 적절한 위치로 조정
            child: SizedBox(
              width: 360 * widthRatio,
              height: 52 * heightRatio,
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isIdAvailable && _isPasswordValid ? const Color(0xFF5F37CF) : const Color(0xFFBDBDBD),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text( // after press this  <실소 회원가입 완료 screen : 3 seconds> 
                  '다음',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}