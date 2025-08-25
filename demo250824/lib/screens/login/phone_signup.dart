// // lib/screens/signup_screen.dart
// import 'dart:async'; // Timer를 사용하기 위해 import 합니다.
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../../services/community_service.dart';

// class PhoneSignUpScreen extends StatefulWidget {
//   const PhoneSignUpScreen({super.key});

//   @override
//   State<PhoneSignUpScreen> createState() => _PhoneSignUpScreenState();
// }

// class _PhoneSignUpScreenState extends State<PhoneSignUpScreen> {
//   final _idController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _authCodeController = TextEditingController();
//   final CommunityService _communityService = CommunityService();

//   bool _isIdAvailable = false; // 아이디 중복 확인 상태
//   bool _isIdAvailableInitial = true; // 아이디 중복 확인 처음 상태
//   bool _isPasswordValid = false; // 비밀번호 유효성 상태


//   // --- State Variables ---
//   final List<bool> _nationalitySelection = [true, false];
//   String _selectedGender = '여';
//   String _selectedTelecom = 'SKT';
//   bool _isLoading = false; // 로딩 상태를 관리하는 변수

//   // --- Phone Verification State Variables (추가된 부분) ---
//   bool _isVerificationRequested = false; // 인증번호 요청 여부
//   bool _isRequestingVerification = false; // 인증번호를 요청하는 중인지 여부
//   String? _verificationId; // Firebase로부터 받은 인증 ID
//   int _resendCountdown = 0; // 재전송 대기 시간 (초)
//   Timer? _timer; // 카운트다운 타이머

