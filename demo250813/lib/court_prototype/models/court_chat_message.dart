import 'package:cloud_firestore/cloud_firestore.dart';

// Model for court chat messages with guilty/not guilty support
class CourtChatMessage {
  final String id;
  final String courtId;
  final String senderId;
  final String senderName;
  final String message;
  final ChatMessageType messageType; // guilty, notGuilty, or system
  final DateTime timestamp;
  final bool isDeleted;

  const CourtChatMessage({
    required this.id,
    required this.courtId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.messageType,
    required this.timestamp,
    this.isDeleted = false,
  });

  // Convert to map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'courtId': courtId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'messageType': messageType.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'isDeleted': isDeleted,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore document
  factory CourtChatMessage.fromFirestore(String documentId, Map<String, dynamic> data) {
    return CourtChatMessage(
      id: documentId,
      courtId: data['courtId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Anonymous',
      message: data['message'] ?? '',
      messageType: ChatMessageType.values.firstWhere(
        (type) => type.name == data['messageType'],
        orElse: () => ChatMessageType.notGuilty,
      ),
      timestamp: data['timestamp'] is Timestamp 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  // Copy with method for updates
  CourtChatMessage copyWith({
    String? id,
    String? courtId,
    String? senderId,
    String? senderName,
    String? message,
    ChatMessageType? messageType,
    DateTime? timestamp,
    bool? isDeleted,
  }) {
    return CourtChatMessage(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

// Enum for chat message types
enum ChatMessageType {
  guilty,    // Supporting guilty verdict
  notGuilty, // Supporting not guilty verdict
  system,    // System messages (like silence marker)
}

// Extension for ChatMessageType display
extension ChatMessageTypeExtension on ChatMessageType {
  String get displayName {
    switch (this) {
      case ChatMessageType.guilty:
        return 'Guilty';
      case ChatMessageType.notGuilty:
        return 'Not Guilty';
      case ChatMessageType.system:
        return 'System';
    }
  }

  String get shortName {
    switch (this) {
      case ChatMessageType.guilty:
        return 'G';
      case ChatMessageType.notGuilty:
        return 'NG';
      case ChatMessageType.system:
        return 'SYS';
    }
  }

  // Color for message type
  int get colorValue {
    switch (this) {
      case ChatMessageType.guilty:
        return 0xFFFF4444; // Red for guilty
      case ChatMessageType.notGuilty:
        return 0xFF4CAF50; // Green for not guilty
      case ChatMessageType.system:
        return 0xFF9E9E9E; // Gray for system messages
    }
  }
}