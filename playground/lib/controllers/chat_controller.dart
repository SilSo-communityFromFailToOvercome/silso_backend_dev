import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';

// 채팅 기능을 관리하는 컨트롤러 클래스
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

  // 메시지 추가 메서드
  void addMessage(String text, BuildContext context) {
    if (text.isEmpty || _isLimitReached) return;

    final isLeft = _random.nextBool();
    final message = Message(text: text, isLeft: isLeft);
    
    _chatSession.messages.add(message);
    
    // 화면 한계 체크
    _checkScreenLimit(context);
    
    notifyListeners();
  }

  // 화면 한계 체크 메서드
  void _checkScreenLimit(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final stackHeight = _chatSession.messageCount * ChatConfig.bubbleHeight;
    final chatAreaHeight = screenHeight - MediaQuery.of(context).viewInsets.bottom;

    if (stackHeight > chatAreaHeight * ChatConfig.stackHeightLimitRatio) {
      _isLimitReached = true;
      _startAutoResetTimer();
    }
  }

  // 자동 리셋 타이머 시작
  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(
      const Duration(seconds: ChatConfig.autoResetSeconds),
      () {
        _resetMessages();
      },
    );
  }

  // 메시지 리셋
  void _resetMessages() {
    _chatSession.messages.clear();
    _isLimitReached = false;
    _showResetNotice = true;
    
    notifyListeners();

    // 리셋 알림 타이머
    _resetNoticeTimer?.cancel();
    _resetNoticeTimer = Timer(
      const Duration(milliseconds: ChatConfig.resetNoticeMilliseconds),
      () {
        _showResetNotice = false;
        notifyListeners();
      },
    );
  }

  // 수동 리셋 (필요시)
  void manualReset() {
    _autoResetTimer?.cancel();
    _resetNoticeTimer?.cancel();
    _resetMessages();
  }

  // 메시지 삭제 (개별)
  void removeMessage(String messageId) {
    _chatSession.messages.removeWhere((message) => message.id == messageId);
    notifyListeners();
  }

  // 참여자 수 업데이트
  void updateParticipantCount(int newCount) {
    _chatSession = _chatSession.copyWith(participantCount: newCount);
    notifyListeners();
  }

  // 리소스 정리
  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _resetNoticeTimer?.cancel();
    super.dispose();
  }

  // 메시지 검색 (추가 기능)
  List<Message> searchMessages(String query) {
    return messages
        .where((message) => message.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // 메시지 통계 (추가 기능)
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