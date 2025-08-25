import 'package:cloud_firestore/cloud_firestore.dart';

// 사건 (Case) model for the voting phase before court sessions
class CaseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final CaseStatus status;
  final int totalVotes;
  final int guiltyVotes;
  final int notGuiltyVotes;
  final double guiltyPercentage;
  final double controversyScore;
  final double promotionPriority;
  final List<String> voters; // User IDs who have voted
  final Map<String, dynamic> metadata;
  final DateTime? promotedAt;
  final String? courtSessionId; // Set when promoted to court session
  final int queuePosition; // Position in promotion queue (0 = not queued)

  const CaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    this.expiresAt,
    required this.status,
    required this.totalVotes,
    required this.guiltyVotes,
    required this.notGuiltyVotes,
    required this.guiltyPercentage,
    required this.controversyScore,
    required this.promotionPriority,
    required this.voters,
    required this.metadata,
    this.promotedAt,
    this.courtSessionId,
    this.queuePosition = 0,
  });

  // Create from Firestore document
  factory CaseModel.fromFirestore(String documentId, Map<String, dynamic> data) {
    final totalVotes = (data['guiltyVotes'] ?? 0) + (data['notGuiltyVotes'] ?? 0);
    final guiltyVotes = data['guiltyVotes'] ?? 0;
    final guiltyPercentage = totalVotes > 0 ? (guiltyVotes / totalVotes) * 100 : 0.0;
    
    return CaseModel(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'General',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Anonymous',
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] is Timestamp 
              ? (data['expiresAt'] as Timestamp).toDate()
              : DateTime.parse(data['expiresAt']))
          : null,
      status: CaseStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => CaseStatus.voting,
      ),
      totalVotes: totalVotes,
      guiltyVotes: guiltyVotes,
      notGuiltyVotes: data['notGuiltyVotes'] ?? 0,
      guiltyPercentage: guiltyPercentage,
      controversyScore: data['controversyScore']?.toDouble() ?? 0.0,
      promotionPriority: data['promotionPriority']?.toDouble() ?? 0.0,
      voters: List<String>.from(data['voters'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      promotedAt: data['promotedAt'] != null
          ? (data['promotedAt'] is Timestamp 
              ? (data['promotedAt'] as Timestamp).toDate()
              : DateTime.parse(data['promotedAt']))
          : null,
      courtSessionId: data['courtSessionId'],
      queuePosition: data['queuePosition'] ?? 0,
    );
  }

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'status': status.name,
      'guiltyVotes': guiltyVotes,
      'notGuiltyVotes': notGuiltyVotes,
      'controversyScore': controversyScore,
      'promotionPriority': promotionPriority,
      'voters': voters,
      'metadata': metadata,
      'promotedAt': promotedAt != null ? Timestamp.fromDate(promotedAt!) : null,
      'courtSessionId': courtSessionId,
      'queuePosition': queuePosition,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updates
  CaseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? creatorId,
    String? creatorName,
    DateTime? createdAt,
    DateTime? expiresAt,
    CaseStatus? status,
    int? totalVotes,
    int? guiltyVotes,
    int? notGuiltyVotes,
    double? guiltyPercentage,
    double? controversyScore,
    double? promotionPriority,
    List<String>? voters,
    Map<String, dynamic>? metadata,
    DateTime? promotedAt,
    String? courtSessionId,
    int? queuePosition,
  }) {
    final newGuiltyVotes = guiltyVotes ?? this.guiltyVotes;
    final newNotGuiltyVotes = notGuiltyVotes ?? this.notGuiltyVotes;
    final newTotalVotes = newGuiltyVotes + newNotGuiltyVotes;
    final newGuiltyPercentage = newTotalVotes > 0 ? (newGuiltyVotes / newTotalVotes) * 100 : 0.0;

    return CaseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      totalVotes: totalVotes ?? newTotalVotes,
      guiltyVotes: newGuiltyVotes,
      notGuiltyVotes: newNotGuiltyVotes,
      guiltyPercentage: guiltyPercentage ?? newGuiltyPercentage,
      controversyScore: controversyScore ?? this.controversyScore,
      promotionPriority: promotionPriority ?? this.promotionPriority,
      voters: voters ?? this.voters,
      metadata: metadata ?? this.metadata,
      promotedAt: promotedAt ?? this.promotedAt,
      courtSessionId: courtSessionId ?? this.courtSessionId,
      queuePosition: queuePosition ?? this.queuePosition,
    );
  }

  // Check if case meets promotion criteria
  bool get meetsPromotionCriteria {
    return status == CaseStatus.voting &&
           totalVotes >= _getMinVotesForPromotion() &&
           guiltyPercentage >= _getControversyRatioMin() &&
           guiltyPercentage <= _getControversyRatioMax();
  }

  // Check if case is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Get time remaining until expiry
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Check if user has already voted
  bool hasUserVoted(String userId) {
    return voters.contains(userId);
  }

  // Get display text for status
  String get statusDisplayText {
    switch (status) {
      case CaseStatus.voting:
        return '투표 중';
      case CaseStatus.qualified:
        return '승급 대기';
      case CaseStatus.queued:
        return '법정 대기열';
      case CaseStatus.promoted:
        return '법정 진행 중';
      case CaseStatus.completed:
        return '완료됨';
      case CaseStatus.expired:
        return '만료됨';
      case CaseStatus.rejected:
        return '거부됨';
    }
  }

  // Get status color
  int get statusColor {
    switch (status) {
      case CaseStatus.voting:
        return 0xFF2196F3; // Blue
      case CaseStatus.qualified:
        return 0xFF4CAF50; // Green
      case CaseStatus.queued:
        return 0xFFFF9800; // Orange
      case CaseStatus.promoted:
        return 0xFF9C27B0; // Purple
      case CaseStatus.completed:
        return 0xFF607D8B; // Blue Grey
      case CaseStatus.expired:
        return 0xFF757575; // Grey
      case CaseStatus.rejected:
        return 0xFFF44336; // Red
    }
  }

  // Helper methods for configuration access
  int _getMinVotesForPromotion() {
    // Import would be: import '../config/court_config.dart';
    // For now, return a default value
    return 50; // CourtSystemConfig.minVotesForPromotion;
  }

  double _getControversyRatioMin() {
    return 40.0; // CourtSystemConfig.controversyRatioMin;
  }

  double _getControversyRatioMax() {
    return 60.0; // CourtSystemConfig.controversyRatioMax;
  }
}

