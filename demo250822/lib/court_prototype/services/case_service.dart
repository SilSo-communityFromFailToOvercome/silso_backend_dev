import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/case_model.dart';
import '../config/court_config.dart';
import '../models/ai_conclusion_model.dart';
import '../models/court_chat_message.dart';

class CaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _casesCollection => _firestore.collection('cases');
  CollectionReference get _caseVotesCollection => _firestore.collection('case_votes');
  CollectionReference get _promotionQueueCollection => _firestore.collection('promotion_queue');
  CollectionReference get _courtsCollection => _firestore.collection('courts');
  CollectionReference get _aiConclusionsCollection => _firestore.collection('ai_conclusions');

  // === CASE CREATION AND MANAGEMENT ===

  // Create a new case for voting
  Future<String> createCase({
    required String title,
    required String description,
    String category = 'General',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user has reached daily case creation limit
      final userCasesToday = await _getUserCasesCreatedToday(user.uid);
      if (userCasesToday >= CourtSystemConfig.maxCasesCreatedPerDay) {
        throw Exception('Daily case creation limit reached (${CourtSystemConfig.maxCasesCreatedPerDay})');
      }

      // Check if new case submission is disabled
      if (CourtSystemConfig.newCaseSubmissionDisabled) {
        throw Exception('Case submission is temporarily disabled');
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: CourtSystemConfig.caseExpiryDays));

      final caseData = {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'creatorId': user.uid,
        'creatorName': user.displayName ?? user.email ?? 'Anonymous',
        'createdAt': Timestamp.fromDate(now),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': CaseStatus.voting.name,
        'guiltyVotes': 0,
        'notGuiltyVotes': 0,
        'controversyScore': 0.0,
        'promotionPriority': 0.0,
        'voters': [],
        'metadata': {
          'version': '1.0',
          'platform': defaultTargetPlatform.name,
        },
        'promotedAt': null,
        'courtSessionId': null,
        'queuePosition': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _casesCollection.add(caseData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create case: ${e.toString()}');
    }
  }

  // Get user's cases created today
  Future<int> _getUserCasesCreatedToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Use single where clause to avoid composite index requirement
    final snapshot = await _casesCollection
        .where('creatorId', isEqualTo: userId)
        .get();

    // Filter by date in memory to avoid composite index
    final todayCases = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay);
    }).toList();

    return todayCases.length;
  }

  // === VOTING SYSTEM ===

  // Cast a vote on a case
  Future<void> voteOnCase({
    required String caseId,
    required CaseVoteType voteType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if voting is temporarily disabled
      if (CourtSystemConfig.votingTemporarilyDisabled) {
        throw Exception('Voting is temporarily disabled');
      }

      // Check user's daily voting limit
      final userVotesToday = await _getUserVotesToday(user.uid);
      if (userVotesToday >= CourtSystemConfig.votesPerUserPerDay) {
        throw Exception('Daily voting limit reached (${CourtSystemConfig.votesPerUserPerDay})');
      }

      await _firestore.runTransaction((transaction) async {
        // Get case document
        final caseDocRef = _casesCollection.doc(caseId);
        final caseSnapshot = await transaction.get(caseDocRef);
        
        if (!caseSnapshot.exists) {
          throw Exception('Case not found');
        }

        final caseData = caseSnapshot.data() as Map<String, dynamic>;
        final caseModel = CaseModel.fromFirestore(caseId, caseData);

        // Validate case state
        if (caseModel.status != CaseStatus.voting) {
          throw Exception('Case is not in voting phase');
        }

        if (caseModel.isExpired) {
          throw Exception('Case voting period has expired');
        }

        // Check if user already voted
        if (caseModel.hasUserVoted(user.uid)) {
          throw Exception('You have already voted on this case');
        }

        // Update case with new vote
        final newVoters = List<String>.from(caseModel.voters)..add(user.uid);
        final newGuiltyVotes = voteType == CaseVoteType.guilty 
            ? caseModel.guiltyVotes + 1 
            : caseModel.guiltyVotes;
        final newNotGuiltyVotes = voteType == CaseVoteType.notGuilty 
            ? caseModel.notGuiltyVotes + 1 
            : caseModel.notGuiltyVotes;
        
        final totalVotes = newGuiltyVotes + newNotGuiltyVotes;
        final guiltyPercentage = totalVotes > 0 ? (newGuiltyVotes / totalVotes) * 100 : 0.0;
        final controversyScore = CourtSystemConfig.calculateControversyScore(guiltyPercentage);
        final promotionPriority = CourtSystemConfig.calculatePromotionPriority(
          totalVotes, guiltyPercentage, caseModel.createdAt);

        // Check if case now meets promotion criteria
        final meetsPromotion = CourtSystemConfig.meetsPromotionCriteria(totalVotes, guiltyPercentage);
        final newStatus = meetsPromotion ? CaseStatus.qualified : CaseStatus.voting;

        // Update case document
        transaction.update(caseDocRef, {
          'guiltyVotes': newGuiltyVotes,
          'notGuiltyVotes': newNotGuiltyVotes,
          'controversyScore': controversyScore,
          'promotionPriority': promotionPriority,
          'voters': newVoters,
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create vote record
        final voteData = CaseVote(
          id: '', // Will be set by Firestore
          caseId: caseId,
          userId: user.uid,
          userName: user.displayName ?? user.email ?? 'Anonymous',
          voteType: voteType,
          createdAt: DateTime.now(),
          deviceInfo: defaultTargetPlatform.name,
          ipAddress: null, // Could be implemented for fraud detection
        );

        await _caseVotesCollection.add(voteData.toMap());

        // If case qualified, add to promotion queue
        if (meetsPromotion) {
          await _addToPromotionQueue(caseId, promotionPriority);
        }
      });
    } catch (e) {
      throw Exception('Failed to vote: ${e.toString()}');
    }
  }

  // Get user's votes today
  Future<int> _getUserVotesToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Use single where clause to avoid composite index requirement
    final snapshot = await _caseVotesCollection
        .where('userId', isEqualTo: userId)
        .get();

    // Filter by date in memory to avoid composite index
    final todayVotes = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.isAfter(startOfDay) && createdAt.isBefore(endOfDay);
    }).toList();

    return todayVotes.length;
  }

  // === QUEUE MANAGEMENT ===

  // Add case to promotion queue
  Future<void> _addToPromotionQueue(String caseId, double priority) async {
    try {
      // Check current queue size (no orderBy needed to avoid index requirement)
      final queueSnapshot = await _promotionQueueCollection.get();

      if (queueSnapshot.docs.length >= CourtSystemConfig.maxQueueSize) {
        throw Exception('Promotion queue is full');
      }

      // Calculate new position
      final newPosition = queueSnapshot.docs.length + 1;
      final estimatedPromotionTime = _calculateEstimatedPromotionTime(newPosition);

      final queueItem = QueueItem(
        caseId: caseId,
        position: newPosition,
        queuedAt: DateTime.now(),
        priority: priority,
        estimatedPromotionTime: estimatedPromotionTime,
      );

      await _promotionQueueCollection.doc(caseId).set(queueItem.toMap());

      // Update case status and queue position
      await _casesCollection.doc(caseId).update({
        'status': CaseStatus.queued.name,
        'queuePosition': newPosition,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check if we can promote immediately
      await _processPromotionQueue();
    } catch (e) {
      throw Exception('Failed to add to promotion queue: ${e.toString()}');
    }
  }

  // Calculate estimated promotion time based on queue position
  DateTime _calculateEstimatedPromotionTime(int position) {
    final averageSessionDuration = CourtSystemConfig.getSessionDuration();
    final estimatedWaitTime = averageSessionDuration * (position - 1);
    return DateTime.now().add(estimatedWaitTime);
  }

  // Process promotion queue and promote cases when slots are available
  Future<void> _processPromotionQueue() async {
    try {
      // Get current active court sessions
      final activeSessionsSnapshot = await _courtsCollection
          .where('isLive', isEqualTo: true)
          .get();

      final activeSessions = activeSessionsSnapshot.docs.length;
      final maxSessions = CourtSystemConfig.getMaxConcurrentSessions();
      final availableSlots = maxSessions - activeSessions;

      if (availableSlots <= 0) {
        return; // No available slots
      }

      // Get next cases in queue
      final queueSnapshot = await _promotionQueueCollection.get();

      // Sort by position in memory and take only needed slots to avoid index requirement
      final queueDocs = queueSnapshot.docs.toList();
      queueDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aPosition = (aData['position'] as num?)?.toInt() ?? 0;
        final bPosition = (bData['position'] as num?)?.toInt() ?? 0;
        return aPosition.compareTo(bPosition); // Ascending order (lowest position first)
      });

      // Take only the number of slots available
      final nextCases = queueDocs.take(availableSlots);

      for (final queueDoc in nextCases) {
        await _promoteCase(queueDoc.id);
      }
    } catch (e) {
      debugPrint('Failed to process promotion queue: ${e.toString()}');
    }
  }

  // Promote a case to active court session
  Future<void> _promoteCase(String caseId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Get case data
        final caseDocRef = _casesCollection.doc(caseId);
        final caseSnapshot = await transaction.get(caseDocRef);
        
        if (!caseSnapshot.exists) {
          throw Exception('Case not found');
        }

        final caseData = caseSnapshot.data() as Map<String, dynamic>;
        final caseModel = CaseModel.fromFirestore(caseId, caseData);

        // Create court session
        final courtSessionData = {
          'title': caseModel.title,
          'description': caseModel.description,
          'dateCreated': FieldValue.serverTimestamp(),
          'currentLiveMembers': 0,
          'guiltyVotes': caseModel.guiltyVotes,
          'notGuiltyVotes': caseModel.notGuiltyVotes,
          'resultWin': null,
          'timeLeft': CourtSystemConfig.getSessionDuration().inMilliseconds,
          'dateEnded': null,
          'category': caseModel.category,
          'creatorId': caseModel.creatorId,
          'isLive': true,
          'participants': [],
          'caseId': caseId, // Link back to original case
          'initialVotingResults': {
            'guiltyVotes': caseModel.guiltyVotes,
            'notGuiltyVotes': caseModel.notGuiltyVotes,
            'guiltyPercentage': caseModel.guiltyPercentage,
            'totalVotes': caseModel.totalVotes,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final courtRef = await _courtsCollection.add(courtSessionData);

        // Update case status
        transaction.update(caseDocRef, {
          'status': CaseStatus.promoted.name,
          'promotedAt': FieldValue.serverTimestamp(),
          'courtSessionId': courtRef.id,
          'queuePosition': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Remove from promotion queue
        await _promotionQueueCollection.doc(caseId).delete();

        // Reorder remaining queue
        await _reorderQueue();
      });
    } catch (e) {
      throw Exception('Failed to promote case: ${e.toString()}');
    }
  }

  // Reorder queue positions after promotion
  Future<void> _reorderQueue() async {
    try {
      final queueSnapshot = await _promotionQueueCollection.get();

      // Sort by priority in memory to avoid index requirement
      final queueDocs = queueSnapshot.docs.toList();
      queueDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aPriority = (aData['priority'] as num?)?.toDouble() ?? 0.0;
        final bPriority = (bData['priority'] as num?)?.toDouble() ?? 0.0;
        return bPriority.compareTo(aPriority); // Descending order
      });

      final batch = _firestore.batch();
      
      for (int i = 0; i < queueDocs.length; i++) {
        final doc = queueDocs[i];
        final newPosition = i + 1;
        
        batch.update(doc.reference, {
          'position': newPosition,
          'estimatedPromotionTime': Timestamp.fromDate(_calculateEstimatedPromotionTime(newPosition)),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update case queue position
        batch.update(_casesCollection.doc(doc.id), {
          'queuePosition': newPosition,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to reorder queue: ${e.toString()}');
    }
  }

  // === DATA RETRIEVAL ===

  // Get all active voting cases
  Stream<List<CaseModel>> getActiveVotingCases() {
    return _casesCollection
        .where('status', isEqualTo: CaseStatus.voting.name)
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by promotion priority and recency
      cases.sort((a, b) {
        final priorityComparison = b.promotionPriority.compareTo(a.promotionPriority);
        if (priorityComparison != 0) return priorityComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
      
      return cases;
    });
  }

  // Get cases in promotion queue
  Stream<List<CaseModel>> getQueuedCases() {
    return _casesCollection
        .where('status', isEqualTo: CaseStatus.queued.name)
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by queue position in memory to avoid composite index
      cases.sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
      return cases;
    });
  }

  // Get promoted cases (active court sessions)
  Stream<List<CaseModel>> getPromotedCases() {
    return _casesCollection
        .where('status', isEqualTo: CaseStatus.promoted.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
    });
  }

  // Get completed cases
  Stream<List<CaseModel>> getCompletedCases() {
    return _casesCollection
        .where('status', isEqualTo: CaseStatus.completed.name)
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by promoted date in memory to avoid composite index
      cases.sort((a, b) {
        final aDate = a.promotedAt ?? a.createdAt;
        final bDate = b.promotedAt ?? b.createdAt;
        return bDate.compareTo(aDate); // Most recent first
      });
      return cases;
    });
  }

  // Get a specific case
  Future<CaseModel?> getCase(String caseId) async {
    try {
      final doc = await _casesCollection.doc(caseId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get case: ${e.toString()}');
    }
  }

  // Get user's created cases
  Stream<List<CaseModel>> getUserCreatedCases() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _casesCollection
        .where('creatorId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by creation date in memory to avoid composite index
      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cases;
    });
  }

  // Get user's voted cases
  Stream<List<CaseModel>> getUserVotedCases() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _casesCollection
        .where('voters', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      final cases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return CaseModel.fromFirestore(doc.id, data);
      }).toList();
      
      // Sort by creation date in memory to avoid composite index
      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cases;
    });
  }

  // === CASE LIFECYCLE MANAGEMENT ===

  // Mark court session as completed and update case
  Future<void> completeCourtSession(String courtSessionId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Find case by court session ID
        final caseSnapshot = await _casesCollection
            .where('courtSessionId', isEqualTo: courtSessionId)
            .get();

        if (caseSnapshot.docs.isEmpty) {
          throw Exception('Case not found for court session');
        }

        final caseDoc = caseSnapshot.docs.first;
        
        // Update case status
        transaction.update(caseDoc.reference, {
          'status': CaseStatus.completed.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update court session
        transaction.update(_courtsCollection.doc(courtSessionId), {
          'isLive': false,
          'dateEnded': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Process promotion queue for next cases
      await _processPromotionQueue();

      // Generate AI conclusion for completed court session
      await _generateAiConclusion(courtSessionId);
    } catch (e) {
      throw Exception('Failed to complete court session: ${e.toString()}');
    }
  }

  // Clean up expired cases
  Future<void> cleanupExpiredCases() async {
    try {
      final now = DateTime.now();
      final expiredCasesSnapshot = await _casesCollection
          .where('status', isEqualTo: CaseStatus.voting.name)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      
      for (final doc in expiredCasesSnapshot.docs) {
        batch.update(doc.reference, {
          'status': CaseStatus.expired.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to cleanup expired cases: ${e.toString()}');
    }
  }

  // === AI CONCLUSION SYSTEM (Placeholder for future implementation) ===

  // Generate AI conclusion for completed court session
  Future<void> _generateAiConclusion(String courtSessionId) async {
    try {
      debugPrint('🤖 Starting AI conclusion generation for session $courtSessionId');
      
      // Get court session data
      final courtDoc = await _courtsCollection.doc(courtSessionId).get();
      if (!courtDoc.exists) {
        throw Exception('Court session not found');
      }
      
      final courtData = courtDoc.data() as Map<String, dynamic>;
      
      // Get chat messages from the session
      final chatSnapshot = await _firestore
          .collection('court_chats')
          .where('courtId', isEqualTo: courtSessionId)
          .where('isDeleted', isEqualTo: false)
          .get();
      
      final chatMessages = chatSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'sender_name': data['senderName'] ?? 'Unknown',
          'message': data['message'] ?? '',
          'messageType': data['messageType'] ?? 'notGuilty',
        };
      }).toList();
      
      // Get final vote counts
      final guiltyVotes = courtData['guiltyVotes'] ?? 0;
      final notGuiltyVotes = courtData['notGuiltyVotes'] ?? 0;
      
      // Create votes array for AI
      final votes = <Map<String, dynamic>>[];
      for (int i = 0; i < guiltyVotes; i++) {
        votes.add({'verdict': 'guilty', 'reasoning': 'Voted guilty based on evidence'});
      }
      for (int i = 0; i < notGuiltyVotes; i++) {
        votes.add({'verdict': 'not_guilty', 'reasoning': 'Voted not guilty due to reasonable doubt'});
      }
      
      // Call Gemini AI endpoint
      final response = await http.post(
        Uri.parse('https://api-3ezpz5haxq-uc.a.run.app/court/generate-conclusion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'court_session_data': {
            'case_title': courtData['title'] ?? 'Unknown Case',
            'case_description': courtData['description'] ?? 'No description available',
            'chat_messages': chatMessages,
            'votes': votes,
            'session_duration': 'Court session completed'
          }
        }),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final aiResponse = jsonDecode(response.body);
        
        if (aiResponse['success'] == true) {
          final conclusion = aiResponse['conclusion'];
          
          // Create AI conclusion model
          final aiConclusion = AiConclusionModel(
            id: '',
            caseId: courtData['caseId'] ?? '',
            courtSessionId: courtSessionId,
            summary: conclusion['ai_generated_summary'] ?? 'No summary available',
            finalVerdict: conclusion['verdict'] ?? 'Unknown',
            verdictReasoning: 'Based on jury vote analysis and AI assessment',
            guiltyArguments: [],
            notGuiltyArguments: [],
            keyMoments: [],
            participantAnalysis: ParticipantAnalysis(
              totalParticipants: chatMessages.length,
              contributions: [],
            ),
            qualityMetrics: const DebateQualityMetrics(
              overallScore: 85.0,
              logicalConsistency: 80.0,
              evidenceQuality: 75.0,
              engagement: 90.0,
            ),
            educationalInsights: ['AI-generated legal analysis completed'],
            legalPrinciples: ['Presumption of innocence', 'Burden of proof'],
            generatedAt: DateTime.now(),
            status: AiConclusionStatus.completed,
            metadata: {
              'ai_model': 'gemini-1.5-flash',
              'confidence_score': conclusion['confidence_score'] ?? 0,
              'vote_breakdown': conclusion['vote_breakdown'] ?? {},
              'processing_time_ms': aiResponse['metadata']['processing_time_ms'] ?? 0,
            },
          );
          
          // Save to Firestore
          await _aiConclusionsCollection.add(aiConclusion.toMap());
          
          debugPrint('✅ AI conclusion generated and saved successfully');
        } else {
          throw Exception('AI response indicated failure');
        }
      } else {
        throw Exception('AI conclusion API returned status ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ AI conclusion generation failed: ${e.toString()}');
      
      // Create fallback conclusion
      final fallbackConclusion = AiConclusionModel(
        id: '',
        caseId: '',
        courtSessionId: courtSessionId,
        summary: 'AI conclusion generation failed: ${e.toString()}',
        finalVerdict: 'Unknown',
        verdictReasoning: 'Could not generate AI conclusion',
        guiltyArguments: [],
        notGuiltyArguments: [],
        keyMoments: [],
        participantAnalysis: const ParticipantAnalysis(totalParticipants: 0, contributions: []),
        qualityMetrics: const DebateQualityMetrics(overallScore: 0, logicalConsistency: 0, evidenceQuality: 0, engagement: 0),
        educationalInsights: [],
        legalPrinciples: [],
        generatedAt: DateTime.now(),
        status: AiConclusionStatus.failed,
        metadata: {'error': e.toString()},
      );
      
      await _aiConclusionsCollection.add(fallbackConclusion.toMap());
    }
  }

  // Get AI conclusion for a court session
  Future<AiConclusionModel?> getAiConclusion(String courtSessionId) async {
    try {
      final snapshot = await _aiConclusionsCollection
          .where('courtSessionId', isEqualTo: courtSessionId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return AiConclusionModel.fromFirestore(doc.id, data);
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get AI conclusion: ${e.toString()}');
      return null;
    }
  }

  // Get AI conclusions stream for a court session
  Stream<AiConclusionModel?> getAiConclusionStream(String courtSessionId) {
    return _aiConclusionsCollection
        .where('courtSessionId', isEqualTo: courtSessionId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return AiConclusionModel.fromFirestore(doc.id, data);
      }
      return null;
    });
  }

  // === SYSTEM MONITORING ===

  // Get system status and metrics
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final activeVotingCount = await _getCaseCountByStatus(CaseStatus.voting);
      final queuedCount = await _getCaseCountByStatus(CaseStatus.queued);
      final promotedCount = await _getCaseCountByStatus(CaseStatus.promoted);
      final completedCount = await _getCaseCountByStatus(CaseStatus.completed);

      final activeSessionsSnapshot = await _courtsCollection
          .where('isLive', isEqualTo: true)
          .get();

      return {
        'activeCases': activeVotingCount,
        'queuedCases': queuedCount,
        'activeCourtSessions': activeSessionsSnapshot.docs.length,
        'promotedCases': promotedCount,
        'completedCases': completedCount,
        'maxConcurrentSessions': CourtSystemConfig.getMaxConcurrentSessions(),
        'queueCapacity': CourtSystemConfig.maxQueueSize,
        'systemMaintenanceMode': CourtSystemConfig.systemMaintenanceMode,
        'isTestingMode': CourtSystemConfig.isTestingMode,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get system status: ${e.toString()}');
    }
  }

  // Get count of cases by status
  Future<int> _getCaseCountByStatus(CaseStatus status) async {
    final snapshot = await _casesCollection
        .where('status', isEqualTo: status.name)
        .get();
    return snapshot.docs.length;
  }

  // Force process promotion queue (admin function)
  Future<void> forceProcessQueue() async {
    await _processPromotionQueue();
  }

  // Complete a case with court session result
  Future<void> completeCase(String caseId, String? resultWin) async {
    try {
      await _casesCollection.doc(caseId).update({
        'status': CaseStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'courtResult': resultWin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Case $caseId completed with result: $resultWin');
    } catch (e) {
      throw Exception('Failed to complete case: ${e.toString()}');
    }
  }
}