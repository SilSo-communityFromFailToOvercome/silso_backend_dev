import 'package:flutter/material.dart';
import '../screens/community/community_main.dart';
import '../screens/contents_page/contents_main.dart';
import '../screens/my_page/my_page_main.dart';

class MainNavigationBar extends StatefulWidget {
  const MainNavigationBar({super.key});

  @override
  State<MainNavigationBar> createState() => _MainNavigationBarState();
}

class _MainNavigationBarState extends State<MainNavigationBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CommunityMainTabScreenMycom(), // Community 
    const ContentsMainPage(), // Contents
    const MyPageMain(), // Profile 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5F37CF),
        unselectedItemColor: Colors.grey,
        elevation: 8,
        currentIndex: 0, // Community 탭이 선택된 상태
        onTap: (index) {
          switch (index) {
            case 0:
              // 현재 페이지 (Community) - 아무 작업 안함
              break;
            case 1:
              // Contents 페이지로 이동
              Navigator.pushNamed(context, '/contents-main');
              break;
            case 2:
              // Profile 페이지로 이동
              Navigator.pushNamed(context, '/my-page');
              break;
          }
        },
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
      ),
    );
  }
}
