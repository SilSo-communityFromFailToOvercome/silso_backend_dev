import 'dart:async';
import 'package:flutter/material.dart';
import '../models/vote_model.dart';

// Vote controller - Manages voting-related business logic
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
  
  // Agree percentage
  int get agreePercentage => (_voteModel.agreeRatio * 100).round();
  
  // Total vote count
  int get totalVotes => _voteModel.agreeCount + _voteModel.disagreeCount;

  // Add vote
  void addVote(bool isAgree) {
    if (!_isVotingActive) return;
    
    _voteModel.addVote(isAgree);
    notifyListeners();
    
    // Handle events after voting (e.g., logging, analytics)
    _onVoteAdded(isAgree);
  }

  // Start voting session
  void startVotingSession({Duration? duration}) {
    _isVotingActive = true;
    _remainingTime = duration ?? const Duration(minutes: 30);
    
    _startTimer();
    notifyListeners();
  }

  // End voting session
  void endVotingSession() {
    _isVotingActive = false;
    _voteSessionTimer?.cancel();
    notifyListeners();
  }

  // Reset votes
  void resetVotes() {
    // Initialize counts by resetting VoteModel
    _voteModel.agreeCount = 0;
    _voteModel.disagreeCount = 0;
    _voteModel.notifyListeners();
    notifyListeners();
  }

  // Start timer
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

  // Handle events after vote is added
  void _onVoteAdded(bool isAgree) {
    // Additional logic after voting can be implemented here
    // e.g., logging, sending analytics data, real-time updates, etc.
    debugPrint('Vote added: ${isAgree ? "Agree" : "Disagree"}');
    
    // Auto-end under specific conditions (e.g., when 100 votes are reached)
    if (totalVotes >= 100) {
      endVotingSession();
    }
  }

  // Vote statistics information
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

  // Vote validity check
  bool isVoteValid() {
    return _isVotingActive && _remainingTime.inSeconds > 0;
  }

  // Vote ratio string (for UI display)
  String getVoteRatioText() {
    if (totalVotes == 0) return "No votes yet";
    return "Agree $agreePercentage% (${_voteModel.agreeCount} votes) vs Disagree ${100 - agreePercentage}% (${_voteModel.disagreeCount} votes)";
  }

  // Remaining time string (for UI display)
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