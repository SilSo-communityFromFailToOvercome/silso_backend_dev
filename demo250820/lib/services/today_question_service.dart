import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/today_question_model.dart';
import 'dart:math';

class TodayQuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Collection names
  static const String questionsCollection = 'todayquestions';
  static const String answersCollection = 'todayquestion_answers';

  // Available emoji avatars for answers
  static const List<String> availableAvatars = [
    '😊', '😎', '🤔', '😄', '🥰', '😇', '🤗', '😋',
    '🍎', '🌟', '🎵', '📚', '🎮', '☕', '💆', '🎨',
    '🌈', '🍕', '🚀', '🎯', '💡', '🌸', '🦋', '⭐',
    '🎭', '🎪', '🎨', '🎬', '🎸', '🏆', '💎', '🔥'
  ];

  // Get random avatar emoji
  String getRandomAvatar() {
    final random = Random();
    return availableAvatars[random.nextInt(availableAvatars.length)];
  }

  // Create a new today's question (Admin function)
  Future<String> createTodayQuestion(CreateTodayQuestionRequest request) async {
    try {
      // Deactivate previous active questions
      await _deactivatePreviousQuestions();

      final docRef = await _firestore
          .collection(questionsCollection)
          .add(request.toMap());

      debugPrint('Created new today question: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating today question: $e');
      throw 'Failed to create today\'s question: ${e.toString()}';
    }
  }

  // Deactivate all previous questions
  Future<void> _deactivatePreviousQuestions() async {
    try {
      final snapshot = await _firestore
          .collection(questionsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error deactivating previous questions: $e');
    }
  }

  // Get the current active question
  Future<TodayQuestion?> getCurrentQuestion() async {
    try {
      final snapshot = await _firestore
          .collection(questionsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) {
        // Create a default question if none exists
        await _createDefaultQuestion();
        return await getCurrentQuestion();
      }

      // Sort by datePosted in memory to avoid index requirement
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['datePosted'] as Timestamp?;
          final bDate = b.data()['datePosted'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      return TodayQuestion.fromMap(sortedDocs.first.data(), sortedDocs.first.id);
    } catch (e) {
      debugPrint('Error getting current question: $e');
      return null;
    }
  }

  // Create default question if none exists
  Future<void> _createDefaultQuestion() async {
    try {
      final defaultQuestion = CreateTodayQuestionRequest(
        questionText: '당신은 스트레스를 어떤 방법으로 풀고있나요?',
        isActive: true,
      );

      await createTodayQuestion(defaultQuestion);
      debugPrint('Created default today question');
    } catch (e) {
      debugPrint('Error creating default question: $e');
    }
  }

  // Get all questions (for admin purposes)
  Future<List<TodayQuestion>> getAllQuestions() async {
    try {
      final snapshot = await _firestore
          .collection(questionsCollection)
          .get();

      // Sort by datePosted in memory to avoid index requirement
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['datePosted'] as Timestamp?;
          final bDate = b.data()['datePosted'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      return sortedDocs.map((doc) {
        return TodayQuestion.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting all questions: $e');
      return [];
    }
  }

  // Submit an answer to today's question
  Future<String> submitAnswer(CreateTodayQuestionAnswerRequest request, {int? maxAnswersPerDay}) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      // Check if user has reached daily answer limit
      final userAnswersToday = await getUserAnswersToday(request.questionId);
      final dailyLimit = maxAnswersPerDay ?? 1; // Default to 1 if not specified
      
      if (userAnswersToday >= dailyLimit) {
        throw 'You have reached the daily limit of $dailyLimit answers';
      }

      // Create the answer
      final docRef = await _firestore
          .collection(answersCollection)
          .add(request.toMap(currentUserId!));

      // Update question's answer count
      await _firestore
          .collection(questionsCollection)
          .doc(request.questionId)
          .update({
        'answerCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Submitted answer: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error submitting answer: $e');
      throw 'Failed to submit answer: ${e.toString()}';
    }
  }

  // Check if user has already answered a question
  Future<bool> hasUserAnswered(String questionId) async {
    if (currentUserId == null) return false;

    try {
      final snapshot = await _firestore
          .collection(answersCollection)
          .where('questionId', isEqualTo: questionId)
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user answered: $e');
      return false;
    }
  }

  // Get number of answers user has submitted today for a specific question
  Future<int> getUserAnswersToday(String questionId) async {
    if (currentUserId == null) return 0;

    try {
      // Get start of today in UTC
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(answersCollection)
          .where('questionId', isEqualTo: questionId)
          .where('userId', isEqualTo: currentUserId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfToday))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting user answers count: $e');
      return 0;
    }
  }

  // Get answers for a specific question
  Future<List<TodayQuestionAnswer>> getQuestionAnswers(String questionId) async {
    try {
      final snapshot = await _firestore
          .collection(answersCollection)
          .where('questionId', isEqualTo: questionId)
          .get();

      // Sort by createdAt in memory to avoid index requirement
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      return sortedDocs.map((doc) {
        return TodayQuestionAnswer.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting question answers: $e');
      return [];
    }
  }

  // Get answers for a specific question (real-time stream)
  Stream<List<TodayQuestionAnswer>> getQuestionAnswersStream(String questionId) {
    return _firestore
        .collection(answersCollection)
        .where('questionId', isEqualTo: questionId)
        .snapshots()
        .map((snapshot) {
      // Sort by createdAt in memory to avoid index requirement
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      return sortedDocs.map((doc) {
        return TodayQuestionAnswer.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get current question with answers (real-time stream)
  Stream<Map<String, dynamic>> getCurrentQuestionWithAnswersStream() {
    return _firestore
        .collection(questionsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((questionSnapshot) async {
      if (questionSnapshot.docs.isEmpty) {
        return {
          'question': null,
          'answers': <TodayQuestionAnswer>[],
          'hasUserAnswered': false,
        };
      }

      // Sort by datePosted in memory to avoid index requirement
      final sortedDocs = questionSnapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['datePosted'] as Timestamp?;
          final bDate = b.data()['datePosted'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      final question = TodayQuestion.fromMap(
        sortedDocs.first.data(),
        sortedDocs.first.id,
      );

      final answers = await getQuestionAnswers(question.questionId);
      final userHasAnswered = await hasUserAnswered(question.questionId);

      return {
        'question': question,
        'answers': answers,
        'hasUserAnswered': userHasAnswered,
      };
    });
  }

  // Delete an answer (only by the user who posted it)
  Future<void> deleteAnswer(String answerId) async {
    if (currentUserId == null) throw 'User not authenticated';

    try {
      final answerDoc = await _firestore
          .collection(answersCollection)
          .doc(answerId)
          .get();

      if (!answerDoc.exists) {
        throw 'Answer not found';
      }

      final answerData = answerDoc.data()!;
      if (answerData['userId'] != currentUserId) {
        throw 'You can only delete your own answers';
      }

      // Delete the answer
      await _firestore.collection(answersCollection).doc(answerId).delete();

      // Update question's answer count
      await _firestore
          .collection(questionsCollection)
          .doc(answerData['questionId'])
          .update({
        'answerCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Deleted answer: $answerId');
    } catch (e) {
      debugPrint('Error deleting answer: $e');
      throw 'Failed to delete answer: ${e.toString()}';
    }
  }

  // Update a question (admin function)
  Future<void> updateQuestion(String questionId, {
    String? questionText,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (questionText != null) {
        updateData['questionText'] = questionText;
      }

      if (isActive != null) {
        updateData['isActive'] = isActive;
        
        // If activating this question, deactivate others
        if (isActive) {
          await _deactivatePreviousQuestions();
        }
      }

      await _firestore
          .collection(questionsCollection)
          .doc(questionId)
          .update(updateData);

      debugPrint('Updated question: $questionId');
    } catch (e) {
      debugPrint('Error updating question: $e');
      throw 'Failed to update question: ${e.toString()}';
    }
  }

  // Get user's answers to today's questions
  Future<List<TodayQuestionAnswer>> getUserAnswers() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(answersCollection)
          .where('userId', isEqualTo: currentUserId)
          .get();

      // Sort by createdAt in memory to avoid index requirement
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final aDate = a.data()['createdAt'] as Timestamp?;
          final bDate = b.data()['createdAt'] as Timestamp?;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate); // descending order
        });

      return sortedDocs.map((doc) {
        return TodayQuestionAnswer.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error getting user answers: $e');
      return [];
    }
  }

  // Initialize service and ensure there's always an active question
  Future<void> initializeService() async {
    try {
      final currentQuestion = await getCurrentQuestion();
      if (currentQuestion == null) {
        debugPrint('No active question found, creating default question');
        await _createDefaultQuestion();
      } else {
        debugPrint('Active question found: ${currentQuestion.questionText}');
      }
    } catch (e) {
      debugPrint('Error initializing today question service: $e');
    }
  }

  // Get answer statistics for a question
  Future<Map<String, dynamic>> getQuestionStatistics(String questionId) async {
    try {
      final answersSnapshot = await _firestore
          .collection(answersCollection)
          .where('questionId', isEqualTo: questionId)
          .get();

      final totalAnswers = answersSnapshot.docs.length;
      final uniqueUsers = answersSnapshot.docs
          .map((doc) => doc.data()['userId'])
          .toSet()
          .length;

      return {
        'totalAnswers': totalAnswers,
        'uniqueUsers': uniqueUsers,
        'averageAnswerLength': totalAnswers > 0
            ? answersSnapshot.docs
                    .map((doc) => (doc.data()['answerText'] as String).length)
                    .reduce((a, b) => a + b) /
                totalAnswers
            : 0,
      };
    } catch (e) {
      debugPrint('Error getting question statistics: $e');
      return {
        'totalAnswers': 0,
        'uniqueUsers': 0,
        'averageAnswerLength': 0,
      };
    }
  }
}