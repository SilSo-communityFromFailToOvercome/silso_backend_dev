import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_model.dart';
import '../models/post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user has completed community setup
  Future<bool> hasCompletedCommunitySetup() async {
    if (currentUserId == null) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      
      // Check if all required fields are present
      return data.containsKey('communityInterests') &&
             data.containsKey('profile') &&
             data.containsKey('phoneNumber') &&
             data.containsKey('policyAgreementTimestamp');
    } catch (e) {
      return false;
    }
  }

  // Step A: Save community interests
  Future<void> saveCommunityInterests(List<String> interests) async {
    if (currentUserId == null) throw 'User not authenticated';
    if (interests.length < 3) throw 'Please select at least 3 interests';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'communityInterests': interests,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save interests: ${e.toString()}';
    }
  }

  // Step B: Save profile information
  Future<void> saveProfileInformation({
    required String name,
    required String country,
    required String birthdate,
    required String gender,
    required String phoneNumber,
  }) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'profile': {
          'name': name,
          'country': country,
          'birthdate': birthdate,
          'gender': gender,
        },
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save profile: ${e.toString()}';
    }
  }

  // Step B: Verify phone number (placeholder for Firebase Auth phone verification)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(String error) verificationFailed,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed
          await linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          verificationFailed(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      verificationFailed('Failed to verify phone number: ${e.toString()}');
    }
  }

  // Step B: Link phone credential to current user
  Future<void> linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'User not authenticated';

      await user.linkWithCredential(credential);
    } catch (e) {
      throw 'Failed to link phone number: ${e.toString()}';
    }
  }

  // Step B: Verify SMS code and link phone
  Future<void> verifySMSCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      await linkPhoneCredential(credential);
    } catch (e) {
      throw 'Failed to verify SMS code: ${e.toString()}';
    }
  }

  // Step C: Save policy agreement
  Future<void> agreePolicies() async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set({
        'policyAgreementTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw 'Failed to save policy agreement: ${e.toString()}';
    }
  }

  // Get user's community profile data
  Future<Map<String, dynamic>?> getCommunityProfile() async {
    if (currentUserId == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  // Available community interest categories
  static const List<String> availableInterests = [
    'Technology',
    'Sports',
    'Music',
    'Art & Design',
    'Travel',
    'Food & Cooking',
    'Health & Fitness',
    'Books & Literature',
    'Movies & TV',
    'Gaming',
    'Photography',
    'Fashion',
    'Business',
    'Science',
    'History',
    'Politics',
    'Environment',
    'Education',
    'Parenting',
    'Pets & Animals',
  ];

  // Available countries (simplified list)
  static const List<String> availableCountries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'South Korea',
    'Brazil',
    'Mexico',
    'India',
    'China',
    'Russia',
    'Italy',
    'Spain',
    'Netherlands',
    'Sweden',
    'Norway',
    'Denmark',
    'Finland',
  ];

  // Available genders
  static const List<String> availableGenders = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  // Create a new community
  Future<String> createCommunity(CreateCommunityRequest request) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      final docRef = await _firestore
          .collection('communities')
          .add(request.toMap(currentUserId!));
      
      return docRef.id;
    } catch (e) {
      throw 'Failed to create community: ${e.toString()}';
    }
  }

  // Get all communities
  Future<List<Community>> getAllCommunities() async {
    try {
      final snapshot = await _firestore
          .collection('communities')
          .orderBy('dateAdded', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return Community.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw 'Failed to load communities: ${e.toString()}';
    }
  }

  // Get communities user has joined
  Future<List<Community>> getMyCommunities() async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      final snapshot = await _firestore
          .collection('communities')
          .where('members', arrayContains: currentUserId)
          .get();

      // Sort in memory to avoid compound index requirement
      final communities = snapshot.docs.map((doc) {
        return Community.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by dateAdded in descending order (newest first)
      communities.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      return communities;
    } catch (e) {
      throw 'Failed to load my communities: ${e.toString()}';
    }
  }

  // Join a community
  Future<void> joinCommunity(String communityId) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore.runTransaction((transaction) async {
        final communityRef = _firestore.collection('communities').doc(communityId);
        final communityDoc = await transaction.get(communityRef);

        if (!communityDoc.exists) {
          throw 'Community not found';
        }

        final communityData = communityDoc.data()!;
        final members = List<String>.from(communityData['members'] ?? []);
        
        if (members.contains(currentUserId)) {
          throw 'Already a member of this community';
        }

        members.add(currentUserId!);
        
        transaction.update(communityRef, {
          'members': members,
          'memberCount': members.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw 'Failed to join community: ${e.toString()}';
    }
  }

  // Leave a community
  Future<void> leaveCommunity(String communityId) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      await _firestore.runTransaction((transaction) async {
        final communityRef = _firestore.collection('communities').doc(communityId);
        final communityDoc = await transaction.get(communityRef);

        if (!communityDoc.exists) {
          throw 'Community not found';
        }

        final communityData = communityDoc.data()!;
        final members = List<String>.from(communityData['members'] ?? []);
        
        if (!members.contains(currentUserId)) {
          throw 'Not a member of this community';
        }

        // Check if user is the creator
        if (communityData['creatorId'] == currentUserId) {
          throw 'Community creator cannot leave the community';
        }

        members.remove(currentUserId);
        
        transaction.update(communityRef, {
          'members': members,
          'memberCount': members.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw 'Failed to leave community: ${e.toString()}';
    }
  }

  // Get a specific community by ID
  Future<Community> getCommunity(String communityId) async {
    try {
      final doc = await _firestore
          .collection('communities')
          .doc(communityId)
          .get();

      if (!doc.exists) {
        throw 'Community not found';
      }

      return Community.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw 'Failed to get community: ${e.toString()}';
    }
  }

  // POST MANAGEMENT METHODS

  // Create a new post in a community
  Future<String> createPost(CreatePostRequest request) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      // First, verify user is a member of the community
      final community = await getCommunity(request.communityId);
      if (!community.members.contains(currentUserId)) {
        throw 'You must be a member of this community to post';
      }

      // Create the post
      final docRef = await _firestore
          .collection('posts')
          .add(request.toMap(currentUserId!));

      // Update community post count
      await _firestore
          .collection('communities')
          .doc(request.communityId)
          .update({
        'posts': FieldValue.arrayUnion([docRef.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to create post: ${e.toString()}';
    }
  }

  // Get all posts for a specific community
  Future<List<Post>> getCommunityPosts(String communityId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('communityId', isEqualTo: communityId)
          .get();

      // Sort in memory to avoid compound index requirement
      final posts = snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by datePosted in descending order (newest first)
      posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));

      return posts;
    } catch (e) {
      throw 'Failed to load community posts: ${e.toString()}';
    }
  }

  // Get all posts stream (real-time updates)
  Stream<List<Post>> getAllPosts() {
    return _firestore
        .collection('posts')
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by datePosted in descending order (newest first)
      posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));

      return posts;
    });
  }

  // Get community posts stream (real-time updates)
  Stream<List<Post>> getCommunityPostsStream(String communityId) {
    return _firestore
        .collection('posts')
        .where('communityId', isEqualTo: communityId)
        .snapshots()
        .map((snapshot) {
      final posts = snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by datePosted in descending order (newest first)
      posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));

      return posts;
    });
  }

  // Get a specific post
  Future<Post> getPost(String postId) async {
    try {
      final doc = await _firestore
          .collection('posts')
          .doc(postId)
          .get();

      if (!doc.exists) {
        throw 'Post not found';
      }

      return Post.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw 'Failed to get post: ${e.toString()}';
    }
  }

  // Get posts by a specific user
  Future<List<Post>> getUserPosts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort in memory to avoid compound index requirement
      final posts = snapshot.docs.map((doc) {
        return Post.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by datePosted in descending order (newest first)
      posts.sort((a, b) => b.datePosted.compareTo(a.datePosted));

      return posts;
    } catch (e) {
      throw 'Failed to load user posts: ${e.toString()}';
    }
  }

  // Delete a post (only by post owner or community creator)
  Future<void> deletePost(String postId) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      final post = await getPost(postId);
      final community = await getCommunity(post.communityId);

      // Check if user can delete (post owner or community creator)
      if (post.userId != currentUserId && community.creatorId != currentUserId) {
        throw 'You can only delete your own posts or posts in communities you created';
      }

      // Delete the post
      await _firestore.collection('posts').doc(postId).delete();

      // Remove from community posts array
      await _firestore
          .collection('communities')
          .doc(post.communityId)
          .update({
        'posts': FieldValue.arrayRemove([postId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Delete associated comments
      final commentsSnapshot = await _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (final doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

    } catch (e) {
      throw 'Failed to delete post: ${e.toString()}';
    }
  }

  // Add a comment to a post
  Future<String> addPostComment({
    required String postId,
    required String content,
    required CommentType type,
    bool anonymous = false,
  }) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      final post = await getPost(postId);
      final community = await getCommunity(post.communityId);

      // Verify user is a member of the community
      if (!community.members.contains(currentUserId)) {
        throw 'You must be a member of this community to comment';
      }

      // Create the comment
      final comment = PostComment(
        commentId: '', // Will be set by Firestore
        postId: postId,
        userId: currentUserId!,
        content: content,
        type: type,
        anonymous: anonymous,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('post_comments')
          .add(comment.toMap());

      // Update post comment count
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw 'Failed to add comment: ${e.toString()}';
    }
  }

  // Get comments for a post
  Future<List<PostComment>> getPostComments(String postId) async {
    try {
      final snapshot = await _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .get();

      // Sort in memory to avoid compound index requirement
      final comments = snapshot.docs.map((doc) {
        return PostComment.fromMap(doc.data(), doc.id);
      }).toList();

      // Sort by createdAt in ascending order (oldest first)
      comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return comments;
    } catch (e) {
      throw 'Failed to load comments: ${e.toString()}';
    }
  }

  // Check if current user is a member of a community
  Future<bool> isUserMemberOfCommunity(String communityId) async {
    if (currentUserId == null) return false;

    try {
      final community = await getCommunity(communityId);
      return community.members.contains(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // Increment view count for a post
  Future<void> incrementPostViewCount(String postId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .update({
        'viewCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle error silently - view count is not critical
    }
  }
}