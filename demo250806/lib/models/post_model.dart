import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String userId; // User who posted
  final String communityId;
  final String communityName; // Denormalized community name for performance
  final int commentCount;
  final int viewCount; // Number of views
  final String title;
  final String caption;
  final bool anonymous; // Whether post is anonymous
  final String? imageUrl; // Optional image
  final DateTime datePosted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.postId,
    required this.userId,
    required this.communityId,
    required this.communityName,
    required this.commentCount,
    required this.viewCount,
    required this.title,
    required this.caption,
    required this.anonymous,
    this.imageUrl,
    required this.datePosted,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Post object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'communityId': communityId,
      'communityName': communityName,
      'commentCount': commentCount,
      'viewCount': viewCount,
      'title': title,
      'caption': caption,
      'anonymous': anonymous,
      'imageUrl': imageUrl,
      'datePosted': Timestamp.fromDate(datePosted),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create Post object from Firestore document
  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    return Post(
      postId: documentId,
      userId: map['userId'] ?? '',
      communityId: map['communityId'] ?? '',
      communityName: map['communityName'] ?? 'Unknown Community', // Fallback for old posts
      commentCount: map['commentCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      title: map['title'] ?? '',
      caption: map['caption'] ?? '',
      anonymous: map['anonymous'] ?? false,
      imageUrl: map['imageUrl'],
      datePosted: (map['datePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy of Post with updated fields
  Post copyWith({
    String? postId,
    String? userId,
    String? communityId,
    String? communityName,
    int? commentCount,
    int? viewCount,
    String? title,
    String? caption,
    bool? anonymous,
    String? imageUrl,
    DateTime? datePosted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      anonymous: anonymous ?? this.anonymous,
      imageUrl: imageUrl ?? this.imageUrl,
      datePosted: datePosted ?? this.datePosted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Post(postId: $postId, title: $title, communityId: $communityId, anonymous: $anonymous)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.postId == postId;
  }

  @override
  int get hashCode => postId.hashCode;
}

// Helper class for creating posts
class CreatePostRequest {
  final String communityId;
  final String title;
  final String caption;
  final bool anonymous;
  final String? imageUrl;

  CreatePostRequest({
    required this.communityId,
    required this.title,
    required this.caption,
    required this.anonymous,
    this.imageUrl,
  });

  Map<String, dynamic> toMap(String userId, {String? communityName}) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'communityId': communityId,
      'communityName': communityName ?? 'Unknown Community', // Include community name
      'title': title,
      'caption': caption,
      'anonymous': anonymous,
      'imageUrl': imageUrl,
      'commentCount': 0, // New posts start with 0 comments
      'viewCount': 0, // New posts start with 0 views
      'datePosted': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}

// Helper class for post comments/interactions
class PostComment {
  final String commentId;
  final String postId;
  final String userId;
  final String content;
  final CommentType type; // advice or empathy
  final bool anonymous;
  final DateTime createdAt;

  PostComment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.content,
    required this.type,
    required this.anonymous,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'userId': userId,
      'content': content,
      'type': type.toString().split('.').last,
      'anonymous': anonymous,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PostComment.fromMap(Map<String, dynamic> map, String documentId) {
    return PostComment(
      commentId: documentId,
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      content: map['content'] ?? '',
      type: map['type'] == 'empathy' ? CommentType.empathy : CommentType.advice,
      anonymous: map['anonymous'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

enum CommentType {
  advice,
  empathy,
}