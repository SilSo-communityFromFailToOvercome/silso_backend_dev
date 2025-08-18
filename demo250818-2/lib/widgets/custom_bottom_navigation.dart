import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  
  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF5F37CF),
      unselectedItemColor: Colors.grey,
      elevation: 8,
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.filter_none),
          activeIcon: Icon(Icons.filter_none),
          label: 'Contents',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onTap(BuildContext context, int index) {
    // 현재 페이지와 같은 탭을 누르면 아무 작업 안함
    if (index == currentIndex) return;
    
    switch (index) {
      case 0:
        // Community 페이지로 이동
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/mvp_community',
          (route) => false,
        );
        break;
      case 1:
        // Contents 페이지로 이동
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/contents-main',
          (route) => false,
        );
        break;
      case 2:
        // Profile 페이지로 이동
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/my-page',
          (route) => false,
        );
        break;
    }
  }
}