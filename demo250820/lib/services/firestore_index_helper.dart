import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to handle Firestore index requirements and provide fallbacks
class FirestoreIndexHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create the required composite index for posts filtering
  /// This method provides instructions for creating the index manually
  static String getRequiredIndexInstructions() {
    return '''
To fix the Firestore index error, you need to create a composite index:

1. Go to Firebase Console → Firestore Database → Indexes
2. Click "Create Index"
3. Collection ID: posts
4. Fields to index:
   - communityId: Ascending
   - createdAt: Descending
5. Click "Create"

Alternatively, click the link in the error message to auto-create the index.

The error occurs because we're querying posts with both:
- where('communityId', isEqualTo: communityId) 
- orderBy('createdAt', descending: true)

This requires a composite index in Firestore.
''';
  }

  /// Get posts with a simple query that doesn't require composite index
  static Future<List<Map<String, dynamic>>> getPostsSimple({
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get posts: ${e.toString()}');
    }
  }

  /// Get posts for a specific community with fallback handling
  static Future<List<Map<String, dynamic>>> getCommunityPostsWithFallback({
    required String communityId,
    int limit = 20,
  }) async {
    try {
      // Try the optimized query first
      final snapshot = await _firestore
          .collection('posts')
          .where('communityId', isEqualTo: communityId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['postId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (e.toString().contains('index')) {
        // Fallback: Get all posts and filter client-side
        print('Index not found, using fallback method');
        return await _getCommunityPostsFallback(communityId, limit);
      }
      rethrow;
    }
  }

  /// Fallback method that gets all posts and filters client-side
  static Future<List<Map<String, dynamic>>> _getCommunityPostsFallback(
    String communityId,
    int limit,
  ) async {
    try {
      // Get all posts ordered by date (this only requires a single-field index)
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit * 3) // Get more posts to account for filtering
          .get();

      // Filter by community on client-side
      final filteredPosts = snapshot.docs
          .where((doc) {
            final data = doc.data();
            return data['communityId'] == communityId;
          })
          .take(limit)
          .map((doc) {
            final data = doc.data();
            data['postId'] = doc.id;
            return data;
          })
          .toList();

      return filteredPosts;
    } catch (e) {
      throw Exception('Fallback method failed: ${e.toString()}');
    }
  }

  /// Check if the required indexes exist by testing queries
  static Future<Map<String, bool>> checkIndexAvailability() async {
    final results = <String, bool>{};

    try {
      // Test simple posts query
      await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      results['posts_by_date'] = true;
    } catch (e) {
      results['posts_by_date'] = false;
    }

    try {
      // Test community posts query
      await _firestore
          .collection('posts')
          .where('communityId', isEqualTo: 'test')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      results['posts_by_community_and_date'] = true;
    } catch (e) {
      results['posts_by_community_and_date'] = false;
    }

    try {
      // Test comments query
      await _firestore
          .collection('comments')
          .where('postId', isEqualTo: 'test')
          .orderBy('createdAt', descending: false)
          .limit(1)
          .get();
      results['comments_by_post_and_date'] = true;
    } catch (e) {
      results['comments_by_post_and_date'] = false;
    }

    return results;
  }

  /// Create index creation URL for Firebase Console
  static String getIndexCreationUrl(String projectId) {
    return 'https://console.firebase.google.com/project/$projectId/firestore/indexes';
  }
}