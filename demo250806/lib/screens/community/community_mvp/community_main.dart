import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/community_service.dart'; // hot posts, general posts, my posts
import '../post_detail_screen.dart';


// 커뮤니티 화면을 구성하는 메인 위젯입니다. (StatefulWidget으로 변경)
class CommunityMainScreen extends StatefulWidget {
  const CommunityMainScreen({super.key});

  @override
  State<CommunityMainScreen> createState() => _CommunityMainScreenState();
}

class _CommunityMainScreenState extends State<CommunityMainScreen> {
  // 현재 선택된 탭을 관리하는 상태 변수
  String _selectedTab = 'MAIN';
  final CommunityService _communityService = CommunityService();
  // HOT 게시물을 비동기적으로 불러오기 위한 Future 변수
  late Future<List<Map<String, dynamic>>> _hotPostsFuture;

  @override
  void initState() {
    super.initState();
    // 위젯이 처음 생성될 때 HOT 게시물 데이터를 불러옵니다.
    _hotPostsFuture = _communityService.getHotPosts();
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
    // 화면의 크기 정보를 가져옵니다.
    final screenSize = MediaQuery.of(context).size;

    // Scaffold는 앱의 기본적인 시각적 레이아웃 구조를 구현합니다.
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      // AppBar를 커스텀하게 구성합니다.
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(164.0),
        child: _buildCustomAppBar(context, screenSize),
      ),
      // SafeArea는 기기의 노치나 상태 표시줄 같은 영역을 피해 UI를 표시합니다.
      body: SafeArea(
        // SingleChildScrollView를 사용하여 화면 내용이 길어져도 스크롤이 가능하게 합니다.
        child: SingleChildScrollView(
          child: Padding(
            // 전체 콘텐츠에 좌우 패딩을 적용합니다.
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
                // 'HOT 게시물' 섹션
                // 'HOT 게시물' 섹션 (FutureBuilder로 감싸서 데이터 로딩 처리)
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _hotPostsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // 데이터 로딩 중일 때 로딩 인디케이터 표시
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      // 에러 발생 시 에러 메시지 표시
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      // 데이터가 없을 때 메시지 표시
                      return _buildBoardSection(
                        title: 'HOT 게시물',
                        items: [], // 빈 리스트 전달
                      );
                    }
                    
                    // 데이터 로딩 완료 시 게시물 목록을 표시
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
                _buildBoardSection(
                  title: '종합게시판',
                  isGeneral: true,
                  items: [
                    '오늘 내가 이런 일이 있었는데 진짜 아닌 것 같다. 내가...',
                    '오늘 내가 이런 일이 있었는데 진짜 아닌 것 같다. 내가...',
                    '오늘 내가 이런 일이 있었는데 진짜 아닌 것 같다. 내가...',
                  ],
                ),
                const SizedBox(height: 30),
                // '내 게시판' 섹션
                _buildBoardSection(
                  title: '내 게시판',
                  isGeneral: true,
                  items: [
                    {'category': '농사 게시판', 'title': '이런 일이 있었는데 진짜 아닌 것 같다. 내..'},
                    {'category': '농사 게시판', 'title': '이런 일이 있었는데 진짜 아닌 것 같다. 내..'},
                    {'category': '농사 게시판', 'title': '이런 일이 있었는데 진짜 아닌 것 같다. 내..'},
                  ],
                ),
                 const SizedBox(height: 40), // 하단 여백
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 커스텀 AppBar를 생성하는 함수입니다.
  Widget _buildCustomAppBar(BuildContext context, Size screenSize) {
        final screenWidth = screenSize.width;

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
                icon: Icon(Icons.filter_list, size: 28,color: Color(0xFF5F37CF),),
                onPressed: () {
                  // TODO: 검색 버튼 클릭 시 동작 구현
                  print('menu button tapped!');
                },
                ), // 메뉴 아이콘
            ],
          ),
              SizedBox(height: screenWidth * (66.15 / 852)),
          // 'MAIN', 'MY' 탭 영역
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
                    print('MAIN tab tapped!'); // 페이지 추가 or 전한 logic 
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
              } else if (isGeneral && item is String) {
                itemWidget = _GeneralPostItem(title: item, isNew: true);
              } else if (item is Map<String, String>) {
                 itemWidget = _MyPostItem(category: item['category']!, title: item['title']!, isNew: true);
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

  const _GeneralPostItem({required this.title, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}

// '내 게시판' 아이템 위젯
class _MyPostItem extends StatelessWidget {
  final String category;
  final String title;
  final bool isNew;

  const _MyPostItem({required this.category, required this.title, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '[$category]',
                  style: const TextStyle(
                    color: Color(0xFF121212),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: ' $title',
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
