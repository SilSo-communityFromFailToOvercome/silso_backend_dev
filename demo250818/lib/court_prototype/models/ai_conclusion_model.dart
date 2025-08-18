import 'package:cloud_firestore/cloud_firestore.dart';

// AI-generated conclusion model for completed court sessions
// This will be implemented in a future version
class AiConclusionModel {
  final String id;
  final String caseId;
  final String courtSessionId;
  final String summary;
  final String finalVerdict;
  final String verdictReasoning;
  final List<ArgumentAnalysis> guiltyArguments;
  final List<ArgumentAnalysis> notGuiltyArguments;
  final List<KeyMoment> keyMoments;
  final ParticipantAnalysis participantAnalysis;
  final DebateQualityMetrics qualityMetrics;
  final List<String> educationalInsights;
  final List<String> legalPrinciples;
  final DateTime generatedAt;
  final AiConclusionStatus status;
  final Map<String, dynamic> metadata;

  const AiConclusionModel({
    required this.id,
    required this.caseId,
    required this.courtSessionId,
    required this.summary,
    required this.finalVerdict,
    required this.verdictReasoning,
    required this.guiltyArguments,
    required this.notGuiltyArguments,
    required this.keyMoments,
    required this.participantAnalysis,
    required this.qualityMetrics,
    required this.educationalInsights,
    required this.legalPrinciples,
    required this.generatedAt,
    required this.status,
    required this.metadata,
  });

