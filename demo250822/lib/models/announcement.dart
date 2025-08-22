import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AnnouncementStatus {
  draft,
  published,
  archived,
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String createdByEmail;
  final AnnouncementStatus status;
  final bool isImportant;
  final bool isPinned;
  final List<String>? attachments;
  final Map<String, dynamic>? metadata;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.publishedAt,
    this.updatedAt,
    required this.createdBy,
    required this.createdByEmail,
    this.status = AnnouncementStatus.draft,
    this.isImportant = false,
    this.isPinned = false,
    this.attachments,
    this.metadata,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'status': status.toString().split('.').last,
      'isImportant': isImportant,
      'isPinned': isPinned,
      'attachments': attachments ?? [],
      'metadata': metadata ?? {},
    };
  }

  // Create from Firestore document
  factory Announcement.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      publishedAt: data['publishedAt'] != null 
          ? (data['publishedAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      createdBy: data['createdBy'] ?? '',
      createdByEmail: data['createdByEmail'] ?? '',
      status: AnnouncementStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['status'],
        orElse: () => AnnouncementStatus.draft,
      ),
      isImportant: data['isImportant'] ?? false,
      isPinned: data['isPinned'] ?? false,
      attachments: data['attachments'] != null 
          ? List<String>.from(data['attachments']) 
          : null,
      metadata: data['metadata'],
    );
  }

  // Create copy with updated fields
  Announcement copyWith({
    String? title,
    String? content,
    DateTime? publishedAt,
    DateTime? updatedAt,
    AnnouncementStatus? status,
    bool? isImportant,
    bool? isPinned,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
  }) {
    return Announcement(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
      status: status ?? this.status,
      isImportant: isImportant ?? this.isImportant,
      isPinned: isPinned ?? this.isPinned,
      attachments: attachments ?? this.attachments,
      metadata: metadata ?? this.metadata,
    );
  }

  // Update map for Firestore updates
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': status.toString().split('.').last,
      'isImportant': isImportant,
      'isPinned': isPinned,
      'attachments': attachments ?? [],
      'metadata': metadata ?? {},
      if (publishedAt != null) 'publishedAt': Timestamp.fromDate(publishedAt!),
    };
  }

  // Check if announcement is visible to users
  bool get isVisible => status == AnnouncementStatus.published;

  // Get status display text
  String get statusDisplayText {
    switch (status) {
      case AnnouncementStatus.draft:
        return '임시저장';
      case AnnouncementStatus.published:
        return '게시됨';
      case AnnouncementStatus.archived:
        return '보관됨';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case AnnouncementStatus.draft:
        return const Color(0xFFF59E0B); // Orange
      case AnnouncementStatus.published:
        return const Color(0xFF059669); // Green
      case AnnouncementStatus.archived:
        return const Color(0xFF8E8E8E); // Gray
    }
  }
}

// Submission model for creating new announcements
class AnnouncementSubmission {
  final String title;
  final String content;
  final bool isImportant;
  final bool isPinned;
  final AnnouncementStatus status;
  final List<String>? attachments;

  AnnouncementSubmission({
    required this.title,
    required this.content,
    this.isImportant = false,
    this.isPinned = false,
    this.status = AnnouncementStatus.draft,
    this.attachments,
  });
}