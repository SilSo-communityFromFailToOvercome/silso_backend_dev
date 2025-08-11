import 'package:flutter/material.dart';
import '../../services/community_service.dart'; // hot posts, general posts, my posts
import '../../services/auth_service.dart'; // auth service for sign out
import 'post_detail_screen.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import 'community_search_page.dart'; // Korean UI 검색 페이지를 가져옵니다.
import 'community_detail_page.dart'; // Korean UI 커뮤니티 상세 페이지를 가져옵니다.
import 'community_find_page.dart'; // Korean UI 커뮤니티 찾아보기 페이지를 가져옵니다.
import 'admin_add_community.dart'; // Admin add community page


// 커뮤니티 화면을 구성하는 메인 위젯입니다. (StatefulWidget으로 변경)
class CommunityMainTabScreenMycom extends StatefulWidget {
  const CommunityMainTabScreenMycom({super.key});

  @override
  State<CommunityMainTabScreenMycom> createState() => _CommunityMainTabScreenMycomState();
}

class _CommunityMainTabScreenMycomState extends State<CommunityMainTabScreenMycom> {
  // 현재 선택된 탭을 관리하는 상태 변수
  String _selectedTab = 'MAIN';
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  // HOT 게시물을 비동기적으로 불러오기 위한 Future 변수
  late Future<List<Map<String, dynamic>>> _hotPostsFuture;
  late Future<List<Post>> _generalPostsFuture; // 종합 게시판 게시물
  late Future<List<Map<String, dynamic>>> _myPostsFuture; // '내 게시판'을 위한 Future 추가
  late Stream<List<Community>> _myCommunitiesStream; // '내 커뮤니티'를 위한 Stream
  late Future<List<Community>> _top5CommunitiesFuture;
  late Stream<List<Community>> _recommendedCommunitiesStream; // 추천 커뮤니티를 위한 Stream
  late Future<List<String>> _userInterestsFuture; // 사용자 관심사를 위한 Future

  // 카테고리 ID와 표시 형식 매핑
  static const Map<String, Map<String, String>> _categoryMapping = {
    'business': {'emoji': '🏬', 'name': '자영업'},
    'startup': {'emoji': '💰', 'name': '창업'},
    'career_change': {'emoji': '💼', 'name': '이직'},
    'resignation': {'emoji': '🚪', 'name': '퇴사'},
    'employment': {'emoji': '🎓', 'name': '취업'},
    'study': {'emoji': '📚', 'name': '학업'},
    'contest': {'emoji': '🏆', 'name': '공모전'},
    'mental_care': {'emoji': '🧘‍♀️', 'name': '멘탈케어'},
    'relationships': {'emoji': '👥', 'name': '인간관계'},
    'daily_life': {'emoji': '☀️', 'name': '일상'},
    'humor': {'emoji': '😄', 'name': '유머'},
    'health': {'emoji': '💪', 'name': '건강'},
  };

  @override
  void initState() {
    super.initState();
    print("screens/korean_ui/community/community_main.dart is currently showing");
    // 위젯이 처음 생성될 때 HOT 게시물 데이터를 불러옵니다.
    _hotPostsFuture = _communityService.getHotPosts();
    // 종합 게시판 게시물 데이터를 불러옵니다.
    _generalPostsFuture = _communityService.getCommunityPosts('r8zn6yjJtKHP3jyDoJ2x');
    _myPostsFuture = _communityService.getLatestPostsFromMyCommunities(); // 새로 만든 함수 호출
    _myCommunitiesStream = _communityService.getMyCommunitiesStream(); // '내 커뮤니티'를 위한 Stream
    _top5CommunitiesFuture = _communityService.getTop5Communities();
    _recommendedCommunitiesStream = _communityService.getRecommendedCommunitiesStream(); // 추천 커뮤니티 스트림
    _userInterestsFuture = _communityService.getUserInterests(); // 사용자 관심사 로드

  }


  // 로그아웃 처리 함수
  Future<void> _handleSignOut() async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // 로그아웃 수행
      await _authService.signOut();
      
      // 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
        
        // 로그인 화면으로 이동하고 모든 이전 화면을 제거
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      // 에러 발생 시 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
        
