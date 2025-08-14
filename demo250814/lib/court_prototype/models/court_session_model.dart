import 'package:cloud_firestore/cloud_firestore.dart';

// Model for court sessions
class CourtSessionData {
  final String id;
  final String title;
  final String description;
  final String caseId;
  final String category;
  final DateTime dateCreated;
  final int currentLiveMembers;
  final int guiltyVotes;
  final int notGuiltyVotes;
  final String? resultWin;
  final Duration timeLeft;
  final DateTime? dateEnded;
  final String creatorId;
  final bool isLive;
  final List<String> participants;
  final Map<String, dynamic> initialVotingResults;
  final Map<String, dynamic> metadata;

  const CourtSessionData({
    required this.id,
    required this.title,
    required this.description,
    required this.caseId,
    required this.category,
    required this.dateCreated,
    required this.currentLiveMembers,
    required this.guiltyVotes,
    required this.notGuiltyVotes,
    this.resultWin,
    required this.timeLeft,
    this.dateEnded,
    required this.creatorId,
    required this.isLive,
    required this.participants,
    required this.initialVotingResults,
    required this.metadata,
  });

  // Create from Firestore document
  factory CourtSessionData.fromFirestore(String documentId, Map<String, dynamic> data) {
    // Calculate time left from creation time and duration
    final createdAt = data['dateCreated'] is Timestamp 
        ? (data['dateCreated'] as Timestamp).toDate()
        : DateTime.now();
    
    final sessionDurationMs = data['timeLeft'] as int? ?? 7200000; // 2 hours default
    final sessionDuration = Duration(milliseconds: sessionDurationMs);
    final elapsed = DateTime.now().difference(createdAt);
    final timeLeft = sessionDuration - elapsed;

    return CourtSessionData(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      caseId: data['caseId'] ?? '',
      category: data['category'] ?? '',
      dateCreated: createdAt,
      currentLiveMembers: data['currentLiveMembers'] ?? 0,
      guiltyVotes: data['guiltyVotes'] ?? 0,
      notGuiltyVotes: data['notGuiltyVotes'] ?? 0,
      resultWin: data['resultWin'],
      timeLeft: timeLeft,
      dateEnded: data['dateEnded'] is Timestamp 
          ? (data['dateEnded'] as Timestamp).toDate()
          : null,
      creatorId: data['creatorId'] ?? '',
      isLive: data['isLive'] ?? false,
      participants: List<String>.from(data['participants'] ?? []),
      initialVotingResults: Map<String, dynamic>.from(data['initialVotingResults'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'caseId': caseId,
      'category': category,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'currentLiveMembers': currentLiveMembers,
      'guiltyVotes': guiltyVotes,
      'notGuiltyVotes': notGuiltyVotes,
      'resultWin': resultWin,
      'timeLeft': timeLeft.inMilliseconds,
      'dateEnded': dateEnded != null ? Timestamp.fromDate(dateEnded!) : null,
      'creatorId': creatorId,
      'isLive': isLive,
      'participants': participants,
      'initialVotingResults': initialVotingResults,
      'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for updates
  CourtSessionData copyWith({
    String? id,
    String? title,
    String? description,
    String? caseId,
    String? category,
    DateTime? dateCreated,
    int? currentLiveMembers,
    int? guiltyVotes,
    int? notGuiltyVotes,
    String? resultWin,
    Duration? timeLeft,
    DateTime? dateEnded,
    String? creatorId,
    bool? isLive,
    List<String>? participants,
    Map<String, dynamic>? initialVotingResults,
    Map<String, dynamic>? metadata,
  }) {
    return CourtSessionData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      caseId: caseId ?? this.caseId,
      category: category ?? this.category,
      dateCreated: dateCreated ?? this.dateCreated,
      currentLiveMembers: currentLiveMembers ?? this.currentLiveMembers,
      guiltyVotes: guiltyVotes ?? this.guiltyVotes,
      notGuiltyVotes: notGuiltyVotes ?? this.notGuiltyVotes,
      resultWin: resultWin ?? this.resultWin,
      timeLeft: timeLeft ?? this.timeLeft,
      dateEnded: dateEnded ?? this.dateEnded,
      creatorId: creatorId ?? this.creatorId,
      isLive: isLive ?? this.isLive,
      participants: participants ?? this.participants,
      initialVotingResults: initialVotingResults ?? this.initialVotingResults,
      metadata: metadata ?? this.metadata,
    );
  }
}