import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/community_service.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import '../community/post_detail_screen.dart';
import '../community/community_detail_page.dart';
import '../../widgets/cached_network_image_widget.dart';
import 'edit_profile.dart';
import 'settings.dart';

class MyPageMain extends StatefulWidget {
  const MyPageMain({super.key});

  @override
  State<MyPageMain> createState() => _MyPageMainState();
}

class _MyPageMainState extends State<MyPageMain> with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService();
  List<Post> _userPosts = [];
  List<PostComment> _userComments = [];
  List<Community> _userCommunities = [];
  Map<String, String> _postTitles = {}; // Cache for post titles
  bool _isLoadingPosts = true;
  bool _isLoadingComments = true;
  bool _isLoadingCommunities = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadUserPosts(),
      _loadUserComments(),
      _loadUserCommunities(),
    ]);
  }

  Future<void> _loadUserPosts() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final posts = await _communityService.getUserPosts(currentUserId);
        setState(() {
          _userPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingPosts = false;
      });
      debugPrint('Error loading user posts: $e');
    }
  }

  Future<void> _loadUserComments() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final comments = await _getUserComments(currentUserId);
        
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
      }
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
      debugPrint('Error loading user comments: $e');
    }
  }

  Future<void> _loadUserCommunities() async {
    try {
      final communities = await _communityService.getMyCommunities();
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

      return snapshot.docs.map((doc) {
        return PostComment.fromMap(doc.data(), doc.id);
      }).toList();
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

  String _getUserDisplayName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        return user.email!;
      } else {
        return user.uid.substring(0, 8);
      }
    }
    return "Guest";
  }

  String? _getUserProfilePicture() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.photoURL;
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
          '프로필',
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: const Color(0xFF121212),
              size: 24 * widthRatio,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
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
                
                // Profile Section (Left-aligned)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture
                    _buildProfilePictureSection(widthRatio, heightRatio),
                    
                    SizedBox(width: 16 * widthRatio),
                    
                    // Username and Edit Button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUsernameSection(widthRatio, heightRatio),
                          SizedBox(height: 8 * heightRatio),
                          _buildEditButton(widthRatio, heightRatio),
                        ],
                      ),
                    ),
                  ],
                ),
                
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
                Tab(text: 'Posts'),
                Tab(text: 'Comments'),
                Tab(text: 'Communities'),
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
    return _isLoadingPosts
        ? _buildLoadingIndicator(heightRatio)
        : _userPosts.isEmpty
            ? _buildEmptyState('작성한 글이 없습니다', heightRatio)
            : ListView.separated(
                padding: EdgeInsets.all(20 * widthRatio),
                itemCount: _userPosts.length,
                separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
                itemBuilder: (context, index) {
                  final post = _userPosts[index];
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
                    child: _buildPostItem(
                      post.title,
                      _formatDate(post.datePosted),
                      '조회 ${post.viewCount}',
                      widthRatio,
                      heightRatio,
                      onTap: () => _navigateToPost(post),
                    ),
                  );
                },
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
                padding: EdgeInsets.all(20 * widthRatio),
                itemCount: _userCommunities.length,
                separatorBuilder: (context, index) => SizedBox(height: 16 * heightRatio),
                itemBuilder: (context, index) {
                  final community = _userCommunities[index];
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
                    child: _buildCommunityItem(
                      community.communityName,
                      '멤버 ${community.memberCount}명',
                      _formatDate(community.dateAdded),
                      widthRatio,
                      heightRatio,
                      onTap: () => _navigateToCommunity(community),
                    ),
                  );
                },
              );
  }

  Widget _buildProfilePictureSection(double widthRatio, double heightRatio) {
    final profilePictureUrl = _getUserProfilePicture();
    
    return Container(
      width: 80 * widthRatio,
      height: 80 * widthRatio,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF5F37CF),
          width: 2 * widthRatio,
        ),
      ),
      child: ClipOval(
        child: profilePictureUrl != null && profilePictureUrl.isNotEmpty
            ? MobileCompatibleNetworkImage(
                imageUrl: profilePictureUrl,
                width: 80 * widthRatio,
                height: 80 * widthRatio,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(40 * widthRatio),
                errorWidget: _buildDefaultProfilePicture(widthRatio),
                placeholder: Container(
                  width: 80 * widthRatio,
                  height: 80 * widthRatio,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E3FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F37CF)),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            : _buildDefaultProfilePicture(widthRatio),
      ),
    );
  }

  Widget _buildDefaultProfilePicture(double widthRatio) {
    return Container(
      width: 80 * widthRatio,
      height: 80 * widthRatio,
      decoration: const BoxDecoration(
        color: Color(0xFFE8E3FF),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 40 * widthRatio,
        color: const Color(0xFF5F37CF),
      ),
    );
  }

  Widget _buildUsernameSection(double widthRatio, double heightRatio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getUserDisplayName(),
          style: TextStyle(
            fontSize: 18 * widthRatio,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121212),
            fontFamily: 'Pretendard',
          ),
        ),
        SizedBox(height: 4 * heightRatio),
        Text(
          '실소 사용자',
          style: TextStyle(
            fontSize: 14 * widthRatio,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E8E),
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton(double widthRatio, double heightRatio) {
    return OutlinedButton(
      onPressed: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const EditProfilePage(),
          ),
        );
        // Refresh profile data if editing was successful
        if (result == true && mounted) {
          setState(() {
            // This will trigger a rebuild and refresh the display name
          });
        }
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: const Color(0xFF5F37CF),
          width: 1.5,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 8 * heightRatio,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * widthRatio),
        ),
      ),
      child: Text(
        'Edit',
        style: TextStyle(
          fontSize: 14 * widthRatio,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF5F37CF),
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildPostItem(
    String title,
    String date,
    String likes,
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
                    title,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8 * heightRatio),
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8E8E8E),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(width: 12 * widthRatio),
                      Text(
                        likes,
                        style: TextStyle(
                          fontSize: 12 * widthRatio,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5F37CF),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
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

  Widget _buildCommunityItem(
    String communityName,
    String memberCount,
    String dateJoined,
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
            // Community Icon
            Container(
              width: 50 * widthRatio,
              height: 50 * widthRatio,
              decoration: BoxDecoration(
                color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(25 * widthRatio),
              ),
              child: Icon(
                Icons.groups,
                color: const Color(0xFF5F37CF),
                size: 24 * widthRatio,
              ),
            ),
            
            SizedBox(width: 16 * widthRatio),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    communityName,
                    style: TextStyle(
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * heightRatio),
                  Text(
                    memberCount,
                    style: TextStyle(
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E8E),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 2 * heightRatio),
                  Text(
                    '가입일: $dateJoined',
                    style: TextStyle(
                      fontSize: 11 * widthRatio,
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

  Widget _buildVirtualPetSection(double widthRatio, double heightRatio) {
    return Column(
      children: [
        // Virtual Pet Illustration
        Container(
          width: 120 * widthRatio,  // Made smaller for profile page
          height: 140 * heightRatio,
          child: Center(
            child: Image.asset(
              'images/pets/pet5.png',
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
        
        // Pet Name Button
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
            '복주',
            style: TextStyle(
              fontSize: 14 * widthRatio,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ],
    );
  }
}