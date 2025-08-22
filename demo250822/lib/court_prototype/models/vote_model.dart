import 'package:flutter/material.dart';

class VoteModel with ChangeNotifier {
  // For live court sessions, we track the actual votes from messages
  int _notGuiltyCount = 0; // 찬성 (agree/support)
  int _guiltyCount = 0;    // 반대 (oppose/guilty)

  // Legacy getters for backwards compatibility 
  int get agreeCount => _notGuiltyCount;
  int get disagreeCount => _guiltyCount;

  // New getters that match the court system terminology
  int get notGuiltyCount => _notGuiltyCount;
  int get guiltyCount => _guiltyCount;

  // Calculate agree ratio (0.0 ~ 1.0) - notGuilty is "agree"
  double get agreeRatio {
    final total = _notGuiltyCount + _guiltyCount;
    return (total == 0) ? 0.5 : _notGuiltyCount / total;
  }

  // Total vote count
  int get totalVotes => _notGuiltyCount + _guiltyCount;

  // Agree percentage (notGuilty percentage)
  int get agreePercentage => (agreeRatio * 100).round();

  // Legacy method for backwards compatibility
  void addVote(bool isAgree) {
    if (isAgree) {
      _notGuiltyCount++;
    } else {
      _guiltyCount++;
    }
    notifyListeners();
  }

  // Reset votes
  void resetVotes() {
    _notGuiltyCount = 0;
    _guiltyCount = 0;
    notifyListeners();
  }

  // Set specific vote counts (for testing and live updates)
  void setVotes(int agreeCount, int disagreeCount) {
    _notGuiltyCount = agreeCount;
    _guiltyCount = disagreeCount;
    notifyListeners();
  }

  // Update with live court vote data
  void updateWithLiveVotes(Map<String, int> liveVotes) {
    final newNotGuiltyCount = liveVotes['notGuiltyVotes'] ?? 0;
    final newGuiltyCount = liveVotes['guiltyVotes'] ?? 0;
    
    // Only notify listeners if the values actually changed
    if (_notGuiltyCount != newNotGuiltyCount || _guiltyCount != newGuiltyCount) {
      _notGuiltyCount = newNotGuiltyCount;
      _guiltyCount = newGuiltyCount;
      notifyListeners();
    }
  }

  // Setter for controller access (legacy)
  set agreeCount(int value) {
    _notGuiltyCount = value;
    notifyListeners();
  }

  set disagreeCount(int value) {
    _guiltyCount = value;
    notifyListeners();
  }

  // New setters that match court terminology
  set notGuiltyCount(int value) {
    _notGuiltyCount = value;
    notifyListeners();
  }

  set guiltyCount(int value) {
    _guiltyCount = value;
    notifyListeners();
  }
}
