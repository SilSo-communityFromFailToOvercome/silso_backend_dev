import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';

// Controller class that manages chat functionality
class ChatController extends ChangeNotifier {
  // Private fields
  ChatSession _chatSession;
  final Random _random = Random();
  bool _isLimitReached = false;
  bool _showResetNotice = false;
  Timer? _autoResetTimer;
  Timer? _resetNoticeTimer;

  // Constructor
  ChatController({
    int initialParticipantCount = 809,
  }) : _chatSession = ChatSession(
          participantCount: initialParticipantCount,
        );

  // Getters
  ChatSession get chatSession => _chatSession;
  List<Message> get messages => _chatSession.messages;
  int get participantCount => _chatSession.participantCount + _chatSession.messageCount;
  bool get isLimitReached => _isLimitReached;
  bool get showResetNotice => _showResetNotice;

  // Method to add a new message
  void addMessage(String text, BuildContext context) {
    if (text.isEmpty || _isLimitReached) return;

    final isLeft = _random.nextBool();
    final message = Message(text: text, isLeft: isLeft);
    
    _chatSession.messages.add(message);
    
    // Check screen limit
    _checkScreenLimit(context);
    
    notifyListeners();
  }

  // Method to check screen limit
  void _checkScreenLimit(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final stackHeight = _chatSession.messageCount * ChatConfig.bubbleHeight;
    final chatAreaHeight = screenHeight - MediaQuery.of(context).viewInsets.bottom;

    if (stackHeight > chatAreaHeight * ChatConfig.stackHeightLimitRatio) {
      _isLimitReached = true;
      _startAutoResetTimer();
    }
  }

  // Start auto reset timer
  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(
      const Duration(seconds: ChatConfig.autoResetSeconds),
      () {
        _resetMessages();
      },
    );
  }

  // Reset messages
  void _resetMessages() {
    _chatSession.messages.clear();
    _isLimitReached = false;
    _showResetNotice = true;
    
    notifyListeners();

    // Reset notification timer
    _resetNoticeTimer?.cancel();
    _resetNoticeTimer = Timer(
      const Duration(milliseconds: ChatConfig.resetNoticeMilliseconds),
      () {
        _showResetNotice = false;
        notifyListeners();
      },
    );
  }

  // Manual reset (if needed)
  void manualReset() {
    _autoResetTimer?.cancel();
    _resetNoticeTimer?.cancel();
    _resetMessages();
  }

  // Delete message (individual)
  void removeMessage(String messageId) {
    _chatSession.messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  // Update participant count
  void updateParticipantCount(int newCount) {
    _chatSession = _chatSession.copyWith(participantCount: newCount);
    notifyListeners();
  }

  // Resource cleanup
  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _resetNoticeTimer?.cancel();
    super.dispose();
  }

  // Message search (additional feature)
  List<Message> searchMessages(String query) {
    return messages
        .where((message) => message.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Message statistics (additional feature)
  Map<String, dynamic> getMessageStats() {
    final leftCount = messages.where((m) => m.isLeft).length;
    final rightCount = messages.where((m) => !m.isLeft).length;
    
    return {
      'total': messages.length,
      'leftAligned': leftCount,
      'rightAligned': rightCount,
      'averageLength': messages.isEmpty 
          ? 0.0 
          : messages.map((m) => m.text.length).reduce((a, b) => a + b) / messages.length,
    };
  }
}