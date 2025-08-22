import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/faq.dart';

class FAQService {
  static final FAQService _instance = FAQService._internal();
  factory FAQService() => _instance;
  FAQService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _faqCollection => _firestore.collection('faqs');

  // Submit a new FAQ question
  Future<String> submitQuestion(FAQSubmission submission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create new FAQ document
      final docRef = _faqCollection.doc();
      final faq = FAQ(
        id: docRef.id,
        userId: user.uid,
        userName: submission.name,
        userEmail: submission.email,
        category: submission.category,
        question: submission.question,
        content: submission.content,
        submitDate: DateTime.now(),
        status: FAQStatus.pending,
        birthDate: submission.birthDate,
        attachments: submission.attachments,
      );

      await docRef.set(faq.toMap());
      
      // Log submission for admin notifications (optional)
      await _logFAQActivity(faq.id, 'submitted', user.uid);
      
      return faq.id;
    } catch (e) {
      throw Exception('Failed to submit question: $e');
    }
  }

  // Get user's FAQ history
  Stream<List<FAQ>> getUserQuestions(String userId) {
    return _faqCollection
        .where('userId', isEqualTo: userId)
        .orderBy('submitDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQ.fromDocument(doc))
            .toList());
  }

  // Get all FAQs for admin (with pagination)
  Stream<List<FAQ>> getAllQuestions({
    FAQStatus? status,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _faqCollection.orderBy('submitDate', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => FAQ.fromDocument(doc)).toList());
  }

  // Get FAQ statistics for admin dashboard
  Future<Map<String, int>> getFAQStatistics() async {
    try {
      final allDocs = await _faqCollection.get();
      final pendingDocs = await _faqCollection
          .where('status', isEqualTo: 'pending')
          .get();
      final answeredDocs = await _faqCollection
          .where('status', isEqualTo: 'answered')
          .get();

      return {
        'total': allDocs.docs.length,
        'pending': pendingDocs.docs.length,
        'answered': answeredDocs.docs.length,
        'closed': allDocs.docs.length - pendingDocs.docs.length - answeredDocs.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get FAQ statistics: $e');
    }
  }

  // Answer a question (admin only)
  Future<void> answerQuestion(String questionId, String answer) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current question to verify it exists
      final doc = await _faqCollection.doc(questionId).get();
      if (!doc.exists) {
        throw Exception('Question not found');
      }

      final faq = FAQ.fromDocument(doc);
      
      // Update with answer
      final updatedFAQ = faq.copyWith(
        status: FAQStatus.answered,
        answer: answer,
        answeredBy: user.email ?? user.uid,
        answeredDate: DateTime.now(),
      );

      await _faqCollection.doc(questionId).update(updatedFAQ.toUpdateMap());
      
      // Log admin activity
      await _logFAQActivity(questionId, 'answered', user.uid);
      
      // TODO: Send notification to user about answer (optional)
      await _notifyUserOfAnswer(faq.userId, questionId);
      
    } catch (e) {
      throw Exception('Failed to answer question: $e');
    }
  }

  // Delete a question (admin only)
  Future<void> deleteQuestion(String questionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the question first to handle attachments
      final doc = await _faqCollection.doc(questionId).get();
      if (!doc.exists) {
        throw Exception('Question not found');
      }

      final faq = FAQ.fromDocument(doc);
      
      // Delete attachments from storage if any
      if (faq.attachments != null && faq.attachments!.isNotEmpty) {
        await _deleteAttachments(faq.attachments!);
      }

      // Delete the document
      await _faqCollection.doc(questionId).delete();
      
      // Log admin activity
      await _logFAQActivity(questionId, 'deleted', user.uid);
      
    } catch (e) {
      throw Exception('Failed to delete question: $e');
    }
  }

  // Close a question without answering (admin only)
  Future<void> closeQuestion(String questionId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _faqCollection.doc(questionId).update({
        'status': FAQStatus.closed.toString().split('.').last,
        'answer': 'Question closed: $reason',
        'answeredBy': user.email ?? user.uid,
        'answeredDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log admin activity
      await _logFAQActivity(questionId, 'closed', user.uid);
      
    } catch (e) {
      throw Exception('Failed to close question: $e');
    }
  }

  // Upload attachment file
  Future<String> uploadAttachment(File file, String questionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('faq_attachments/$questionId/$fileName');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  // Delete attachments from storage
  Future<void> _deleteAttachments(List<String> attachmentUrls) async {
    try {
      for (final url in attachmentUrls) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
    } catch (e) {
      // Log error but don't fail the main operation
      print('Warning: Failed to delete some attachments: $e');
    }
  }

  // Search questions (admin feature)
  Future<List<FAQ>> searchQuestions(String searchTerm) async {
    try {
      // Firestore doesn't support full-text search, so we'll use a simple approach
      // In production, you might want to use Algolia or Elasticsearch
      
      final questionResults = await _faqCollection
          .where('question', isGreaterThanOrEqualTo: searchTerm)
          .where('question', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();
          
      final categoryResults = await _faqCollection
          .where('category', isGreaterThanOrEqualTo: searchTerm)
          .where('category', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final results = <FAQ>[];
      
      // Add question matches
      for (final doc in questionResults.docs) {
        results.add(FAQ.fromDocument(doc));
      }
      
      // Add category matches (avoid duplicates)
      for (final doc in categoryResults.docs) {
        final faq = FAQ.fromDocument(doc);
        if (!results.any((existing) => existing.id == faq.id)) {
          results.add(faq);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search questions: $e');
    }
  }

  // Get questions by category
  Stream<List<FAQ>> getQuestionsByCategory(String category) {
    return _faqCollection
        .where('category', isEqualTo: category)
        .orderBy('submitDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQ.fromDocument(doc))
            .toList());
  }

  // Get recent activity for admin dashboard
  Stream<List<FAQ>> getRecentActivity({int limit = 10}) {
    return _faqCollection
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FAQ.fromDocument(doc))
            .toList());
  }

  // Log FAQ activity for audit trail
  Future<void> _logFAQActivity(String questionId, String action, String userId) async {
    try {
      await _firestore.collection('faq_activity').add({
        'questionId': questionId,
        'action': action,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Warning: Failed to log FAQ activity: $e');
    }
  }

  // Notify user of answer (placeholder for future notification system)
  Future<void> _notifyUserOfAnswer(String userId, String questionId) async {
    try {
      // TODO: Implement push notification or in-app notification
      // For now, we'll create a notification document
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'faq_answered',
        'questionId': questionId,
        'title': '문의 답변 완료',
        'message': '귀하의 문의에 대한 답변이 등록되었습니다.',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Warning: Failed to create notification: $e');
    }
  }

  // Get FAQ categories (for dropdowns)
  Future<List<String>> getFAQCategories() async {
    try {
      // In a real app, you might have a separate categories collection
      // For now, we'll get unique categories from existing FAQs
      final snapshot = await _faqCollection.get();
      final categories = <String>{};
      
      for (final doc in snapshot.docs) {
        final category = doc.data() as Map<String, dynamic>;
        if (category['category'] != null) {
          categories.add(category['category'] as String);
        }
      }
      
      // Add default categories if empty
      if (categories.isEmpty) {
        categories.addAll([
          '계정/로그인',
          '기능 문의',
          '기술 지원',
          '결제/환불',
          '기타',
        ]);
      }
      
      return categories.toList()..sort();
    } catch (e) {
      // Return default categories on error
      return [
        '계정/로그인',
        '기능 문의',
        '기술 지원',
        '결제/환불',
        '기타',
      ];
    }
  }

  // Batch operations for admin efficiency
  Future<void> batchUpdateStatus(List<String> questionIds, FAQStatus status) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (final questionId in questionIds) {
        final docRef = _faqCollection.doc(questionId);
        batch.update(docRef, {
          'status': status.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update questions: $e');
    }
  }

  // Check if user has permission to manage FAQs (admin check)
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check admin status from user document or custom claims
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['isAdmin'] == true || userData['role'] == 'admin';
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}