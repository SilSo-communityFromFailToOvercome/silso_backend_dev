import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/announcement.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection reference
  CollectionReference get _announcementsCollection => _firestore.collection('announcements');

  // Create a new announcement
  Future<String> createAnnouncement(AnnouncementSubmission submission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create new announcement document
      final docRef = _announcementsCollection.doc();
      final announcement = Announcement(
        id: docRef.id,
        title: submission.title,
        content: submission.content,
        createdAt: DateTime.now(),
        publishedAt: submission.status == AnnouncementStatus.published 
            ? DateTime.now() 
            : null,
        createdBy: user.uid,
        createdByEmail: user.email ?? user.uid,
        status: submission.status,
        isImportant: submission.isImportant,
        isPinned: submission.isPinned,
        attachments: submission.attachments,
      );

      await docRef.set(announcement.toMap());
      
      // Log activity for admin tracking
      await _logAnnouncementActivity(announcement.id, 'created', user.uid);
      
      return announcement.id;
    } catch (e) {
      throw Exception('Failed to create announcement: $e');
    }
  }

  // Get all announcements for admin (including drafts)
  Stream<List<Announcement>> getAllAnnouncementsForAdmin({
    AnnouncementStatus? status,
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _announcementsCollection.orderBy('createdAt', descending: true);
    
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
        snapshot.docs.map((doc) => Announcement.fromDocument(doc)).toList());
  }

  // Get published announcements for users
  Stream<List<Announcement>> getPublishedAnnouncements({
    int? limit,
    DocumentSnapshot? startAfter,
  }) {
    Query query = _announcementsCollection
        .where('status', isEqualTo: 'published')
        .orderBy('isPinned', descending: true)
        .orderBy('publishedAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => Announcement.fromDocument(doc)).toList());
  }

  // Get announcement by ID
  Future<Announcement?> getAnnouncementById(String id) async {
    try {
      final doc = await _announcementsCollection.doc(id).get();
      if (doc.exists) {
        return Announcement.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get announcement: $e');
    }
  }

  // Update announcement
  Future<void> updateAnnouncement(String id, AnnouncementSubmission submission) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get current announcement to preserve original data
      final doc = await _announcementsCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Announcement not found');
      }

      final currentAnnouncement = Announcement.fromDocument(doc);
      
      // Update announcement
      final updatedAnnouncement = currentAnnouncement.copyWith(
        title: submission.title,
        content: submission.content,
        status: submission.status,
        isImportant: submission.isImportant,
        isPinned: submission.isPinned,
        attachments: submission.attachments,
        updatedAt: DateTime.now(),
        publishedAt: submission.status == AnnouncementStatus.published &&
                    currentAnnouncement.publishedAt == null
            ? DateTime.now()
            : currentAnnouncement.publishedAt,
      );

      await _announcementsCollection.doc(id).update(updatedAnnouncement.toUpdateMap());
      
      // Log admin activity
      await _logAnnouncementActivity(id, 'updated', user.uid);
      
    } catch (e) {
      throw Exception('Failed to update announcement: $e');
    }
  }

  // Delete announcement
  Future<void> deleteAnnouncement(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the announcement first to handle attachments
      final doc = await _announcementsCollection.doc(id).get();
      if (!doc.exists) {
        throw Exception('Announcement not found');
      }

      final announcement = Announcement.fromDocument(doc);
      
      // Delete attachments from storage if any
      if (announcement.attachments != null && announcement.attachments!.isNotEmpty) {
        await _deleteAttachments(announcement.attachments!);
      }

      // Delete the document
      await _announcementsCollection.doc(id).delete();
      
      // Log admin activity
      await _logAnnouncementActivity(id, 'deleted', user.uid);
      
    } catch (e) {
      throw Exception('Failed to delete announcement: $e');
    }
  }

  // Publish announcement (change from draft to published)
  Future<void> publishAnnouncement(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _announcementsCollection.doc(id).update({
        'status': AnnouncementStatus.published.toString().split('.').last,
        'publishedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log admin activity
      await _logAnnouncementActivity(id, 'published', user.uid);
      
    } catch (e) {
      throw Exception('Failed to publish announcement: $e');
    }
  }

  // Archive announcement
  Future<void> archiveAnnouncement(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _announcementsCollection.doc(id).update({
        'status': AnnouncementStatus.archived.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Log admin activity
      await _logAnnouncementActivity(id, 'archived', user.uid);
      
    } catch (e) {
      throw Exception('Failed to archive announcement: $e');
    }
  }

  // Upload attachment file
  Future<String> uploadAttachment(File file, String announcementId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('announcement_attachments/$announcementId/$fileName');
      
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

  // Search announcements (admin feature)
  Future<List<Announcement>> searchAnnouncements(String searchTerm) async {
    try {
      // Search in titles
      final titleResults = await _announcementsCollection
          .where('title', isGreaterThanOrEqualTo: searchTerm)
          .where('title', isLessThanOrEqualTo: '$searchTerm\uf8ff')
          .get();

      final results = <Announcement>[];
      
      // Add title matches
      for (final doc in titleResults.docs) {
        results.add(Announcement.fromDocument(doc));
      }
      
      return results;
    } catch (e) {
      throw Exception('Failed to search announcements: $e');
    }
  }

  // Get announcement statistics for admin dashboard
  Future<Map<String, int>> getAnnouncementStatistics() async {
    try {
      final allDocs = await _announcementsCollection.get();
      
      int total = allDocs.docs.length;
      int published = 0;
      int draft = 0;
      int archived = 0;
      int important = 0;

      // Count by status and importance
      for (final doc in allDocs.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        final isImportant = data['isImportant'] as bool? ?? false;
        
        if (isImportant) important++;
        
        switch (status) {
          case 'published':
            published++;
            break;
          case 'draft':
            draft++;
            break;
          case 'archived':
            archived++;
            break;
        }
      }

      return {
        'total': total,
        'published': published,
        'draft': draft,
        'archived': archived,
        'important': important,
      };
    } catch (e) {
      print('Error getting announcement statistics: $e');
      return {
        'total': 0,
        'published': 0,
        'draft': 0,
        'archived': 0,
        'important': 0,
      };
    }
  }

  // Log announcement activity for audit trail
  Future<void> _logAnnouncementActivity(String announcementId, String action, String userId) async {
    try {
      await _firestore.collection('announcement_activity').add({
        'announcementId': announcementId,
        'action': action,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Log error but don't fail the main operation
      print('Warning: Failed to log announcement activity: $e');
    }
  }

  // Check if user has permission to manage announcements (admin check)
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

  // Batch operations for admin efficiency
  Future<void> batchUpdateStatus(List<String> announcementIds, AnnouncementStatus status) async {
    try {
      final batch = _firestore.batch();
      final user = _auth.currentUser;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      for (final announcementId in announcementIds) {
        final docRef = _announcementsCollection.doc(announcementId);
        final updateData = {
          'status': status.toString().split('.').last,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Add publishedAt for published status if not already set
        if (status == AnnouncementStatus.published) {
          updateData['publishedAt'] = FieldValue.serverTimestamp();
        }
        
        batch.update(docRef, updateData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update announcements: $e');
    }
  }
}