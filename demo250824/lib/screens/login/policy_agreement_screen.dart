import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // PDF 링크를 열기 위해 패키지 추가 필요
import '../../../services/community_service.dart';
import 'mypet_select.dart'; // 마이팻 select

class PolicyAgreementScreen extends StatefulWidget {
  const PolicyAgreementScreen({super.key});

  @override
  State<PolicyAgreementScreen> createState() => _PolicyAgreementScreenState();
}

class _PolicyAgreementScreenState extends State<PolicyAgreementScreen>
    with TickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _communityGuidelinesAccepted = false;
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _checkboxAnimationController;
  late Animation<double> _checkboxAnimation;

  bool get _allPoliciesAccepted =>
      _termsAccepted && _privacyAccepted && _communityGuidelinesAccepted;

  @override
  void initState() {
    super.initState();
    print("screens/community/policy_agreement_screen.dart is showing");

    // Initialize animations
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // Final step - complete progress
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _checkboxAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _checkboxAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _checkboxAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start progress animation
    _progressAnimationController.forward();
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    _progressAnimationController.dispose();
    _checkboxAnimationController.dispose();
    super.dispose();
  }

  void _triggerButtonAnimation() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
    });
  }

  void _triggerCheckboxAnimation() {
    _checkboxAnimationController.forward().then((_) {
      _checkboxAnimationController.reverse();
    });
  }

  Future<void> _confirmAndFinish() async {
    if (!_allPoliciesAccepted) {
      _showValidationError('정책 동의 필요', '모든 정책에 동의해주셔야 서비스를 이용하실 수 있습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _communityService.agreePolicies();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showValidationError('오류', '설정 완료에 실패했습니다: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showValidationError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(
                color: Color(0xFF5F37CF),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF5F37CF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '커뮤니티에 오신 것을\n환영합니다!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '프로필 설정이 성공적으로 완료되었습니다.\n이제 다른 커뮤니티 멤버들과 소통하실 수 있습니다.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFC7C7C7),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MyPetSelect()), // 마이팻 select
                    (route) => route.settings.name == '/temporary-home',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F37CF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ✨ New Feature Start ---
  // 전체 서비스 이용약관 및 부칙을 보여주는 다이얼로그
  void _showFullTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '서비스 이용약관 전체보기',
          style: TextStyle(fontFamily: 'Pretendard',fontSize: 18, fontWeight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: RichText(
            text: const TextSpan(
              style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: const Color(0xFF5F37CF)),
              children: [
                TextSpan(text: "본 약관은 귀하가 실소(SilSo)가 제공하는 서비스를 이용함에 있어, 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다. [cite: 2]\n\n"),
                TextSpan(text: "제1조 [목적 및 정의]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "본 약관은 회사가 운영하는 실소 플랫폼과 관련하여 필요한 사항을 규정합니다. [cite: 5]\n\n"),
                TextSpan(text: "제2조 [약관의 게시, 효력 및 변경]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "회사는 본 약관을 플랫폼 초기화면 등을 통해 게시하며, 변경 시 사전 공지합니다. [cite: 12, 13]\n\n"),
                TextSpan(text: "제3조 [서비스 이용계약의 체결 및 회원가입]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "이용계약은 약관 동의 및 회원가입 완료 후 회사의 승낙으로 성립됩니다. [cite: 18]\n\n"),
                TextSpan(text: "제4조 [서비스 내용 및 변경]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "회사는 실패 경험 공유, 회고 분석, 커뮤니티 기능, AI 기반 피드백 등의 서비스를 제공하며, 내용은 변경될 수 있습니다. [cite: 24, 30]\n\n"),
                TextSpan(text: "제5조 [회원의 의무 및 금지행위]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "회원은 계정 거래, 불법/차별적/악의적 행위, 타인의 권리 침해, 서비스 조작 등 약관에 위배되는 행위를 해서는 안 됩니다. [cite: 33, 34, 35, 36, 48]\n\n"),
                TextSpan(text: "제6조 [사용자 게시 콘텐츠]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "게시물의 소유권은 회원에게 있으나, 회사는 서비스 운영, 홍보, 연구 등을 위해 해당 콘텐츠를 사용할 수 있는 라이선스를 부여받습니다. [cite: 58, 59] 회원은 콘텐츠에 대한 책임을 지며, 회사는 부적절한 콘텐츠를 제한할 수 있습니다. [cite: 71, 82]\n\n"),
                TextSpan(text: "제7조 [서비스 이용의 제한 및 탈퇴]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "약관 위반 시 서비스 이용이 제한될 수 있으며, 회원은 언제든지 탈퇴할 수 있습니다. [cite: 102, 104]\n\n"),
                TextSpan(text: "제8조 [개인정보의 보호 및 활용]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "개인정보는 관련 법령에 따라 보호되며, 서비스 제공 및 개선 목적으로 활용됩니다. [cite: 107, 108]\n\n"),
                TextSpan(text: "제9조 [지식재산권 및 콘텐츠 활용]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "플랫폼의 지식재산권은 회사에 귀속됩니다. [cite: 114]\n\n"),
                TextSpan(text: "제10조 [면책조항]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "천재지변 등 불가항력이나 회원 간의 분쟁에 대해 회사는 책임을 지지 않습니다. [cite: 117, 122]\n\n"),
                TextSpan(text: "제11조 [준거법 및 분쟁해결]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "본 약관은 대한민국 법령에 따르며, 분쟁 발생 시 회사 본사 소재지 관할 법원에서 해결합니다. [cite: 124]\n\n"),
                TextSpan(text: "[부칙]\n", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: "본 약관은 2025년 8월 6일부터 시행됩니다. [cite: 126]"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // 호스팅된 PDF 파일의 URL을 입력하세요. (실소이용약관 / silso contract)
              final Uri pdfUrl = Uri.parse('https://drive.google.com/file/d/1wLnKbJmmXIrVyRgpzYmUt6LNrOxjftvc/view?usp=sharing');
              
              // url_launcher 패키지를 사용하여 URL을 엽니다.
              // 이 기능을 사용하려면 pubspec.yaml 파일에 url_launcher를 추가해야 합니다.
              if (await canLaunchUrl(pdfUrl)) {
                await launchUrl(pdfUrl);
              } else {
                // URL을 열 수 없는 경우 사용자에게 알림
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF 문서를 열 수 없습니다.')),
                );
              }
            },
            child: const Text(
              'PDF 원문 보기',
              style: TextStyle(color: Color(0xFF5F37CF), fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '닫기',
              style: TextStyle(color: Color(0xFF5F37CF), fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  // --- ✨ New Feature End ---

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 393.0;
    final double widthRatio = screenWidth / baseWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, widthRatio),
      body: Column(
        children: [
          Expanded(
            child: _buildMainContent(context, widthRatio),
          ),
          _buildBottomButton(context, widthRatio),
        ],
      ),
    );
  }

  /// Build app bar with progress indicator
  PreferredSizeWidget _buildAppBar(BuildContext context, double widthRatio) {
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
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: const Color(0xFFE0E0E0),
                    color: const Color(0xFF5F37CF),
                    minHeight: 8,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main content area
  Widget _buildMainContent(BuildContext context, double widthRatio) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 60 * widthRatio),

            // Title
            Text(
              '정책 검토 및\n동의해주세요',
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 24 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.21,
              ),
            ),

            SizedBox(height: 16 * widthRatio),

            // Subtitle
            Text(
              '프로필 설정을 완료하기 위해 커뮤니티 정책을 검토하고 동의해주세요',
              style: TextStyle(
                color: const Color(0xFFC7C7C7),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                height: 1.39,
              ),
            ),

            SizedBox(height: 32 * widthRatio),

            // Policy Checkboxes
            _buildPolicyCheckbox(
              title: '서비스 이용약관',
              description: '서비스의 기본 규칙, 사용자의 권리와 의무, 게시물 사용권 부여 등에 관한 내용을 확인하고 이에 동의합니다.',
              value: _termsAccepted,
              onChanged: (value) {
                setState(() => _termsAccepted = value ?? false);
                _triggerCheckboxAnimation();
                _triggerButtonAnimation();
              },
              widthRatio: widthRatio,
            ),

            _buildPolicyCheckbox(
              title: '개인정보처리방침',
              description: '회원가입 및 서비스 이용 과정에서 이메일, 이용 기록 등의 개인정보가 수집되며, 서비스 개선 및 AI 학습에 활용됨을 확인하고 동의합니다.',
              value: _privacyAccepted,
              onChanged: (value) {
                setState(() => _privacyAccepted = value ?? false);
                _triggerCheckboxAnimation();
                _triggerButtonAnimation();
              },
              widthRatio: widthRatio,
            ),

            _buildPolicyCheckbox(
              title: '커뮤니티 가이드라인',
              description: '타인 비방, 차별, 불법 정보 게시 등 커뮤니티 안정성을 저해하는 활동을 하지 않을 것을 약속하며, 위반 시 서비스 이용이 제한될 수 있음을 확인합니다.',
              value: _communityGuidelinesAccepted,
              onChanged: (value) {
                setState(() => _communityGuidelinesAccepted = value ?? false);
                _triggerCheckboxAnimation();
                _triggerButtonAnimation();
              },
              widthRatio: widthRatio,
            ),
            
            SizedBox(height: 16 * widthRatio),

            // --- ✨ New Feature Start ---
            // 전체 약관 보기 버튼
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showFullTermsDialog(context),
                child: Text(
                  '전체 서비스 이용약관 및 부칙 보기',
                  style: TextStyle(
                    color: const Color(0xFF5F37CF),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            // --- ✨ New Feature End ---
            
            SizedBox(height: 8 * widthRatio),

            // Additional Info
            Container(
              padding: EdgeInsets.all(16 * widthRatio),
              decoration: BoxDecoration(
                color: const Color(0xFF5F37CF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12 * widthRatio),
                border: Border.all(
                  color: const Color(0xFF5F37CF).withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF5F37CF),
                    size: 20 * widthRatio,
                  ),
                  SizedBox(width: 12 * widthRatio),
                  Expanded(
                    child: Text(
                      '이러한 정책에 동의함으로써 모두를 위한 안전하고 환영받는 커뮤니티를 만드는 데 도움을 주고 있습니다. 계정 설정에서 언제든지 전체 정책을 검토할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        color: const Color(0xFF121212).withOpacity(0.8),
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 40 * widthRatio),
          ],
        ),
      ),
    );
  }

  /// Build individual policy checkbox with modern design
  Widget _buildPolicyCheckbox({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required double widthRatio,
  }) {
    return AnimatedBuilder(
      animation: _checkboxAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: value ? _checkboxAnimation.value : 1.0,
          child: Container(
            margin: EdgeInsets.only(bottom: 16 * widthRatio),
            padding: EdgeInsets.all(16 * widthRatio),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12 * widthRatio),
              border: Border.all(
                color: value
                    ? const Color(0xFF5F37CF)
                    : const Color(0xFFE0E0E0),
                width: value ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: value,
                    onChanged: onChanged,
                    activeColor: const Color(0xFF5F37CF),
                    checkColor: Colors.white,
                    side: BorderSide(
                      color: value
                          ? const Color(0xFF5F37CF)
                          : const Color(0xFFC7C7C7),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                SizedBox(width: 12 * widthRatio),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 4 * widthRatio),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          color: const Color(0xFFC7C7C7),
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build bottom confirm button with animation
  Widget _buildBottomButton(BuildContext context, double widthRatio) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.0 * widthRatio),
      child: AnimatedBuilder(
        animation: _buttonScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _allPoliciesAccepted ? _buttonScaleAnimation.value : 0.98,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: (_isLoading || !_allPoliciesAccepted) ? null : _confirmAndFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allPoliciesAccepted
                      ? const Color(0xFF5F37CF)
                      : const Color(0xFFBDBDBD),
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16 * widthRatio),
                  elevation: _allPoliciesAccepted ? 2 : 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        '확인 및 커뮤니티 가입',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _allPoliciesAccepted
                              ? Colors.white
                              : const Color(0xFFEEEEEE),
                          fontSize: 18 * widthRatio,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.23,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}