class ContentsConfig {
  // Today's Question Configuration
  static const int maxAnswersPerDay = 50;
  
  // Other content-related configurations can be added here
  static const int maxAnswerLength = 200;
  static const int minAnswerLength = 1;
  
  // Answer display settings
  static const int answersPerPage = 50;
  static const bool enableAnswerLikes = false;
  static const bool enableAnswerReports = true;
  
  // Refresh and update intervals
  static const Duration questionRefreshInterval = Duration(hours: 24);
  static const Duration answersRefreshInterval = Duration(minutes: 5);
  
  // UI Configuration
  static const double answerCardSpacing = 16.0;
  static const double containerPadding = 16.0;
  static const double borderRadius = 20.0;
  
  // Colors (can override default theme colors)
  static const int primaryPurple = 0xFF7C3AED;
  static const int darkPurple = 0xFF6D28D9;
  static const int lightGray = 0xFFF5F5F5;
  static const int mediumGray = 0xFF666666;
  static const int avatarPink = 0xFFFFB3BA;
}