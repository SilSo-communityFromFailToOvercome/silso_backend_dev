import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart' as app_models;
import '../models/community_model.dart';
import 'user_service.dart';
import 'community_service.dart';

/// Integration service that adds blocking functionality to existing app services
/// This service extends the existing CommunityService with blocking filters
class BlockingIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final CommunityService _communityService = CommunityService();

  /// Get posts with blocking filter applied
  Future<List<app_models.Post>> getFilteredPosts({
    String? communityId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Get blocked user IDs
      final blockedUserIds = await _userService.getAllBlockingRelationships();
      
      // Use existing community service method to avoid index issues
      List<app_models.Post> allPosts;
      if (communityId != null) {
        allPosts = await _communityService.getCommunityPosts(communityId);
      } else {
        // If no community specified, get posts using a simple query
        final snapshot = await _firestore.collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
        
        allPosts = [];
        for (final doc in snapshot.docs) {
          try {
            final post = app_models.Post.fromMap(doc.data(), doc.id);
            allPosts.add(post);
          } catch (e) {
            // Skip posts that can't be parsed
            continue;
          }
        }
      }
      
      // Filter out posts from blocked users
      final filteredPosts = allPosts.where((post) {
        return !blockedUserIds.contains(post.userId);
      }).toList();
      
      // Apply limit if specified
      if (filteredPosts.length > limit) {
        return filteredPosts.take(limit).toList();
      }
      
      return filteredPosts;
      
    } catch (e) {
      throw Exception('Failed to get filtered posts: ${e.toString()}');
    }
  }

  /// Get hot posts with blocking filter
  Future<List<Map<String, dynamic>>> getFilteredHotPosts() async {
    try {
      // Get blocked user IDs
      final blockedUserIds = await _userService.getAllBlockingRelationships();
      
      // Get hot posts using existing service
      final hotPosts = await _communityService.getHotPosts();
      
      // Filter out posts from blocked users
      final filteredPosts = hotPosts.where((postData) {
        final userId = postData['userId'] as String?;
        return userId != null && !blockedUserIds.contains(userId);
      }).toList();
      
      return filteredPosts;
      
    } catch (e) {
      throw Exception('Failed to get filtered hot posts: ${e.toString()}');
    }
  }

  /// Get general posts with blocking filter
  Future<List<app_models.Post>> getFilteredGeneralPosts() async {
    try {
      // Get blocked user IDs first
      final blockedUserIds = await _userService.getAllBlockingRelationships();
      
      // Try to use the existing community service method first
      try {
        final allGeneralPosts = await _communityService.getCommunityPosts('r8zn6yjJtKHP3jyDoJ2x');
        
        // Filter out posts from blocked users
        final filteredPosts = allGeneralPosts.where((post) {
          return !blockedUserIds.contains(post.userId);
        }).toList();
        
        return filteredPosts;
        
      } catch (e) {
        if (e.toString().contains('index') || e.toString().contains('requires an index')) {
          // Fallback: Get all posts and filter client-side
          return await _getGeneralPostsFallback(blockedUserIds);
        }
        rethrow;
      }
      
    } catch (e) {
      throw Exception('Failed to get filtered general posts: ${e.toString()}');
    }
  }

  /// Fallback method for getting general posts when index is missing
  Future<List<app_models.Post>> _getGeneralPostsFallback(List<String> blockedUserIds) async {
    try {
      // Get all posts with simple query (only requires single-field index)
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100) // Get more posts to account for filtering
          .get();

      // Filter by community and blocked users on client-side
      final filteredPosts = <app_models.Post>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final communityId = data['communityId'] as String?;
          final userId = data['userId'] as String?;
          
          // Check if it's the general community and user is not blocked
          if (communityId == 'r8zn6yjJtKHP3jyDoJ2x' && 
              userId != null && 
              !blockedUserIds.contains(userId)) {
            final post = app_models.Post.fromMap(data, doc.id);
            filteredPosts.add(post);
          }
        } catch (e) {
          // Skip posts that can't be parsed
          continue;
        }
      }
      
      return filteredPosts.take(20).toList(); // Return first 20 results
      
    } catch (e) {
      throw Exception('Fallback method failed: ${e.toString()}');
    }
  }

  /// Get user's posts with blocking filter applied to comments
  Future<List<app_models.Post>> getFilteredUserPosts() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];
      
      // Get user's posts using existing service
      final userPosts = await _communityService.getUserPosts(currentUserId);
      
      // Note: User's own posts are not filtered, but their comments will be filtered later
      return userPosts;
      
    } catch (e) {
      throw Exception('Failed to get filtered user posts: ${e.toString()}');
    }
  }

  /// Get post comments with blocking filter
  Future<List<app_models.PostComment>> getFilteredPostComments(String postId) async {
    try {
      // Get blocked user IDs
      final blockedUserIds = await _userService.getAllBlockingRelationships();
      
      // Get all comments using existing service
      final allComments = await _communityService.getPostComments(postId);
      
      // Filter out comments from blocked users
      final filteredComments = allComments.where((comment) {
        return !blockedUserIds.contains(comment.userId);
      }).toList();
      
      return filteredComments;
      
    } catch (e) {
      throw Exception('Failed to get filtered comments: ${e.toString()}');
    }
  }

  /// Get posts stream with blocking filter
  Stream<List<app_models.Post>> getFilteredPostsStream({
    String? communityId,
    int limit = 20,
  }) {
    Query query = _firestore.collection('posts');
    
    if (communityId != null) {
      query = query.where('communityId', isEqualTo: communityId);
    }
    
    query = query.orderBy('createdAt', descending: true).limit(limit);
    
    return query.snapshots().asyncMap((snapshot) async {
      try {
        // Get blocked user IDs for each update
        final blockedUserIds = await _userService.getAllBlockingRelationships();
        
        // Filter out posts from blocked users
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] as String?;
          return userId != null && !blockedUserIds.contains(userId);
        }).toList();
        
        // Convert to Post objects
        final posts = <app_models.Post>[];
        for (final doc in filteredDocs) {
          try {
            final post = app_models.Post.fromMap(doc.data() as Map<String, dynamic>, doc.id);
            posts.add(post);
          } catch (e) {
            // Skip posts that can't be parsed
            continue;
          }
        }
        
        return posts;
        
      } catch (e) {
        // Return empty list on error
        return <app_models.Post>[];
      }
    });
  }

  /// Check if a user should be shown (not blocked)
  Future<bool> shouldShowUser(String userId) async {
    try {
      return !(await _userService.isUserBlocked(userId));
    } catch (e) {
      // If there's an error checking, show user by default
      return true;
    }
  }

  /// Block a user with user-friendly error handling
  Future<void> blockUserWithFeedback(String userIdToBlock, String username) async {
    try {
      await _userService.blockUser(userIdToBlock);
    } catch (e) {
      throw Exception('$username님을 차단하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// Unblock a user with user-friendly error handling
  Future<void> unblockUserWithFeedback(String userIdToUnblock, String username) async {
    try {
      await _userService.unblockUser(userIdToUnblock);
    } catch (e) {
      throw Exception('$username님의 차단을 해제하는데 실패했습니다: ${e.toString()}');
    }
  }

  /// Get blocked users for settings page
  Future<List<Map<String, dynamic>>> getBlockedUsersForSettings() async {
    try {
      final blockedUsers = await _userService.getBlockedUsers();
      
      // Convert to format expected by existing UI
      return blockedUsers.map((user) => {
        'id': user.id,
        'username': user.username,
        'profileImage': user.profileImage,
        'blockedAt': user.blockedAt,
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to get blocked users: ${e.toString()}');
    }
  }

  /// Get all communities with blocking filter (exclude communities created by blocked users)
  Future<List<Community>> getFilteredCommunities() async {
    try {
      // Get blocked user IDs
      final blockedUserIds = await _userService.getAllBlockingRelationships();
      
      // Get all communities using existing service
      final communities = await _communityService.getAllCommunities();
      
      // Filter out communities created by blocked users
      final filteredCommunities = communities.where((community) {
        return !blockedUserIds.contains(community.creatorId);
      }).toList();
      
      return filteredCommunities;
      
    } catch (e) {
      throw Exception('Failed to get filtered communities: ${e.toString()}');
    }
  }

  /// Get recommended communities with blocking filter
  Stream<List<Community>> getFilteredRecommendedCommunitiesStream() {
    return _communityService.getRecommendedCommunitiesStream().asyncMap((communities) async {
      try {
        // Get blocked user IDs
        final blockedUserIds = await _userService.getAllBlockingRelationships();
        
        // Filter out communities created by blocked users
        final filteredCommunities = communities.where((community) {
          return !blockedUserIds.contains(community.creatorId);
        }).toList();
        
        return filteredCommunities;
        
      } catch (e) {
        // Return original list on error
        return communities;
      }
    });
  }

  /// Refresh blocking cache (call after blocking/unblocking operations)
  Future<void> refreshBlockingCache() async {
    await _userService.refreshCache();
  }

  /// Get blocking statistics for analytics
  Future<Map<String, int>> getBlockingStats() async {
    try {
      final blockedUsers = await _userService.getBlockedUsers();
      final blockedUserIds = await _userService.getBlockedUserIds();
      
      return {
        'totalBlockedUsers': blockedUsers.length,
        'cachedBlockedUsers': blockedUserIds.length,
      };
      
    } catch (e) {
      return {
        'totalBlockedUsers': 0,
        'cachedBlockedUsers': 0,
      };
    }
  }
}