import 'package:flutter/material.dart';
import '../../../services/authentication/auth_service.dart';
import 'change_pw.dart';
import 'blocked_users.dart';
import 'usage_limit_history.dart';
import 'faq.dart';
import 'announcements.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;
  
  // Toggle states for notifications
  bool _publicPostsNotification = true;
  bool _chatNotification = true;
  bool _generalNotification = true;
  bool _sosNotification = true;

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppVersionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF5F37CF),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '앱 버전',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '실소 (Silso)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '버전: Beta 1.0.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '베타 테스트 버전입니다.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5F37CF),
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    const double baseHeight = 852.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    final double heightRatio = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF121212),
            size: 20 * widthRatio,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'MY설정',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24 * heightRatio),
            
            // Account Section
            _buildSectionHeader('계정', widthRatio, heightRatio),
            _buildMenuItem('아이디', 'kimmeeeen0707', null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('비밀번호 변경', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('계정인증', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('회원 탈퇴', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('차단된 계정', null, null, widthRatio, heightRatio),
            
            SizedBox(height: 32 * heightRatio),
            
            // Notifications Section
            _buildSectionHeader('알림', widthRatio, heightRatio),
            _buildToggleMenuItem('공지 알림', _publicPostsNotification, (value) {
              setState(() => _publicPostsNotification = value);
            }, widthRatio, heightRatio),
            _buildDivider(),
            _buildToggleMenuItem('댓글 알림', _chatNotification, (value) {
              setState(() => _chatNotification = value);
            }, widthRatio, heightRatio),
            _buildDivider(),
            _buildToggleMenuItem('채팅 알림', _generalNotification, (value) {
              setState(() => _generalNotification = value);
            }, widthRatio, heightRatio),
            _buildDivider(),
            _buildToggleMenuItem('실소 소식 알림', _sosNotification, (value) {
              setState(() => _sosNotification = value);
            }, widthRatio, heightRatio),
            
            SizedBox(height: 32 * heightRatio),
            
            // Other Section
            _buildSectionHeader('이용약관', widthRatio, heightRatio),
            _buildMenuItem('이용 제한 내역', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('문의하기', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('공지사항', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('서비스 이용약관 및 정책', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('오픈 소스 라이선스', null, null, widthRatio, heightRatio),
            
            SizedBox(height: 32 * heightRatio),
            
            // App Info Section
            _buildMenuItem('정보 동의', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('앱 버전', null, null, widthRatio, heightRatio),
            _buildDivider(),
            _buildMenuItem('로그아웃', null, null, widthRatio, heightRatio),
            
            SizedBox(height: 40 * heightRatio),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, double widthRatio, double heightRatio) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 8 * heightRatio),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14 * widthRatio,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8E8E8E),
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
    );
  }

  Widget _buildMenuItem(String title, String? subtitle, String? trailing, double widthRatio, double heightRatio) {
    return InkWell(
      onTap: () {
        if (title == '로그아웃') {
          _signOut();
        } else if (title == '앱 버전') {
          _showAppVersionDialog();
        } else if (title == '비밀번호 변경') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChangePasswordPage(),
            ),
          );
        } else if (title == '차단된 계정') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BlockedUsersPage(),
            ),
          );
        } else if (title == '이용 제한 내역') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UsageLimitHistoryPage(),
            ),
          );
        } else if (title == '문의하기') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const FAQPage(),
            ),
          );
        } else if (title == '공지사항') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AnnouncementsPage(),
            ),
          );
        } else {
          // TODO: Add navigation functionality for other menu items
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * heightRatio,
        ),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2 * heightRatio),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16 * widthRatio,
                color: const Color(0xFF8E8E8E),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMenuItem(String title, bool value, ValueChanged<bool> onChanged, double widthRatio, double heightRatio) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * widthRatio,
        vertical: 16 * heightRatio,
      ),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5F37CF),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}