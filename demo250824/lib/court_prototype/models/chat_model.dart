// Chat message data model class
class Message {
  final String text;
  final bool isLeft;
  final DateTime timestamp;
  final String id;

  Message({
    required this.text,
    required this.isLeft,
    DateTime? timestamp,
    String? id,
  })  : timestamp = timestamp ?? DateTime.now(),
        id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isLeft': isLeft,
      'timestamp': timestamp.toIso8601String(),
      'id': id,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      text: json['text'],
      isLeft: json['isLeft'],
      timestamp: DateTime.parse(json['timestamp']),
      id: json['id'],
    );
  }
}

// Chat session information model class
class ChatSession {
  final List<Message> messages;
  final int participantCount;
  final DateTime sessionStart;
  final Duration remainingTime;

  ChatSession({
    List<Message>? messages,
    required this.participantCount,
    DateTime? sessionStart,
    Duration? remainingTime,
  })  : messages = messages ?? [],
        sessionStart = sessionStart ?? DateTime.now(),
        remainingTime = remainingTime ?? const Duration(hours: 3);

  int get messageCount => messages.length;
  
  bool get isLimitReached => messageCount >= 20; // Example limit value

  ChatSession copyWith({
    List<Message>? messages,
    int? participantCount,
    DateTime? sessionStart,
    Duration? remainingTime,
  }) {
    return ChatSession(
      messages: messages ?? this.messages,
      participantCount: participantCount ?? this.participantCount,
      sessionStart: sessionStart ?? this.sessionStart,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

// Chat configuration model class
class ChatConfig {
  static const double bubbleHeight = 55.0;
  static const double inputBarHeight = 100.0;
  static const int autoResetSeconds = 3;
  static const int resetNoticeMilliseconds = 1500;
  static const double maxBubbleWidthRatio = 0.6;
  static const double stackHeightLimitRatio = 0.9;
}