//   @override
//   void dispose() {
//     _idController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//     /// 전화번호 인증 코드 발송을 요청하는 메서드 (새로 추가된 메서드)
//   Future<void> _requestVerification() async {
//     // 전화번호 유효성 검사
//     final phone = _phoneController.text.trim();
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('전화번호를 입력해주세요.'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() {
//       _isRequestingVerification = true;
//       _isLoading = true; // 전체적인 로딩 상태
//     });

//     // 국가번호(+82)를 포함한 전체 전화번호
//     final fullPhoneNumber = "+82$phone";

//     try {
//       await _communityService.verifyPhoneNumber(
//         phoneNumber: fullPhoneNumber,
//         codeSent: (verificationId) {
//           if (mounted) {
//             setState(() {
//               _verificationId = verificationId;
//               _isVerificationRequested = true;
//               _isRequestingVerification = false;
//               _isLoading = false;
//               _resendCountdown = 60; // 60초 타이머 시작
//             });
//             _startCountdown();
//           }
//         },
//         verificationFailed: (error) {
//           if (mounted) {
//             setState(() {
//               _isRequestingVerification = false;
//               _isLoading = false;
//             });
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('인증 실패: $error'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         },
//       );
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isRequestingVerification = false;
//           _isLoading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('인증 코드 요청에 실패했습니다: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
  
//   // 아이디 중복 확인 로직 - 현재 사용자 제외  
//   void _checkIdAvailability() async {
//     final id = _idController.text;

//     // 1) 로컬 유효성 검사 (정규식 사용)
//     final idRegex = RegExp(r'^[a-zA-Z][a-zA-Z0-9]{3,11}$');
//     _isIdAvailableInitial = false; // 최초 상태 false 

//     if (!idRegex.hasMatch(id)) {
//       setState(() {
//         _isIdAvailable = false;
//       });
//       return;
//     }

//     // 2) Firebase Firestore 탐색 및 중복 확인
//     try {
//       final auth = FirebaseAuth.instance;
//       final firestore = FirebaseFirestore.instance;
//       final currentUser = auth.currentUser;
      
//       // 'users' 컬렉션에서 해당 아이디를 사용하는 문서 검색
//       final result = await firestore.collection('users').where('authentication.id', isEqualTo: id).limit(1).get();

//       if (result.docs.isEmpty) {
//         // 중복되는 ID가 없으면 사용 가능
//         setState(() {
//           _isIdAvailable = true;
//         });
//       } else {
//         // 문서가 존재하는 경우, 현재 사용자의 문서인지 확인
//         final existingDoc = result.docs.first;
//         final isCurrentUserDoc = (currentUser != null && existingDoc.id == currentUser.uid);
        
//         if (isCurrentUserDoc) {
//           // 현재 사용자의 기존 문서라면 사용 가능
//           setState(() {
//             _isIdAvailable = true;
//           });
//           print('💡 현재 사용자의 기존 아이디입니다. 사용 가능합니다.');
//         } else {
//           // 다른 사용자가 사용 중인 아이디
//           setState(() {
//             _isIdAvailable = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('이미 사용 중인 아이디입니다. 다른 아이디를 사용해주세요.')),
//           );
//         }
//       }
//     } catch (e) {
//       print('아이디 중복 확인 중 오류 발생: $e');
//       setState(() {
//         _isIdAvailable = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
//       );
//     }
//   }

//   // 비밀번호 유효성 검사 로직
//   void _validatePassword() {
//     final password = _passwordController.text;
//     final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
//     final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
//     final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

//     final meetsTwoCriteria = (hasLetters && hasNumbers) ||
//                              (hasLetters && hasSpecial) ||
//                              (hasNumbers && hasSpecial);
    
//     final isLengthValid = password.length >= 6 && password.length <= 20;
//     final isValid = isLengthValid && meetsTwoCriteria;

//     setState(() {
//       _isPasswordValid = isValid;
//     });
//   }

// // '다음' 버튼 로직 - 기존 사용자 계정에 이메일/비밀번호 추가
// void _onNext() async {
//   // 1. 기본 유효성 검사
//   if (!_isIdAvailable) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('아이디 중복 확인을 완료해주세요.')),
//     );
//     return;
//   }
  
//   if (!_isPasswordValid) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('올바른 비밀번호를 입력해주세요.')),
//     );
//     return;
//   }
  
//   if (_passwordController.text != _confirmPasswordController.text) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
//     );
//     return;
//   }

//   // 2. 로딩 상태 표시
//   showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) => const Center(child: CircularProgressIndicator()),
//   );

//   try {
//     // 3. Firebase 초기화 확인
//     await Firebase.initializeApp();
    
//     final auth = FirebaseAuth.instance;
//     final firestore = FirebaseFirestore.instance;

//     // 4. 현재 로그인된 사용자 확인 (phone_confirm에서 인증된 사용자)
//     final currentUser = auth.currentUser;
//     if (currentUser == null) {
//       throw Exception('사용자가 로그인되어 있지 않습니다. 다시 처음부터 진행해주세요.');
//     }
    
//     final currentUserId = currentUser.uid;
//     print('🔄 기존 사용자 계정 사용. UID: $currentUserId');

//     // 5. 기존 사용자에게 이메일/비밀번호 인증 정보 추가
//     print('🔄 이메일/비밀번호 인증 정보 추가 중...');
//     final credential = EmailAuthProvider.credential(
//       email: _idController.text + '@silso.com',
//       password: _passwordController.text,
//     );
    
//     // 기존 사용자 계정에 이메일/비밀번호 인증 방법 연결
//     await currentUser.linkWithCredential(credential);
//     print('✅ 이메일/비밀번호 인증 정보 추가 완료');

//     // 6. Firestore의 기존 사용자 문서에 추가 정보 merge
//     print('🔄 Firestore에 추가 사용자 정보 merge 중...');
    
//     // 기존 문서 존재 여부 확인
//     final existingDoc = await firestore.collection('users').doc(currentUserId).get();
//     print('📄 기존 문서 존재: ${existingDoc.exists}');

//     final additionalUserData = {
//       'profile': {
//         'uid': currentUserId,
//        },
//       'authentication': {
//         'id': _idController.text + '@silso.com',  // email 형식 활용
//         'password' : _passwordController.text, 
//         'hasPhoneAuth': true,
//         'hasEmailPassword': true,
//         'emailPasswordSetupAt': FieldValue.serverTimestamp(),
//       },
//       'settings': {
//         'isActive': true,
//         'signUpCompleted': true,
//         'emailPasswordCompleted': true,
//       },
//       'updatedAt': FieldValue.serverTimestamp(),
//     };

//     // 기존 문서와 merge
//     await firestore.collection('users').doc(currentUserId).set(
//       additionalUserData,
//       SetOptions(merge: true)
//     );

//     // 7. 업데이트 확인 (재검증)
//     print('🔄 Firestore 업데이트 확인 중...');
//     final updatedDocSnapshot = await firestore.collection('users').doc(currentUserId).get();
//     if (!updatedDocSnapshot.exists) {
//       throw Exception('Firestore 문서 업데이트에 실패했습니다.');
//     }
    
//     final updatedData = updatedDocSnapshot.data()!;
//     if (!updatedData.containsKey('authentication') || 
//         !updatedData['authentication']['hasEmailPassword']) {
//       throw Exception('이메일/비밀번호 정보 저장이 확인되지 않습니다.');
//     }
//     print('✅ Firestore 업데이트 확인 완료');
//     print('📊 최종 사용자 데이터: ${updatedData.keys}');

//     // 8. 로딩 다이얼로그 닫기
//     if (Navigator.canPop(context)) {
//       Navigator.of(context).pop();
//     }

//     // 9. 성공 메시지 및 다음 페이지로 이동
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('아이디/비밀번호 설정이 완료되었습니다!'),
//         backgroundColor: Color(0xFF03A20B),
//       ),
//     );
    
//     Navigator.of(context).pushReplacementNamed('/login-splash');

//   } on FirebaseAuthException catch (e) {
//     // Firebase Auth 에러 처리
//     if (Navigator.canPop(context)) {
//       Navigator.of(context).pop();
//     }
    
//     String errorMessage = '아이디/비밀번호 설정 중 오류가 발생했습니다.';
//     print('🚨 FirebaseAuthException: ${e.code} - ${e.message}');
    
//     switch (e.code) {
//       case 'weak-password':
//         errorMessage = '비밀번호가 너무 약합니다.';
//         break;
//       case 'email-already-in-use':
//         errorMessage = '이미 사용 중인 아이디(이메일)입니다.';
//         break;
//       case 'invalid-email':
//         errorMessage = '유효하지 않은 이메일 형식입니다.';
//         break;
//       case 'credential-already-in-use':
//         errorMessage = '이미 다른 계정에서 사용 중인 이메일입니다.';
//         break;
//       case 'provider-already-linked':
//         errorMessage = '이미 이메일/비밀번호가 설정된 계정입니다.';
//         break;
//       case 'network-request-failed':
//         errorMessage = '네트워크 연결을 확인해주세요.';
//         break;
//       default:
//         errorMessage = '인증 오류: ${e.message}';
//     }
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(errorMessage),
//         backgroundColor: const Color(0xFFC31A1A),
//       ),
//     );
    
//   } on FirebaseException catch (e) {
//     // Firestore 에러 처리
//     if (Navigator.canPop(context)) {
//       Navigator.of(context).pop();
//     }
    
//     print('🚨 FirebaseException: ${e.code} - ${e.message}');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('데이터 저장 오류: ${e.message}'),
//         backgroundColor: const Color(0xFFC31A1A),
//       ),
//     );
    
//   } catch (e) {
//     // 일반 에러 처리
//     if (Navigator.canPop(context)) {
//       Navigator.of(context).pop();
//     }
    
//     print('🚨 일반 오류 발생: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('아이디/비밀번호 설정 중 예상치 못한 오류가 발생했습니다: $e'),
//         backgroundColor: const Color(0xFFC31A1A),
//       ),
//     );
//   }
// }

//   /// 재전송 카운트다운을 시작하는 메서드 (새로 추가된 메서드)
//   void _startCountdown() {
//     _timer?.cancel(); // 기존 타이머가 있다면 취소
//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_resendCountdown == 0) {
//         if (mounted) {
//           setState(() {
//             timer.cancel();
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _resendCountdown--;
//           });
//         }
//       }
//     });
//   }

//   Widget _buildRadioButton(String label) {
//     final bool isSelected = (_selectedTelecom == label);
//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedTelecom = label;
//         });
//       },
//       child: Row(
//         children: [
//           Container(
//             width: 19,
//             height: 19,
//             decoration: ShapeDecoration(
//               shape: OvalBorder(
//                 side: const BorderSide(width: 1, color: Color(0xFFBBBBBB)),
//               ),
//             ),
//             child: isSelected
//                 ? Center(
//                     child: Container(
//                       width: 11,
//                       height: 11,
//                       decoration: const ShapeDecoration(
//                         color: Color(0xFF121212),
//                         shape: OvalBorder(),
//                       ),
//                     ),
//                   )
//                 : null,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             label,
//             style: const TextStyle(
//               color: Color(0xFF121212),
//               fontSize: 16,
//               fontFamily: 'Pretendard',
//               fontWeight: FontWeight.w500,
//             ),
//           )
//         ],
//       ),
//     );
//   }



//   Widget _buildSectionTitle(String title) {
//     return Text(
//       title,
//       style: const TextStyle(
//         color: Color(0xFF121212),
//         fontSize: 16,
//         fontFamily: 'Pretendard',
//         fontWeight: FontWeight.w500,
//       ),
//     );
//   }

//   /// 휴대폰 인증 섹션 UI (수정된 부분)
//   Widget _buildPhoneAuthSection() {
//     // 재전송 버튼이 활성화되어야 하는지 여부
//     final canResend = _resendCountdown == 0 && !_isRequestingVerification;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             _buildRadioButton('SKT'),
//             const SizedBox(width: 30),
//             _buildRadioButton('KT'),
//             const SizedBox(width: 30),
//             _buildRadioButton('LG U+'),
//           ],
//         ),
//         const SizedBox(height: 15),
//         Row(
//           children: [
//             Expanded(
//               child: TextFormField( // TextField -> TextFormField로 변경
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 style: const TextStyle(
//                   color: Color(0xFF121212),
//                   fontSize: 16,
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: _textFieldDecoration(
//                   hintText: "'-' 없이 전화번호 입력",
//                   prefixText: '+82 ',
//                 ).copyWith(
//                   border: const OutlineInputBorder(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(6),
//                       bottomLeft: Radius.circular(6),
//                     ),
//                     borderSide: BorderSide.none,
//                   ),
//                   focusedBorder: const OutlineInputBorder(
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(6),
//                       bottomLeft: Radius.circular(6),
//                     ),
//                     borderSide: BorderSide(color: Color(0xFF5F37CF)),
//                   ),
//                 ),
//                  validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return '전화번호를 입력해주세요.';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             SizedBox(
//               width: 116,
//               height: 52,
//               child: TextButton(
//                 // 카운트다운 중이 아닐 때만 버튼 활성화
//                 onPressed: canResend ? _requestVerification : null,
//                 style: TextButton.styleFrom(
//                   backgroundColor: canResend ? const Color(0xFF121212) : Colors.grey,
//                   foregroundColor: Colors.white,
//                   shape: const RoundedRectangleBorder(
//                     borderRadius: BorderRadius.only(
//                       topRight: Radius.circular(6),
//                       bottomRight: Radius.circular(6),
//                     ),
//                   ),
//                 ),
//                 child: _isRequestingVerification 
//                   ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))
//                   : Text(
//                       _isVerificationRequested ? (_resendCountdown > 0 ? '${_resendCountdown}초' : '재전송') : '인증요청',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontFamily: 'Pretendard',
//                         fontWeight: FontWeight.w500,
//                       ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         if (_isVerificationRequested) ...[
//           const SizedBox(height: 8),
//           TextFormField( // TextField -> TextFormField로 변경
//             controller: _authCodeController,
//             keyboardType: TextInputType.number,
//             maxLength: 6,
//             style: const TextStyle(
//               color: Color(0xFF121212),
//               fontSize: 16,
//               fontFamily: 'Pretendard',
//               fontWeight: FontWeight.w500,
//             ),
//             decoration: _textFieldDecoration(hintText: '인증번호 6자리 입력').copyWith(
//               counterText: '', // 글자 수 카운터 숨기기
//             ),
//             validator: (value) {
//               if (value == null || value.length != 6) {
//                 return '인증번호 6자리를 입력해주세요.';
//               }
//               return null;
//             },
//           ),
//         ]
//       ],
//     );
//   }
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     backgroundColor: const Color(0xFFFAFAFA),
//     body: SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 상단 뒤로가기 버튼
//               Row(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(top: 16.0),
//                     child: IconButton(
//                       icon: const Icon(Icons.arrow_back_ios),
//                       color: Color(0xFF121212),
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                     ),
//                   ),

//                   Text(
//                           '실소 회원가입',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                               color: const Color(0xFF121212),
//                               fontSize: 18,
//                               fontFamily: 'Pretendard',
//                               fontWeight: FontWeight.w600,
//                               height: 1.62,
//                           ),
//                       ),      
//                 ],
//               ),
//               const SizedBox(height: 16),
//               // '아이디' 섹션
//               _buildSectionTitle('아이디'),
//               const SizedBox(height: 8),
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _idController,
//                       style: const TextStyle(
//                         color: Color(0xFF121212),
//                         fontSize: 16,
//                         fontFamily: 'Pretendard',
//                         fontWeight: FontWeight.w500,
//                       ),
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: const Color(0xFFEAEAEA),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(6),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
//                         hintText: '아이디를 입력하세요',
//                         hintStyle: const TextStyle(
//                           color: Color(0xFFBBBBBB),
//                           fontSize: 16,
//                           fontFamily: 'Pretendard',
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           _isIdAvailableInitial = true;
//                           _isIdAvailable = false;
//                         });
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 106,
//                     height: 52,
//                     child: ElevatedButton(
//                       onPressed: _checkIdAvailability,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF121212),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//                         padding: EdgeInsets.zero,
//                       ),
//                       child: const Text(
//                         '중복확인',
//                         style: TextStyle(
//                           color: Color(0xFFFAFAFA),
//                           fontSize: 16,
//                           fontFamily: 'Pretendard',
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               // 아이디 유효성 메시지
//               Padding(
//                 padding: const EdgeInsets.only(left: 8.0),
//                 child: Text(
//                   _isIdAvailableInitial
//                       ? '영문과 숫자만 사용하여, 영문으로 시작되는 4-12자의 아이디를 입력해주세요.'
//                       : (_isIdAvailable ? '사용 가능한 아이디!' : '이미 사용 중인 아이디입니다.'),
//                   style: TextStyle(
//                     color: _isIdAvailableInitial
//                         ? const Color(0xFF5F37CF)
//                         : (_isIdAvailable ? const Color(0xFF03A20B) : const Color(0xFFC31A1A)),
//                     fontSize: 12,
//                     fontFamily: 'Pretendard',
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // '비밀번호' 섹션
//               _buildSectionTitle('비밀번호'),
//               const SizedBox(height: 8),
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: true,
//                 onChanged: (_) => _validatePassword(),
//                 style: const TextStyle(
//                   color: Color(0xFF121212),
//                   fontSize: 16,
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: const Color(0xFFEAEAEA),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(6),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
//                   hintText: '비밀번호를 입력하세요',
//                   hintStyle: const TextStyle(
//                     color: Color(0xFFBBBBBB),
//                     fontSize: 16,
//                     fontFamily: 'Pretendard',
//                     fontWeight: FontWeight.w500,
//                   ),
//                   suffixIcon: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: Text(
//                       _isPasswordValid ? '사용가능' : '사용불가',
//                       style: TextStyle(
//                         color: _isPasswordValid ? const Color(0xFF03A20B) : const Color(0xFFC31A1A),
//                         fontSize: 12,
//                         fontFamily: 'Pretendard',
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
//                 ),
//               ),

//               const SizedBox(height: 8),
//               // 비밀번호 확인 입력 필드
//               TextFormField(
//                 controller: _confirmPasswordController,
//                 obscureText: true,
//                 onChanged: (_) {
//                   setState(() {});
//                 },
//                 validator: (value) {
//                   if (value != _passwordController.text) {
//                     return '비밀번호가 일치하지 않습니다.';
//                   }
//                   return null;
//                 },
//                 style: const TextStyle(
//                   color: Color(0xFF121212),
//                   fontSize: 16,
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   filled: true,
//                   fillColor: const Color(0xFFEAEAEA),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(6),
//                     borderSide: BorderSide.none,
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
//                   hintText: '비밀번호를 다시 입력하세요',
//                   hintStyle: const TextStyle(
//                     color: Color(0xFFBBBBBB),
//                     fontSize: 16,
//                     fontFamily: 'Pretendard',
//                     fontWeight: FontWeight.w500,
//                   ),
//                   suffixIcon: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 10),
//                     child: (_confirmPasswordController.text.isEmpty)
//                         ? null
//                         : (_confirmPasswordController.text != _passwordController.text)
//                             ? const Icon(Icons.cancel_outlined, color: Color(0xFFC31A1A))
//                             : const Icon(Icons.check_circle_outline_outlined, color: Color(0xFF03A20B)),
//                   ),
//                   suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // 비밀번호 유효성 메시지
//               Padding(
//                 padding: const EdgeInsets.only(left: 8.0),
//                 child: Text(
//                   _isPasswordValid ? '' : '영문 대소문자, 숫자, 특수문자 중 2가지 이상을 조합하여 6-20자로 입력해주세요',
//                   style: const TextStyle(
//                     color: Color(0xFF5F37CF),
//                     fontSize: 12,
//                     fontFamily: 'Pretendard',
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               // 휴대폰 인증 섹션
//               _buildSectionTitle('휴대폰 인증'),
//               const SizedBox(height: 15),
//               _buildPhoneAuthSection(),
//               const SizedBox(height: 24),
//               // '다음' 버튼
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: _onNext,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _isIdAvailable && _isPasswordValid ? const Color(0xFF5F37CF) : const Color(0xFFBDBDBD),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text(
//                     '다음',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontFamily: 'Pretendard',
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ),
//   );
// }

//     InputDecoration _textFieldDecoration(
//       {required String hintText, String? prefixText}) {
//     return InputDecoration(
//       hintText: hintText,
//       hintStyle: const TextStyle(color: Color(0xFF737373)),
//       prefixText: prefixText,
//       prefixStyle: const TextStyle(
//         color: Color(0xFF121212),
//         fontSize: 16,
//         fontFamily: 'Pretendard',
//         fontWeight: FontWeight.w500,
//       ),
//       filled: true,
//       fillColor: const Color(0xFFEAEAEA),
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: BorderSide.none,
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: Color(0xFF5F37CF)),
//       ),
//       errorBorder: OutlineInputBorder( // 에러 발생 시 테두리
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: Colors.red, width: 1.0),
//       ),
//       focusedErrorBorder: OutlineInputBorder( // 에러 발생 후 포커스 시 테두리
//         borderRadius: BorderRadius.circular(6),
//         borderSide: const BorderSide(color: Colors.red, width: 2.0),
//       ),
//     );
//   }
// }