        // 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // PostDetailScreen으로 이동하는 함수
  Future<void> _navigateToPostDetail(String postId, String communityId) async {
    // Increment view count when navigating to post detail
    await _communityService.incrementPostViewCount(postId);

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
                          communityId: postData['communityId'] ?? '',
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

  /// Builds the content for the 'MY' tab.
  /// It dynamically shows either a list of joined communities or an empty state message.
  Widget _buildMyTabContent() {
    // Define base screen dimensions for responsive UI calculations
    const double designWidth = 393.0;
    const double designHeight = 870.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final widthRatio = screenWidth / designWidth;
    final heightRatio = screenHeight / designHeight;

    return StreamBuilder<List<Community>>(
      stream: _myCommunitiesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final myJoinedCommunities = snapshot.data ?? [];

        // Use LayoutBuilder to get available constraints
        return LayoutBuilder(
          builder: (context, constraints) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20 * heightRatio),
                    
                    // My Communities Section (if any)
                    if (myJoinedCommunities.isNotEmpty) ...[
                      _buildMyCommunitiesSection(widthRatio, heightRatio, myJoinedCommunities),
                      SizedBox(height: 30 * heightRatio),
                    ],
                    
                    // Empty state message or find community button
                    if (myJoinedCommunities.isEmpty) ...[
                      SizedBox(height: 60 * heightRatio),
                      _buildEmptyStateMessage(widthRatio, heightRatio),
                      SizedBox(height: 30 * heightRatio),
                    ],
                    
                    // Find Community Button (always visible)
                    Center(
                      child: _buildFindCommunityButton(widthRatio, heightRatio),
                    ),
                    
                    SizedBox(height: 40 * heightRatio),
                    
                    // Recommended Communities Section
                    _buildRecommendedHeader(widthRatio),
                    SizedBox(height: 18 * heightRatio),
                    
                    // Category filter chips with horizontal scroll
                    SizedBox(
                      height: 40 * heightRatio,
                      child: _buildCategoryChips(widthRatio, heightRatio),
                    ),
                    SizedBox(height: 22 * heightRatio),
                    
                    // Grid of recommended community cards with proper constraints
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 220 * heightRatio,
                        maxWidth: constraints.maxWidth - (32 * widthRatio),
                      ),
                      child: _buildRecommendedCommunityGrid(widthRatio, heightRatio),
                    ),
                    
                    SizedBox(height: 40 * heightRatio), // Bottom padding
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 가입한 커뮤니티 목록을 스크롤 가능한 리스트로 빌드합니다.
  Widget _buildMyCommunitiesScrollableList(double widthRatio, double heightRatio, List<Community> communities) {
    return SingleChildScrollView(
      // 중앙 버튼에 마지막 항목이 가려지지 않도록 하단에 충분한 여백을 추가합니다.
      padding: EdgeInsets.only(
        top: 40 * heightRatio,
        left: 16 * widthRatio,
        right: 16 * widthRatio,
        bottom: 150 * heightRatio, // 하단 여유 공간 확보
      ),
      child: ListView.separated(
        shrinkWrap: true, // 자식 위젯의 크기만큼만 차지하도록 설정
        physics: const NeverScrollableScrollPhysics(), // 부모 스크롤과 충돌 방지
        itemCount: communities.length,
        separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
        itemBuilder: (context, index) {
          final community = communities[index];
          // 기존의 커뮤니티 카드 위젯을 재사용합니다.
          return _buildMyCommunityCard(widthRatio, heightRatio, community);
        },
      ),
    );
  }

  /// 가입한 커뮤니티 섹션을 빌드합니다.
  Widget _buildMyCommunitiesSection(double widthRatio, double heightRatio, List<Community> communities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '내 커뮤니티',
          style: TextStyle(
            color: const Color(0xFF121212),
            fontSize: 20 * widthRatio,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16 * heightRatio),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: communities.length,
          separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildMyCommunityCard(widthRatio, heightRatio, community);
          },
        ),
      ],
    );
  }

  /// 가입한 커뮤니티가 없을 때 보여줄 안내 메시지 위젯입니다.
  Widget _buildEmptyStateMessage(double widthRatio, double heightRatio) {
    return Text(
      '참여한 커뮤니티가 없어요.\n자유롭게 관심있는 커뮤니티를 추가해보세요!',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFC7C7C7),
        fontSize: 14 * widthRatio,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
        height: 1.43,
      ),
    );
  }


  /// 화면 중앙에 위치할 '커뮤니티 찾아보기' 버튼을 빌드합니다.
  Widget _buildFindCommunityButton(double widthRatio, double heightRatio) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityFindPage()),
        );
      },
      child: Container(
        width: 139 * widthRatio,
        height: 35 * heightRatio, // 터치 영역을 고려하여 높이 조정
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1.20,
              color: Color(0xFF5F37CF),
            ),
            borderRadius: BorderRadius.circular(400),
          ),
        ),
        child: Center(
          child: Text(
            '커뮤니티 찾아보기',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5F37CF),
              fontSize: 14 * widthRatio,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }


  /// Helper widget to show when the user has not joined any communities.
  // Widget _buildEmptyMyTab(double widthRatio, double heightRatio) {
  //   return SingleChildScrollView(
  //     child: Container(
  //       width: double.infinity,
  //       color: const Color(0xFFFAFAFA),
  //       padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           SizedBox(height: 120 * heightRatio),
  //           _buildEmptyState(widthRatio, heightRatio),
  //           SizedBox(height: 124 * heightRatio),
  //           _buildTop5Header(widthRatio),
  //           SizedBox(height: 12 * heightRatio),
  //           _buildTop5CommunityList(widthRatio, heightRatio),
  //           SizedBox(height: 40 * heightRatio),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// Helper widget to display the list of joined communities.
  Widget _buildMyCommunitiesList(double widthRatio, double heightRatio, List<Community> communities) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFAFAFA),
        padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40 * heightRatio),
            // List of joined communities
            ListView.separated(
              shrinkWrap: true, // Important for nesting in a Column
              physics: const NeverScrollableScrollPhysics(), // Disable its own scrolling
              itemCount: communities.length,
              separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
              itemBuilder: (context, index) {
                final community = communities[index];
                return _buildMyCommunityCard(widthRatio, heightRatio, community);
              },
            ),
            SizedBox(height: 50 * heightRatio),
            // // "TOP 5" section below the user's communities
            // _buildTop5Header(widthRatio),
            // SizedBox(height: 12 * heightRatio),
            // _buildTop5CommunityList(widthRatio, heightRatio),
            // SizedBox(height: 40 * heightRatio),
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

  // Builds a card for a joined community, now with dynamic data.
  Widget _buildMyCommunityCard(double widthRatio, double heightRatio, Community community) {
    return Container(
      margin: EdgeInsets.only(bottom: 12 * heightRatio),
      height: 150 * heightRatio, // Define explicit height for the card
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * widthRatio),
          side: const BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
        clipBehavior: Clip.antiAlias, // Ensure image respects card border radius
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => KoreanCommunityDetailPage(community: community),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Make children fill full height
            children: [
              // Community image on the left - stretches full height
              Container(
                width: 80 * widthRatio, // Made slightly wider for better proportion
                decoration: const BoxDecoration(
                  color: Color(0xFFE9E9E9),
                ),
                child: community.communityBanner != null
                    ? Image.network(
                        community.communityBanner!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80 * widthRatio,
                            color: const Color(0xFFE9E9E9),
                            child: const Icon(Icons.group, color: Colors.grey, size: 32),
                          );
                        },
                      )
                    : const Icon(Icons.group, color: Colors.grey, size: 32),
              ),
              
              // Community info on the right
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16 * widthRatio),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Community title
                          Text(
                            community.communityName,
                            style: TextStyle(
                              color: const Color(0xFF121212),
                              fontSize: 16 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: 4 * heightRatio),
                          
                          // Community description
                          if (community.announcement != null && community.announcement!.isNotEmpty) ...[
                            Text(
                              community.announcement!,
                              style: TextStyle(
                                color: const Color(0xFF8E8E8E),
                                fontSize: 14 * widthRatio,
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                      
                      // Member count at bottom right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.people,
                            size: 14 * widthRatio,
                            color: const Color(0xFF8E8E8E),
                          ),
                          SizedBox(width: 4 * widthRatio),
                          Text(
                            '${community.memberCount}명',
                            style: TextStyle(
                              color: const Color(0xFF8E8E8E),
                              fontSize: 12 * widthRatio,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget for the "추천 커뮤니티" header.
  Widget _buildRecommendedHeader(double widthRatio) {
    return Text(
      '추천 커뮤니티',
      style: TextStyle(
        color: const Color(0xFF121212),
        fontSize: 20 * widthRatio,
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Helper widget for the category filter chips.
  Widget _buildCategoryChips(double widthRatio, double heightRatio) {
    return FutureBuilder<List<String>>(
      future: _userInterestsFuture,
      builder: (context, snapshot) {
        // 로딩 중일 때 로딩 인디케이터 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 40 * heightRatio,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // 에러가 발생했거나 데이터가 없을 때 기본 카테고리 표시
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('🏬', '자영업', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('💼', '이직', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('🧘‍♀️', '멘탈케어', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('🎓', '취업', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('💰', '창업', widthRatio, heightRatio),
              ],
            ),
          );
        }

        final userInterests = snapshot.data!;
        
        // 사용자의 관심사에 해당하는 카테고리만 표시
        final categoryChips = <Widget>[];
        for (String interestId in userInterests) {
          final categoryData = _categoryMapping[interestId];
          if (categoryData != null) {
            if (categoryChips.isNotEmpty) {
              categoryChips.add(SizedBox(width: 8 * widthRatio));
            }
            categoryChips.add(
              _buildChip(
                categoryData['emoji']!, 
                categoryData['name']!, 
                widthRatio, 
                heightRatio
              )
            );
          }
        }

        // 사용자 관심사가 없거나 매핑되는 카테고리가 없을 때 기본 표시
        if (categoryChips.isEmpty) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip('🏬', '자영업', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('💼', '이직', widthRatio, heightRatio),
                SizedBox(width: 8 * widthRatio),
                _buildChip('🧘‍♀️', '멘탈케어', widthRatio, heightRatio),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: categoryChips),
        );
      },
    );
  }
  
  // A single filter chip widget
  Widget _buildChip(String emoji, String label, double widthRatio, double heightRatio) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12 * widthRatio, vertical: 5 * heightRatio),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1.0,
              color: Color(0xFF121212),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$emoji ',
                style: TextStyle(fontSize: 14 * widthRatio),
              ),
              TextSpan(
                text: label,
                style: TextStyle(
                  color: const Color(0xFF121212),
                  fontSize: 14 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
  }


  /// Helper widget for the grid of recommended community cards.
  /// Helper widget for the grid of recommended community cards, now as a horizontal carousel.
  Widget _buildRecommendedCommunityGrid(double widthRatio, double heightRatio) {
    return StreamBuilder<List<Community>>(
      stream: _recommendedCommunitiesStream,
      builder: (context, snapshot) {
        // 로딩 중일 때 로딩 인디케이터 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 201 * heightRatio,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // 에러가 발생했을 때 에러 메시지 표시
        if (snapshot.hasError) {
          return SizedBox(
            height: 201 * heightRatio,
            child: const Center(child: Text('추천 커뮤니티를 불러오는데 실패했습니다.')),
          );
        }
        
        // 데이터가 없거나 비어있을 때 메시지 표시
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 201 * heightRatio,
            child: const Center(child: Text('추천할 커뮤니티가 없습니다.')),
          );
        }

        final recommendedCommunities = snapshot.data!;

        // A SizedBox is used to give a specific height to the horizontal ListView.
        // This is crucial when placing a horizontal list inside a vertical scrolling parent.
        return SizedBox(
          height: 201 * heightRatio, // Set the height to the height of a single card
          child: ListView.separated(
            scrollDirection: Axis.horizontal, // Make the list scroll horizontally
            itemCount: recommendedCommunities.length,
            // To prevent the card's shadow from being cut off
            clipBehavior: Clip.none, 
            itemBuilder: (context, index) {
              final community = recommendedCommunities[index];
              // We reuse the same card widget from before
              return _buildRecommendedCard(
                widthRatio,
                heightRatio,
                title: community.communityName,
                members: '${community.memberCount}명',
                imageUrl: community.communityBanner ?? 'https://placehold.co/144x201/A9A9A9/FFFFFF?text=${Uri.encodeComponent(community.communityName)}',
                community: community, // 커뮤니티 객체 전달 (탭 이벤트용)
              );
            },
            // This widget builds the space between the cards
            separatorBuilder: (context, index) => SizedBox(width: 12 * widthRatio),
          ),
        );
      },
    );
  }

  /// Builds a single card for the recommended community section.
  Widget _buildRecommendedCard(
    double widthRatio, 
    double heightRatio, {
    required String title,
    required String members,
    required String imageUrl,
    required Community community, // 커뮤니티 객체 추가
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KoreanCommunityDetailPage(community: community),
          ),
        );
      },
      child: Container(
        width: 144 * widthRatio,
        height: 201 * heightRatio,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Container(
          // Add a gradient overlay for better text readability
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7), // 더 어둡게 해서 텍스트 가독성 향상
                  ]
              )
          ),
          child: Stack(
            children: [
              Positioned(
                left: 7 * widthRatio,
                top: 32 * heightRatio,
                right: 7 * widthRatio, // Added right constraint to help with text wrapping
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.29 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: 8 * widthRatio,
                bottom: 8 * heightRatio,
                child: Row(
                  children: [
                     Icon(Icons.person_outline, color: Colors.white, size: 14 * widthRatio),
                     SizedBox(width: 4 * widthRatio),
                    Text(
                      members,
                      style: TextStyle(
                        color: const Color(0xFFFAFAFA),
                        fontSize: 12 * widthRatio,
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
// community_tab_mycom.dart

// Helper widget for the horizontally scrollable TOP 5 communities
Widget _buildTop5CommunityList(double widthRatio, double heightRatio) {
  // FutureBuilder를 사용하여 비동기 데이터를 처리합니다.
  return FutureBuilder<List<Community>>(
    future: _top5CommunitiesFuture, // 여기서 state 변수를 사용합니다.
    builder: (context, snapshot) {
      // 데이터 로딩 중일 때 로딩 인디케이터를 표시합니다.
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      // 에러가 발생했을 때 에러 메시지를 표시합니다.
      if (snapshot.hasError) {
        return Center(child: Text('커뮤니티를 불러오는 데 실패했습니다.'));
      }
      // 데이터가 없거나 비어있을 때 메시지를 표시합니다.
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('표시할 커뮤니티가 없습니다.'));
      }

      // 데이터를 성공적으로 가져왔을 때 리스트를 빌드합니다.
      final topCommunities = snapshot.data!;

      return SizedBox(
        height: 176 * heightRatio,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: topCommunities.length,
          separatorBuilder: (context, index) => SizedBox(width: 12 * widthRatio),
          itemBuilder: (context, index) {
            final community = topCommunities[index];
            // 순위를 표시하기 위해 index를 활용합니다.
            final rank = '${index + 1}위'; 

            return _buildRankedCommunityCard(
              widthRatio,
              heightRatio,
              rank: rank,
              // Community 모델의 프로퍼티를 직접 사용합니다.
              title: community.communityName,
              description: community.announcement ?? '소개가 없습니다.', // announcement가 null일 경우 기본값 설정
              members: '${community.memberCount}명',
              imageUrl: community.communityBanner ?? 'https://placehold.co/300x87', // 배너가 없을 경우 기본 이미지
            );
          },
        ),
      );
    },
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ExploreSearchPage(),
                    ),
                  );
                },
                ), // 검색 아이콘
              SizedBox(width: screenWidth * (6.15 / 393.0)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, size: 28, color: Color(0xFF5F37CF)),
                onSelected: (String value) async {
                  switch (value) {
                    case 'signout':
                      await _handleSignOut();
                      break;
                    case 'admin_add_community':
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdminAddCommunityPage(),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'admin_add_community',
                    child: Row(
                      children: [
                        Icon(Icons.add_business, color: Color(0xFF5F37CF)),
                        SizedBox(width: 8),
                        Text('Admin Add Community'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Color(0xFF5F37CF)),
                        SizedBox(width: 8),
                        Text('로그아웃'),
                      ],
                    ),
                  ),
                ],
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
        const SizedBox(height: 4),
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