import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String category;
  final String question;
  final String content;
  final DateTime submitDate;
  final FAQStatus status;
  final String? answer;
  final String? answeredBy;
  final DateTime? answeredDate;
  final List<String>? attachments; // URLs to uploaded files
  final String? birthDate;

  FAQ({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.category,
    required this.question,
    required this.content,
    required this.submitDate,
    required this.status,
    this.answer,
    this.answeredBy,
    this.answeredDate,
    this.attachments,
    this.birthDate,
  });

  // Convert FAQ object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'category': category,
      'question': question,
      'content': content,
      'submitDate': Timestamp.fromDate(submitDate),
      'status': status.toString().split('.').last,
      'answer': answer,
      'answeredBy': answeredBy,
      'answeredDate': answeredDate != null ? Timestamp.fromDate(answeredDate!) : null,
      'attachments': attachments,
      'birthDate': birthDate,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create FAQ object from Firestore document
  factory FAQ.fromMap(Map<String, dynamic> map, String docId) {
    return FAQ(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      category: map['category'] ?? '',
      question: map['question'] ?? '',
      content: map['content'] ?? '',
      submitDate: (map['submitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: FAQStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => FAQStatus.pending,
      ),
      answer: map['answer'],
      answeredBy: map['answeredBy'],
      answeredDate: (map['answeredDate'] as Timestamp?)?.toDate(),
      attachments: map['attachments'] != null 
          ? List<String>.from(map['attachments']) 
          : null,
      birthDate: map['birthDate'],
    );
  }

  // Create FAQ object from Firestore DocumentSnapshot
  factory FAQ.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQ.fromMap(data, doc.id);
  }

  // Copy FAQ with updated fields
  FAQ copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? category,
    String? question,
    String? content,
    DateTime? submitDate,
    FAQStatus? status,
    String? answer,
    String? answeredBy,
    DateTime? answeredDate,
    List<String>? attachments,
    String? birthDate,
  }) {
    return FAQ(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      category: category ?? this.category,
      question: question ?? this.question,
      content: content ?? this.content,
      submitDate: submitDate ?? this.submitDate,
      status: status ?? this.status,
      answer: answer ?? this.answer,
      answeredBy: answeredBy ?? this.answeredBy,
      answeredDate: answeredDate ?? this.answeredDate,
      attachments: attachments ?? this.attachments,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  // Update map for Firestore updates (excludes immutable fields)
  Map<String, dynamic> toUpdateMap() {
    return {
      'status': status.toString().split('.').last,
      'answer': answer,
      'answeredBy': answeredBy,
      'answeredDate': answeredDate != null ? Timestamp.fromDate(answeredDate!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  @override
  String toString() {
    return 'FAQ(id: $id, question: $question, status: $status, submitDate: $submitDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FAQ && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum FAQStatus {
  pending,
  answered,
  closed, // For questions that are closed without answer
}

// Extension to get display text for status
extension FAQStatusExtension on FAQStatus {
  String get displayText {
    switch (this) {
      case FAQStatus.pending:
        return '답변대기';
      case FAQStatus.answered:
        return '답변완료';
      case FAQStatus.closed:
        return '종료됨';
    }
  }

  String get adminDisplayText {
    switch (this) {
      case FAQStatus.pending:
        return 'Pending';
      case FAQStatus.answered:
        return 'Answered';
      case FAQStatus.closed:
        return 'Closed';
    }
  }
}

// FAQ submission data class
class FAQSubmission {
  final String name;
  final String email;
  final String category;
  final String question;
  final String content;
  final String? birthDate;
  final List<String>? attachments;

  FAQSubmission({
    required this.name,
    required this.email,
    required this.category,
    required this.question,
    required this.content,
    this.birthDate,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'category': category,
      'question': question,
      'content': content,
      'birthDate': birthDate,
      'attachments': attachments,
    };
  }
}