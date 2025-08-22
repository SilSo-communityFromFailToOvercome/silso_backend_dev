import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/comment.dart';
import 'user_service.dart';

class PostsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  /// Get posts with blocking filter
  Future<List<Post>> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    bool includeBlockedUsers = false,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      // Get blocked user IDs (unless explicitly including blocked users)
      List<String> blockedUserIds = [];
      if (!includeBlockedUsers) {
        blockedUserIds = await _userService.getAllBlockingRelationships();
      }
      
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      final snapshot = await query.get();
      
      // Filter out posts from blocked users
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final authorId = data['authorId'] as String;
        return !blockedUserIds.contains(authorId);
      }).toList();
      
      return filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Post.fromFirestore(doc.id, data);
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to get posts: ${e.toString()}');
    }
  }

  /// Get posts stream with blocking filter
  Stream<List<Post>> getPostsStream({
    int limit = 20,
    bool includeBlockedUsers = false,
  }) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        // Get blocked user IDs for each update
        List<String> blockedUserIds = [];
        if (!includeBlockedUsers) {
          blockedUserIds = await _userService.getAllBlockingRelationships();
        }
        
        // Filter out posts from blocked users
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          final authorId = data['authorId'] as String;
          return !blockedUserIds.contains(authorId);
        }).toList();
        
        return filteredDocs.map((doc) {
          final data = doc.data();
          return Post.fromFirestore(doc.id, data);
        }).toList();
        
      } catch (e) {
        // Return empty list on error
        return <Post>[];
      }
    });
  }

  /// Get comments for a post with blocking filter
  Future<List<Comment>> getComments(
    String postId, {
    bool includeBlockedUsers = false,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      // Get blocked user IDs
      List<String> blockedUserIds = [];
      if (!includeBlockedUsers) {
        blockedUserIds = await _userService.getAllBlockingRelationships();
      }
      
      final snapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .get();
      
      // Filter out comments from blocked users
      final filteredDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        final authorId = data['authorId'] as String;
        return !blockedUserIds.contains(authorId);
      }).toList();
      
      return filteredDocs.map((doc) {
        final data = doc.data();
        return Comment.fromFirestore(doc.id, data);
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to get comments: ${e.toString()}');
    }
  }

  /// Get comments stream for a post with blocking filter
  Stream<List<Comment>> getCommentsStream(
    String postId, {
    bool includeBlockedUsers = false,
  }) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        // Get blocked user IDs for each update
        List<String> blockedUserIds = [];
        if (!includeBlockedUsers) {
          blockedUserIds = await _userService.getAllBlockingRelationships();
        }
        
        // Filter out comments from blocked users
        final filteredDocs = snapshot.docs.where((doc) {
          final data = doc.data();
          final authorId = data['authorId'] as String;
          return !blockedUserIds.contains(authorId);
        }).toList();
        
        return filteredDocs.map((doc) {
          final data = doc.data();
          return Comment.fromFirestore(doc.id, data);
        }).toList();
        
      } catch (e) {
        // Return empty list on error
        return <Comment>[];
      }
    });
  }

  /// Create a new post
  Future<String> createPost({
    required String content,
    List<String> imageUrls = const [],
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      
      final userData = userDoc.data()!;
      
      final postData = {
        'authorId': currentUser.uid,
        'authorUsername': userData['username'] ?? '',
        'authorProfileImage': userData['profileImage'] ?? '',
        'content': content,
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
      };
      
      final docRef = await _firestore.collection('posts').add(postData);
      return docRef.id;
      
    } catch (e) {
      throw Exception('Failed to create post: ${e.toString()}');
    }
  }

  /// Create a new comment
  Future<String> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Get current user data
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      
      final userData = userDoc.data()!;
      
      final commentData = {
        'postId': postId,
        'authorId': currentUser.uid,
        'authorUsername': userData['username'] ?? '',
        'authorProfileImage': userData['profileImage'] ?? '',
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'parentCommentId': parentCommentId,
      };
      
      final docRef = await _firestore.collection('comments').add(commentData);
      
      // Update post comments count
      await _firestore.collection('posts').doc(postId).update({
        'commentsCount': FieldValue.increment(1),
      });
      
      return docRef.id;
      
    } catch (e) {
      throw Exception('Failed to create comment: ${e.toString()}');
    }
  }

  /// Get a single post by ID
  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      
      // Check if post author is blocked
      final authorId = data['authorId'] as String;
      final isBlocked = await _userService.isUserBlocked(authorId);
      
      if (isBlocked) return null;
      
      return Post.fromFirestore(doc.id, data);
      
    } catch (e) {
      throw Exception('Failed to get post: ${e.toString()}');
    }
  }

  /// Delete a post (only by author)
  Future<void> deletePost(String postId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }
      
      final postData = postDoc.data()!;
      if (postData['authorId'] != currentUserId) {
        throw Exception('Not authorized to delete this post');
      }
      
      // Delete the post
      await _firestore.collection('posts').doc(postId).delete();
      
      // Delete all comments for this post
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  /// Like/unlike a post
  Future<void> togglePostLike(String postId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final likeRef = _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId);
      
      final likeDoc = await likeRef.get();
      
      if (likeDoc.exists) {
        // Unlike
        await likeRef.delete();
        await _firestore.collection('posts').doc(postId).update({
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        // Like
        await likeRef.set({
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await _firestore.collection('posts').doc(postId).update({
          'likesCount': FieldValue.increment(1),
        });
      }
      
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
    }
  }

  /// Check if current user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;
    
    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserId)
          .get();
      
      return likeDoc.exists;
      
    } catch (e) {
      return false;
    }
  }
}