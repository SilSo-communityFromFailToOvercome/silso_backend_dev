import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vote_model.dart';

// 투표 컨트롤러 - 투표 관련 비즈니스 로직 관리
class VoteController extends ChangeNotifier {
  final VoteModel _voteModel;
  Timer? _voteSessionTimer;
  bool _isVotingActive = true;
  Duration _remainingTime = const Duration(minutes: 30);

  VoteController(this._voteModel);

  // Getters
  VoteModel get voteModel => _voteModel;
  bool get isVotingActive => _isVotingActive;
  Duration get remainingTime => _remainingTime;
  
  // 찬성률 (퍼센트)
  int get agreePercentage => (_voteModel.agreeRatio * 100).round();
  
  // 총 투표수
  int get totalVotes => _voteModel.agreeCount + _voteModel.disagreeCount;

  // 투표 추가
  void addVote(bool isAgree) {
    if (!_isVotingActive) return;
    
    _voteModel.addVote(isAgree);
    notifyListeners();
    
    // 투표 후 이벤트 처리 (예: 로그, 분석)
    _onVoteAdded(isAgree);
  }

  // 투표 세션 시작
  void startVotingSession({Duration? duration}) {
    _isVotingActive = true;
    _remainingTime = duration ?? const Duration(minutes: 30);
    
    _startTimer();
    notifyListeners();
  }

  // 투표 세션 종료
  void endVotingSession() {
    _isVotingActive = false;
    _voteSessionTimer?.cancel();
    notifyListeners();
  }

  // 투표 초기화
  void resetVotes() {
    // VoteModel을 새로 생성하여 카운트 초기화
    _voteModel.agreeCount = 0;
    _voteModel.disagreeCount = 0;
    _voteModel.notifyListeners();
    notifyListeners();
  }

  // 타이머 시작
  void _startTimer() {
    _voteSessionTimer?.cancel();
    _voteSessionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingTime.inSeconds <= 0) {
          endVotingSession();
          return;
        }
        
        _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        notifyListeners();
      },
    );
  }

  // 투표 추가 후 이벤트 처리
  void _onVoteAdded(bool isAgree) {
    // 여기에 투표 후 추가 로직 구현 가능
    // 예: 로그 기록, 분석 데이터 전송, 실시간 업데이트 등
    debugPrint('Vote added: ${isAgree ? "Agree" : "Disagree"}');
    
    // 특정 조건에서 자동 종료 (예: 투표수가 100개에 도달)
    if (totalVotes >= 100) {
      endVotingSession();
    }
  }

  // 투표 통계 정보
  Map<String, dynamic> getVoteStatistics() {
    return {
      'totalVotes': totalVotes,
      'agreeCount': _voteModel.agreeCount,
      'disagreeCount': _voteModel.disagreeCount,
      'agreePercentage': agreePercentage,
      'disagreePercentage': 100 - agreePercentage,
      'isActive': _isVotingActive,
      'remainingTime': _remainingTime.toString(),
    };
  }

  // 투표 유효성 검사
  bool isVoteValid() {
    return _isVotingActive && _remainingTime.inSeconds > 0;
  }

  // 투표 비율 문자열 (UI 표시용)
  String getVoteRatioText() {
    if (totalVotes == 0) return "투표가 없습니다";
    return "찬성 $agreePercentage% (${_voteModel.agreeCount}표) vs 반대 ${100 - agreePercentage}% (${_voteModel.disagreeCount}표)";
  }

  // 남은 시간 문자열 (UI 표시용)
  String getRemainingTimeText() {
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _voteSessionTimer?.cancel();
    super.dispose();
  }
}