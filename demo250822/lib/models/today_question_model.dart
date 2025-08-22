import 'package:cloud_firestore/cloud_firestore.dart';

class TodayQuestion {
  final String questionId;
  final String questionText;
  final DateTime datePosted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int answerCount;

  TodayQuestion({
    required this.questionId,
    required this.questionText,
    required this.datePosted,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.answerCount,
  });

  // Convert TodayQuestion object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'questionText': questionText,
      'datePosted': Timestamp.fromDate(datePosted),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'answerCount': answerCount,
    };
  }

  // Create TodayQuestion object from Firestore document
  factory TodayQuestion.fromMap(Map<String, dynamic> map, String documentId) {
    return TodayQuestion(
      questionId: documentId,
      questionText: map['questionText'] ?? '',
      datePosted: (map['datePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      answerCount: map['answerCount'] ?? 0,
    );
  }

  // Create a copy of TodayQuestion with updated fields
  TodayQuestion copyWith({
    String? questionId,
    String? questionText,
    DateTime? datePosted,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? answerCount,
  }) {
    return TodayQuestion(
      questionId: questionId ?? this.questionId,
      questionText: questionText ?? this.questionText,
      datePosted: datePosted ?? this.datePosted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      answerCount: answerCount ?? this.answerCount,
    );
  }

  @override
  String toString() {
    return 'TodayQuestion(questionId: $questionId, questionText: $questionText, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodayQuestion && other.questionId == questionId;
  }

  @override
  int get hashCode => questionId.hashCode;
}

class TodayQuestionAnswer {
  final String answerId;
  final String questionId;
  final String userId;
  final String answerText;
  final String avatarEmoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodayQuestionAnswer({
    required this.answerId,
    required this.questionId,
    required this.userId,
    required this.answerText,
    required this.avatarEmoji,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert TodayQuestionAnswer object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'answerId': answerId,
      'questionId': questionId,
      'userId': userId,
      'answerText': answerText,
      'avatarEmoji': avatarEmoji,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create TodayQuestionAnswer object from Firestore document
  factory TodayQuestionAnswer.fromMap(Map<String, dynamic> map, String documentId) {
    return TodayQuestionAnswer(
      answerId: documentId,
      questionId: map['questionId'] ?? '',
      userId: map['userId'] ?? '',
      answerText: map['answerText'] ?? '',
      avatarEmoji: map['avatarEmoji'] ?? '😊',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create a copy of TodayQuestionAnswer with updated fields
  TodayQuestionAnswer copyWith({
    String? answerId,
    String? questionId,
    String? userId,
    String? answerText,
    String? avatarEmoji,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodayQuestionAnswer(
      answerId: answerId ?? this.answerId,
      questionId: questionId ?? this.questionId,
      userId: userId ?? this.userId,
      answerText: answerText ?? this.answerText,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TodayQuestionAnswer(answerId: $answerId, questionId: $questionId, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodayQuestionAnswer && other.answerId == answerId;
  }

  @override
  int get hashCode => answerId.hashCode;
}

// Helper class for creating new questions
class CreateTodayQuestionRequest {
  final String questionText;
  final bool isActive;

  CreateTodayQuestionRequest({
    required this.questionText,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    final now = DateTime.now();
    return {
      'questionText': questionText,
      'datePosted': Timestamp.fromDate(now),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'isActive': isActive,
      'answerCount': 0,
    };
  }
}

// Helper class for creating new answers
class CreateTodayQuestionAnswerRequest {
  final String questionId;
  final String answerText;
  final String avatarEmoji;

  CreateTodayQuestionAnswerRequest({
    required this.questionId,
    required this.answerText,
    this.avatarEmoji = '😊',
  });

  Map<String, dynamic> toMap(String userId) {
    final now = DateTime.now();
    return {
      'questionId': questionId,
      'userId': userId,
      'answerText': answerText,
      'avatarEmoji': avatarEmoji,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };
  }
}