// Case status enumeration
enum CaseStatus {
  voting,     // Active voting phase
  qualified,  // Meets promotion criteria, waiting for queue
  queued,     // In promotion queue, waiting for court slot
  promoted,   // Promoted to active court session
  completed,  // Court session completed
  expired,    // Voting period expired without promotion
  rejected,   // Rejected for promotion (admin action)
}

// Case vote record for individual user votes
class CaseVote {
  final String id;
  final String caseId;
  final String userId;
  final String userName;
  final CaseVoteType voteType;
  final DateTime createdAt;
  final String? deviceInfo;
  final String? ipAddress; // For fraud detection

  const CaseVote({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.userName,
    required this.voteType,
    required this.createdAt,
    this.deviceInfo,
    this.ipAddress,
  });

  // Create from Firestore document
  factory CaseVote.fromFirestore(String documentId, Map<String, dynamic> data) {
    return CaseVote(
      id: documentId,
      caseId: data['caseId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      voteType: CaseVoteType.values.firstWhere(
        (type) => type.name == data['voteType'],
        orElse: () => CaseVoteType.notGuilty,
      ),
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
    );
  }

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'userId': userId,
      'userName': userName,
      'voteType': voteType.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }
}

// Case vote type enumeration
enum CaseVoteType {
  guilty,    // Vote for guilty
  notGuilty, // Vote for not guilty
}

// Extension for CaseVoteType display
extension CaseVoteTypeExtension on CaseVoteType {
  String get displayName {
    switch (this) {
      case CaseVoteType.guilty:
        return '유죄';
      case CaseVoteType.notGuilty:
        return '무죄';
    }
  }

  String get shortName {
    switch (this) {
      case CaseVoteType.guilty:
        return 'G';
      case CaseVoteType.notGuilty:
        return 'NG';
    }
  }

  // Color for vote type
  int get colorValue {
    switch (this) {
      case CaseVoteType.guilty:
        return 0xFFFF3838; // Red for guilty
      case CaseVoteType.notGuilty:
        return 0xFF3146E6; // Green for not guilty
    }
  }
}

// Case category enumeration
enum CaseCategory {
  general,
  social,
  technology,
  politics,
  ethics,
  entertainment,
  sports,
  education,
  business,
  health,
}

// Extension for CaseCategory display
extension CaseCategoryExtension on CaseCategory {
  String get displayName {
    switch (this) {
      case CaseCategory.general:
        return '일반';
      case CaseCategory.social:
        return '사회';
      case CaseCategory.technology:
        return '기술';
      case CaseCategory.politics:
        return '정치';
      case CaseCategory.ethics:
        return '윤리';
      case CaseCategory.entertainment:
        return '엔터테인먼트';
      case CaseCategory.sports:
        return '스포츠';
      case CaseCategory.education:
        return '교육';
      case CaseCategory.business:
        return '비즈니스';
      case CaseCategory.health:
        return '건강';
    }
  }

  String get iconData {
    switch (this) {
      case CaseCategory.general:
        return '📋';
      case CaseCategory.social:
        return '🏛️';
      case CaseCategory.technology:
        return '💻';
      case CaseCategory.politics:
        return '🗳️';
      case CaseCategory.ethics:
        return '⚖️';
      case CaseCategory.entertainment:
        return '🎭';
      case CaseCategory.sports:
        return '⚽';
      case CaseCategory.education:
        return '📚';
      case CaseCategory.business:
        return '💼';
      case CaseCategory.health:
        return '🏥';
    }
  }
}

// Queue item for case promotion management
class QueueItem {
  final String caseId;
  final int position;
  final DateTime queuedAt;
  final double priority;
  final DateTime estimatedPromotionTime;

  const QueueItem({
    required this.caseId,
    required this.position,
    required this.queuedAt,
    required this.priority,
    required this.estimatedPromotionTime,
  });

  // Create from Firestore document
  factory QueueItem.fromFirestore(String documentId, Map<String, dynamic> data) {
    return QueueItem(
      caseId: documentId,
      position: data['position'] ?? 0,
      queuedAt: data['queuedAt'] is Timestamp 
          ? (data['queuedAt'] as Timestamp).toDate()
          : DateTime.now(),
      priority: data['priority']?.toDouble() ?? 0.0,
      estimatedPromotionTime: data['estimatedPromotionTime'] is Timestamp 
          ? (data['estimatedPromotionTime'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'position': position,
      'queuedAt': Timestamp.fromDate(queuedAt),
      'priority': priority,
      'estimatedPromotionTime': Timestamp.fromDate(estimatedPromotionTime),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}