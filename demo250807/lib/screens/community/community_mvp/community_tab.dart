// Of course\! I can help you with that.

// It looks like you want to replace the current placeholder UI in the `_buildMyTabContent()` widget with a new, more detailed layout. You also want to make sure this new UI is responsive and adapts to different screen sizes, using a base design of 393x800.

// I've refactored the UI code you provided to be responsive and structured it using standard Flutter layout widgets like `SingleChildScrollView`, `Column`, and `Row` instead of `Stack` with hardcoded positions. This makes the code cleaner and more adaptable.

// Here is the updated code for the entire `community_tab.dart` file. You can copy and paste this to replace the existing file.

// ### Overview of the Solution

// 1.  **Responsiveness**: I've used `MediaQuery` to get the screen's width and height. All sizing and spacing are now calculated as a ratio of the original design's dimensions (393x800), ensuring the layout scales properly on any device.
// 2.  **Layout Structure**: The main layout is built with a `SingleChildScrollView` containing a `Column`. This is a robust way to create a vertically scrolling screen that avoids pixel overflows.
// 3.  **Helper Widgets**: To keep the code organized and readable, I've broken down the UI into smaller, reusable helper methods:
//       * `_buildEmptyState()`: Displays the central message and "Find Community" button.
//       * `_buildMyCommunityCard()`: Creates the top card for the "General Bulletin Board."
//       * `_buildTop5Header()`: Creates the title for the "TOP 5 Community" section.
//       * `_buildTop5CommunityList()`: Builds the horizontally scrolling list of ranked community cards.
// 4.  **Dummy Data**: As requested, the UI is built with placeholder data to show how it will look.

// -----

// ### Updated Code: `community_tab.dart`

// Here is the complete code for the file. The main changes are within the `_buildMyTabContent` widget and the new helper methods I've added below it.
 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/community_service.dart'; // hot posts, general posts, my posts
import '../post_detail_screen.dart';
import '../../../models/post_model.dart';


// 커뮤니티 화면을 구성하는 메인 위젯입니다. (StatefulWidget으로 변경)
class CommunityMainTabScreen extends StatefulWidget {
  const CommunityMainTabScreen({super.key});

  @override
  State<CommunityMainTabScreen> createState() => _CommunityMainTabScreenState();
}

