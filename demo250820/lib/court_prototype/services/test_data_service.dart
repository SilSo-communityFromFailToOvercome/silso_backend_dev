import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/case_model.dart';
import '../config/court_config.dart';
import 'case_service.dart';

// Service for generating test data and admin controls
class TestDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CaseService _caseService = CaseService();

  // Collection references
  CollectionReference get _casesCollection => _firestore.collection('cases');
  CollectionReference get _caseVotesCollection => _firestore.collection('case_votes');
  CollectionReference get _courtsCollection => _firestore.collection('courts');

  // === TEST DATA GENERATION ===

  // Generate test cases with predefined vote counts
  Future<List<String>> generateTestCases() async {
    if (!CourtSystemConfig.isTestingMode) {
      throw Exception('Test data generation only available in testing mode');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final testCases = <String>[];
      
      // Case 1: Active voting, close to promotion (controversial)
      testCases.add(await _createTestCase(
        title: "원격근무가 사무실 근무보다 생산적인가?",
        description: "코로나19 이후 원격근무가 확산되면서 생산성에 대한 논쟁이 계속되고 있습니다. 원격근무의 효율성과 사무실 근무의 협업 효과 중 무엇이 더 생산적일까요?",
        category: CaseCategory.business,
        guiltyVotes: 42,
        notGuiltyVotes: 31,
        status: CaseStatus.voting,
        hoursAgo: 12,
      ));

      // Case 2: Ready for promotion (meets criteria)
      testCases.add(await _createTestCase(
        title: "SNS에 연령 제한을 둬야 하는가?",
        description: "청소년들의 SNS 사용이 정신건강에 미치는 영향에 대한 연구가 증가하고 있습니다. SNS 플랫폼에 최소 연령 제한을 강화해야 할까요?",
        category: CaseCategory.social,
        guiltyVotes: 58,
        notGuiltyVotes: 47,
        status: CaseStatus.voting,
        hoursAgo: 8,
      ));

      // Case 3: In queue
      testCases.add(await _createTestCase(
        title: "인공지능이 인간의 일자리를 대체하는 것이 윤리적인가?",
        description: "AI 기술의 발전으로 많은 직업이 자동화되고 있습니다. 이러한 변화가 사회적으로 윤리적인지에 대한 논의가 필요합니다.",
        category: CaseCategory.ethics,
        guiltyVotes: 67,
        notGuiltyVotes: 56,
        status: CaseStatus.queued,
        queuePosition: 1,
        hoursAgo: 6,
      ));

      // Case 4: One-sided (not controversial enough)
      testCases.add(await _createTestCase(
        title: "기후변화는 인간이 원인인가?",
        description: "과학적 합의에 따르면 현재의 기후변화는 인간 활동이 주요 원인입니다. 이에 대한 여러분의 의견은 어떠신가요?",
        category: CaseCategory.general,
        guiltyVotes: 89,
        notGuiltyVotes: 12,
        status: CaseStatus.voting,
        hoursAgo: 24,
      ));

      // Case 5: Recent case, low votes
      testCases.add(await _createTestCase(
        title: "게임 내 확률형 아이템은 도박인가?",
        description: "모바일 게임과 온라인 게임의 가챠 시스템과 랜덤박스가 도박의 성격을 가지는지에 대한 논쟁이 지속되고 있습니다.",
        category: CaseCategory.entertainment,
        guiltyVotes: 8,
        notGuiltyVotes: 5,
        status: CaseStatus.voting,
        hoursAgo: 2,
      ));

      // Case 6: Promoted (active court session)
      testCases.add(await _createTestCase(
        title: "대학 입시에서 수능 비중을 줄여야 하는가?",
        description: "현재 대학 입시제도에서 수능의 비중이 너무 높다는 의견과 객관적 평가의 필요성이라는 의견이 대립하고 있습니다.",
        category: CaseCategory.education,
        guiltyVotes: 73,
        notGuiltyVotes: 52,
        status: CaseStatus.promoted,
        hoursAgo: 4,
      ));

      // Case 7: Completed
      testCases.add(await _createTestCase(
        title: "온라인 수업이 대면 수업보다 효과적인가?",
        description: "코로나19로 인한 온라인 수업 경험을 바탕으로 교육 효과성에 대한 평가가 이뤄지고 있습니다.",
        category: CaseCategory.education,
        guiltyVotes: 45,
        notGuiltyVotes: 67,
        status: CaseStatus.completed,
        hoursAgo: 48,
      ));

      debugPrint('Generated ${testCases.length} test cases');
      return testCases;
    } catch (e) {
      throw Exception('Failed to generate test cases: ${e.toString()}');
    }
  }

  // Create a single test case with specified parameters
  Future<String> _createTestCase({
    required String title,
    required String description,
    required CaseCategory category,
    required int guiltyVotes,
    required int notGuiltyVotes,
    required CaseStatus status,
    int queuePosition = 0,
    required int hoursAgo,
  }) async {
    final user = _auth.currentUser!;
    final createdAt = DateTime.now().subtract(Duration(hours: hoursAgo));
    final expiresAt = createdAt.add(Duration(days: CourtSystemConfig.caseExpiryDays));
    
    final totalVotes = guiltyVotes + notGuiltyVotes;
    final guiltyPercentage = totalVotes > 0 ? (guiltyVotes / totalVotes) * 100 : 0.0;
    final controversyScore = CourtSystemConfig.calculateControversyScore(guiltyPercentage);
    final promotionPriority = CourtSystemConfig.calculatePromotionPriority(
      totalVotes, guiltyPercentage, createdAt);

    // Generate fake voter IDs
    final voters = List.generate(totalVotes, (index) => 'test_user_$index');

    final caseData = {
      'title': title,
      'description': description,
      'category': category.name,
      'creatorId': user.uid,
      'creatorName': 'Test User',
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.name,
      'guiltyVotes': guiltyVotes,
      'notGuiltyVotes': notGuiltyVotes,
      'controversyScore': controversyScore,
      'promotionPriority': promotionPriority,
      'voters': voters,
      'metadata': {
        'isTestData': true,
        'version': '1.0',
        'platform': defaultTargetPlatform.name,
      },
      'promotedAt': status.index >= CaseStatus.promoted.index 
          ? Timestamp.fromDate(createdAt.add(Duration(hours: 6)))
          : null,
      'courtSessionId': status == CaseStatus.promoted ? 'test_court_${DateTime.now().millisecondsSinceEpoch}' : null,
      'queuePosition': queuePosition,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _casesCollection.add(caseData);

    // Create vote records for this case
    await _createVoteRecords(docRef.id, guiltyVotes, notGuiltyVotes);

    // If promoted, create a court session
    if (status == CaseStatus.promoted) {
      await _createTestCourtSession(docRef.id, title, description, guiltyVotes, notGuiltyVotes);
    }

    return docRef.id;
  }

  // Create vote records for a test case
  Future<void> _createVoteRecords(String caseId, int guiltyVotes, int notGuiltyVotes) async {
    final batch = _firestore.batch();
    
    // Create guilty votes
    for (int i = 0; i < guiltyVotes; i++) {
      final voteRef = _caseVotesCollection.doc();
      batch.set(voteRef, {
        'caseId': caseId,
        'userId': 'test_user_$i',
        'userName': 'Test User $i',
        'voteType': CaseVoteType.guilty.name,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: i * 5))),
        'deviceInfo': 'test_device',
        'ipAddress': '127.0.0.1',
      });
    }

    // Create not guilty votes
    for (int i = 0; i < notGuiltyVotes; i++) {
      final voteRef = _caseVotesCollection.doc();
      batch.set(voteRef, {
        'caseId': caseId,
        'userId': 'test_user_${i + guiltyVotes}',
        'userName': 'Test User ${i + guiltyVotes}',
        'voteType': CaseVoteType.notGuilty.name,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: (i + guiltyVotes) * 5))),
        'deviceInfo': 'test_device',
        'ipAddress': '127.0.0.1',
      });
    }

    await batch.commit();
  }

  // Create a test court session for promoted cases
  Future<void> _createTestCourtSession(String caseId, String title, String description, int guiltyVotes, int notGuiltyVotes) async {
    final courtSessionData = {
      'title': title,
      'description': description,
      'dateCreated': FieldValue.serverTimestamp(),
      'currentLiveMembers': 3, // Simulate some participants
      'guiltyVotes': guiltyVotes,
      'notGuiltyVotes': notGuiltyVotes,
      'resultWin': null,
      'timeLeft': CourtSystemConfig.getSessionDuration().inMilliseconds,
      'dateEnded': null,
      'category': 'Test',
      'creatorId': _auth.currentUser!.uid,
      'isLive': true,
      'participants': ['test_user_1', 'test_user_2', 'test_user_3'],
      'caseId': caseId,
      'initialVotingResults': {
        'guiltyVotes': guiltyVotes,
        'notGuiltyVotes': notGuiltyVotes,
        'guiltyPercentage': (guiltyVotes / (guiltyVotes + notGuiltyVotes)) * 100,
        'totalVotes': guiltyVotes + notGuiltyVotes,
      },
      'metadata': {
        'isTestData': true,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _courtsCollection.add(courtSessionData);
  }

  // === ADMIN CONTROLS ===

  // Add votes to a specific case
  Future<void> addVotesToCase({
    required String caseId,
    required int guiltyVotes,
    required int notGuiltyVotes,
  }) async {
    if (!CourtSystemConfig.isTestingMode) {
      throw Exception('Admin controls only available in testing mode');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final caseDocRef = _casesCollection.doc(caseId);
        final caseSnapshot = await transaction.get(caseDocRef);
        
        if (!caseSnapshot.exists) {
          throw Exception('Case not found');
        }

        final caseData = caseSnapshot.data() as Map<String, dynamic>;
        final currentGuiltyVotes = caseData['guiltyVotes'] ?? 0;
        final currentNotGuiltyVotes = caseData['notGuiltyVotes'] ?? 0;
        final currentVoters = List<String>.from(caseData['voters'] ?? []);
        
        final newGuiltyVotes = currentGuiltyVotes + guiltyVotes;
        final newNotGuiltyVotes = currentNotGuiltyVotes + notGuiltyVotes;
        final totalVotes = newGuiltyVotes + newNotGuiltyVotes;
        final guiltyPercentage = totalVotes > 0 ? (newGuiltyVotes / totalVotes) * 100 : 0.0;
        
        // Add fake voter IDs
        final newVoters = List<String>.from(currentVoters);
        for (int i = 0; i < guiltyVotes + notGuiltyVotes; i++) {
          newVoters.add('admin_test_user_${DateTime.now().millisecondsSinceEpoch}_$i');
        }

        final controversyScore = CourtSystemConfig.calculateControversyScore(guiltyPercentage);
        final promotionPriority = CourtSystemConfig.calculatePromotionPriority(
          totalVotes, guiltyPercentage, (caseData['createdAt'] as Timestamp).toDate());

        // Check if case now meets promotion criteria
        final meetsPromotion = CourtSystemConfig.meetsPromotionCriteria(totalVotes, guiltyPercentage);
        final currentStatus = CaseStatus.values.firstWhere(
          (status) => status.name == caseData['status'],
          orElse: () => CaseStatus.voting,
        );
        final newStatus = (currentStatus == CaseStatus.voting && meetsPromotion) 
            ? CaseStatus.qualified 
            : currentStatus;

        transaction.update(caseDocRef, {
          'guiltyVotes': newGuiltyVotes,
          'notGuiltyVotes': newNotGuiltyVotes,
          'controversyScore': controversyScore,
          'promotionPriority': promotionPriority,
          'voters': newVoters,
          'status': newStatus.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Create vote records for the new votes
      await _createVoteRecords(caseId, guiltyVotes, notGuiltyVotes);
    } catch (e) {
      throw Exception('Failed to add votes: ${e.toString()}');
    }
  }

  // Force promote a case to court session
  Future<void> forcePromoteCase(String caseId) async {
    if (!CourtSystemConfig.isTestingMode) {
      throw Exception('Admin controls only available in testing mode');
    }

    try {
      await _caseService.forceProcessQueue();
      
      // If still not promoted, force it
      final caseDoc = await _casesCollection.doc(caseId).get();
      if (caseDoc.exists) {
        final caseData = caseDoc.data() as Map<String, dynamic>;
        if (caseData['status'] != CaseStatus.promoted.name) {
          await _casesCollection.doc(caseId).update({
            'status': CaseStatus.qualified.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // Add to queue if needed
          await _caseService.forceProcessQueue();
        }
      }
    } catch (e) {
      throw Exception('Failed to force promote case: ${e.toString()}');
    }
  }

  // Clear all test data
  Future<void> clearAllTestData() async {
    if (!CourtSystemConfig.isTestingMode) {
      throw Exception('Test data clearing only available in testing mode');
    }

    try {
      // Clear test cases
      final testCasesSnapshot = await _casesCollection
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in testCasesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Clear test votes
      final testVotesSnapshot = await _caseVotesCollection
          .where('userId', isGreaterThanOrEqualTo: 'test_user')
          .where('userId', isLessThan: 'test_user_z')
          .get();

      for (final doc in testVotesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Clear test court sessions
      final testCourtsSnapshot = await _courtsCollection
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      for (final doc in testCourtsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('All test data cleared');
    } catch (e) {
      throw Exception('Failed to clear test data: ${e.toString()}');
    }
  }

  // Simulate user activity (rapid voting)
  Future<void> simulateUserActivity({
    required String caseId,
    required int activityLevel, // 1-10 scale
    required int durationMinutes,
  }) async {
    if (!CourtSystemConfig.isTestingMode) {
      throw Exception('Simulation only available in testing mode');
    }

    try {
      final votesPerMinute = activityLevel;
      final totalVotes = votesPerMinute * durationMinutes;
      
      // Split randomly between guilty and not guilty
      final guiltyRatio = 0.4 + (0.2 * (DateTime.now().millisecond % 100) / 100); // 40-60%
      final guiltyVotes = (totalVotes * guiltyRatio).round();
      final notGuiltyVotes = totalVotes - guiltyVotes;

      await addVotesToCase(
        caseId: caseId,
        guiltyVotes: guiltyVotes,
        notGuiltyVotes: notGuiltyVotes,
      );

      debugPrint('Simulated $totalVotes votes ($guiltyVotes guilty, $notGuiltyVotes not guilty)');
    } catch (e) {
      throw Exception('Failed to simulate activity: ${e.toString()}');
    }
  }

  // Get test data statistics
  Future<Map<String, dynamic>> getTestDataStats() async {
    try {
      final testCasesSnapshot = await _casesCollection
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      final testVotesSnapshot = await _caseVotesCollection
          .where('userId', isGreaterThanOrEqualTo: 'test_user')
          .where('userId', isLessThan: 'test_user_z')
          .get();

      final testCourtsSnapshot = await _courtsCollection
          .where('metadata.isTestData', isEqualTo: true)
          .get();

      return {
        'testCases': testCasesSnapshot.docs.length,
        'testVotes': testVotesSnapshot.docs.length,
        'testCourtSessions': testCourtsSnapshot.docs.length,
        'isTestingMode': CourtSystemConfig.isTestingMode,
        'lastGenerated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get test data stats: ${e.toString()}');
    }
  }

  // === SYSTEM CONFIGURATION CONTROLS ===

  // Enable testing mode
  void enableTestingMode() {
    CourtSystemConfig.enableTestingMode();
    debugPrint('Testing mode enabled');
  }

  // Disable testing mode
  void disableTestingMode() {
    CourtSystemConfig.disableTestingMode();
    debugPrint('Testing mode disabled');
  }

  // Enable maintenance mode
  void enableMaintenanceMode() {
    CourtSystemConfig.enableMaintenanceMode();
    debugPrint('Maintenance mode enabled');
  }

  // Disable maintenance mode
  void disableMaintenanceMode() {
    CourtSystemConfig.disableMaintenanceMode();
    debugPrint('Maintenance mode disabled');
  }

  // Get system configuration debug info
  Map<String, dynamic> getSystemDebugInfo() {
    return CourtSystemConfig.getDebugInfo();
  }
}