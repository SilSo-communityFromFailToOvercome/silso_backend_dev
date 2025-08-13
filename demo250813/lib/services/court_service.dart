import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../court_prototype/add_court.dart';
import '../models/court_chat_message.dart';

class CourtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference for court sessions
  CollectionReference get _courtsCollection => _firestore.collection('courts');
  
  // Collection reference for court chat messages
  CollectionReference get _courtChatsCollection => _firestore.collection('court_chats');

  // Create a new court session
  Future<String> createCourtSession({
    required String title,
    required String description,
    String category = 'General',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final courtData = {
        'title': title,
        'description': description,
        'dateCreated': FieldValue.serverTimestamp(), // Use server timestamp for synchronization
        'currentLiveMembers': 1, // Creator is first member
        'guiltyVotes': 0,
        'notGuiltyVotes': 0,
        'resultWin': null, // null until session ends
        'sessionDurationMinutes': 2, // Session duration in minutes for testing
        'dateEnded': null, // null until session ends
        'category': category,
        'creatorId': user.uid,
        'isLive': true,
        'participants': [user.uid], // Creator is first participant
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _courtsCollection.add(courtData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create court session: ${e.toString()}');
    }
  }

  // Get all live court sessions (automatically filters out expired ones)
  Stream<List<CourtSessionData>> getLiveCourtSessions() {
    return _courtsCollection
        .where('isLive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final sessions = <CourtSessionData>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final session = CourtSessionData.fromFirestore(doc.id, data);
        
        // Check if session has expired
        if (session.timeLeft <= Duration.zero) {
          // Automatically end expired session
          await _autoEndSession(session.id);
        } else {
          // Only include non-expired sessions
          sessions.add(session);
        }
      }
      
      // Sort in memory to avoid needing a composite index
      sessions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      return sessions;
    });
  }

  // Get all completed court sessions (for history)
  Stream<List<CourtSessionData>> getCompletedCourtSessions() {
    return _courtsCollection
        .where('isLive', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtSessionData.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by end date (most recent first)
      sessions.sort((a, b) {
        final aDate = a.dateEnded ?? a.dateCreated;
        final bDate = b.dateEnded ?? b.dateCreated;
        return bDate.compareTo(aDate);
      });
      return sessions;
    });
  }

  // Get a specific court session
  Future<CourtSessionData?> getCourtSession(String courtId) async {
    try {
      final doc = await _courtsCollection.doc(courtId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtSessionData.fromFirestore(doc.id, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get court session: ${e.toString()}');
    }
  }

  // Get real-time updates for a specific court session
  Stream<CourtSessionData?> getCourtSessionStream(String courtId) {
    return _courtsCollection.doc(courtId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return CourtSessionData.fromFirestore(snapshot.id, data);
      }
      return null;
    });
  }

  // Join a court session
  Future<void> joinCourtSession(String courtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Court session not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (!participants.contains(user.uid)) {
          participants.add(user.uid);
          transaction.update(docRef, {
            'participants': participants,
            'currentLiveMembers': participants.length,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to join court session: ${e.toString()}');
    }
  }

  // Leave a court session
  Future<void> leaveCourtSession(String courtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Court session not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (participants.contains(user.uid)) {
          participants.remove(user.uid);
          transaction.update(docRef, {
            'participants': participants,
            'currentLiveMembers': participants.length,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to leave court session: ${e.toString()}');
    }
  }

  // Cast vote before joining session (used in dialog)
  Future<void> castVote({
    required String courtId,
    required bool isGuilty,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Court session not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final guiltyVotes = data['guiltyVotes'] ?? 0;
        final notGuiltyVotes = data['notGuiltyVotes'] ?? 0;
        final participants = List<String>.from(data['participants'] ?? []);

        // Add user to participants if not already there
        if (!participants.contains(user.uid)) {
          participants.add(user.uid);
        }

        if (isGuilty) {
          transaction.update(docRef, {
            'guiltyVotes': guiltyVotes + 1,
            'participants': participants,
            'currentLiveMembers': participants.length,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(docRef, {
            'notGuiltyVotes': notGuiltyVotes + 1,
            'participants': participants,
            'currentLiveMembers': participants.length,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to cast vote: ${e.toString()}');
    }
  }

  // Vote in a court session (legacy method, kept for compatibility)
  Future<void> voteInCourtSession(String courtId, bool isGuiltyVote) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Court session not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        
        if (!participants.contains(user.uid)) {
          throw Exception('You must join the session to vote');
        }

        // Check if user has already voted (you might want to track individual votes)
        final guiltyVotes = data['guiltyVotes'] ?? 0;
        final notGuiltyVotes = data['notGuiltyVotes'] ?? 0;

        if (isGuiltyVote) {
          transaction.update(docRef, {
            'guiltyVotes': guiltyVotes + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(docRef, {
            'notGuiltyVotes': notGuiltyVotes + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to vote in court session: ${e.toString()}');
    }
  }

  // End a court session
  Future<void> endCourtSession(String courtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Court session not found');
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final creatorId = data['creatorId'];
        
        // Only creator can end the session
        if (creatorId != user.uid) {
          throw Exception('Only the creator can end the session');
        }

        final guiltyVotes = data['guiltyVotes'] ?? 0;
        final notGuiltyVotes = data['notGuiltyVotes'] ?? 0;
        
        String? resultWin;
        if (guiltyVotes > notGuiltyVotes) {
          resultWin = 'guilty';
        } else if (notGuiltyVotes > guiltyVotes) {
          resultWin = 'not_guilty';
        } else {
          resultWin = 'tie';
        }

        transaction.update(docRef, {
          'isLive': false,
          'dateEnded': FieldValue.serverTimestamp(),
          'resultWin': resultWin,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to end court session: ${e.toString()}');
    }
  }

  // Check if session should be auto-ended (called periodically)
  Future<void> checkAndEndExpiredSession(String courtId) async {
    try {
      final session = await getCourtSession(courtId);
      if (session != null && session.isLive && session.timeLeft <= Duration.zero) {
        await _autoEndSession(courtId);
      }
    } catch (e) {
      throw Exception('Failed to check session expiry: ${e.toString()}');
    }
  }

  // Auto-end session when time runs out
  Future<void> _autoEndSession(String courtId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _courtsCollection.doc(courtId);
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final guiltyVotes = data['guiltyVotes'] ?? 0;
        final notGuiltyVotes = data['notGuiltyVotes'] ?? 0;
        
        String? resultWin;
        if (guiltyVotes > notGuiltyVotes) {
          resultWin = 'guilty';
        } else if (notGuiltyVotes > guiltyVotes) {
          resultWin = 'not_guilty';
        } else {
          resultWin = 'tie';
        }

        transaction.update(docRef, {
          'isLive': false,
          'dateEnded': FieldValue.serverTimestamp(),
          'resultWin': resultWin,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      // Log error but don't throw to avoid breaking calling function
      debugPrint('Auto-end session failed: ${e.toString()}');
    }
  }

  // Get user's created court sessions
  Stream<List<CourtSessionData>> getUserCreatedSessions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _courtsCollection
        .where('creatorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtSessionData.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort in memory to avoid needing a composite index
      sessions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      return sessions;
    });
  }

  // Get user's participated court sessions
  Stream<List<CourtSessionData>> getUserParticipatedSessions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _courtsCollection
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtSessionData.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort in memory to avoid needing a composite index
      sessions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      return sessions;
    });
  }

  // Delete a court session (only creator can delete)
  Future<void> deleteCourtSession(String courtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _courtsCollection.doc(courtId).get();
      if (!doc.exists) {
        throw Exception('Court session not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final creatorId = data['creatorId'];
      
      if (creatorId != user.uid) {
        throw Exception('Only the creator can delete the session');
      }

      await _courtsCollection.doc(courtId).delete();
    } catch (e) {
      throw Exception('Failed to delete court session: ${e.toString()}');
    }
  }

  // === CHAT FUNCTIONALITY ===

  // Send a chat message to a court session
  Future<String> sendChatMessage({
    required String courtId,
    required String message,
    required ChatMessageType messageType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user is participant in the court session
      final courtDoc = await _courtsCollection.doc(courtId).get();
      if (!courtDoc.exists) {
        throw Exception('Court session not found');
      }

      final courtData = courtDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(courtData['participants'] ?? []);
      
      if (!participants.contains(user.uid)) {
        throw Exception('You must join the session to send messages');
      }

      // Get user display name (fallback to email or uid)
      String senderName = user.displayName ?? user.email ?? 'Anonymous';

      final chatData = {
        'courtId': courtId,
        'senderId': user.uid,
        'senderName': senderName,
        'message': message.trim(),
        'messageType': messageType.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _courtChatsCollection.add(chatData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  // Get chat messages for a court session
  Stream<List<CourtChatMessage>> getCourtChatMessages(String courtId) {
    return _courtChatsCollection
        .where('courtId', isEqualTo: courtId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtChatMessage.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by timestamp (oldest first for chat display)
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Get chat messages count by type for a court session
  Future<Map<ChatMessageType, int>> getChatMessageCounts(String courtId) async {
    try {
      final snapshot = await _courtChatsCollection
          .where('courtId', isEqualTo: courtId)
          .where('isDeleted', isEqualTo: false)
          .get();

      int guiltyCount = 0;
      int notGuiltyCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final messageType = data['messageType'] ?? 'notGuilty';
        
        if (messageType == 'guilty') {
          guiltyCount++;
        } else {
          notGuiltyCount++;
        }
      }

      return {
        ChatMessageType.guilty: guiltyCount,
        ChatMessageType.notGuilty: notGuiltyCount,
      };
    } catch (e) {
      throw Exception('Failed to get message counts: ${e.toString()}');
    }
  }

  // Delete a chat message (only sender or court creator can delete)
  Future<void> deleteChatMessage(String messageId, String courtId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the message to check ownership
      final messageDoc = await _courtChatsCollection.doc(messageId).get();
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }

      final messageData = messageDoc.data() as Map<String, dynamic>;
      final messageSenderId = messageData['senderId'];

      // Get court data to check if user is creator
      final courtDoc = await _courtsCollection.doc(courtId).get();
      if (!courtDoc.exists) {
        throw Exception('Court session not found');
      }

      final courtData = courtDoc.data() as Map<String, dynamic>;
      final courtCreatorId = courtData['creatorId'];

      // Only message sender or court creator can delete
      if (messageSenderId != user.uid && courtCreatorId != user.uid) {
        throw Exception('You can only delete your own messages or messages in your court');
      }

      // Soft delete the message
      await _courtChatsCollection.doc(messageId).update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }

  // Get user's recent chat activity in court sessions
  Stream<List<CourtChatMessage>> getUserRecentChatActivity({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _courtChatsCollection
        .where('senderId', isEqualTo: user.uid)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CourtChatMessage.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit
      return messages.take(limit).toList();
    });
  }
}