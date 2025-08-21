import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { failure, freedom }

class Post {
  final String postId;
  final String userId; // User who posted
  final String communityId;
  final int commentCount;
  final int viewCount; // Number of views
  final int likeCount; // Number of likes
  final List<String> likedBy; // List of user IDs who liked this post
  final String title;
  final String caption;
  final bool anonymous; // Whether post is anonymous
  final String? imageUrl; // Optional image
  final PostType postType; // Post type (failure or freedom)
  final DateTime datePosted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.postId,
    required this.userId,
    required this.communityId,
    required this.commentCount,
    required this.viewCount,
    required this.likeCount,
    required this.likedBy,
    required this.title,
    required this.caption,
    required this.anonymous,
    this.imageUrl,
    required this.postType,
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
      'commentCount': commentCount,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'likedBy': likedBy,
      'title': title,
      'caption': caption,
      'anonymous': anonymous,
      'imageUrl': imageUrl,
      'postType': postType.toString().split('.').last,
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
      commentCount: map['commentCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      title: map['title'] ?? '',
      caption: map['caption'] ?? '',
      anonymous: map['anonymous'] ?? false,
      imageUrl: map['imageUrl'],
      postType: map['postType'] == 'freedom' ? PostType.freedom : PostType.failure,
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
    int? commentCount,
    int? viewCount,
    int? likeCount,
    List<String>? likedBy,
    String? title,
    String? caption,
    bool? anonymous,
    String? imageUrl,
    PostType? postType,
    DateTime? datePosted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      anonymous: anonymous ?? this.anonymous,
      imageUrl: imageUrl ?? this.imageUrl,
      postType: postType ?? this.postType,
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
  final PostType postType;

  CreatePostRequest({
    required this.communityId,
    required this.title,
    required this.caption,
    required this.anonymous,
    this.imageUrl,
    required this.postType,
  });

  Map<String, dynamic> toMap(String userId) {
    final now = DateTime.now();
    return {
      'userId': userId,
      'communityId': communityId,
      'title': title,
      'caption': caption,
      'anonymous': anonymous,
      'imageUrl': imageUrl,
      'postType': postType.toString().split('.').last,
      'commentCount': 0, // New posts start with 0 comments
      'viewCount': 0, // New posts start with 0 views
      'likeCount': 0, // New posts start with 0 likes
      'likedBy': [], // New posts start with no likes
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