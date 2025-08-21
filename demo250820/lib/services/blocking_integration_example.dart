import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/posts_service.dart';
import '../models/post.dart';
import '../models/comment.dart';

/// Example integration showing how to use the blocking system
/// throughout the app. Copy these patterns to your actual screens.
class BlockingIntegrationExample {
  final UserService _userService = UserService();
  final PostsService _postsService = PostsService();

  /// Example: Block a user from a user profile screen
  Future<void> blockUserExample(BuildContext context, String userIdToBlock, String username) async {
    try {
      // Show confirmation dialog
      final shouldBlock = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('사용자 차단'),
          content: Text('$username님을 차단하시겠습니까?\n\n차단하면 이 사용자의 게시물과 댓글이 더 이상 표시되지 않습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('차단', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldBlock == true) {
        await _userService.blockUser(userIdToBlock);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$username님을 차단했습니다.'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '실행취소',
                onPressed: () async {
                  await _userService.unblockUser(userIdToBlock);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('차단이 해제되었습니다.')),
                    );
                  }
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차단에 실패했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Example: Get posts for a feed with blocking filter
  Future<List<Post>> getFilteredPostsExample() async {
    try {
      // This will automatically exclude posts from blocked users
      final posts = await _postsService.getPosts(limit: 20);
      return posts;
    } catch (e) {
      print('Error getting filtered posts: $e');
      return [];
    }
  }

  /// Example: Get comments for a post with blocking filter
  Future<List<Comment>> getFilteredCommentsExample(String postId) async {
    try {
      // This will automatically exclude comments from blocked users
      final comments = await _postsService.getComments(postId);
      return comments;
    } catch (e) {
      print('Error getting filtered comments: $e');
      return [];
    }
  }

  /// Example: Use streams for real-time updates with blocking
  Stream<List<Post>> getPostsStreamExample() {
    // This stream will automatically update when users are blocked/unblocked
    return _postsService.getPostsStream(limit: 20);
  }

  /// Example: Check if a user is blocked before showing their content
  Future<bool> shouldShowUserContentExample(String userId) async {
    try {
      final isBlocked = await _userService.isUserBlocked(userId);
      return !isBlocked;
    } catch (e) {
      // If there's an error checking, show content by default
      return true;
    }
  }

  /// Example: Get blocked users count for settings badge
  Future<int> getBlockedUsersCountExample() async {
    try {
      final blockedUsers = await _userService.getBlockedUsers();
      return blockedUsers.length;
    } catch (e) {
      return 0;
    }
  }
}

/// Example Widget: Post item with block option
class PostItemWithBlockExample extends StatelessWidget {
  final Post post;
  final VoidCallback? onPostUpdated;

  const PostItemWithBlockExample({
    super.key,
    required this.post,
    this.onPostUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header with user info and menu
          ListTile(
            leading: CircleAvatar(
              backgroundImage: post.authorProfileImage.isNotEmpty
                  ? NetworkImage(post.authorProfileImage)
                  : null,
              child: post.authorProfileImage.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(post.authorUsername),
            subtitle: Text(_formatDate(post.createdAt)),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'block') {
                  await _blockUser(context, post.authorId, post.authorUsername);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text('사용자 차단', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Post content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(post.content),
          ),
          
          // Post actions (like, comment, etc.)
          Row(
            children: [
              IconButton(
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? Colors.red : null,
                ),
                onPressed: () => _toggleLike(),
              ),
              Text('${post.likesCount}'),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: () => _showComments(context),
              ),
              Text('${post.commentsCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(BuildContext context, String userId, String username) async {
    final blockingExample = BlockingIntegrationExample();
    await blockingExample.blockUserExample(context, userId, username);
    onPostUpdated?.call(); // Refresh the feed
  }

  void _toggleLike() {
    // Implement like toggle
  }

  void _showComments(BuildContext context) {
    // Navigate to comments screen
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}

/// Example Widget: Comments section with blocking
class CommentsWithBlockingExample extends StatefulWidget {
  final String postId;

  const CommentsWithBlockingExample({super.key, required this.postId});

  @override
  State<CommentsWithBlockingExample> createState() => _CommentsWithBlockingExampleState();
}

class _CommentsWithBlockingExampleState extends State<CommentsWithBlockingExample> {
  final PostsService _postsService = PostsService();
  List<Comment> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      // This automatically excludes comments from blocked users
      final loadedComments = await _postsService.getComments(widget.postId);
      setState(() {
        comments = loadedComments;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글을 불러오는데 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final comment = comments[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: comment.authorProfileImage.isNotEmpty
                ? NetworkImage(comment.authorProfileImage)
                : null,
            child: comment.authorProfileImage.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(comment.authorUsername),
          subtitle: Text(comment.content),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'block') {
                final blockingExample = BlockingIntegrationExample();
                await blockingExample.blockUserExample(
                  context, 
                  comment.authorId, 
                  comment.authorUsername,
                );
                _loadComments(); // Refresh comments
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 8),
                    Text('사용자 차단', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}