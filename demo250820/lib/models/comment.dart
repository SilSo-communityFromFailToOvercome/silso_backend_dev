import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String authorProfileImage;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final bool isLiked;
  final String? parentCommentId; // For nested replies

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    required this.authorProfileImage,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentCommentId,
  });

  factory Comment.fromFirestore(String id, Map<String, dynamic> data) {
    return Comment(
      id: id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? '',
      authorProfileImage: data['authorProfileImage'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likesCount: data['likesCount'] ?? 0,
      isLiked: data['isLiked'] ?? false,
      parentCommentId: data['parentCommentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'authorProfileImage': authorProfileImage,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'likesCount': likesCount,
      'parentCommentId': parentCommentId,
    };
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorUsername,
    String? authorProfileImage,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    bool? isLiked,
    String? parentCommentId,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorProfileImage: authorProfileImage ?? this.authorProfileImage,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}