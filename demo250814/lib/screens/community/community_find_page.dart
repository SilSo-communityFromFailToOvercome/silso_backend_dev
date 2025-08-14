import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/community_model.dart';
import 'community_detail_page.dart';
import 'community_search_page.dart';

class CommunityFindPage extends StatefulWidget {
  const CommunityFindPage({super.key});

  @override
  State<CommunityFindPage> createState() => _CommunityFindPageState();
}

class _CommunityFindPageState extends State<CommunityFindPage> {
  final CommunityService _communityService = CommunityService();
  final PageController _pageController = PageController();
  
  String _selectedSort = '인기순';
  int _currentPage = 0;
  
  late Future<List<Community>> _topCommunitiesFuture;
  List<Community> _sortedCommunities = [];
  List<Community> _joinedCommunities = [];
  bool _isLoadingCommunities = true;

  @override
  void initState() {
    super.initState();
    _topCommunitiesFuture = _communityService.getTop5Communities();
    _loadAllCommunities();
  }

  Future<void> _loadAllCommunities() async {
    try {
      final allCommunities = await _communityService.getAllCommunities();
      final joinedCommunities = await _communityService.getMyCommunities();
      
      //Purpose refactor :  To show all communites 
      // // Get IDs of joined communities for filtering
      // final joinedIds = joinedCommunities.map((c) => c.communityId).toSet();
      
      // // Filter out communities that user has already joined
      // final availableCommunities = allCommunities
      //     .where((community) => !joinedIds.contains(community.communityId))
      //     .toList();
      
      setState(() {
        // _sortedCommunities = List.from(availableCommunities);
        _sortedCommunities = List.from(allCommunities); 
        _joinedCommunities = joinedCommunities;
        _isLoadingCommunities = false;
      });
      _applySorting();
    } catch (e) {
      setState(() {
        _isLoadingCommunities = false;
      });
    }
  }

