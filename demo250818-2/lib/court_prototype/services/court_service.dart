import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/court_chat_message.dart';
import '../models/court_session_model.dart';
import '../config/court_config.dart';
import 'case_service.dart';
import '../models/case_model.dart';

// Court service for managing court sessions created from promoted cases
class CourtService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CaseService _caseService = CaseService();

  // Collection references
  CollectionReference get _courtsCollection => _firestore.collection('courts');
  CollectionReference get _courtChatsCollection => _firestore.collection('court_chats');

  // === COURT SESSION MANAGEMENT ===

  // Create court session from promoted case
  Future<String> createCourtSessionFromCase({
    required String caseId,
    required CaseModel caseModel,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final courtSessionData = {
        'title': caseModel.title,
        'description': caseModel.description,
        'caseId': caseId,
        'category': caseModel.category,
        'dateCreated': FieldValue.serverTimestamp(),
        'currentLiveMembers': 0, // Will increment as users join
        'guiltyVotes': caseModel.guiltyVotes,
        'notGuiltyVotes': caseModel.notGuiltyVotes,
        'resultWin': null, // Will be set when session ends
        'timeLeft': CourtSystemConfig.getSessionDuration().inMilliseconds,
        'dateEnded': null,
        'creatorId': caseModel.creatorId,
        'isLive': true,
        'participants': <String>[], // Users who join the session
        'initialVotingResults': {
          'guiltyVotes': caseModel.guiltyVotes,
          'notGuiltyVotes': caseModel.notGuiltyVotes,
          'guiltyPercentage': caseModel.guiltyPercentage,
          'totalVotes': caseModel.totalVotes,
        },
        'metadata': {
          'fromCase': true,
          'originalCaseId': caseId,
          'promotedAt': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _courtsCollection.add(courtSessionData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create court session from case: ${e.toString()}');
    }
  }

  // Get all live court sessions
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
          sessions.add(session);
        }
      }
      
      // Sort by creation date (newest first)
      sessions.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      return sessions;
    });
  }

  // Get completed court sessions
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

        // If this was from a case, update the case status to completed
        final caseId = data['caseId'];
        if (caseId != null) {
          await _caseService.completeCase(caseId, resultWin);
        }
      });
    } catch (e) {
      throw Exception('Failed to end court session: ${e.toString()}');
    }
  }

  // Check if session should be auto-ended
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

        // If this was from a case, update the case status to completed
        final caseId = data['caseId'];
        if (caseId != null) {
          await _caseService.completeCase(caseId, resultWin);
        }
      });
    } catch (e) {
      debugPrint('Auto-end session failed: ${e.toString()}');
    }
  }

  // === CHAT FUNCTIONALITY ===

  // Send a chat message to a court session
  Future<String> sendChatMessage({
    required String courtId,
    required String message,
    required ChatMessageType messageType,
    bool isSystemMessage = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if court session exists
      final courtDoc = await _courtsCollection.doc(courtId).get();
      if (!courtDoc.exists) {
        throw Exception('Court session not found');
      }

      // Auto-join user if not system message
      if (messageType != ChatMessageType.system) {
        await joinCourtSession(courtId);
      }

      // Get user display name
      String senderName = user.displayName ?? user.email ?? 'Anonymous';

      final chatData = {
        'courtId': courtId,
        'senderId': user.uid,
        'senderName': senderName,
        'message': message.trim(),
        'messageType': messageType.name,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isSystemMessage': isSystemMessage,
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

  // Update a chat message
  Future<void> updateChatMessage(String messageId, String newMessage) async {
    try {
      await _courtChatsCollection.doc(messageId).update({
        'message': newMessage.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update message: ${e.toString()}');
    }
  }

  // Delete a chat message
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

  // Get live vote counts based on each user's most recent message
  Future<Map<String, int>> getLiveVoteCounts(String courtId) async {
    try {
      final snapshot = await _courtChatsCollection
          .where('courtId', isEqualTo: courtId)
          .where('isDeleted', isEqualTo: false)
          .where('isSystemMessage', isEqualTo: false)
          .get();

      // Map to track each user's most recent message
      final Map<String, CourtChatMessage> latestUserMessages = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final message = CourtChatMessage.fromFirestore(doc.id, data);
        
        // Keep only the latest message per user
        final currentLatest = latestUserMessages[message.senderId];
        if (currentLatest == null || message.timestamp.isAfter(currentLatest.timestamp)) {
          latestUserMessages[message.senderId] = message;
        }
      }

      // Count votes based on latest messages
      int guiltyVotes = 0;
      int notGuiltyVotes = 0;

      for (final message in latestUserMessages.values) {
        switch (message.messageType) {
          case ChatMessageType.guilty:
            guiltyVotes++;
            break;
          case ChatMessageType.notGuilty:
            notGuiltyVotes++;
            break;
          case ChatMessageType.system:
            // System messages don't count as votes
            break;
        }
      }

      return {
        'guiltyVotes': guiltyVotes,
        'notGuiltyVotes': notGuiltyVotes,
        'totalVotes': guiltyVotes + notGuiltyVotes,
      };
    } catch (e) {
      throw Exception('Failed to get live vote counts: ${e.toString()}');
    }
  }

  // Get real-time stream of live vote counts
  Stream<Map<String, int>> getLiveVoteCountsStream(String courtId) {
    return _courtChatsCollection
        .where('courtId', isEqualTo: courtId)
        .where('isDeleted', isEqualTo: false)
        .where('isSystemMessage', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      // Map to track each user's most recent message
      final Map<String, CourtChatMessage> latestUserMessages = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final message = CourtChatMessage.fromFirestore(doc.id, data);
        
        // Keep only the latest message per user
        final currentLatest = latestUserMessages[message.senderId];
        if (currentLatest == null || message.timestamp.isAfter(currentLatest.timestamp)) {
          latestUserMessages[message.senderId] = message;
        }
      }

      // Count votes based on latest messages
      int guiltyVotes = 0;
      int notGuiltyVotes = 0;

      for (final message in latestUserMessages.values) {
        switch (message.messageType) {
          case ChatMessageType.guilty:
            guiltyVotes++;
            break;
          case ChatMessageType.notGuilty:
            notGuiltyVotes++;
            break;
          case ChatMessageType.system:
            // System messages don't count as votes
            break;
        }
      }

      final totalVotes = guiltyVotes + notGuiltyVotes;
      
      // Print to terminal for debugging
      debugPrint('🗳️ Live Vote Update for Court $courtId:');
      debugPrint('   Guilty (반대): $guiltyVotes votes');
      debugPrint('   Not Guilty (찬성): $notGuiltyVotes votes');
      debugPrint('   Total Active Voters: $totalVotes');
      if (totalVotes > 0) {
        final guiltyPercentage = (guiltyVotes / totalVotes * 100).toStringAsFixed(1);
        final notGuiltyPercentage = (notGuiltyVotes / totalVotes * 100).toStringAsFixed(1);
        debugPrint('   Percentage: Guilty $guiltyPercentage% | Not Guilty $notGuiltyPercentage%');
      }
      debugPrint('   ---');

      return {
        'guiltyVotes': guiltyVotes,
        'notGuiltyVotes': notGuiltyVotes,
        'totalVotes': totalVotes,
      };
    });
  }

  // Get chat message counts by type for a court session (legacy method)
  Future<Map<ChatMessageType, int>> getChatMessageCounts(String courtId) async {
    try {
      final snapshot = await _courtChatsCollection
          .where('courtId', isEqualTo: courtId)
          .where('isDeleted', isEqualTo: false)
          .get();

      int guiltyCount = 0;
      int notGuiltyCount = 0;
      int systemCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final messageType = data['messageType'] ?? 'notGuilty';
        
        switch (messageType) {
          case 'guilty':
            guiltyCount++;
            break;
          case 'notGuilty':
            notGuiltyCount++;
            break;
          case 'system':
            systemCount++;
            break;
        }
      }

      return {
        ChatMessageType.guilty: guiltyCount,
        ChatMessageType.notGuilty: notGuiltyCount,
        ChatMessageType.system: systemCount,
      };
    } catch (e) {
      throw Exception('Failed to get message counts: ${e.toString()}');
    }
  }
}