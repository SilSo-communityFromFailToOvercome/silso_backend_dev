import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/community_model.dart';
import '../models/post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default community configuration
  static const String defaultCommunityName = '종합게시반';
  static const String defaultCommunityId = 'default_general_board'; // You can change this if needed

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if a community is the default community
  bool isDefaultCommunity(String communityName) {
    return communityName == defaultCommunityName;
  }

  // Check if a community ID is the default community ID
  bool isDefaultCommunityById(String communityId) {
    return communityId == defaultCommunityId;
  }

  // Get the default community
  Future<Community?> getDefaultCommunity() async {
    try {
      // First try to find by specific ID
      try {
        final doc = await _firestore.collection('communities').doc(defaultCommunityId).get();
        if (doc.exists) {
          return Community.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        // If specific ID doesn't work, search by name
      }

      // Fallback: search by community name
      final snapshot = await _firestore
          .collection('communities')
          .where('communityName', isEqualTo: defaultCommunityName)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Community.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }

      // If default community doesn't exist, create it
      debugPrint('Default community not found, creating it...');
      await _createDefaultCommunity();
      
      // Try to get it again after creation
      final newSnapshot = await _firestore
          .collection('communities')
          .where('communityName', isEqualTo: defaultCommunityName)
          .limit(1)
          .get();

      if (newSnapshot.docs.isNotEmpty) {
        return Community.fromMap(newSnapshot.docs.first.data(), newSnapshot.docs.first.id);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting default community: $e');
      return null;
    }
  }

  // Create the default community if it doesn't exist
  Future<void> _createDefaultCommunity() async {
    try {
      // Use a system user ID for the creator (you can change this)
      const String systemUserId = 'system_admin';
      
      final defaultCommunityData = {
        'communityId': defaultCommunityId,
        'communityName': defaultCommunityName,
        'announcement': '실소 커뮤니티의 기본 게시판입니다. 모든 사용자가 자동으로 가입되어 자유롭게 소통할 수 있습니다.',
        'communityBanner': null,
        'creatorId': systemUserId,
        'dateAdded': FieldValue.serverTimestamp(),
        'hashtags': ['일반', '자유게시판', '종합', 'general', 'community', '실소'],
        'memberCount': 0,
        'members': <String>[],
        'posts': <String>[],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Create with specific document ID
      await _firestore
          .collection('communities')
          .doc(defaultCommunityId)
          .set(defaultCommunityData);

      debugPrint('Default community created successfully: $defaultCommunityName');
    } catch (e) {
      debugPrint('Error creating default community: $e');
      throw 'Failed to create default community: ${e.toString()}';
    }
  }

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

      // Auto-subscribe user to default community
      await _autoSubscribeToDefaultCommunity();
    } catch (e) {
      throw 'Failed to save policy agreement: ${e.toString()}';
    }
  }

  // Auto-subscribe user to default community
  Future<void> _autoSubscribeToDefaultCommunity() async {
    if (currentUserId == null) return;

    try {
      final defaultCommunity = await getDefaultCommunity();
      if (defaultCommunity == null) {
        debugPrint('Default community not found, skipping auto-subscription');
        return;
      }

      // Check if user is already a member
      if (defaultCommunity.members.contains(currentUserId)) {
        debugPrint('User already subscribed to default community');
        return;
      }

      // Add user to default community
      await joinCommunity(defaultCommunity.communityId);
      debugPrint('User auto-subscribed to default community: ${defaultCommunity.communityName}');
    } catch (e) {
      debugPrint('Error auto-subscribing to default community: $e');
      // Don't throw error as this shouldn't block user setup
    }
  }


  // Ensure user is subscribed to default community (call this on login/app start)
  Future<void> ensureDefaultCommunitySubscription() async {
    if (currentUserId == null) return;

    try {
      final defaultCommunity = await getDefaultCommunity();
      if (defaultCommunity == null) {
        debugPrint('Default community not found after creation attempt');
        return;
      }

      // Check if user is already a member
      if (!defaultCommunity.members.contains(currentUserId)) {
        await joinCommunity(defaultCommunity.communityId);
        debugPrint('User subscribed to default community on login');
      } else {
        debugPrint('User already subscribed to default community');
      }
    } catch (e) {
      debugPrint('Error ensuring default community subscription: $e');
      // Don't throw error as this shouldn't block user login
    }
  }

  // Initialize default community and ensure current user is subscribed (call this when needed)
  Future<Community?> initializeDefaultCommunity() async {
    try {
      // Get or create the default community
      final defaultCommunity = await getDefaultCommunity();
      if (defaultCommunity == null) {
        debugPrint('Failed to create or get default community');
        return null;
      }

      // Ensure current user is subscribed if logged in
      if (currentUserId != null) {
        await ensureDefaultCommunitySubscription();
      }

      return defaultCommunity;
    } catch (e) {
      debugPrint('Error initializing default community: $e');
      return null;
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

  // Get community Hot posting (Top3, Top View Posting; HOT 게시물 가져오기 (상위 3개)) 
  Future<List<Map<String, dynamic>>> getHotPosts() async {
    try {
      // 'posts' 컬렉션에서 'viewCount'를 기준으로 내림차순 정렬하여 상위 3개 문서를 가져옵니다.
      final postSnapshot = await _firestore
          .collection('posts')
          .orderBy('viewCount', descending: true)
          .limit(3)
          .get();

      if (postSnapshot.docs.isEmpty) {
        return [];
      }

      // 각 게시물의 커뮤니티 이름을 가져오기 위한 비동기 작업 목록을 생성합니다.
      final futures = postSnapshot.docs.map((postDoc) async {
        final postData = postDoc.data();
        final communityId = postData['communityId'] as String?;
        String communityName = 'Unknown'; // 기본값

        if (communityId != null) {
          try {
            final communityDoc = await _firestore
                .collection('communities')
                .doc(communityId)
                .get();
            if (communityDoc.exists) {
              communityName = communityDoc.data()?['communityName'] ?? 'Unknown';
            }
          } catch (e) {
            // 커뮤니티를 찾지 못해도 오류를 발생시키지 않고 기본값을 사용합니다.
            print('Error fetching community name for post ${postDoc.id}: $e');
          }
        }

        // UI에 필요한 데이터 형식으로 맵을 구성합니다.
        return {
          'postId': postDoc.id,
          'communityId': communityId,
          'category': communityName,
          'title': postData['title'] ?? 'No Title',
          'views': (postData['viewCount'] ?? 0).toString(),
        };
      }).toList();

      // 모든 비동기 작업을 병렬로 실행하고 결과를 기다립니다.
      return await Future.wait(futures);
    } catch (e) {
      print('Error fetching hot posts: $e');
      // 오류 발생 시 빈 리스트를 반환하여 앱이 중단되지 않도록 합니다.
      return [];
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
        final communityName = communityData['communityName'] ?? '';
        final members = List<String>.from(communityData['members'] ?? []);
        
        if (!members.contains(currentUserId)) {
          throw 'Not a member of this community';
        }

        // Check if this is the default community
        if (isDefaultCommunity(communityName) || isDefaultCommunityById(communityId)) {
          throw 'Cannot leave the default community ($defaultCommunityName)';
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

  // Get user interests for recommendations
  Future<List<String>> getUserInterests() async {
    if (currentUserId == null) return [];

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      if (!doc.exists) return [];

      final data = doc.data()!;
      final interests = List<String>.from(data['communityInterests'] ?? []);
      return interests;
    } catch (e) {
      debugPrint('Error getting user interests: $e');
      return [];
    }
  }

  // Get recommended communities based on user interests
  Future<List<Community>> getRecommendedCommunities() async {
    if (currentUserId == null) return [];

    try {
      // Get user interests
      final userInterests = await getUserInterests();
      if (userInterests.isEmpty) {
        // If no interests, return general communities
        return await _getGeneralRecommendations();
      }

      // Get all communities
      final allCommunities = await getAllCommunities();
      if (allCommunities.isEmpty) return [];

      // Filter out communities user is already a member of
      final userCommunities = await getMyCommunities();
      final userCommunityIds = userCommunities.map((c) => c.communityId).toSet();
      final availableCommunities = allCommunities
          .where((community) => !userCommunityIds.contains(community.communityId))
          .toList();

      if (availableCommunities.isEmpty) return [];

      // Calculate relevance scores and sort
      final recommendationsWithScores = availableCommunities.map((community) {
        final score = _calculateCommunityRelevanceScore(community, userInterests);
        return {'community': community, 'score': score};
      }).toList();

      // Sort by relevance score (highest first)
      recommendationsWithScores.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // Return top communities (limit to 20)
      return recommendationsWithScores
          .take(20)
          .map((item) => item['community'] as Community)
          .toList();
    } catch (e) {
      debugPrint('Error getting recommended communities: $e');
      return [];
    }
  }

  // Get general recommendations when user has no interests set
  Future<List<Community>> _getGeneralRecommendations() async {
    try {
      // Get communities sorted by member count (most popular)
      final allCommunities = await getAllCommunities();
      if (allCommunities.isEmpty) return [];

      // Filter out communities user is already a member of
      final userCommunities = await getMyCommunities();
      final userCommunityIds = userCommunities.map((c) => c.communityId).toSet();
      final availableCommunities = allCommunities
          .where((community) => !userCommunityIds.contains(community.communityId))
          .toList();

      // Sort by member count (most popular first)
      availableCommunities.sort((a, b) => b.memberCount.compareTo(a.memberCount));

      // Return top 15 popular communities
      return availableCommunities.take(15).toList();
    } catch (e) {
      debugPrint('Error getting general recommendations: $e');
      return [];
    }
  }

  // Calculate relevance score between community and user interests
  int _calculateCommunityRelevanceScore(Community community, List<String> userInterests) {
    int score = 0;
    
    // Map Korean interest categories to English hashtags for matching
    final interestKeywords = _getInterestKeywords(userInterests);
    
    // Check hashtags for matches
    for (String hashtag in community.hashtags) {
      for (String keyword in interestKeywords) {
        if (hashtag.toLowerCase().contains(keyword.toLowerCase()) ||
            keyword.toLowerCase().contains(hashtag.toLowerCase())) {
          score += 10; // High weight for hashtag matches
        }
      }
    }

    // Check community name for matches
    for (String keyword in interestKeywords) {
      if (community.communityName.toLowerCase().contains(keyword.toLowerCase())) {
        score += 5; // Medium weight for name matches
      }
    }

    // Check announcement for matches
    if (community.announcement != null) {
      for (String keyword in interestKeywords) {
        if (community.announcement!.toLowerCase().contains(keyword.toLowerCase())) {
          score += 2; // Lower weight for announcement matches
        }
      }
    }

    // Bonus for active communities (more members = more activity)
    if (community.memberCount > 50) score += 5;
    if (community.memberCount > 100) score += 5;
    
    // Bonus for recent activity
    final daysSinceCreation = DateTime.now().difference(community.dateAdded).inDays;
    if (daysSinceCreation < 30) score += 3; // Recent communities get bonus

    return score;
  }

  // Get English keywords for Korean interest categories for matching
  List<String> _getInterestKeywords(List<String> userInterests) {
    const Map<String, List<String>> interestToKeywords = {
      'business': ['business', 'entrepreneur', 'startup', 'self-employed', '자영업', '사업', '비즈니스'],
      'startup': ['startup', 'tech', 'innovation', 'entrepreneur', '스타트업', '창업', '기술'],
      'career_change': ['career', 'job', 'work', 'employment', 'transition', '이직', '직장', '커리어'],
      'resignation': ['quit', 'resignation', 'career', 'job', '퇴사', '이직', '직장'],
      'employment': ['job', 'employment', 'career', 'hiring', 'work', '취업', '취직', '직장'],
      'study': ['study', 'education', 'learning', 'academic', 'school', '학업', '공부', '교육'],
      'contest': ['contest', 'competition', 'award', 'challenge', '공모전', '대회', '경진'],
      'mental_care': ['mental', 'health', 'wellness', 'psychology', 'therapy', '멘탈', '정신건강', '힐링'],
      'relationships': ['relationship', 'friendship', 'social', 'people', '인간관계', '친구', '연애'],
      'daily_life': ['daily', 'life', 'lifestyle', 'routine', '일상', '라이프', '생활'],
      'humor': ['humor', 'funny', 'comedy', 'joke', 'entertainment', '유머', '재미', '웃긴'],
      'health': ['health', 'fitness', 'wellness', 'medical', 'exercise', '건강', '운동', '의료'],
    };

    List<String> keywords = [];
    for (String interest in userInterests) {
      keywords.addAll(interestToKeywords[interest] ?? [interest]);
    }
    return keywords;
  }
}