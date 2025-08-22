import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReportType {
  spam,
  harassment,
  inappropriateContent,
  fakeProfiling,
  violence,
  hateSpeech,
  copyright,
  other,
}

enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

enum ReportedContentType {
  post,
  comment,
  user,
  message,
}

class Report {
  final String id;
  final String reporterId;
  final String reporterEmail;
  final String reportedUserId;
  final String? reportedUserEmail;
  final ReportedContentType contentType;
  final String? contentId; // post ID, comment ID, etc.
  final String? contentText; // excerpt of reported content
  final ReportType reportType;
  final String description;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? adminId; // who handled the report
  final String? adminNotes;
  final Map<String, dynamic>? metadata;

  Report({
    required this.id,
    required this.reporterId,
    required this.reporterEmail,
    required this.reportedUserId,
    this.reportedUserEmail,
    required this.contentType,
    this.contentId,
    this.contentText,
    required this.reportType,
    required this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.adminId,
    this.adminNotes,
    this.metadata,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterEmail': reporterEmail,
      'reportedUserId': reportedUserId,
      'reportedUserEmail': reportedUserEmail,
      'contentType': contentType.toString().split('.').last,
      'contentId': contentId,
      'contentText': contentText,
      'reportType': reportType.toString().split('.').last,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminId': adminId,
      'adminNotes': adminNotes,
      'metadata': metadata ?? {},
    };
  }

  // Create from Firestore document
  factory Report.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reportedUserEmail: data['reportedUserEmail'],
      contentType: ReportedContentType.values.firstWhere(
        (type) => type.toString().split('.').last == data['contentType'],
        orElse: () => ReportedContentType.post,
      ),
      contentId: data['contentId'],
      contentText: data['contentText'],
      reportType: ReportType.values.firstWhere(
        (type) => type.toString().split('.').last == data['reportType'],
        orElse: () => ReportType.other,
      ),
      description: data['description'] ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.toString().split('.').last == data['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      resolvedAt: data['resolvedAt'] != null 
          ? (data['resolvedAt'] as Timestamp).toDate() 
          : null,
      adminId: data['adminId'],
      adminNotes: data['adminNotes'],
      metadata: data['metadata'],
    );
  }

  // Create copy with updated fields
  Report copyWith({
    String? description,
    ReportStatus? status,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? adminId,
    String? adminNotes,
    Map<String, dynamic>? metadata,
  }) {
    return Report(
      id: id,
      reporterId: reporterId,
      reporterEmail: reporterEmail,
      reportedUserId: reportedUserId,
      reportedUserEmail: reportedUserEmail,
      contentType: contentType,
      contentId: contentId,
      contentText: contentText,
      reportType: reportType,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminId: adminId ?? this.adminId,
      adminNotes: adminNotes ?? this.adminNotes,
      metadata: metadata ?? this.metadata,
    );
  }

  // Get status display text in Korean
  String get statusDisplayText {
    switch (status) {
      case ReportStatus.pending:
        return '대기중';
      case ReportStatus.underReview:
        return '검토중';
      case ReportStatus.resolved:
        return '처리완료';
      case ReportStatus.dismissed:
        return '기각';
    }
  }

  // Get status color
  Color get statusColor {
    switch (status) {
      case ReportStatus.pending:
        return const Color(0xFFF59E0B); // Orange
      case ReportStatus.underReview:
        return const Color(0xFF0EA5E9); // Blue
      case ReportStatus.resolved:
        return const Color(0xFF059669); // Green
      case ReportStatus.dismissed:
        return const Color(0xFF8E8E8E); // Gray
    }
  }

  // Get report type display text in Korean
  String get reportTypeDisplayText {
    switch (reportType) {
      case ReportType.spam:
        return '스팸';
      case ReportType.harassment:
        return '괴롭힘';
      case ReportType.inappropriateContent:
        return '부적절한 콘텐츠';
      case ReportType.fakeProfiling:
        return '허위 프로필';
      case ReportType.violence:
        return '폭력적 콘텐츠';
      case ReportType.hateSpeech:
        return '혐오 발언';
      case ReportType.copyright:
        return '저작권 침해';
      case ReportType.other:
        return '기타';
    }
  }

  // Get content type display text in Korean
  String get contentTypeDisplayText {
    switch (contentType) {
      case ReportedContentType.post:
        return '게시글';
      case ReportedContentType.comment:
        return '댓글';
      case ReportedContentType.user:
        return '사용자';
      case ReportedContentType.message:
        return '메시지';
    }
  }
}

// Submission model for creating new reports
class ReportSubmission {
  final String reportedUserId;
  final String? reportedUserEmail;
  final ReportedContentType contentType;
  final String? contentId;
  final String? contentText;
  final ReportType reportType;
  final String description;

  ReportSubmission({
    required this.reportedUserId,
    this.reportedUserEmail,
    required this.contentType,
    this.contentId,
    this.contentText,
    required this.reportType,
    required this.description,
  });
}