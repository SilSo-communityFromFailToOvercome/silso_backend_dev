import 'package:flutter/material.dart';
import '../../services/community_service.dart';
import '../../models/post_model.dart';
import '../../models/community_model.dart';
import '../../widgets/cached_network_image_widget.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final Community community;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.community,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _commentController = TextEditingController();
  List<PostComment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _isUserMember = false;
  CommentType _selectedCommentType = CommentType.advice;
  bool _isAnonymousComment = false;
  String _selectedCommentTab = 'advice'; // 'advice' or 'empathy'

  @override
  void initState() {
    super.initState();
    _loadComments();
    _checkMembership();
    _incrementViewCount();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _communityService.getPostComments(widget.post.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load comments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkMembership() async {
    try {
      final isMember = await _communityService.isUserMemberOfCommunity(widget.community.communityId);
      if (mounted) {
        setState(() => _isUserMember = isMember);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _incrementViewCount() async {
    try {
      await _communityService.incrementPostViewCount(widget.post.postId);
    } catch (e) {
      // Handle error silently - view count is not critical
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    if (!_isUserMember) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be a member of this community to comment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoadingComments = true);

    try {
      // Automatically determine comment type based on current tab
      final commentType = _selectedCommentTab == 'advice' ? CommentType.advice : CommentType.empathy;
      
      await _communityService.addPostComment(
        postId: widget.post.postId,
        content: _commentController.text.trim(),
        type: commentType,
        anonymous: _isAnonymousComment,
      );

      _commentController.clear();
      await _loadComments(); // Refresh comments

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.community.communityName,
          style: const TextStyle(
            color: Color(0xFF121212),
            fontWeight: FontWeight.w600,
            fontSize: 18,
            fontFamily: 'Pretendard',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF121212)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF121212)),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Post Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Card
                    _buildPostCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Comments Section
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
            
            // Comment Input (only for members)
            if (_isUserMember) _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                // Author Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF5F37CF),
                  child: Text(
                    widget.post.anonymous 
                        ? '익명' 
                        : widget.post.userId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Author Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.anonymous 
                            ? '익명' 
                            : '사용자${widget.post.userId.substring(0, 4)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF121212),
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatKoreanDate(widget.post.datePosted),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E8E),
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 12,
                                color: Color(0xFF8E8E8E),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '조회 ${widget.post.viewCount}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E8E),
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Anonymous Badge
                if (widget.post.anonymous)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F37CF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 12,
                          color: Color(0xFF5F37CF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '익명',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF5F37CF),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Post Title
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                height: 1.4,
                fontFamily: 'Pretendard',
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Post Caption
            Text(
              widget.post.caption,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF121212),
                height: 1.6,
                fontFamily: 'Pretendard',
              ),
            ),
            
            // Post Image
            if (widget.post.imageUrl != null) ...[
              const SizedBox(height: 20),
              MobileCompatibleNetworkImage(
                imageUrl: widget.post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(12),
                errorWidget: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '이미지를 불러올 수 없습니다',
                        style: const TextStyle(
                          color: Color(0xFF8E8E8E),
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


  Widget _buildCommentsSection() {
    final adviceComments = _comments.where((c) => c.type == CommentType.advice).toList();
    final empathyComments = _comments.where((c) => c.type == CommentType.empathy).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Comments Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            '댓글 ${_comments.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF121212),
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        
        // Comment Tabs Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Row(
            children: [
              // Advice Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCommentTab = 'advice'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedCommentTab == 'advice' 
                              ? const Color(0xFF121212) 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '조언 ${adviceComments.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedCommentTab == 'advice'
                            ? const Color(0xFF121212)
                            : const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
              // Empathy Tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCommentTab = 'empathy'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _selectedCommentTab == 'empathy' 
                              ? const Color(0xFF121212) 
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      '공감 ${empathyComments.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedCommentTab == 'empathy'
                            ? const Color(0xFF121212)
                            : const Color(0xFF8E8E8E),
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Selected Comments
        _buildSelectedCommentsSection(),
      ],
    );
  }

  Widget _buildSelectedCommentsSection() {
    final adviceComments = _comments.where((c) => c.type == CommentType.advice).toList();
    final empathyComments = _comments.where((c) => c.type == CommentType.empathy).toList();
    final currentComments = _selectedCommentTab == 'advice' ? adviceComments : empathyComments;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
          ),
        ),
      );
    }
    
    if (currentComments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: const Color(0xFF8E8E8E).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedCommentTab == 'advice' 
                  ? '첫 번째 조언을 남겨보세요!' 
                  : '첫 번째 공감을 남겨보세요!',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentComments.length,
      itemBuilder: (context, index) {
        final comment = currentComments[index];
        return _buildCommentCard(comment, index);
      },
    );
  }


  Widget _buildCommentCard(PostComment comment, int index) {
    final isAdvice = comment.type == CommentType.advice;
    final typeLabel = isAdvice ? '조언' : '공감';
    final typeColor = isAdvice ? const Color(0xFF5F37CF) : const Color(0xFFE17055);
    final adviceComments = _comments.where((c) => c.type == CommentType.advice).toList();
    final empathyComments = _comments.where((c) => c.type == CommentType.empathy).toList();
    final currentComments = _selectedCommentTab == 'advice' ? adviceComments : empathyComments;

    return Container(
      margin: EdgeInsets.only(
        bottom: index == currentComments.length - 1 ? 0 : 16,
      ),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF121212),
                child: Text(
                  comment.anonymous 
                      ? '익' 
                      : comment.userId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.anonymous 
                              ? '익명' 
                              : '사용자${comment.userId.substring(0, 4)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF121212),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatKoreanDate(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E8E),
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Comment Content
                    Text(
                      comment.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF121212),
                        height: 1.5,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Comment Input Field
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    style: const TextStyle(
                      color: Color(0xFF121212),
                      fontFamily: 'Pretendard',
                    ),
                    decoration: InputDecoration(
                      hintText: _selectedCommentTab == 'advice'
                          ? '조언이나 지지의 말을 남겨주세요...'
                          : '공감과 이해의 말을 남겨주세요...',
                      hintStyle: const TextStyle(
                        color: Color(0xFFBBBBBB),
                        fontFamily: 'Pretendard',
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF121212),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              GestureDetector(
                onTap: _isLoadingComments ? null : _addComment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isLoadingComments
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8E8E8E)),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Color(0xFF8E8E8E),
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatKoreanDate(DateTime date) {
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

  Widget _buildAllCommentsSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
          ),
        ),
      );
    }
    
    if (_comments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: const Color(0xFF8E8E8E).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '첫 번째 댓글을 남겨보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentCard(comment, index);
      },
    );
  }
}