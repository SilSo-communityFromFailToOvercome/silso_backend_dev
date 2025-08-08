import 'package:flutter/material.dart';
import 'dart:math' as math; // for PageController rotation
import '../../../models/community_model.dart'; // 커뮤니티 모델을 가져옵니다.
import '../../../services/community_service.dart'; // 커뮤니티 서비스 (API 호출 등)를 가져옵니다.
import '../../../utils/community_navigation_helper.dart'; // 네비게이션 헬퍼를 가져옵니다.
import '../community_detail_screen.dart'; // 커뮤니티 상세 페이지를 가져옵니다.

class CommunityExplorePage extends StatefulWidget {
  const CommunityExplorePage({super.key});

  @override
  State<CommunityExplorePage> createState() => _CommunityExplorePageState();
}

class _CommunityExplorePageState extends State<CommunityExplorePage> {
  // --- 상태 변수 ---
  int _carouselCurrentPage = 0; // 배너 캐러셀의 현재 페이지 인덱스
  String _activeFilter = '인기순'; // 현재 선택된 필터
  final PageController _pageController = PageController(
    viewportFraction: 0.91, // 화면 너비의 91% 만큼 각 페이지가 보이도록 설정
  );

  // REFACTOR: Add an instance of CommunityService and a Future to hold the data.
  final CommunityService _communityService = CommunityService();
  late Future<List<Community>> _topCommunitiesFuture;
  
  // REFACTOR: 전체 커뮤니티 목록을 위한 Future 상태 변수 추가
  late Future<List<Community>> _allCommunitiesFuture;

  // REFACTOR: Fetch data when the widget is initialized.
  @override
  void initState() {
    super.initState();
    // Start fetching the data as soon as the page is loaded.
    _topCommunitiesFuture = _communityService.getTop5Communities();
    // REFACTOR: Fetch all communities for the list view.
    _fetchCommunityData();
  }
  // REFACTOR: 현재 필터에 맞춰 데이터를 다시 불러오는 메소드
  void _fetchCommunityData() {
    String sortBy;
    bool descending;

    switch (_activeFilter) {
      case '최신순':
        sortBy = 'createdAt';
        descending = true;
        break;
      case '오래된 순':
        sortBy = 'createdAt';
        descending = false;
        break;
      case '인기순':
      default:
        sortBy = 'memberCount';
        descending = true;
        break;
    }

    // 상태를 업데이트하여 FutureBuilder가 새로운 Future를 사용하도록 합니다.
    setState(() {
      _allCommunitiesFuture = _communityService.getCommunities(
        sortBy: sortBy,
        descending: descending,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 화면 크기 및 비율 계산 ---
    final screenSize = MediaQuery.of(context).size;
    final double scale = screenSize.width / 393.0; // 기준 너비 393px에 대한 비율

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(scale),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 18 * scale),
            // _buildTopCommunityCarousel(scale),
            // SizedBox(height: 12 * scale),
            // _buildCarouselIndicator(scale),
  // REFACTOR: Use a FutureBuilder to handle loading/error/data states.
            _buildTopCommunitySection(scale),
            SizedBox(height: 30 * scale),
            const Divider(color: Color(0xFFF4F4F4), thickness: 1.5, height: 1.5),
            SizedBox(height: 24 * scale),
            _buildFilterButtons(scale),
            SizedBox(height: 24 * scale),
            _buildCommunityList(scale),
          ],
        ),
      ),
    );
  }

  /// ## 상단 앱바 위젯
  PreferredSizeWidget _buildAppBar(double scale) {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFA),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 24 * scale),
        onPressed: () {
          // TODO: 뒤로가기 로직 구현
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset("assets/images/community/logo.png", width: 69, height: 25),
          SizedBox(width: 10 * scale),
          Text(
            '커뮤니티',
            style: TextStyle(
              color: const Color(0xFF5F37CF),
              fontSize: 22 * scale,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: false, // 왼쪽 정렬 위함. 
      titleSpacing: 0, // 왼쪽 정렬 위함. 
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: Colors.black, size: 28 * scale),
          onPressed: () {
            // TODO: 검색 로직 구현
          },
        ),
        SizedBox(width: 8 * scale),
      ],
    );
  }
  
  /// ## 상단 TOP 5 커뮤니티 배너 캐러셀
  // REFACTOR: This new helper widget builds the UI based on the Future's state.
  /// ## Top Community Section with Loading/Error/Data states
  Widget _buildTopCommunitySection(double scale) {
    return FutureBuilder<List<Community>>(
      future: _topCommunitiesFuture,
      builder: (context, snapshot) {
        // 1. While data is loading, show a spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Reserve space for the carousel and indicator to prevent layout shifts.
          return SizedBox(
            height: (212 * scale) + (12 * scale) + (6 * scale),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If an error occurs, display an error message.
        if (snapshot.hasError) {
          return Center(child: Text('데이터를 불러오는데 실패했습니다: ${snapshot.error}'));
        }

        // 3. If data is empty or null, show a confirmation message.
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('TOP 5 커뮤니티가 없습니다.'));
        }

        // 4. When data is successfully fetched, build the UI.
        final topCommunities = snapshot.data!;
        return Column(
          children: [
            _buildTopCommunityCarousel(scale, topCommunities),
            SizedBox(height: 12 * scale),
            _buildCarouselIndicator(scale, topCommunities),
          ],
        );
      },
    );
  }


  Widget _buildTopCommunityCarousel(double scale, List<Community> communities) {
    return SizedBox(
      height: 212 * scale,
      child: PageView.builder(
        controller: _pageController,
        itemCount: communities.length,
        onPageChanged: (index) {
          setState(() {
            _carouselCurrentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return _TopCommunityCard(
            info: communities[index],
            scale: scale,
            rank: index + 1, // 랭킹은 1부터 시작하므로 index + 1
          );
        },
      ),
    );
  }

  /// ## 캐러셀 인디케이터 (페이지 표시 점)
  Widget _buildCarouselIndicator(double scale, List<Community> communities) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(communities.length, (index) {
        return Container(
          width: 6 * scale,
          height: 6 * scale,
          margin: EdgeInsets.symmetric(horizontal: 4.5 * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _carouselCurrentPage == index
                ? const Color(0xFF5F37CF)
                : const Color(0xFFDFD4FF),
          ),
        );
      }),
    );
  }

  /// ## 정렬 필터 버튼 (인기순, 최신순, 오래된순)
  Widget _buildFilterButtons(double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.0 * scale),
      child: Row(
        children: ['인기순', '최신순', '오래된순'].map((filter) {
          bool isActive = _activeFilter == filter;
          return Padding(
            padding: EdgeInsets.only(right: 5 * scale),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                  // TODO: 필터에 따른 데이터 정렬 로직 구현
                });
                _fetchCommunityData();
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * scale,
                  vertical: 8 * scale,
                ),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF5F37CF) : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(400),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFBBBBBB),
                    fontSize: 14 * scale,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// ## 전체 커뮤니티 목록
  /// ## 전체 커뮤니티 목록 (REFACTORED)
  Widget _buildCommunityList(double scale) {
    return FutureBuilder<List<Community>>(
      future: _allCommunitiesFuture,
      builder: (context, snapshot) {
        // 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // 에러 발생 시
        if (snapshot.hasError) {
          return Center(child: Text('목록을 불러오는데 실패했습니다: ${snapshot.error}'));
        }
        // 데이터가 없거나 비어있을 때
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('표시할 커뮤니티가 없습니다.'));
        }

        // 성공적으로 데이터를 가져왔을 때
        final communities = snapshot.data!;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 17 * scale),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              // Community 모델 객체를 아이템 위젯에 직접 전달합니다.
              return _CommunityListItem(
                community: communities[index],
                scale: scale,
              );
            },
            separatorBuilder: (context, index) => SizedBox(height: 6 * scale),
          ),
        );
      },
    );
  }
}


