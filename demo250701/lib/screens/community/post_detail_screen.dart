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
      await _communityService.addPostComment(
        postId: widget.post.postId,
        content: _commentController.text.trim(),
        type: _selectedCommentType,
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
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.community.communityName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Header
            Row(
              children: [
                // Author Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6C5CE7),
                  child: Text(
                    widget.post.anonymous 
                        ? 'A' 
                        : widget.post.userId.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
                            ? 'Anonymous' 
                            : 'User ${widget.post.userId.substring(0, 8)}...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _formatDate(widget.post.datePosted),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.post.viewCount} views',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
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
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 14,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Anonymous',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Post Caption
            Text(
              widget.post.caption,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
                        'Image failed to load',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14,
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
        // Advice Comments Section
        _buildCommentTypeSection(
          title: '💡 Advice & Support',
          comments: adviceComments,
          accentColor: const Color(0xFF74B9FF),
          icon: Icons.lightbulb,
          emptyMessage: 'No advice comments yet',
        ),
        
        const SizedBox(height: 32),
        
        // Empathy Comments Section
        _buildCommentTypeSection(
          title: '❤️ Empathy & Understanding',
          comments: empathyComments,
          accentColor: const Color(0xFFE17055),
          icon: Icons.favorite,
          emptyMessage: 'No empathy comments yet',
        ),
      ],
    );
  }

  Widget _buildCommentTypeSection({
    required String title,
    required List<PostComment> comments,
    required Color accentColor,
    required IconData icon,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '$title (${comments.length})',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            ),
          )
        else if (comments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: accentColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to share!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return _buildCommentCard(comment, accentColor);
            },
          ),
      ],
    );
  }

  Widget _buildCommentCard(PostComment comment, Color accentColor) {
    final isAdvice = comment.type == CommentType.advice;
    final icon = isAdvice ? Icons.lightbulb : Icons.favorite;
    final typeLabel = isAdvice ? 'Advice' : 'Empathy';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: accentColor,
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
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
                              ? 'Anonymous' 
                              : 'User ${comment.userId.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Comment Content
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment Type Selection
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCommentType = CommentType.advice),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedCommentType == CommentType.advice
                          ? const Color(0xFF74B9FF).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedCommentType == CommentType.advice
                            ? const Color(0xFF74B9FF)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lightbulb,
                          size: 16,
                          color: _selectedCommentType == CommentType.advice
                              ? const Color(0xFF74B9FF)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Advice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedCommentType == CommentType.advice
                                ? const Color(0xFF74B9FF)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCommentType = CommentType.empathy),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedCommentType == CommentType.empathy
                          ? const Color(0xFFE17055).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedCommentType == CommentType.empathy
                            ? const Color(0xFFE17055)
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: _selectedCommentType == CommentType.empathy
                              ? const Color(0xFFE17055)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Empathy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedCommentType == CommentType.empathy
                                ? const Color(0xFFE17055)
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _selectedCommentType == CommentType.advice
                          ? 'Share your advice or support...'
                          : 'Share your empathy and understanding...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _selectedCommentType == CommentType.advice
                              ? const Color(0xFF74B9FF)
                              : const Color(0xFFE17055),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  // Anonymous toggle
                  GestureDetector(
                    onTap: () => setState(() => _isAnonymousComment = !_isAnonymousComment),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAnonymousComment
                            ? Colors.orange.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isAnonymousComment
                              ? Colors.orange
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.visibility_off,
                        size: 16,
                        color: _isAnonymousComment
                            ? Colors.orange
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Send button
                  GestureDetector(
                    onTap: _isLoadingComments ? null : _addComment,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedCommentType == CommentType.advice
                            ? const Color(0xFF74B9FF)
                            : const Color(0xFFE17055),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoadingComments
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ],
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
}