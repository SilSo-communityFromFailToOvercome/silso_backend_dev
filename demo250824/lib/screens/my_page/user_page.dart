import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/community_service.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import '../community/post_detail_screen.dart';
import '../community/community_detail_page.dart';
import '../../widgets/pet_profile_picture.dart';
import '../../widgets/blocking_utils.dart';

class UserPage extends StatefulWidget {
  final String userId;
  final String? username; // Optional display name

  const UserPage({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  List<Post> _userPosts = [];
  List<PostComment> _userComments = [];
  List<Community> _userCommunities = [];
  Map<String, String> _postTitles = {}; // Cache for post titles
  bool _isLoadingPosts = true;
  bool _isLoadingComments = true;
  bool _isLoadingCommunities = true;
  bool _isLoadingUserInfo = true;
  late TabController _tabController;
  
  // Filter state variables
  String _selectedPostType = 'All'; // All, Freedom, Failure
  String _selectedSortOrder = 'Recent'; // Recent, Most Popular, Oldest
  
  // User info
  String _selectedPetId = 'pet5'; // Default pet
  String _displayName = '';
  int _currentStreak = 0;
  bool _isLoadingStreak = true;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _checkIfUserBlocked();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserBlocked() async {
    try {
      final shouldShow = await BlockingUtils.shouldShowUser(widget.userId);
      setState(() {
        _isBlocked = !shouldShow;
      });
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
    }
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadUserPosts(),
      _loadUserComments(),
      _loadUserCommunities(),
    ]);
  }

