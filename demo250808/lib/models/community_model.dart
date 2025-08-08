import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String communityId;
  final String communityName;
  final String creatorId; // User ID who created the community
  final int memberCount;
  final List<String> members; // List of user IDs who are members
  final String? announcement; // Optional community announcement
  final List<String> posts; // List of post IDs in this community
  final String? communityBanner; // URL to community banner image (png/jpg)
  final List<String> hashtags; // Hashtags for filtering communities
  final DateTime dateAdded; // Date when community was created/added
  final DateTime createdAt;
  final DateTime updatedAt;

  Community({
    required this.communityId,
    required this.communityName,
    required this.creatorId,
    required this.memberCount,
    required this.members,
    this.announcement,
    required this.posts,
    this.communityBanner,
    required this.hashtags,
    required this.dateAdded,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Community object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'communityName': communityName,
      'creatorId': creatorId,
      'memberCount': memberCount,
      'members': members,
      'announcement': announcement,
      'posts': posts,
      'communityBanner': communityBanner,
      'hashtags': hashtags,
      'dateAdded': Timestamp.fromDate(dateAdded),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Community object from Firestore document
  factory Community.fromMap(Map<String, dynamic> map, String documentId) {
    return Community(
      communityId: documentId,
      communityName: map['communityName'] ?? '',
      creatorId: map['creatorId'] ?? '',
      memberCount: map['memberCount'] ?? 0,
      members: List<String>.from(map['members'] ?? []),
      announcement: map['announcement'],
      posts: List<String>.from(map['posts'] ?? []),
      communityBanner: map['communityBanner'],
      hashtags: List<String>.from(map['hashtags'] ?? []),
      dateAdded: (map['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Check if this is the default community
  bool get isDefaultCommunity {
    return communityName == '종합게시반' || communityId == 'default_general_board';
  }

  // Create a copy of Community with updated fields
  Community copyWith({
    String? communityId,
    String? communityName,
    String? creatorId,
    int? memberCount,
    List<String>? members,
    String? announcement,
    List<String>? posts,
    String? communityBanner,
    List<String>? hashtags,
    DateTime? dateAdded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Community(
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      creatorId: creatorId ?? this.creatorId,
      memberCount: memberCount ?? this.memberCount,
      members: members ?? this.members,
      announcement: announcement ?? this.announcement,
      posts: posts ?? this.posts,
      communityBanner: communityBanner ?? this.communityBanner,
      hashtags: hashtags ?? this.hashtags,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Community(communityId: $communityId, communityName: $communityName, creatorId: $creatorId, memberCount: $memberCount, hashtags: $hashtags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community && other.communityId == communityId;
  }

  @override
  int get hashCode => communityId.hashCode;
}

// Helper class for community creation
class CreateCommunityRequest {
  final String communityName;
  final String? announcement;
  final String? communityBanner;
  final List<String> hashtags;

  CreateCommunityRequest({
    required this.communityName,
    this.announcement,
    this.communityBanner,
    required this.hashtags,
  });

  Map<String, dynamic> toMap(String creatorId) {
    final now = DateTime.now();
    return {
      'communityName': communityName,
      'creatorId': creatorId,
      'memberCount': 1, // Creator is the first member
      'members': [creatorId], // Creator joins automatically
      'announcement': announcement,
      'posts': <String>[], // Empty posts list initially
      'communityBanner': communityBanner,
      'hashtags': hashtags,
      'dateAdded': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}

// Helper class for community membership
class CommunityMembership {
  final String userId;
  final String communityId;
  final DateTime joinedAt;
  final bool isCreator;
  final bool isModerator;

  CommunityMembership({
    required this.userId,
    required this.communityId,
    required this.joinedAt,
    required this.isCreator,
    this.isModerator = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'communityId': communityId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isCreator': isCreator,
      'isModerator': isModerator,
    };
  }

  factory CommunityMembership.fromMap(Map<String, dynamic> map) {
    return CommunityMembership(
      userId: map['userId'] ?? '',
      communityId: map['communityId'] ?? '',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCreator: map['isCreator'] ?? false,
      isModerator: map['isModerator'] ?? false,
    );
  }
}