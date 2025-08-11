import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community/community_main.dart';

class TemporaryHomePage extends StatefulWidget {
  const TemporaryHomePage({super.key});

  @override
  State<TemporaryHomePage> createState() => _TemporaryHomePageState();
}

class _TemporaryHomePageState extends State<TemporaryHomePage> {
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CommunityMainTabScreenMycom(),
                    ),
                  );
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
              
              // Contents button (temporary)
              ElevatedButton(
                onPressed: () {
                  print("content page button clicked");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5F37CF),
                  padding: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * widthRatio),
                    side: const BorderSide(
                      color: Color(0xFF5F37CF),
                      width: 1.5,
                    ),
                  ),
                  elevation: 1,
                ),
                child: Text(
                  '콘텐츠',
                  style: TextStyle(
                    fontSize: 18 * widthRatio,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}