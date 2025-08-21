import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _reportsCollection => _firestore.collection('reports');

  // Submit a new report
  Future<String> submitReport(ReportSubmission submission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already reported this content (prevent spam)
      if (submission.contentId != null) {
        final existingReport = await _reportsCollection
            .where('reporterId', isEqualTo: user.uid)
            .where('contentId', isEqualTo: submission.contentId)
            .where('reportedUserId', isEqualTo: submission.reportedUserId)
            .limit(1)
            .get();

        if (existingReport.docs.isNotEmpty) {
          throw Exception('You have already reported this content');
        }
      }

      // Create new report document
      final docRef = _reportsCollection.doc();
      final report = Report(
        id: docRef.id,
        reporterId: user.uid,
        reporterEmail: user.email ?? user.uid,
        reportedUserId: submission.reportedUserId,
        reportedUserEmail: submission.reportedUserEmail,
        contentType: submission.contentType,
        contentId: submission.contentId,
        contentText: submission.contentText,
        reportType: submission.reportType,
        description: submission.description,
        status: ReportStatus.pending,
        createdAt: DateTime.now(),
      );

      await docRef.set(report.toMap());
      
      // Log activity for admin tracking
      await _logReportActivity(report.id, 'created', user.uid);
      
      return report.id;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  // Get all reports for admin (with filtering)
  Stream<List<Report>> getAllReportsForAdmin({
    ReportStatus? status,
    ReportType? reportType,
    ReportedContentType? contentType,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _reportsCollection.orderBy('createdAt', descending: true);
    
    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }
    
    if (reportType != null) {
      query = query.where('reportType', isEqualTo: reportType.toString().split('.').last);
    }
    
    if (contentType != null) {
      query = query.where('contentType', isEqualTo: contentType.toString().split('.').last);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => Report.fromDocument(doc)).toList());
  }

  // Get reports by user (for user's own reports)
  Stream<List<Report>> getReportsByUser(String userId, {int? limit}) {
    Query query = _reportsCollection
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => Report.fromDocument(doc)).toList());
  }

  // Get reports against a specific user
  Stream<List<Report>> getReportsAgainstUser(String userId, {int? limit}) {
    Query query = _reportsCollection
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => Report.fromDocument(doc)).toList());
  }

  // Get report by ID
  Future<Report?> getReportById(String id) async {
    try {
      final doc = await _reportsCollection.doc(id).get();
      if (doc.exists) {
        return Report.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get report: $e');
    }
  }

  // Update report status (admin only)
  Future<void> updateReportStatus(
    String reportId, 
    ReportStatus newStatus, {
    String? adminNotes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminId': user.uid,
      };

      if (adminNotes != null && adminNotes.isNotEmpty) {
        updateData['adminNotes'] = adminNotes;
      }

      if (newStatus == ReportStatus.resolved || newStatus == ReportStatus.dismissed) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _reportsCollection.doc(reportId).update(updateData);
      
      // Log admin activity
      await _logReportActivity(reportId, 'status_updated', user.uid);
      
    } catch (e) {
      throw Exception('Failed to update report status: $e');
    }
  }

  // Delete report (admin only)
  Future<void> deleteReport(String reportId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _reportsCollection.doc(reportId).delete();
      
      // Log admin activity
      await _logReportActivity(reportId, 'deleted', user.uid);
      
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  // Get report statistics for admin dashboard
  Future<Map<String, int>> getReportStatistics() async {
    try {
      final allDocs = await _reportsCollection.get();
      
      int total = allDocs.docs.length;
      int pending = 0;
      int underReview = 0;
      int resolved = 0;
      int dismissed = 0;
      
      // Count by report types
      Map<String, int> reportTypeCounts = {};
      Map<String, int> contentTypeCounts = {};

      for (final doc in allDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        final reportType = data['reportType'] as String?;
        final contentType = data['contentType'] as String?;
        
        // Count statuses
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'underReview':
            underReview++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'dismissed':
            dismissed++;
            break;
        }

        // Count report types
        if (reportType != null) {
          reportTypeCounts[reportType] = (reportTypeCounts[reportType] ?? 0) + 1;
        }

        // Count content types
        if (contentType != null) {
          contentTypeCounts[contentType] = (contentTypeCounts[contentType] ?? 0) + 1;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'underReview': underReview,
        'resolved': resolved,
        'dismissed': dismissed,
        // Add top report types
        ...reportTypeCounts.map((key, value) => MapEntry('reportType_$key', value)),
        // Add content type counts
        ...contentTypeCounts.map((key, value) => MapEntry('contentType_$key', value)),
      };
    } catch (e) {
      print('Error getting report statistics: $e');
      return {
        'total': 0,
        'pending': 0,
        'underReview': 0,
        'resolved': 0,
        'dismissed': 0,
      };
    }
  }

  // Search reports (admin feature)
  Future<List<Report>> searchReports(String searchTerm) async {
    try {
      // Search in descriptions and reporter emails
      final descriptionResults = await _reportsCollection
          .where('description', isGreaterThanOrEqualTo: searchTerm)
          .where('description', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final emailResults = await _reportsCollection
          .where('reporterEmail', isGreaterThanOrEqualTo: searchTerm)
          .where('reporterEmail', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final results = <Report>[];
      final processedIds = <String>{};
      
      // Add description matches
      for (final doc in descriptionResults.docs) {
        if (!processedIds.contains(doc.id)) {
          results.add(Report.fromDocument(doc));
          processedIds.add(doc.id);
        }
      }

      // Add email matches
      for (final doc in emailResults.docs) {
        if (!processedIds.contains(doc.id)) {
          results.add(Report.fromDocument(doc));
          processedIds.add(doc.id);
        }
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search reports: $e');
    }
  }

  // Batch update report statuses
  Future<void> batchUpdateStatus(List<String> reportIds, ReportStatus status) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (final reportId in reportIds) {
        final docRef = _reportsCollection.doc(reportId);
        final updateData = {
          'status': status.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
          'adminId': user.uid,
        };
        
        if (status == ReportStatus.resolved || status == ReportStatus.dismissed) {
          updateData['resolvedAt'] = FieldValue.serverTimestamp();
        }
        
        batch.update(docRef, updateData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update reports: $e');
    }
  }

  // Log report activity for audit trail
  Future<void> _logReportActivity(String reportId, String action, String userId) async {
    try {
      await _firestore.collection('report_activity').add({
        'reportId': reportId,
        'action': action,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Warning: Failed to log report activity: $e');
    }
  }

  // Check if user has permission to manage reports (admin check)
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

  // Get recent reports (last 7 days)
  Future<List<Report>> getRecentReports({int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final query = await _reportsCollection
          .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => Report.fromDocument(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get recent reports: $e');
    }
  }
}