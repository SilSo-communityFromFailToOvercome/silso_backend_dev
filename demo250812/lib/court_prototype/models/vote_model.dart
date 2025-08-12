import 'package:flutter/material.dart';

class VoteModel with ChangeNotifier {
  int _agreeCount = 0;
  int _disagreeCount = 0;

  int get agreeCount => _agreeCount;
  int get disagreeCount => _disagreeCount;

  // Calculate agree ratio (0.0 ~ 1.0)
  double get agreeRatio {
    final total = _agreeCount + _disagreeCount;
    return (total == 0) ? 0.5 : _agreeCount / total;
  }

  // Total vote count
  int get totalVotes => _agreeCount + _disagreeCount;

  // Agree percentage
  int get agreePercentage => (agreeRatio * 100).round();

  void addVote(bool isAgree) {
    if (isAgree) {
      _agreeCount++;
    } else {
      _disagreeCount++;
    }
    notifyListeners();
  }

  // Reset votes
  void resetVotes() {
    _agreeCount = 0;
    _disagreeCount = 0;
    notifyListeners();
  }

  // Set specific vote counts (for testing)
  void setVotes(int agreeCount, int disagreeCount) {
    _agreeCount = agreeCount;
    _disagreeCount = disagreeCount;
    notifyListeners();
  }

  // Setter for controller access
  set agreeCount(int value) {
    _agreeCount = value;
    notifyListeners();
  }

  set disagreeCount(int value) {
    _disagreeCount = value;
    notifyListeners();
  }
}
