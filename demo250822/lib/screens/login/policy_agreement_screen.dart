import 'package:flutter/material.dart';
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
              description: '플랫폼의 서비스 이용약관에 동의하며, 사용자로서의 권리와 책임을 이해합니다.',
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
              description: '개인정보가 어떻게 수집, 사용, 보호되는지에 대한 개인정보처리방침을 이해합니다.',
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
              description: '존중하는 상호작용을 유지하고 긍정적인 환경을 위한 커뮤니티 표준을 따르는 것에 동의합니다.',
              value: _communityGuidelinesAccepted,
              onChanged: (value) {
                setState(() => _communityGuidelinesAccepted = value ?? false);
                _triggerCheckboxAnimation();
                _triggerButtonAnimation();
              },
              widthRatio: widthRatio,
            ),
            
            SizedBox(height: 24 * widthRatio),
            
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