  void _applySorting() {
    setState(() {
      switch (_selectedSort) {
        case '인기순':
          _sortedCommunities.sort((a, b) {
            return b.memberCount.compareTo(a.memberCount); // 내림차순 (많은 멤버가 위로)
          });
          break;
        case '최신순':
          _sortedCommunities.sort((a, b) {
            return b.createdAt.compareTo(a.createdAt); // 내림차순 (최신이 위로)
          });
          break;
        case '오래된순':
          _sortedCommunities.sort((a, b) {
            return a.createdAt.compareTo(b.createdAt); // 오름차순 (오래된 것이 위로)
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Swipable Community Cards
          _buildTopCommunitiesSection(),
          
          // Sorting Buttons
          _buildSortingButtons(),
          
          // Community List
          Expanded(
            child: _buildCommunityList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFA),
      foregroundColor: const Color(0xFF5F37CF),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5F37CF)),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset("assets/images/community/logo.png", width: 69, height: 25),
          const SizedBox(width: 16),
          const Text(
            '커뮤니티',
            style: TextStyle(
              color: Color(0xFF5F37CF),
              fontSize: 22,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 28, color: Color(0xFF5F37CF)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExploreSearchPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopCommunitiesSection() {
    return FutureBuilder<List<Community>>(
      future: _topCommunitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('커뮤니티를 불러올 수 없습니다')),
          );
        }

        // // Filter out communities that user has already joined
        // final joinedIds = _joinedCommunities.map((c) => c.communityId).toSet();
        // final availableTopCommunities = snapshot.data!
        //     .where((community) => !joinedIds.contains(community.communityId))
        //     .take(5)
        //     .toList();
        
        // // Check if there are any available communities to show
        // if (availableTopCommunities.isEmpty) {
        //   return const SizedBox(
        //     height: 200,
        //     child: Center(child: Text('모든 인기 커뮤니티에 이미 가입되어 있습니다!')),
        //   );
        // }

        // --- 수정된 부분(modify) ---
        // 가입 여부 필터링 로직을 제거하고, snapshot에서 받아온 데이터를 그대로 사용합니다.
        final topCommunities = snapshot.data!.take(5).toList();
        
        // 데이터가 없는 경우를 위한 방어 코드만 남겨둡니다.
        if (topCommunities.isEmpty) {
          return const SizedBox.shrink(); // 아무것도 표시하지 않음
        }

        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: topCommunities.length,
                itemBuilder: (context, index) {
                  return _buildTopCommunityCard(topCommunities[index], index + 1);
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildPageIndicators(topCommunities.length),
          ],
        );
      },
    );
  }

  Widget _buildTopCommunityCard(Community community, int rank) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KoreanCommunityDetailPage(community: community),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Community Image
            Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: Colors.grey[200],
              ),
              child: community.communityBanner != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Image.network(
                        community.communityBanner!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.group, size: 40, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.group, size: 40, color: Colors.grey),
            ),
            
            // Community Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ranking Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$rank위',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Community Title
                    Text(
                      community.communityName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Community Description
                    Text(
                      community.announcement ?? '커뮤니티 소개가 없습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    // Member Count
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${community.memberCount}명',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
    );
  }

  Widget _buildPageIndicators(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index 
                ? const Color(0xFF8B5CF6) 
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildSortingButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSortButton('인기순'),
          const SizedBox(width: 8),
          _buildSortButton('최신순'),
          const SizedBox(width: 8),
          _buildSortButton('오래된순'),
        ],
      ),
    );
  }

  Widget _buildSortButton(String title) {
    final isSelected = _selectedSort == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSort = title;
        });
        _applySorting();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityList() {
    if (_isLoadingCommunities) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_sortedCommunities.isEmpty) {
      return const Center(child: Text('커뮤니티가 없습니다'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _sortedCommunities.length,
      itemBuilder: (context, index) {
        return _buildCommunityListItem(_sortedCommunities[index]);
      },
    );
  }

  Widget _buildCommunityListItem(Community community) {
    // --- 이 부분이 수정되었습니다 ---
    // 현재 아이템이 내가 가입한 커뮤니티 목록에 있는지 확인합니다.
    // Set으로 변환하여 검색 성능을 높입니다.
    final joinedIds = _joinedCommunities.map((c) => c.communityId).toSet();
    final bool isJoined = joinedIds.contains(community.communityId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isJoined ? const Color(0xFFDFD4FF) : const Color(0xFF8B5CF6), width: 1.5),
      ),
      child: Row(
        children: [
          // Left Section - Community Info (Tappable to navigate to detail page)
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => KoreanCommunityDetailPage(community: community),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      community.communityName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontFamily: 'Nanum Gothic',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.announcement ?? '커뮤니티 소개가 없습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Nanum Gothic',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Right Section - Action Button (fills entire right side)
          GestureDetector(
            onTap: isJoined ? null : () => _joinCommunityAndShowDialog(community),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color:  isJoined ? const Color(0xFFDFD4FF) : const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.only(
                topRight: Radius.circular(10.5),
                bottomRight: Radius.circular(10.5),
                ),
              ),
              
              child:  isJoined
              // CASE1 : "가입됨" 상태의 UI
                ?  Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Plus Icon
                  const Icon(
                    Icons.check,
                    color:  Color(0xFF8B5CF6),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  // Member Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:  Color(0xFF8B5CF6).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color:  Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${community.memberCount}명',
                          style: const TextStyle(
                            fontSize: 11,
                            color:  Color(0xFF8B5CF6),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Nanum Gothic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ) : 
              //CASE2 :  "가입하기" 상태의 UI
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Plus Icon
                  const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  // Member Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${community.memberCount}명',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Nanum Gothic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinCommunityAndShowDialog(Community community) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Join the community
      await _communityService.joinCommunity(community.communityId);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (mounted) {
        // Refresh the community lists
        _loadAllCommunities();
        setState(() {
          _topCommunitiesFuture = _communityService.getTop5Communities();
        });
        
        // Show success dialog
        _showJoinCommunityDialog(community);
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('가입 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showJoinCommunityDialog(Community community) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Character Image
                Image.asset(
                  'assets/images/splash/character.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 20),
                
                // Main Message
                const Text(
                  '새로운 커뮤니티가 추가되었어요!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Sub Message
                const Text(
                  '커뮤니티에서 자유롭게 실패를 나누어 보세요.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E8E),
                    fontFamily: 'Pretendard',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    // My Community Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          // Navigate back to home page and switch to MY section
                          Navigator.of(context).pop(); // Go back to previous screen (likely home)
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MY 커뮤니티 가기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B5CF6),
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Continue Exploring Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          // Just stay on the current page - no additional action needed
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '계속 구경하기',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'Pretendard',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}