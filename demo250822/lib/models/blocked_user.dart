import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String id;
  final String username;
  final String profileImage;
  final DateTime? blockedAt;

  BlockedUser({
    required this.id,
    required this.username,
    required this.profileImage,
    this.blockedAt,
  });

  factory BlockedUser.fromFirestore(String id, Map<String, dynamic> data) {
    return BlockedUser(
      id: id,
      username: data['blockedUserUsername'] ?? '',
      profileImage: data['blockedUserProfileImage'] ?? '',
      blockedAt: (data['blockedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'blockedUserUsername': username,
      'blockedUserProfileImage': profileImage,
      'blockedAt': FieldValue.serverTimestamp(),
    };
  }
}