  // Create from Firestore document
  factory AiConclusionModel.fromFirestore(String documentId, Map<String, dynamic> data) {
    return AiConclusionModel(
      id: documentId,
      caseId: data['caseId'] ?? '',
      courtSessionId: data['courtSessionId'] ?? '',
      summary: data['summary'] ?? '',
      finalVerdict: data['finalVerdict'] ?? '',
      verdictReasoning: data['verdictReasoning'] ?? '',
      guiltyArguments: (data['guiltyArguments'] as List<dynamic>? ?? [])
          .map((arg) => ArgumentAnalysis.fromMap(arg as Map<String, dynamic>))
          .toList(),
      notGuiltyArguments: (data['notGuiltyArguments'] as List<dynamic>? ?? [])
          .map((arg) => ArgumentAnalysis.fromMap(arg as Map<String, dynamic>))
          .toList(),
      keyMoments: (data['keyMoments'] as List<dynamic>? ?? [])
          .map((moment) => KeyMoment.fromMap(moment as Map<String, dynamic>))
          .toList(),
      participantAnalysis: data['participantAnalysis'] != null
          ? ParticipantAnalysis.fromMap(data['participantAnalysis'] as Map<String, dynamic>)
          : const ParticipantAnalysis(totalParticipants: 0, contributions: []),
      qualityMetrics: data['qualityMetrics'] != null
          ? DebateQualityMetrics.fromMap(data['qualityMetrics'] as Map<String, dynamic>)
          : const DebateQualityMetrics(overallScore: 0, logicalConsistency: 0, evidenceQuality: 0, engagement: 0),
      educationalInsights: List<String>.from(data['educationalInsights'] ?? []),
      legalPrinciples: List<String>.from(data['legalPrinciples'] ?? []),
      generatedAt: data['generatedAt'] is Timestamp 
          ? (data['generatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: AiConclusionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => AiConclusionStatus.pending,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'caseId': caseId,
      'courtSessionId': courtSessionId,
      'summary': summary,
      'finalVerdict': finalVerdict,
      'verdictReasoning': verdictReasoning,
      'guiltyArguments': guiltyArguments.map((arg) => arg.toMap()).toList(),
      'notGuiltyArguments': notGuiltyArguments.map((arg) => arg.toMap()).toList(),
      'keyMoments': keyMoments.map((moment) => moment.toMap()).toList(),
      'participantAnalysis': participantAnalysis.toMap(),
      'qualityMetrics': qualityMetrics.toMap(),
      'educationalInsights': educationalInsights,
      'legalPrinciples': legalPrinciples,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'status': status.name,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

// Analysis of individual arguments presented during debate
class ArgumentAnalysis {
  final String argument;
  final double strengthScore; // 0-100
  final double logicalConsistency; // 0-100
  final double evidenceQuality; // 0-100
  final String participantId;
  final String participantName;
  final DateTime timestamp;
  final List<String> supportingPoints;
  final List<String> weaknesses;

  const ArgumentAnalysis({
    required this.argument,
    required this.strengthScore,
    required this.logicalConsistency,
    required this.evidenceQuality,
    required this.participantId,
    required this.participantName,
    required this.timestamp,
    required this.supportingPoints,
    required this.weaknesses,
  });

  factory ArgumentAnalysis.fromMap(Map<String, dynamic> data) {
    return ArgumentAnalysis(
      argument: data['argument'] ?? '',
      strengthScore: data['strengthScore']?.toDouble() ?? 0.0,
      logicalConsistency: data['logicalConsistency']?.toDouble() ?? 0.0,
      evidenceQuality: data['evidenceQuality']?.toDouble() ?? 0.0,
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? '',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      supportingPoints: List<String>.from(data['supportingPoints'] ?? []),
      weaknesses: List<String>.from(data['weaknesses'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'argument': argument,
      'strengthScore': strengthScore,
      'logicalConsistency': logicalConsistency,
      'evidenceQuality': evidenceQuality,
      'participantId': participantId,
      'participantName': participantName,
      'timestamp': Timestamp.fromDate(timestamp),
      'supportingPoints': supportingPoints,
      'weaknesses': weaknesses,
    };
  }
}

// Key moments that changed the debate direction
class KeyMoment {
  final String description;
  final DateTime timestamp;
  final String participantId;
  final String participantName;
  final KeyMomentType type;
  final double impactScore; // 0-100
  final String context;

  const KeyMoment({
    required this.description,
    required this.timestamp,
    required this.participantId,
    required this.participantName,
    required this.type,
    required this.impactScore,
    required this.context,
  });

  factory KeyMoment.fromMap(Map<String, dynamic> data) {
    return KeyMoment(
      description: data['description'] ?? '',
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? '',
      type: KeyMomentType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => KeyMomentType.strongArgument,
      ),
      impactScore: data['impactScore']?.toDouble() ?? 0.0,
      context: data['context'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'participantId': participantId,
      'participantName': participantName,
      'type': type.name,
      'impactScore': impactScore,
      'context': context,
    };
  }
}

// Analysis of participant contributions
class ParticipantAnalysis {
  final int totalParticipants;
  final List<ParticipantContribution> contributions;

  const ParticipantAnalysis({
    required this.totalParticipants,
    required this.contributions,
  });

  factory ParticipantAnalysis.fromMap(Map<String, dynamic> data) {
    return ParticipantAnalysis(
      totalParticipants: data['totalParticipants'] ?? 0,
      contributions: (data['contributions'] as List<dynamic>? ?? [])
          .map((contrib) => ParticipantContribution.fromMap(contrib as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalParticipants': totalParticipants,
      'contributions': contributions.map((contrib) => contrib.toMap()).toList(),
    };
  }
}

// Individual participant contribution analysis
class ParticipantContribution {
  final String participantId;
  final String participantName;
  final int messageCount;
  final double engagementScore; // 0-100
  final double argumentQuality; // 0-100
  final double respectfulness; // 0-100
  final List<String> topArguments;

  const ParticipantContribution({
    required this.participantId,
    required this.participantName,
    required this.messageCount,
    required this.engagementScore,
    required this.argumentQuality,
    required this.respectfulness,
    required this.topArguments,
  });

  factory ParticipantContribution.fromMap(Map<String, dynamic> data) {
    return ParticipantContribution(
      participantId: data['participantId'] ?? '',
      participantName: data['participantName'] ?? '',
      messageCount: data['messageCount'] ?? 0,
      engagementScore: data['engagementScore']?.toDouble() ?? 0.0,
      argumentQuality: data['argumentQuality']?.toDouble() ?? 0.0,
      respectfulness: data['respectfulness']?.toDouble() ?? 0.0,
      topArguments: List<String>.from(data['topArguments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'messageCount': messageCount,
      'engagementScore': engagementScore,
      'argumentQuality': argumentQuality,
      'respectfulness': respectfulness,
      'topArguments': topArguments,
    };
  }
}

// Debate quality metrics
class DebateQualityMetrics {
  final double overallScore; // 0-100
  final double logicalConsistency; // 0-100
  final double evidenceQuality; // 0-100
  final double engagement; // 0-100
  final double respectfulness; // 0-100
  final double informativeness; // 0-100

  const DebateQualityMetrics({
    required this.overallScore,
    required this.logicalConsistency,
    required this.evidenceQuality,
    required this.engagement,
    this.respectfulness = 0.0,
    this.informativeness = 0.0,
  });

  factory DebateQualityMetrics.fromMap(Map<String, dynamic> data) {
    return DebateQualityMetrics(
      overallScore: data['overallScore']?.toDouble() ?? 0.0,
      logicalConsistency: data['logicalConsistency']?.toDouble() ?? 0.0,
      evidenceQuality: data['evidenceQuality']?.toDouble() ?? 0.0,
      engagement: data['engagement']?.toDouble() ?? 0.0,
      respectfulness: data['respectfulness']?.toDouble() ?? 0.0,
      informativeness: data['informativeness']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'overallScore': overallScore,
      'logicalConsistency': logicalConsistency,
      'evidenceQuality': evidenceQuality,
      'engagement': engagement,
      'respectfulness': respectfulness,
      'informativeness': informativeness,
    };
  }
}

// Key moment types
enum KeyMomentType {
  strongArgument,
  counterArgument,
  evidencePresentation,
  logicalFallacy,
  paradigmShift,
  consensus,
  disagreement,
}

// AI conclusion status
enum AiConclusionStatus {
  pending,
  processing,
  completed,
  failed,
  reviewed,
}

// Extension for KeyMomentType display
extension KeyMomentTypeExtension on KeyMomentType {
  String get displayName {
    switch (this) {
      case KeyMomentType.strongArgument:
        return '강력한 논증';
      case KeyMomentType.counterArgument:
        return '반박';
      case KeyMomentType.evidencePresentation:
        return '증거 제시';
      case KeyMomentType.logicalFallacy:
        return '논리적 오류';
      case KeyMomentType.paradigmShift:
        return '관점 전환';
      case KeyMomentType.consensus:
        return '합의점';
      case KeyMomentType.disagreement:
        return '의견 충돌';
    }
  }

  String get iconData {
    switch (this) {
      case KeyMomentType.strongArgument:
        return '💪';
      case KeyMomentType.counterArgument:
        return '🔄';
      case KeyMomentType.evidencePresentation:
        return '📊';
      case KeyMomentType.logicalFallacy:
        return '❌';
      case KeyMomentType.paradigmShift:
        return '💡';
      case KeyMomentType.consensus:
        return '🤝';
      case KeyMomentType.disagreement:
        return '⚡';
    }
  }
}

// Extension for AiConclusionStatus display
extension AiConclusionStatusExtension on AiConclusionStatus {
  String get displayName {
    switch (this) {
      case AiConclusionStatus.pending:
        return '대기 중';
      case AiConclusionStatus.processing:
        return '분석 중';
      case AiConclusionStatus.completed:
        return '완료됨';
      case AiConclusionStatus.failed:
        return '실패';
      case AiConclusionStatus.reviewed:
        return '검토됨';
    }
  }

  int get colorValue {
    switch (this) {
      case AiConclusionStatus.pending:
        return 0xFFFF9800; // Orange
      case AiConclusionStatus.processing:
        return 0xFF2196F3; // Blue
      case AiConclusionStatus.completed:
        return 0xFF4CAF50; // Green
      case AiConclusionStatus.failed:
        return 0xFFF44336; // Red
      case AiConclusionStatus.reviewed:
        return 0xFF9C27B0; // Purple
    }
  }
}