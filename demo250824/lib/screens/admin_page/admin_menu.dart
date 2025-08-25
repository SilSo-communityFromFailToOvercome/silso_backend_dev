import 'package:flutter/material.dart';
import 'contents_admin.dart';
import 'faq_admin.dart';
import 'announcement_admin.dart';
import 'reports.dart';

class AdminMenuPage extends StatelessWidget {
  const AdminMenuPage({super.key});

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
          'Admin Menu',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20 * widthRatio),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                'Admin Tools',
                style: TextStyle(
                  fontSize: 24 * widthRatio,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 8 * heightRatio),
              
              SizedBox(height: 40 * heightRatio),
              
              // Admin menu buttons
              _buildAdminMenuButton(
                context: context,
                icon: Icons.article_outlined,
                title: 'Contents',
                description: 'Contents Page and QOTD',
                color: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ContentsAdminPage(),
                    ),
                  );
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // FAQ Management button
              _buildAdminMenuButton(
                context: context,
                icon: Icons.help_center_outlined,
                title: 'FAQ',
                description: 'Manage user questions and support',
                color: const Color(0xFF0EA5E9),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FAQAdminPage(),
                    ),
                  );
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // Announcements Management button
              _buildAdminMenuButton(
                context: context,
                icon: Icons.campaign_outlined,
                title: 'Announcements',
                description: 'Manage app announcements and notices',
                color: const Color(0xFFf59e0b),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementAdminPage(),
                    ),
                  );
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // Reports Management button
              _buildAdminMenuButton(
                context: context,
                icon: Icons.flag_outlined,
                title: 'Reports',
                description: 'Manage user reports and violations',
                color: const Color(0xFFDC2626),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ReportsAdminPage(),
                    ),
                  );
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // Placeholder for future admin features
              _buildAdminMenuButton(
                context: context,
                icon: Icons.people_outline,
                title: '사용자 관리',
                description: '사용자 계정 관리 및 제재 내역',
                color: const Color(0xFF64748B),
                onTap: () {
                  _showComingSoonDialog(context);
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
                isEnabled: false,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              _buildAdminMenuButton(
                context: context,
                icon: Icons.analytics_outlined,
                title: '통계 및 분석',
                description: '앱 사용량 통계 및 사용자 행동 분석',
                color: const Color(0xFF059669),
                onTap: () {
                  _showComingSoonDialog(context);
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
                isEnabled: false,
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              _buildAdminMenuButton(
                context: context,
                icon: Icons.settings_outlined,
                title: '시스템 설정',
                description: '앱 설정 및 시스템 관리',
                color: const Color(0xFFDC2626),
                onTap: () {
                  _showComingSoonDialog(context);
                },
                widthRatio: widthRatio,
                heightRatio: heightRatio,
                isEnabled: false,
              ),
              
              const Spacer(),
              
              // Footer warning
              Container(
                padding: EdgeInsets.all(16 * widthRatio),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8 * widthRatio),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: const Color(0xFFD97706),
                      size: 20 * widthRatio,
                    ),
                    SizedBox(width: 12 * widthRatio),
                    Expanded(
                      child: Text(
                        '관리자 권한이 필요한 기능입니다. 신중하게 사용해 주세요.',
                        style: TextStyle(
                          fontSize: 13 * widthRatio,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD97706),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminMenuButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    required double widthRatio,
    required double heightRatio,
    bool isEnabled = true,
  }) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12 * widthRatio),
      child: Container(
        padding: EdgeInsets.all(20 * widthRatio),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12 * widthRatio),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.2) : const Color(0xFFE9ECEF),
            width: 1,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48 * widthRatio,
              height: 48 * widthRatio,
              decoration: BoxDecoration(
                color: isEnabled 
                    ? color.withValues(alpha: 0.1) 
                    : const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color : const Color(0xFF6C757D),
                size: 24 * widthRatio,
              ),
            ),
            
            SizedBox(width: 16 * widthRatio),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: isEnabled 
                          ? const Color(0xFF121212) 
                          : const Color(0xFF6C757D),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  
                  SizedBox(height: 4 * heightRatio),
                  
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              size: 16 * widthRatio,
              color: isEnabled 
                  ? const Color(0xFF8E8E8E) 
                  : const Color(0xFFCED4DA),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.construction,
                color: Color(0xFF5F37CF),
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '개발 예정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
          content: const Text(
            '이 기능은 현재 개발 중입니다.\n곧 사용할 수 있도록 준비하고 있습니다.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF8E8E8E),
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
}