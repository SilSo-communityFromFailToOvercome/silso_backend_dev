import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 필요한 서비스와 화면을 import 합니다.
import '../../services/community_service.dart';
import 'policy_agreement_screen.dart';

/// 사용자의 프로필 정보를 입력받는 화면입니다.
/// 사용자 입력을 처리하기 위해 StatefulWidget으로 구성되었습니다.
class ProfileInformationScreen extends StatefulWidget {
  const ProfileInformationScreen({super.key});

  @override
  State<ProfileInformationScreen> createState() =>
      _ProfileInformationScreenState();
}

class _ProfileInformationScreenState extends State<ProfileInformationScreen> {
  // --- Services ---
  final CommunityService _communityService = CommunityService();

  // --- Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();

  // --- State Variables ---
  final List<bool> _nationalitySelection = [true, false];
  String _selectedGender = '여';
  String _selectedTelecom = 'SKT';
  bool _isVerificationRequested = false;
  bool _isLoading = false; // 로딩 상태를 관리하는 변수

  @override
  void dispose() {
    _nameController.dispose();
    _birthdateController.dispose();
    _phoneController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  /// '계속하기' 버튼을 눌렀을 때 실행될 메서드
  Future<void> _submitProfile() async {
    // TODO: 폼 유효성 검사 로직 추가 (예: 모든 필드가 채워졌는지)

    setState(() {
      _isLoading = true; // 로딩 시작
    });

    try {
      // 국적 문자열 결정
      final String country = _nationalitySelection[0] ? '내국인' : '외국인';

      // Firestore에 프로필 정보 저장
      await _communityService.saveProfileInformation(
        name: _nameController.text,
        country: country,
        birthdate: _birthdateController.text,
        gender: _selectedGender,
        phoneNumber: "+82${_phoneController.text}", // 국가번호 포함
      );

      // 저장 성공 시 다음 화면으로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PolicyAgreementScreen(),
          ),
        );
      }
    } catch (e) {
      // 오류 발생 시 SnackBar로 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 저장에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    _buildSectionTitle('이름'),
                    const SizedBox(height: 8),
                    _buildNameAndNationality(),
                    const SizedBox(height: 35),
                    _buildSectionTitle('생년월일'),
                    const SizedBox(height: 8),
                    _buildBirthdateAndGender(),
                    const SizedBox(height: 35),
                    _buildSectionTitle('휴대폰 인증'),
                    const SizedBox(height: 15),
                    _buildPhoneAuthSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          _buildContinueButton(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFA),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                value: 0.67,
                backgroundColor: Color(0xFFE0E0E0),
                color: Color(0xFF5F37CF),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
      centerTitle: true,
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

  Widget _buildNameAndNationality() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _nameController,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
            decoration: _textFieldDecoration(hintText: '이름'),
          ),
        ),
        const SizedBox(width: 15),
        ToggleButtons(
          isSelected: _nationalitySelection,
          onPressed: (int index) {
            setState(() {
              for (int i = 0; i < _nationalitySelection.length; i++) {
                _nationalitySelection[i] = i == index;
              }
            });
          },
          borderRadius: BorderRadius.circular(6),
          selectedColor: Colors.white,
          color: const Color(0xFF121212),
          fillColor: const Color(0xFF121212),
          splashColor: const Color(0xFF5F37CF).withOpacity(0.12),
          constraints: const BoxConstraints(
            minHeight: 52.0,
            minWidth: 70.0,
          ),
          children: const <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('내국인', style: TextStyle(fontFamily: 'Pretendard')),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('외국인', style: TextStyle(fontFamily: 'Pretendard')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBirthdateAndGender() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _birthdateController,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
            decoration: _textFieldDecoration(hintText: 'YYMMDD'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
        ),
        const SizedBox(width: 25),
        Row(
          children: [
            _buildGenderOption('남'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '|',
                style: TextStyle(
                    color: Color(0xFF575757),
                    fontSize: 16,
                    fontFamily: 'Pretendard'),
              ),
            ),
            _buildGenderOption('여'),
          ],
        )
      ],
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Text(
        gender,
        style: TextStyle(
          color: isSelected ? const Color(0xFF121212) : const Color(0xFFC4C4C4),
          fontSize: 16,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhoneAuthSection() {
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
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  color: Color(0xFF121212),
                  fontSize: 16,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
                decoration: _textFieldDecoration(
                  hintText: '전화번호 입력',
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
              ),
            ),
            SizedBox(
              width: 116,
              height: 52,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isVerificationRequested = true;
                  });
                  // TODO: Add phone verification logic here
                  print('Verification requested for ${_phoneController.text}');
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF121212),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                ),
                child: Text(
                  _isVerificationRequested ? '재전송' : '인증요청',
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
        const SizedBox(height: 8),
        TextField(
          controller: _authCodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
          decoration: _textFieldDecoration(hintText: '인증번호 입력'),
        ),
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

  /// 하단의 '계속하기' 버튼 위젯을 빌드합니다. (수정된 부분)
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
              disabledBackgroundColor: Colors.grey,
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
    );
  }
}
