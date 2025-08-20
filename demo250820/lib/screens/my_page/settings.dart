import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'edit_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;

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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40 * heightRatio),
              
              // MY설정 Section
              _buildMySettingsSection(widthRatio, heightRatio),
              
              SizedBox(height: 40 * heightRatio),
              
              // App Information Section
              _buildAppInfoSection(widthRatio, heightRatio),
              
              SizedBox(height: 40 * heightRatio),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMySettingsSection(double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        SizedBox(height: 20 * heightRatio),
        
        // Menu Items
        _buildMenuItem('프로필 수정', widthRatio, heightRatio),
        _buildMenuItem('커뮤니티 활동', widthRatio, heightRatio),
        _buildMenuItem('공지사항', widthRatio, heightRatio),
        _buildMenuItem('환경설정', widthRatio, heightRatio),
      ],
    );
  }

  Widget _buildAppInfoSection(double widthRatio, double heightRatio) {
    return Column(
      children: [
        _buildMenuItem('앱 버전', widthRatio, heightRatio),
        _buildMenuItem('로그아웃', widthRatio, heightRatio),
      ],
    );
  }

  Widget _buildMenuItem(String title, double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * heightRatio),
      child: InkWell(
        onTap: () {
          if (title == '로그아웃') {
            _signOut();
          } else if (title == '앱 버전') {
            _showAppVersionDialog();
          } else if (title == '프로필 수정') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ),
            );
          } else {
            // TODO: Add navigation functionality for other menu items
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * widthRatio,
            vertical: 20 * heightRatio,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * widthRatio),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16 * widthRatio,
                color: const Color(0xFF8E8E8E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}