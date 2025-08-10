import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../models/post_model.dart';
import '../../services/community_service.dart';
import '../../services/auth_service.dart';
import 'post_detail_screen.dart';
import 'add_post_screen.dart';

class KoreanCommunityDetailPage extends StatefulWidget {
  final Community community;

  const KoreanCommunityDetailPage({
    super.key,
    required this.community,
  });

  @override
  State<KoreanCommunityDetailPage> createState() => _KoreanCommunityDetailPageState();
}

class _KoreanCommunityDetailPageState extends State<KoreanCommunityDetailPage> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();
  
  late Community _community;
  bool _isSubscribed = false;
  bool _isLoading = false;
  
  String _selectedTab = '전체'; // 전체, 자유글, 실패글
  List<Post> _allPosts = [];
  List<Post> _popularPosts = [];
  List<Post> _filteredPosts = [];
  bool _isLoadingPosts = false;

  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _checkSubscriptionStatus();
    _loadPosts();
  }

  void _checkSubscriptionStatus() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      setState(() {
        _isSubscribed = _community.members.contains(currentUserId);
      });
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final posts = await _communityService.getCommunityPosts(_community.communityId);
      setState(() {
        _allPosts = posts;
        _popularPosts = posts.take(5).toList(); // Top 5 as popular
        _filterPosts();
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  void _filterPosts() {
    setState(() {
      switch (_selectedTab) {
        case '전체':
          _filteredPosts = _allPosts;
          _popularPosts = _allPosts.take(5).toList();
          break;
        case '자유글':
          // Filter for freedom posts
          _filteredPosts = _allPosts.where((post) => post.postType == PostType.freedom).toList();
          _popularPosts = _filteredPosts.take(5).toList();
          break;
        case '실패글':
          // Filter for failure posts
          _filteredPosts = _allPosts.where((post) => post.postType == PostType.failure).toList();
          _popularPosts = _filteredPosts.take(5).toList();
          break;
      }
    });
  }

  Future<void> _toggleSubscription() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSubscribed) {
        await _communityService.leaveCommunity(_community.communityId);
        setState(() {
          _isSubscribed = false;
          _community = _community.copyWith(
            memberCount: _community.memberCount - 1,
            members: _community.members.where((id) => id != currentUserId).toList(),
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커뮤니티를 나갔습니다'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _communityService.joinCommunity(_community.communityId);
        setState(() {
          _isSubscribed = true;
          _community = _community.copyWith(
            memberCount: _community.memberCount + 1,
            members: [..._community.members, currentUserId],
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('커뮤니티에 가입했습니다!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_isSubscribed ? '나가기' : '가입'} 실패: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToPostDetail(Post post) async {
    try {
      // Increment view count when navigating to post detail
      await _communityService.incrementPostViewCount(post.postId);
      
      // Navigate to PostDetailScreen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: post,
              community: _community,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시물을 여는 데 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTabSelected(String tab) {
    setState(() {
      _selectedTab = tab;
    });
    _filterPosts();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final widthRatio = screenSize.width / 393;
    final heightRatio = screenSize.height / 852;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with banner
          SliverAppBar(
            expandedHeight: 200 * heightRatio,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFFAFAFA),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildBannerSection(widthRatio, heightRatio),
            ),
          ),
          
          // Community Info Section
          SliverToBoxAdapter(
            child: _buildCommunityInfoSection(widthRatio, heightRatio),
          ),
          
          // Tab Section
          SliverToBoxAdapter(
            child: _buildTabSection(widthRatio, heightRatio),
          ),
          
          // Popular Posts Section
          SliverToBoxAdapter(
            child: _buildPopularPostsSection(widthRatio, heightRatio),
          ),
          
          // Posts List
          SliverToBoxAdapter(
            child: _buildPostsList(widthRatio, heightRatio),
          ),
        ],
      ),
      floatingActionButton: _isSubscribed ? _buildFloatingActionButton(widthRatio, heightRatio) : null,
    );
  }

  Widget _buildBannerSection(double widthRatio, double heightRatio) {
    return Container(
      width: double.infinity,
      height: 200 * heightRatio,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        image: _community.communityBanner != null
            ? DecorationImage(
                image: NetworkImage(_community.communityBanner!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: _community.communityBanner == null
          ? const Center(
              child: Icon(
                Icons.image,
                size: 60,
                color: Colors.grey,
              ),
            )
          : null,
    );
  }

  Widget _buildCommunityInfoSection(double widthRatio, double heightRatio) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 20 * heightRatio),
      child: Column(
        children: [
          // Community Title
          Text(
            _community.communityName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF121212),
              fontSize: 24 * widthRatio,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
          
          SizedBox(height: 12 * heightRatio),
          
          // Community Description
          if (_community.announcement != null && _community.announcement!.isNotEmpty)
            Text(
              _community.announcement!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF8E8E8E),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          
          SizedBox(height: 20 * heightRatio),
          
          // Participate Button
          GestureDetector(
            onTap: _isLoading ? null : _toggleSubscription,
            child: Container(
              width: 160 * widthRatio,
              height: 44 * heightRatio,
              decoration: BoxDecoration(
                color: _isSubscribed ? const Color(0xFFE9E9E9) : const Color(0xFF5F37CF),
                borderRadius: BorderRadius.circular(22 * heightRatio),
              ),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 20 * widthRatio,
                        height: 20 * widthRatio,
                        child: CircularProgressIndicator(
                          color: _isSubscribed ? Colors.black : Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isSubscribed ? '참여중' : '참여하기',
                        style: TextStyle(
                          color: _isSubscribed ? const Color(0xFF8E8E8E) : Colors.white,
                          fontSize: 16 * widthRatio,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          
          SizedBox(height: 12 * heightRatio),
          
          // Member Count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: 16 * widthRatio,
                color: const Color(0xFF8E8E8E),
              ),
              SizedBox(width: 4 * widthRatio),
              Text(
                '${_community.memberCount}명',
                style: TextStyle(
                  color: const Color(0xFF8E8E8E),
                  fontSize: 14 * widthRatio,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24 * heightRatio),
          
          // Announcement Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16 * widthRatio),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12 * widthRatio),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '공지사항',
                  style: TextStyle(
                    color: const Color(0xFF121212),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8 * heightRatio),
                Text(
                  _community.announcement ?? '공지사항이 없습니다.',
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 14 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 16 * heightRatio),
      child: Row(
        children: [
          _buildTabButton('전체', widthRatio, heightRatio),
          SizedBox(width: 12 * widthRatio),
          _buildTabButton('자유글', widthRatio, heightRatio),
          SizedBox(width: 12 * widthRatio),
          _buildTabButton('실패글', widthRatio, heightRatio),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, double widthRatio, double heightRatio) {
    final bool isSelected = _selectedTab == title;
    return GestureDetector(
      onTap: () => _onTabSelected(title),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 8 * heightRatio),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F37CF) : Colors.white,
          borderRadius: BorderRadius.circular(20 * widthRatio),
          border: Border.all(
            color: isSelected ? const Color(0xFF5F37CF) : const Color(0xFFE9E9E9),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF8E8E8E),
            fontSize: 14 * widthRatio,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPopularPostsSection(double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(top: 16 * heightRatio),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
            child: Text(
              '인기 글',
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 18 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12 * heightRatio),
          _popularPosts.isEmpty
              ? Container(
                  height: 120 * heightRatio,
                  padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
                  child: Center(
                    child: Text(
                      '인기 게시물이 없습니다',
                      style: TextStyle(
                        color: const Color(0xFF8E8E8E),
                        fontSize: 16 * widthRatio,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 150 * heightRatio,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
                    scrollDirection: Axis.horizontal,
                    itemCount: _popularPosts.length,
                    separatorBuilder: (context, index) => SizedBox(width: 12 * widthRatio),
                    itemBuilder: (context, index) {
                      final post = _popularPosts[index];
                      return _buildPopularPostCard(post, widthRatio, heightRatio);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildPopularPostCard(Post post, double widthRatio, double heightRatio) {
    return GestureDetector(
      onTap: () {
        _navigateToPostDetail(post);
      },
      child: Container(
        width: 200 * widthRatio,
        padding: EdgeInsets.all(12 * widthRatio),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8 * widthRatio),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6 * heightRatio),
            Text(
              post.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF8E8E8E),
                fontSize: 12 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.remove_red_eye,
                  size: 12 * widthRatio,
                  color: const Color(0xFFCCCCCC),
                ),
                SizedBox(width: 4 * widthRatio),
                Text(
                  '${post.viewCount}',
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 10 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(double widthRatio, double heightRatio) {
    return Container(
      margin: EdgeInsets.only(top: 24 * heightRatio),
      padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio),
      child: Column(
        children: [
          if (_isLoadingPosts)
            const Center(child: CircularProgressIndicator())
          else if (_filteredPosts.isEmpty)
            SizedBox(
              height: 200 * heightRatio,
              child: Center(
                child: Text(
                  '게시물이 없습니다',
                  style: TextStyle(
                    color: const Color(0xFF8E8E8E),
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredPosts.length,
              separatorBuilder: (context, index) => SizedBox(height: 12 * heightRatio),
              itemBuilder: (context, index) {
                final post = _filteredPosts[index];
                return _buildPostCard(post, widthRatio, heightRatio);
              },
            ),
          
          SizedBox(height: 40 * heightRatio),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post, double widthRatio, double heightRatio) {
    return GestureDetector(
      onTap: () {
        _navigateToPostDetail(post);
      },
      child: Container(
        padding: EdgeInsets.all(16 * widthRatio),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * widthRatio),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF121212),
                fontSize: 16 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8 * heightRatio),
            Text(
              post.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF8E8E8E),
                fontSize: 14 * widthRatio,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12 * heightRatio),
            Row(
              children: [
                Icon(
                  Icons.remove_red_eye,
                  size: 14 * widthRatio,
                  color: const Color(0xFFCCCCCC),
                ),
                SizedBox(width: 4 * widthRatio),
                Text(
                  '${post.viewCount}',
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 12 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(width: 16 * widthRatio),
                Icon(
                  Icons.chat_bubble_outline,
                  size: 14 * widthRatio,
                  color: const Color(0xFFCCCCCC),
                ),
                SizedBox(width: 4 * widthRatio),
                Text(
                  '${post.commentCount}',
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 12 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(post.datePosted),
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: 12 * widthRatio,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Widget _buildFloatingActionButton(double widthRatio, double heightRatio) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AddPostScreen(community: _community),
          ),
        );
      },
      backgroundColor: Colors.transparent,
      elevation: 0,
      highlightElevation: 0,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF5F37CF),
            width: 2,
          ),
          color: Colors.transparent,
        ),
        child: const Icon(
          Icons.edit,
          color: Color(0xFF5F37CF),
          size: 24,
        ),
      ),
    );
  }
}