  Future<void> _loadUserInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _selectedPetId = data['selectedPet'] ?? 'pet5';
          _displayName = widget.username ?? 
              data['displayName'] ?? 
              '사용자${widget.userId.substring(0, 4)}';
          _currentStreak = data['currentStreak'] ?? 0;
          _isLoadingUserInfo = false;
          _isLoadingStreak = false;
        });
      } else {
        setState(() {
          _displayName = widget.username ?? '사용자${widget.userId.substring(0, 4)}';
          _isLoadingUserInfo = false;
          _isLoadingStreak = false;
        });
      }
    } catch (e) {
      setState(() {
        _displayName = widget.username ?? '사용자${widget.userId.substring(0, 4)}';
        _isLoadingUserInfo = false;
        _isLoadingStreak = false;
      });
      debugPrint('Error loading user info: $e');
    }
  }

  Future<void> _loadUserPosts() async {
    try {
      final allPosts = await _communityService.getUserPosts(widget.userId);
      // Filter out anonymous posts - only show non-anonymous posts to other users
      final nonAnonymousPosts = allPosts.where((post) => !post.anonymous).toList();
      setState(() {
        _userPosts = nonAnonymousPosts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      debugPrint('Error loading user posts: $e');
    }
  }

  Future<void> _loadUserComments() async {
    try {
      final comments = await _getUserComments(widget.userId);
      
      // Fetch post titles for each comment
      final postIds = comments.map((comment) => comment.postId).toSet();
      final postTitles = <String, String>{};
      
      for (final postId in postIds) {
        final title = await _getPostTitle(postId);
        postTitles[postId] = title;
      }
      
      setState(() {
        _userComments = comments;
        _postTitles = postTitles;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      debugPrint('Error loading user comments: $e');
    }
  }

  Future<void> _loadUserCommunities() async {
    try {
      // Get communities where user is a member
      final snapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('userId', isEqualTo: widget.userId)
          .get();

      final communityIds = snapshot.docs
          .map((doc) => doc.data()['communityId'] as String)
          .toList();

      if (communityIds.isEmpty) {
        setState(() {
          _userCommunities = [];
          _isLoadingCommunities = false;
        });
        return;
      }

      // Fetch community details
      final communities = <Community>[];
      for (final communityId in communityIds) {
        try {
          final community = await _communityService.getCommunity(communityId);
          communities.add(community);
        } catch (e) {
          debugPrint('Error loading community $communityId: $e');
        }
      }

      setState(() {
        _userCommunities = communities;
        _isLoadingCommunities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCommunities = false;
      });
      debugPrint('Error loading user communities: $e');
    }
  }

  Future<List<PostComment>> _getUserComments(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('post_comments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final allComments = snapshot.docs.map((doc) {
        return PostComment.fromMap(doc.data(), doc.id);
      }).toList();

      // Filter out anonymous comments - only show non-anonymous comments to other users
      return allComments.where((comment) => !comment.anonymous).toList();
    } catch (e) {
      debugPrint('Error fetching user comments: $e');
      return [];
    }
  }

  Future<String> _getPostTitle(String postId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      
      if (doc.exists) {
        return doc.data()?['title'] ?? 'Unknown Post';
      }
      return 'Unknown Post';
    } catch (e) {
      return 'Unknown Post';
    }
  }

  Future<void> _navigateToPost(Post post) async {
    try {
      final community = await _communityService.getCommunity(post.communityId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: post,
              community: community,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글을 불러올 수 없습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToPostFromComment(String postId) async {
    try {
      final post = await _communityService.getPost(postId);
      final community = await _communityService.getCommunity(post.communityId);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              post: post,
              community: community,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게시글을 불러올 수 없습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToCommunity(Community community) async {
    try {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KoreanCommunityDetailPage(
              community: community,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('커뮤니티를 불러올 수 없습니다: ${e.toString()}'),
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

    // Show blocked user message if user is blocked
    if (_isBlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: const Color(0xFF121212),
              size: 20 * widthRatio,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            '사용자 프로필',
            style: TextStyle(
              fontSize: 16 * widthRatio,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64 * widthRatio,
                color: const Color(0xFFCCCCCC),
              ),
              SizedBox(height: 16 * heightRatio),
              Text(
                '차단된 사용자입니다',
                style: TextStyle(
                  fontSize: 18 * widthRatio,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8E8E8E),
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 8 * heightRatio),
              Text(
                '이 사용자의 프로필을 볼 수 없습니다',
                style: TextStyle(
                  fontSize: 14 * widthRatio,
                  color: const Color(0xFFCCCCCC),
                  fontFamily: 'Pretendard',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF121212),
            size: 20 * widthRatio,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/silso_logo/black_silso_logo.png',
              height: 24 * heightRatio,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 8 * widthRatio),
            Text(
              '사용자 프로필',
              style: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        actions: [
          // Report and Block Menu
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: const Color(0xFF121212),
              size: 24 * widthRatio,
            ),
            onSelected: (value) async {
              await BlockingUtils.handleMenuSelection(
                context: context,
                selectedValue: value,
                userId: widget.userId,
                username: _displayName,
                onBlocked: () {
                  // Refresh the page or navigate back
                  Navigator.of(context).pop();
                },
              );
            },
            itemBuilder: (context) => [
              BlockingUtils.createBlockMenuItem(),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Profile Header Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20 * widthRatio),
            child: Column(
              children: [
                SizedBox(height: 20 * heightRatio),
                
                // Virtual Pet Section
                _buildVirtualPetSection(widthRatio, heightRatio),
                
                SizedBox(height: 30 * heightRatio),
                
                SizedBox(height: 30 * heightRatio),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF5F37CF),
              unselectedLabelColor: const Color(0xFF8E8E8E),
              indicatorColor: const Color(0xFF5F37CF),
              indicatorWeight: 2,
              labelStyle: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 16 * widthRatio,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
              tabs: const [
                Tab(text: '게시글'),
                Tab(text: '댓글'),
                Tab(text: '커뮤니티'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(widthRatio, heightRatio),
                _buildCommentsTab(widthRatio, heightRatio),
                _buildCommunitiesTab(widthRatio, heightRatio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(double widthRatio, double heightRatio) {
    if (_isLoadingPosts) {
      return _buildLoadingIndicator(heightRatio);
    }
    
    if (_userPosts.isEmpty) {
      return _buildEmptyState('작성한 글이 없습니다', heightRatio);
    }
    
    // Apply filters to posts
    List<Post> filteredPosts = _getFilteredAndSortedPosts();
    
    return Column(
      children: [
        // Filter buttons row
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20 * widthRatio,
            vertical: 16 * heightRatio,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left filter - Post Type
              GestureDetector(
                onTap: () => _showPostTypeDropdown(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getPostTypeDisplayText(),
                      style: TextStyle(
                        color: const Color(0xFF121212),
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * widthRatio,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(width: 4 * widthRatio),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF121212),
                      size: 16 * widthRatio,
                    ),
                  ],
                ),
              ),
              // Right filter - Sort Order
              GestureDetector(
                onTap: () => _showSortOrderDropdown(),
                child: Icon(
                  Icons.tune,
                  color: const Color(0xFF121212),
                  size: 20 * widthRatio,
                ),
              ),
            ],
          ),
        ),
        // Posts list
        Expanded(
          child: filteredPosts.isEmpty
              ? _buildEmptyState('필터 조건에 맞는 글이 없습니다', heightRatio)
              : ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16 * widthRatio,
                    vertical: 0,
                  ),
                  itemCount: filteredPosts.length,
                  separatorBuilder: (context, index) => Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                    margin: EdgeInsets.symmetric(vertical: 16 * heightRatio),
                  ),
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return _buildSocialMediaStylePostItem(
                      post,
                      widthRatio,
                      heightRatio,
                      onTap: () => _navigateToPost(post),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommentsTab(double widthRatio, double heightRatio) {
    return _isLoadingComments
        ? _buildLoadingIndicator(heightRatio)
        : _userComments.isEmpty
            ? _buildEmptyState('작성한 댓글이 없습니다', heightRatio)
            : ListView.separated(
                padding: EdgeInsets.all(20 * widthRatio),
                itemCount: _userComments.length,
                separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
                itemBuilder: (context, index) {
                  final comment = _userComments[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12 * widthRatio),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildCommentItem(
                      comment.content,
                      '"${_postTitles[comment.postId] ?? 'Unknown Post'}"에서',
                      _formatDate(comment.createdAt),
                      widthRatio,
                      heightRatio,
                      onTap: () => _navigateToPostFromComment(comment.postId),
                    ),
                  );
                },
              );
  }

  Widget _buildCommunitiesTab(double widthRatio, double heightRatio) {
    return _isLoadingCommunities
        ? _buildLoadingIndicator(heightRatio)
        : _userCommunities.isEmpty
            ? _buildEmptyState('가입한 커뮤니티가 없습니다', heightRatio)
            : ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16 * widthRatio, vertical: 20 * heightRatio),
                itemCount: _userCommunities.length,
                separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
                itemBuilder: (context, index) {
                  final community = _userCommunities[index];
                  return _buildMyCommunityCard(widthRatio, heightRatio, community);
                },
              );
  }

  Widget _buildCommentItem(
    String comment,
    String postTitle,
    String date,
    double widthRatio,
    double heightRatio, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16 * widthRatio),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 14 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * heightRatio),
                  Text(
                    postTitle,
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 4 * heightRatio),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16 * widthRatio,
              color: const Color(0xFF8E8E8E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(double heightRatio) {
    return Padding(
      padding: EdgeInsets.all(40 * heightRatio),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, double heightRatio) {
    return Padding(
      padding: EdgeInsets.all(40 * heightRatio),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  List<Post> _getFilteredAndSortedPosts() {
    List<Post> filteredPosts = List.from(_userPosts);
    
    // Filter by post type using the postType field from Firebase
    if (_selectedPostType != 'All') {
      filteredPosts = filteredPosts.where((post) {
        if (_selectedPostType == 'Freedom') {
          return post.postType == PostType.freedom;
        } else if (_selectedPostType == 'Failure') {
          return post.postType == PostType.failure;
        }
        return true;
      }).toList();
    }
    
    // Sort posts
    switch (_selectedSortOrder) {
      case 'Recent':
        filteredPosts.sort((a, b) => b.datePosted.compareTo(a.datePosted));
        break;
      case 'Oldest':
        filteredPosts.sort((a, b) => a.datePosted.compareTo(b.datePosted));
        break;
      case 'Most Popular':
        filteredPosts.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
    }
    
    return filteredPosts;
  }

  // Social media style post item matching reference image
  Widget _buildSocialMediaStylePostItem(
    Post post,
    double widthRatio,
    double heightRatio, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 16 * heightRatio,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                // Profile picture
                PetProfilePicture(
                  size: 40 * widthRatio,
                  userId: widget.userId,
                ),
                
                SizedBox(width: 12 * widthRatio),
                
                // Username and date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.anonymous ? '익명' : _displayName,
                        style: TextStyle(
                          fontSize: 14 * widthRatio,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      Text(
                        _formatTimeAgo(post.datePosted),
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8E8E8E),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 12 * heightRatio),
            
            // Post content
            Text(
              post.caption,
              style: TextStyle(
                fontSize: 14 * widthRatio,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF121212),
                fontFamily: 'Pretendard',
                height: 1.5,
              ),
            ),
            
            SizedBox(height: 16 * heightRatio),
            
            // Comment count
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.comment_outlined,
                  color: const Color(0xFF8E8E8E),
                  size: 16 * widthRatio,
                ),
                SizedBox(width: 4 * widthRatio),
                FutureBuilder<int>(
                  future: _getPostCommentCount(post.postId),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0}',
                      style: TextStyle(
                        fontSize: 14 * widthRatio,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get comment count for a specific post
  Future<int> _getPostCommentCount(String postId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting comment count: $e');
      return 0;
    }
  }

  // Format time as "1일전" style
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분전';
    } else {
      return '방금전';
    }
  }

  // Get display text for post type filter
  String _getPostTypeDisplayText() {
    switch (_selectedPostType) {
      case 'All':
        return '전체';
      case 'Freedom':
        return '자유';
      case 'Failure':
        return '실패';
      default:
        return '전체';
    }
  }

  // Show dropdown for post type selection
  void _showPostTypeDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                '게시글 타입',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 20),
              
              // Options
              _buildDropdownOption('전체', 'All'),
              _buildDropdownOption('자유', 'Freedom'),
              _buildDropdownOption('실패', 'Failure'),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build dropdown option
  Widget _buildDropdownOption(String displayText, String value) {
    final isSelected = _selectedPostType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPostType = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF121212) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  // Show dropdown for sort order selection
  void _showSortOrderDropdown() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                '정렬 순서',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 20),
              
              // Options
              _buildSortDropdownOption('최신순', 'Recent'),
              _buildSortDropdownOption('인기순', 'Most Popular'),
              _buildSortDropdownOption('오래된순', 'Oldest'),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Build sort dropdown option
  Widget _buildSortDropdownOption(String displayText, String value) {
    final isSelected = _selectedSortOrder == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSortOrder = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF121212) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF121212) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  // Builds a card for a joined community, using the same style as community main page
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
          onTap: () => _navigateToCommunity(community),
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

  Widget _buildStreakIndicator(double widthRatio, double heightRatio) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20 * widthRatio,
        vertical: 8 * heightRatio,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF5F37CF),
        borderRadius: BorderRadius.circular(20 * widthRatio),
      ),
      child: _isLoadingStreak
          ? SizedBox(
              width: 100 * widthRatio,
              height: 20 * heightRatio,
              child: Center(
                child: SizedBox(
                  width: 12 * widthRatio,
                  height: 12 * widthRatio,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fire emoji icon
                Text(
                  '🔥',
                  style: TextStyle(fontSize: 16 * widthRatio),
                ),
                SizedBox(width: 6 * widthRatio),
                Text(
                  '$_currentStreak일째 방문중',
                  style: TextStyle(
                    fontSize: 14 * widthRatio,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVirtualPetSection(double widthRatio, double heightRatio) {
    return Column(
      children: [
        // Virtual Pet Illustration
        SizedBox(
          width: 120 * widthRatio,  // Made smaller for profile page
          height: 140 * heightRatio,
          child: Center(
            child: Image.asset(
              'assets/images/pets/$_selectedPetId.png',
              width: 100 * widthRatio,
              height: 120 * heightRatio,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 100 * widthRatio,
                  height: 120 * heightRatio,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50 * widthRatio),
                  ),
                  child: Center(
                    child: Text(
                      '🐾',
                      style: TextStyle(fontSize: 32 * widthRatio),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        
        SizedBox(height: 12 * heightRatio),
        
        // User Display Name
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16 * widthRatio,
            vertical: 6 * heightRatio,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16 * widthRatio),
          ),
          child: Text(
            _displayName,
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        
        SizedBox(height: 16 * heightRatio),
        
        // Streak Indicator
        _buildStreakIndicator(widthRatio, heightRatio),
      ],
    );
  }
}