/// ## [컴포넌트] 상단 캐러셀에 들어갈 카드 위젯
/// ## [컴포넌트] 상단 캐러셀에 들어갈 카드 위젯 (Overflow 해결)
/// REFACTOR: The card widget is now updated to use the 'Community' model.

class _TopCommunityCard extends StatelessWidget {
  final Community info;
  final int rank;
  final double scale;

  const _TopCommunityCard({required this.info, required this.rank, required this.scale});

  @override
  Widget build(BuildContext context) {
    // PageView의 높이와 일치시키기 위해 카드 전체 높이를 명시적으로 지정합니다.
    return Container(
      height: 212 * scale,
      margin: EdgeInsets.symmetric(horizontal: 4 * scale), // 카드 간 간격
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // REFACTOR: 탭 기능을 추가하기 위해 ClipRRect와 InkWell 위젯으로 감싸줍니다.
      child: ClipRRect(
        // InkWell의 물결 효과가 둥근 모서리를 벗어나지 않도록 설정합니다.
        borderRadius: BorderRadius.circular(12 * scale),
        child: InkWell(
          // 탭 했을 때의 동작을 정의합니다.
          onTap: () {
            // 중앙에서 관리하는 공용 네비게이션 함수를 호출합니다.
            NavigationHelper.navigateToCommunityDetail(context, info.communityId);
          },
          child: Row(
            children: [
              // 왼쪽 이미지
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12 * scale),
                  bottomLeft: Radius.circular(12 * scale),
                ),
                child: Image.network(
                  info.communityBanner ?? 'https://placehold.co/159x217/EFEFEF/9E9E9E?text=No+Image',
                  width: 159 * scale,
                  height: 212 * scale,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF5F37CF)));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 159 * scale,
                      height: 212 * scale,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
              // 오른쪽 텍스트 정보
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18.0 * scale, 18.0 * scale, 18.0 * scale, 12.0 * scale
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 랭킹 배지
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F37CF),
                          borderRadius: BorderRadius.circular(400),
                        ),
                        child: Text(
                          '$rank위',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * scale,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(height: 14 * scale),
                      // 커뮤니티 제목
                      Text(
                        info.communityName,
                        style: TextStyle(
                          color: const Color(0xFF121212),
                          fontSize: 18 * scale,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8 * scale),
                      Flexible(
                        child: Text(
                          info.announcement ?? '공지사항이 없습니다.',
                          style: TextStyle(
                            color: const Color(0xFF8E8E8E),
                            fontSize: 14 * scale,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      // 멤버 수
                      Row(
                        children: [
                          Icon(Icons.person, color: const Color(0xFF5F37CF), size: 14 * scale),
                          SizedBox(width: 4 * scale),
                          Text(
                            '${info.memberCount}명',
                            style: TextStyle(
                              color: const Color(0xFF5F37CF),
                              fontSize: 12 * scale,
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
}

/// ## [컴포넌트] 하단 리스트에 들어갈 아이템 위젯
// class _CommunityListItem extends StatelessWidget {
//   final String title;
//   final String description;
//   final String memberCount;
//   final double scale;

//   const _CommunityListItem({
//     required this.title,
//     required this.description,
//     required this.memberCount,
//     required this.scale,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 85 * scale,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8 * scale),
//         border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
//       ),
//       child: Row(
//         children: [
//           // 왼쪽 텍스트 정보
//           Expanded(
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 15 * scale),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     title,
//                     style: TextStyle(
//                       color: const Color(0xFF121212),
//                       fontSize: 16 * scale,
//                       fontFamily: 'Pretendard',
//                       fontWeight: FontWeight.w600,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                   const Spacer(),
//                   Text(
//                     description,
//                     style: TextStyle(
//                       color: const Color(0xFF8E8E8E),
//                       fontSize: 14 * scale,
//                       fontFamily: 'Pretendard',
//                       fontWeight: FontWeight.w500,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // 오른쪽 아이콘 및 멤버 수
//           Container(
//             width: 90 * scale,
//             height: double.infinity,
//             decoration: BoxDecoration(
//               color: const Color(0xFF5F37CF),
//               borderRadius: BorderRadius.only(
//                 topRight: Radius.circular(7 * scale),
//                 bottomRight: Radius.circular(7 * scale),
//               ),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.add, color: Colors.white, size: 30 * scale),
//                 SizedBox(height: 8 * scale),
//                 Container(
//                    padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
//                    decoration: BoxDecoration(
//                        borderRadius: BorderRadius.circular(400),
//                        border: Border.all(color: Colors.white, width: 1)
//                    ),
//                    child: Row(
//                      mainAxisSize: MainAxisSize.min,
//                      children: [
//                        Icon(Icons.person, color: Colors.white, size: 14 * scale),
//                        SizedBox(width: 4 * scale),
//                        Text(
//                          '$memberCount명',
//                          style: TextStyle(
//                            color: Colors.white,
//                            fontSize: 12 * scale,
//                            fontFamily: 'Pretendard',
//                            fontWeight: FontWeight.w500,
//                          ),
//                        ),
//                      ],
//                    ),
//                 )
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }

/// ## [컴포넌트] 하단 리스트에 들어갈 아이템 위젯 (REFACTORED)
class _CommunityListItem extends StatelessWidget {
  // REFACTOR: Community 모델 객체를 직접 받도록 수정
  final Community community;
  final double scale;

  const _CommunityListItem({
    required this.community,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Row(
        children: [
          // 왼쪽 텍스트 정보
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 15 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    community.communityName, // REFACTOR: 모델 데이터 사용
                    style: TextStyle(
                      color: const Color(0xFF121212),
                      fontSize: 16 * scale,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const Spacer(),
                  Text(
                    community.announcement ?? '소개글이 없습니다.', // REFACTOR: 모델 데이터 사용
                    style: TextStyle(
                      color: const Color(0xFF8E8E8E),
                      fontSize: 14 * scale,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
          // 오른쪽 아이콘 및 멤버 수
          Container(
            width: 90 * scale,
            height: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF5F37CF),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(7 * scale),
                bottomRight: Radius.circular(7 * scale),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 30 * scale),
                SizedBox(height: 8 * scale),
                Container(
                   padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
                   decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(400),
                       border: Border.all(color: Colors.white, width: 1)
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(Icons.person, color: Colors.white, size: 14 * scale),
                       SizedBox(width: 4 * scale),
                       Text(
                         '${community.memberCount}명', // REFACTOR: 모델 데이터 사용
                         style: TextStyle(
                           color: Colors.white,
                           fontSize: 12 * scale,
                           fontFamily: 'Pretendard',
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}