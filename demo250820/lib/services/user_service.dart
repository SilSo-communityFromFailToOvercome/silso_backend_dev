import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/blocked_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for blocked user IDs to improve performance
  static List<String>? _cachedBlockedUserIds;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Block a user by their ID
  Future<void> blockUser(String userIdToBlock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    if (currentUserId == userIdToBlock) {
      throw Exception('Cannot block yourself');
    }
    
    try {
      // Get the user data to block
      final userToBlockDoc = await _firestore
          .collection('users')
          .doc(userIdToBlock)
          .get();
      
      if (!userToBlockDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userToBlockDoc.data()!;
      
      // Create blocked user data
      final blockedUserData = {
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedUserUsername': userData['username'] ?? '',
        'blockedUserProfileImage': userData['profileImage'] ?? '',
      };
      
      // Add to blocked users subcollection
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userIdToBlock)
          .set(blockedUserData);
      
      // Clear cache to force refresh
      _clearCache();
      
    } catch (e) {
      throw Exception('Failed to block user: ${e.toString()}');
    }
  }

  /// Unblock a user by their ID
  Future<void> unblockUser(String userIdToUnblock) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userIdToUnblock)
          .delete();
      
      // Clear cache to force refresh
      _clearCache();
      
    } catch (e) {
      throw Exception('Failed to unblock user: ${e.toString()}');
    }
  }

  /// Get list of blocked user IDs with caching
  Future<List<String>> getBlockedUserIds() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    // Check if cache is still valid
    if (_cachedBlockedUserIds != null && 
        _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry) {
      return _cachedBlockedUserIds!;
    }

    // Refresh cache
    try {
      final blockedIds = await _fetchBlockedUserIdsFromFirestore();
      _cachedBlockedUserIds = blockedIds;
      _lastCacheUpdate = DateTime.now();
      
      return blockedIds;
    } catch (e) {
      // Return empty list on error, but don't cache the error
      return [];
    }
  }

  /// Fetch blocked user IDs from Firestore (internal method)
  Future<List<String>> _fetchBlockedUserIdsFromFirestore() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    final snapshot = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .get();
    
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  /// Get detailed list of blocked users
  Future<List<BlockedUser>> getBlockedUsers() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .orderBy('blockedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BlockedUser.fromFirestore(doc.id, data);
      }).toList();
      
    } catch (e) {
      throw Exception('Failed to get blocked users: ${e.toString()}');
    }
  }

  /// Get real-time stream of blocked users
  Stream<List<BlockedUser>> getBlockedUsersStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blockedUsers')
        .orderBy('blockedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BlockedUser.fromFirestore(doc.id, data);
      }).toList();
    }).handleError((error) {
      // Handle stream errors gracefully
      print('Error in blocked users stream: $error');
      return <BlockedUser>[];
    });
  }

  /// Check if a specific user is blocked
  Future<bool> isUserBlocked(String userId) async {
    final blockedUserIds = await getBlockedUserIds();
    return blockedUserIds.contains(userId);
  }

  /// Get users who blocked me (bidirectional blocking)
  Future<List<String>> getUsersWhoBlockedMe() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collectionGroup('blockedUsers')
          .where(FieldPath.documentId, isEqualTo: currentUserId)
          .get();
      
      return snapshot.docs.map((doc) => 
          doc.reference.parent.parent!.id).toList();
          
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  /// Get all blocking relationships (users I blocked + users who blocked me)
  Future<List<String>> getAllBlockingRelationships() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return [];
    
    try {
      // Get users I blocked
      final iBlocked = await getBlockedUserIds();
      
      // Get users who blocked me
      final whoBlockedMe = await getUsersWhoBlockedMe();
      
      // Combine and remove duplicates
      final allBlocked = <String>{...iBlocked, ...whoBlockedMe}.toList();
      
      return allBlocked;
      
    } catch (e) {
      // Fallback to just users I blocked
      return await getBlockedUserIds();
    }
  }

  /// Clear the cache (call when blocking/unblocking users)
  void _clearCache() {
    _cachedBlockedUserIds = null;
    _lastCacheUpdate = null;
  }

  /// Force refresh the cache
  Future<void> refreshCache() async {
    _clearCache();
    await getBlockedUserIds();
  }

  /// Check if current user is authenticated
  bool isAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }
}