class _CommunityMainTabScreenState extends State<CommunityMainTabScreen> {
  // 현재 선택된 탭을 관리하는 상태 변수
  String _selectedTab = 'MAIN';
  final CommunityService _communityService = CommunityService();
  // HOT 게시물을 비동기적으로 불러오기 위한 Future 변수
  late Future<List<Map<String, dynamic>>> _hotPostsFuture;
  late Future<List<Post>> _generalPostsFuture; // 종합 게시판 게시물
  late Future<List<Map<String, dynamic>>> _myPostsFuture; // '내 게시판'을 위한 Future 추가

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 HOT 게시물 데이터를 불러옵니다.
    _hotPostsFuture = _communityService.getHotPosts();
    // 종합 게시판 게시물 데이터를 불러옵니다.
    _generalPostsFuture = _communityService.getCommunityPosts('r8zn6yjJtKHP3jyDoJ2x');
    _myPostsFuture = _communityService.getLatestPostsFromMyCommunities(); // 새로 만든 함수 호출

  }

  // PostDetailScreen으로 이동하는 함수
  Future<void> _navigateToPostDetail(String postId, String communityId) async {
    // 데이터 로딩 중임을 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // 게시물과 커뮤니티의 상세 정보를 가져옵니다.
      final post = await _communityService.getPost(postId);
      final community = await _communityService.getCommunity(communityId);

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      // PostDetailScreen으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PostDetailScreen(
            post: post,
            community: community,
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
      // 에러 발생 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시물 정보를 불러오는 데 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    // Scaffold는 앱의 기본적인 시각적 레이아웃 구조를 구현합니다.
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // AppBar를 커스텀하게 구성합니다.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(164.0),
        child: _buildCustomAppBar(context),
      ),
      // SafeArea는 기기의 노치나 상태 표시줄 같은 영역을 피해 UI를 표시합니다.
      body: SafeArea(
        // _selectedTab 값에 따라 다른 위젯을 보여줍니다.
        child: _selectedTab == 'MAIN'
            ? _buildMainTabContent()
            : _buildMyTabContent(),
      ),
    );
  }

  /// Builds the content for the 'MAIN' tab.
  Widget _buildMainTabContent() {
    final screenSize = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 35), // 상단 여백
            // '실시간 재판소' 섹션
            _buildSectionHeader(
              title: '실시간 재판소',
              subtitle: '실시간으로 재판에 참여해 투표해보세요!',
            ),
            const SizedBox(height: 26),
            // 가로로 스크롤되는 재판 카드 리스트
            _buildLiveTrialsList(screenSize),
            const SizedBox(height: 40),
            // 'HOT 게시물' 섹션 (FutureBuilder로 감싸서 데이터 로딩 처리)
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _hotPostsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildBoardSection(
                    title: 'HOT 게시물',
                    items: [], // 빈 리스트 전달
                  );
                }
                final hotPosts = snapshot.data!
                    .map((postData) => _HotPostItem(
                          postId: postData['postId'],
                          communityId: postData['communityId'],
                          category: postData['category'],
                          title: postData['title'],
                          views: postData['views'],
                          onTap: () => _navigateToPostDetail(postData['postId'], postData['communityId']),
                        ))
                    .toList();
                return _buildBoardSection(
                  title: 'HOT 게시물',
                  items: hotPosts,
                );
              },
            ),
            const SizedBox(height: 30),
            // '종합게시판' 섹션
            FutureBuilder<List<Post>>(
              future: _generalPostsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildBoardSection(
                    title: '종합게시판',
                    items: [], // Pass an empty list
                  );
                }
                final generalPosts = snapshot.data!.map((post) {
                  final bool isNew = DateTime.now().difference(post.datePosted).inHours < 24;
                  return _GeneralPostItem(
                    title: post.title,
                    isNew: isNew,
                    postId: post.postId,
                    communityId: post.communityId,
                    onTap: () => _navigateToPostDetail(post.postId, post.communityId),
                  );
                }).toList();
                return _buildBoardSection(
                  title: '종합게시판',
                  isGeneral: true,
                  items: generalPosts,
                );
              },
            ),
            const SizedBox(height: 30),
            // '내 게시판' 섹션
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _myPostsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('게시판을 불러오는 데 실패했습니다: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildBoardSection(
                    title: '내 게시판',
                    items: [], // 데이터가 없으면 빈 리스트를 전달
                  );
                }
                final myPosts = snapshot.data!.map((postData) {
                  final DateTime postDate = postData['postDate'];
                  final bool isNew = DateTime.now().difference(postDate).inHours < 24;
                  return _MyPostItem(
                    category: postData['communityName'],
                    title: postData['postTitle'],
                    isNew: isNew,
                    postId: postData['postId'],
                    communityId: postData['communityId'],
                    onTap: () => _navigateToPostDetail(postData['postId'], postData['communityId']),
                  );
                }).toList();
                return _buildBoardSection(
                  title: '내 게시판',
                  items: myPosts,
                );
              },
            ),
            const SizedBox(height: 40), // 하단 여백
          ],
        ),
      ),
    );
  }

  /// Builds the content for the 'MY' tab using a responsive layout.
  Widget _buildMyTabContent() {
    // Base screen dimensions from the design
    const double designWidth = 393.0;
    const double designHeight = 800.0;

    // Get current screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive ratios
    final widthRatio = screenWidth / designWidth;
    final heightRatio = screenHeight / designHeight;

    return SingleChildScrollView(
      child: Container(
        width: screenWidth,
        color: const Color(0xFFFAFAFA),
        padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40 * heightRatio),
            _buildMyCommunityCard(widthRatio, heightRatio),
            SizedBox(height: 53 * heightRatio),
            _buildEmptyState(widthRatio, heightRatio),
            SizedBox(height: 124 * heightRatio),
            _buildTop5Header(widthRatio),
            SizedBox(height: 12 * heightRatio),
            _buildTop5CommunityList(widthRatio, heightRatio),
            SizedBox(height: 40 * heightRatio),
          ],
        ),
      ),
    );
  }

  // Helper widget for the 'MY' tab's empty state message and button
  Widget _buildEmptyState(double widthRatio, double heightRatio) {
    return Column(
      children: [
        Text(
          '참여한 커뮤니티가 없어요.\n자유롭게 관심있는 커뮤니티를 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFC7C7C7),
            fontSize: 14 * widthRatio,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            height: 1.43,
          ),
        ),
        SizedBox(height: 13 * heightRatio),
        GestureDetector(
          onTap: () {
            // TODO: Implement navigation to the community search/discovery page
            print('Navigate to find community page!');
          },
          child: Container(
            width: 139 * widthRatio,
            height: 29 * heightRatio,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  width: 1.20,
                  color: Color(0xFF121212),
                ),
                borderRadius: BorderRadius.circular(400),
              ),
            ),
            child: Center(
              child: Text(
                '커뮤니티 찾아보기',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 14 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for the card at the top of the 'MY' tab
  Widget _buildMyCommunityCard(double widthRatio, double heightRatio) {
    return Container(
      width: 360 * widthRatio,
      height: 125 * heightRatio,
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFC7C7C7)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 101 * widthRatio,
            height: 125 * heightRatio,
            decoration: const ShapeDecoration(
              image: DecorationImage(
                image: NetworkImage("https://placehold.co/101x125"),
                fit: BoxFit.cover,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(width: 13 * widthRatio),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '종합게시판',
                  style: TextStyle(
                    color: const Color(0xFF121212),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 11 * heightRatio),
                Text(
                  '다양한 사람들의 실패 썰들을 들어보세요!',
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for the "TOP 5" header
  Widget _buildTop5Header(double widthRatio) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'TOP 5 커뮤니티',
        style: TextStyle(
          color: const Color(0xFF121212),
          fontSize: 18 * widthRatio,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  // Helper widget for the horizontally scrollable TOP 5 communities
  Widget _buildTop5CommunityList(double widthRatio, double heightRatio) {
    // Dummy data for the top 5 communities
    final topCommunities = [
      {
        'rank': '1위',
        'title': '대학교 빌런이 되지말자',
        'description': '대학교에서 팀플 많은 사람들 모여라! 팀플 꿀팁 대방출',
        'members': '9,909명',
        'imageUrl': 'https://placehold.co/300x87'
      },
      {
        'rank': '2위',
        'title': '스타트업 시작하는 사람들의 모임',
        'description': '스타트업을 시작하며 겪었던 여러 실패들을 서로 공유하는 공간',
        'members': '8,013명',
        'imageUrl': 'https://placehold.co/300x87'
      },
      {
        'rank': '3위',
        'title': '엄빠가 처음이라',
        'description': '육아에서 시행착오를 겪은 부모들이 진솔한 경험담을 나누는 공간',
        'members': '8,112명',
        'imageUrl': 'https://placehold.co/300x87'
      },
    ];

    return SizedBox(
      height: 176 * heightRatio,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topCommunities.length,
        separatorBuilder: (context, index) => SizedBox(width: 12 * widthRatio),
        itemBuilder: (context, index) {
          final community = topCommunities[index];
          return _buildRankedCommunityCard(
            widthRatio,
            heightRatio,
            rank: community['rank']!,
            title: community['title']!,
            description: community['description']!,
            members: community['members']!,
            imageUrl: community['imageUrl']!,
          );
        },
      ),
    );
  }
  
  // Helper widget for a single ranked community card
  Widget _buildRankedCommunityCard(double widthRatio, double heightRatio,
      {required String rank,
      required String title,
      required String description,
      required String members,
      required String imageUrl}) {
    return Container(
      width: 300 * widthRatio,
      height: 176 * heightRatio,
      decoration: ShapeDecoration(
        color: const Color(0xFFFAFAFA),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFF5F37CF)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 87 * heightRatio,
                width: 300 * widthRatio,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 11 * widthRatio,
                top: 11 * heightRatio,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10 * widthRatio, vertical: 2 * heightRatio),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F37CF),
                    borderRadius: BorderRadius.circular(400),
                  ),
                  child: Text(
                    rank,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10 * widthRatio,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12 * widthRatio,
                bottom: 8 * heightRatio,
                child: Row(
                  children: [
                     Icon(Icons.person, color: Colors.white, size: 14 * widthRatio),
                     SizedBox(width: 4 * widthRatio),
                    Text(
                      members,
                      style: TextStyle(
                        color: const Color(0xFFFAFAFA),
                        fontSize: 12 * widthRatio,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12 * widthRatio),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF121212),
                    fontSize: 16 * widthRatio,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4 * heightRatio),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // 커스텀 AppBar를 생성하는 함수입니다.
  Widget _buildCustomAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: [
          // 상단 로고, 타이틀, 아이콘 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset("assets/images/community/logo.png", width: 69, height: 25),
              SizedBox(width: screenWidth * (9.93 / 393.0)),
              const Text(
                '커뮤니티',
                style: TextStyle(
                  color: Color(0xFF5F37CF),
                  fontSize: 22,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon : const Icon(Icons.search, size: 28, color: Color(0xFF5F37CF),),
                onPressed: () {
                  // TODO: 검색 버튼 클릭 시 동작 구현
                  print('Search button tapped!');
                },
                ), // 검색 아이콘
              SizedBox(width: screenWidth * (6.15 / 393.0)),
              IconButton(
                icon: const Icon(Icons.filter_list, size: 28,color: Color(0xFF5F37CF),),
                onPressed: () {
                  // TODO: 검색 버튼 클릭 시 동작 구현
                  print('menu button tapped!');
                },
                ), // 메뉴 아이콘
            ],
          ),
              const SizedBox(height: 40), // Adjusted for better spacing
          // 'MAIN', 'MY' 탭 영역
          Row(
            children: [
              Expanded(
                child: _buildTab(
                  'MAIN',
                  _selectedTab == 'MAIN', // 상태 변수와 비교하여 활성화 여부 결정
                  onTap: () {
                    setState(() {
                      _selectedTab = 'MAIN'; // 상태 변경
                    });
                    print('MAIN tab tapped!');
                  }
                ),
              ),
              Expanded(
                child: _buildTab(
                  'MY',
                  _selectedTab == 'MY', // 상태 변수와 비교하여 활성화 여부 결정
                  onTap: () {
                    setState(() {
                      _selectedTab = 'MY'; // 상태 변경
                    });
                    print('MY tab tapped!');
                  }
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // 탭 위젯을 생성하는 함수입니다.
  Widget _buildTab(String title, bool isActive, {required VoidCallback onTap}) {
    return InkWell(
            onTap: onTap,
      child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? const Color(0xFF5F37CF) : const Color(0xFFC7C7C7),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 3,
          color: isActive ? const Color(0xFF5F37CF) : const Color(0xFFEEEEEE),
        ),
      ],
      ),
    );
  }

  // 각 섹션의 헤더(제목, 부제목)를 생성하는 함수입니다.
  Widget _buildSectionHeader({required String title, String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFC7C7C7),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // '실시간 재판소'의 가로 스크롤 리스트를 생성하는 함수입니다.
  Widget _buildLiveTrialsList(Size screenSize) {
    // 화면 너비의 절반보다 약간 크게 카드의 너비를 설정하여 옆의 카드가 살짝 보이게 합니다.
    final cardWidth = screenSize.width * 0.55;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 스크롤 끝에 도달했을 때 시각적 효과를 제거합니다.
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTrialCard(
            imageUrl: "assets/images/community/judge_1.png",
            title: '여친이랑 헤어짐; 드루와',
            timeLeft: '판결까지 3시간 남음',
            participants: '현재 참여수 56명',
            isLive: true,
            width: cardWidth,
          ),
          const SizedBox(width: 8),
          _buildTrialCard(
            imageUrl: "assets/images/community/judge_2.png",
            title: '상사한테 꾸중을 들었...',
            timeLeft: '판결까지 9시간 남음',
            participants: '현재 참여수 56명',
            isLive: true,
            width: cardWidth,
          ),
          const SizedBox(width: 8),
          _buildTrialCard(
            imageUrl: "assets/images/community/judge_1.png",
            title: '또 다른 재판 이야기',
            timeLeft: '판결까지 1일 남음',
            participants: '현재 참여수 102명',
            isLive: false,
            width: cardWidth,
          ),
        ],
      ),
    );
  }

  // '실시간 재판소' 카드를 생성하는 함수입니다.
  Widget _buildTrialCard({
    required String imageUrl,
    required String title,
    required String timeLeft,
    required String participants,
    required bool isLive,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 이미지 부분
          Container(
            height: 121,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: AssetImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 11,
                  top: 12,
                  child: Text(
                    timeLeft,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    right: 11,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC31A1A),
                        borderRadius: BorderRadius.circular(400),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 11,
                  bottom: 12,
                  child: Text(
                    participants,
                    style: const TextStyle(
                      color: Color(0xFFBBBBBB),
                      fontSize: 10,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          // 카드 제목 부분
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF121212),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // 게시판 섹션을 생성하는 함수입니다.
  Widget _buildBoardSection({
    required String title,
    required List<dynamic> items,
    bool isGeneral = false,
  }) {
    // If there are no items, show a message instead of an empty box.
    if (items.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5F37CF),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                '게시물이 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF5F37CF),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            // ListView.separated를 사용하여 아이템 사이에 구분선을 추가합니다.
            children: List.generate(items.length, (index) {
              final item = items[index];
              Widget itemWidget;
              // 게시판 종류에 따라 다른 위젯을 렌더링합니다.
              if (title == 'HOT 게시물' && item is _HotPostItem) {
                itemWidget = item;
              } else if (item is _GeneralPostItem) {
                itemWidget = item;
              } else if (item is _MyPostItem) {
                 itemWidget = item;
              } else {
                itemWidget = const SizedBox.shrink();
              }

              // 마지막 아이템이 아닐 경우에만 간격을 줍니다.
              return Padding(
                padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                child: itemWidget,
              );
            }),
          ),
        ),
      ],
    );
  }
}


// 'HOT 게시물' 아이템 위젯
class _HotPostItem extends StatelessWidget {
  final String postId;
  final String communityId;
  final String category;
  final String title;
  final String views;
  final VoidCallback onTap;

  const _HotPostItem({
    required this.postId,
    required this.communityId,
    required this.category,
    required this.title,
    required this.views,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFAFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF5F37CF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(
                color: Color(0xFF8E8E8E),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '조회수: $views',
                  style: const TextStyle(
                    color: Color(0xFF5F37CF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// '종합게시판' 아이템 위젯
class _GeneralPostItem extends StatelessWidget {
  final String title;
  final bool isNew;
  final String postId;
  final String communityId;
  final VoidCallback onTap;

  const _GeneralPostItem({
    required this.title,
    this.isNew = false,
    required this.postId,
    required this.communityId,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    // Wrap with InkWell to make it tappable
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: 7),
            _buildNewBadge(),
          ]
        ],
      ),
    );
  }
}

// '내 게시판' 아이템 위젯
class _MyPostItem extends StatelessWidget {
  final String category;
  final String title;
  final bool isNew;
  final String postId;
  final String communityId;
  final VoidCallback onTap;

  const _MyPostItem({
    required this.category,
    required this.title,
    this.isNew = false,
    required this.postId,
    required this.communityId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // InkWell로 감싸서 탭 이벤트를 처리합니다.
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$category ', // 커뮤니티 이름을 타이틀과 구분
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontSize: 14,
                      fontWeight: FontWeight.w600, // 더 잘보이게 Bold 처리
                    ),
                  ),
                  TextSpan(
                    text: title,
                    style: const TextStyle(
                      color: Color(0xFF8E8E8E),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isNew) ...[
            const SizedBox(width: 7),
            _buildNewBadge(),
          ]
        ],
      ),
    );
  }
}

// 'N' 뱃지를 생성하는 공통 함수
Widget _buildNewBadge() {
  return Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: const Color(0xFF5F37CF),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Center(
      child: Text(
        'N',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}