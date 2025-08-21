import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community/community_main.dart';
import 'community/initial_profile/intro_community_splash2.dart';
import 'contents_page/contents_main.dart';
import 'admin_page/admin_menu.dart';
import 'my_page/my_page_main.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';

class TemporaryHomePage extends StatefulWidget {
  const TemporaryHomePage({super.key});

  @override
  State<TemporaryHomePage> createState() => _TemporaryHomePageState();
}

class _TemporaryHomePageState extends State<TemporaryHomePage> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to get display name first, fallback to email, then to uid
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        return user.email!;
      } else {
        return user.uid.substring(0, 8); // First 8 characters of uid
      }
    }
    return "Guest";
  }

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
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16 * widthRatio),
            child: TextButton(
              onPressed: _isSigningOut ? null : _signOut,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8E8E8E),
              ),
              child: _isSigningOut
                  ? SizedBox(
                      width: 16 * widthRatio,
                      height: 16 * widthRatio,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E8E)),
                      ),
                    )
                  : Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * widthRatio),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Text(
                'Welcome, ${_getUserDisplayName()}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF121212),
                  fontFamily: 'Pretendard',
                ),
              ),
              
              SizedBox(height: 60 * heightRatio),
              
              // Community button
              ElevatedButton(
                onPressed: () async {
                  // Check if user has completed community setup
                  final hasCompletedSetup = await _communityService.hasCompletedCommunitySetup();
                  
                  if (!mounted) return;
                  
                  if (hasCompletedSetup) {
                    // Go directly to community main
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CommunityMainTabScreenMycom(),
                      ),
                    );
                  } else {
                    // Go through the setup flow
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const IntroCommunitySplash(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5F37CF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  '커뮤니티',
                  style: TextStyle(
                    fontSize: 18 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // Contents button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ContentsMainPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B46C1),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  '실소 콘텐츠',
                  style: TextStyle(
                    fontSize: 18 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // Admin button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminMenuPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 20 * widthRatio,
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 18 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16 * heightRatio),
              
              // My Page button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyPageMain(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 20 * widthRatio,
                    ),
                    SizedBox(width: 8 * widthRatio),
                    Text(
                      '마이 페이지',
                      style: TextStyle(
                        fontSize: 18 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
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
}