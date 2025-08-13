// Court System Configuration Management
// Controls all variables for the two-stage court system

class CourtSystemConfig {
  // Singleton pattern for global access
  static final CourtSystemConfig _instance = CourtSystemConfig._internal();
  factory CourtSystemConfig() => _instance;
  CourtSystemConfig._internal();

  // === CORE SESSION MANAGEMENT ===
  static const int maxConcurrentSessions = 8;
  static const int sessionDurationHours = 2;
  static const int sessionAutoExtendMinutes = 15;
  static const int minParticipantsToStart = 1;
  static const int maxParticipantsPerSession = 50;
  static const int sessionIdleTimeoutMinutes = 30;

  // === 사건 VOTING SYSTEM ===
  static const int minVotesForPromotion = 1;
  static const double controversyRatioMin = 0;
  static const double controversyRatioMax = 100;
  static const int votingPhaseDurationHours = 24;
  static const int votesPerUserPerDay = 10;
  static const int caseExpiryDays = 7;
  static const int revoteCooldownHours = 1;

  // === QUEUE MANAGEMENT ===
  static const int maxQueueSize = 20;
  static const int queuePositionUpdateIntervalMinutes = 5;
  static const int queueTimeoutHours = 48;
  static const double priorityBoostFactor = 1.5;
  static const int emergencyPromotionThreshold = 100;

  // === CHAT & MODERATION ===
  static const int silenceTriggerMessageCount = 5;
  static const int silenceDurationSeconds = 10;
  static const int maxMessageLength = 500;
  static const int messageRateLimitPerMinute = 10;
  static const bool autoModerationEnabled = true;
  static const bool profanityFilterEnabled = true;

  // === USER PARTICIPATION LIMITS ===
  static const int maxCasesCreatedPerDay = 3;
  static const int maxCourtSessionsJoinedSimultaneously = 3;
  static const int courtCreationCooldownHours = 6;
  static const int reputationRequiredForCaseCreation = 10;
  static const int newUserVotingDelayHours = 24;

  // === SYSTEM PERFORMANCE ===
  static const int databaseQueryTimeoutSeconds = 30;
  static const int realTimeUpdateIntervalSeconds = 2;
  static const int analyticsCalculationIntervalMinutes = 15;
  static const int cacheDurationMinutes = 5;
  static const int imageUploadMaxSizeMB = 5;

  // === PROMOTION ALGORITHM ===
  static const double voteCountWeight = 0.6;
  static const double controversyWeight = 0.3;
  static const double recencyWeight = 0.1;
  static const double trendingBoostMultiplier = 1.2;
  static const int staleCasePenaltyHours = 12;

  // === BUSINESS RULES ===
  static const int courtSessionCostCredits = 100;
  static const int votingRewardCredits = 1;
  static const int caseCreationCostCredits = 50;
  static const int successfulCourtHostBonus = 200;
  static const int minimumAgeVerification = 13;

  // === NOTIFICATION SYSTEM ===
  static const int casePromotionNotifyDelayMinutes = 5;
  static const int courtStartingWarningMinutes = 10;
  static const int sessionEndingWarningMinutes = 15;
  static const bool queuePositionChangeNotify = true;
  static const bool dailySummaryEnabled = true;

  // === EMERGENCY CONTROLS ===
  static bool systemMaintenanceMode = false;
  static bool emergencySessionTermination = false;
  static bool newCaseSubmissionDisabled = false;
  static bool votingTemporarilyDisabled = false;
  static const int maxServerLoadThreshold = 80;

  // === ANALYTICS & MONITORING ===
  static const bool trackUserEngagement = true;
  static const bool caseSuccessRateTracking = true;
  static const bool sessionQualityMetrics = true;
  static const bool abuseDetectionEnabled = true;
  static const bool performanceMonitoring = true;

  // === EXPERIMENTAL FEATURES ===
  static const bool aiCaseSuggestionEnabled = false;
  static const bool dynamicSessionDuration = false;
  static const bool userReputationSystem = true;
  static const bool caseCategoryFiltering = true;
  static const bool multilingualSupport = false;

  // === AI CONCLUSION SYSTEM (Future Implementation) ===
  static const bool aiConclusionEnabled = false;
  static const int aiAnalysisTimeoutMinutes = 10;
  static const bool aiArgumentQualityAssessment = false;
  static const bool aiKeyPointExtraction = false;
  static const bool aiDebateSummary = false;
  static const bool aiParticipantContributionAnalysis = false;

  // === TESTING CONFIGURATION ===
  static bool isTestingMode = false;
  
  // Testing overrides (only active when isTestingMode = true)
  static int get testMinVotesForPromotion => isTestingMode ? 10 : minVotesForPromotion;
  static double get testSessionDurationHours => isTestingMode ? 0.1 : sessionDurationHours.toDouble();
  static int get testMaxConcurrentSessions => isTestingMode ? 2 : maxConcurrentSessions;
  static double get testControversyRatioMin => isTestingMode ? 30.0 : controversyRatioMin;
  static double get testControversyRatioMax => isTestingMode ? 70.0 : controversyRatioMax;

  // === DYNAMIC CONFIGURATION METHODS ===
  
  // Check if case meets promotion criteria
  static bool meetsPromotionCriteria(int voteCount, double guiltyPercentage) {
    final minVotes = isTestingMode ? testMinVotesForPromotion : minVotesForPromotion;
    final minRatio = isTestingMode ? testControversyRatioMin : controversyRatioMin;
    final maxRatio = isTestingMode ? testControversyRatioMax : controversyRatioMax;
    
    return voteCount >= minVotes && 
           guiltyPercentage >= minRatio && 
           guiltyPercentage <= maxRatio;
  }

  // Calculate controversy score (higher = more controversial)
  static double calculateControversyScore(double guiltyPercentage) {
    final middle = 50.0;
    final distance = (guiltyPercentage - middle).abs();
    return 100.0 - (distance * 2); // 100 = perfectly controversial, 0 = completely one-sided
  }

  // Calculate promotion priority score
  static double calculatePromotionPriority(int voteCount, double guiltyPercentage, DateTime createdAt) {
    final controversyScore = calculateControversyScore(guiltyPercentage);
    final recencyScore = _calculateRecencyScore(createdAt);
    
    return (voteCount * voteCountWeight) + 
           (controversyScore * controversyWeight) + 
           (recencyScore * recencyWeight);
  }

  // Calculate recency score (newer cases get higher scores)
  static double _calculateRecencyScore(DateTime createdAt) {
    final hoursSinceCreation = DateTime.now().difference(createdAt).inHours;
    if (hoursSinceCreation <= staleCasePenaltyHours) {
      return 100.0; // Full recency score
    } else {
      // Gradually decrease score after penalty threshold
      final decayHours = hoursSinceCreation - staleCasePenaltyHours;
      return (100.0 - (decayHours * 2)).clamp(0.0, 100.0);
    }
  }

  // Get session duration based on mode
  static Duration getSessionDuration() {
    if (isTestingMode) {
      return Duration(minutes: (testSessionDurationHours * 60).round());
    }
    return Duration(hours: sessionDurationHours);
  }

  // Get maximum concurrent sessions based on mode
  static int getMaxConcurrentSessions() {
    return isTestingMode ? testMaxConcurrentSessions : maxConcurrentSessions;
  }

  // Emergency controls
  static void enableMaintenanceMode() {
    systemMaintenanceMode = true;
  }

  static void disableMaintenanceMode() {
    systemMaintenanceMode = false;
  }

  static void enableTestingMode() {
    isTestingMode = true;
  }

  static void disableTestingMode() {
    isTestingMode = false;
  }

  // Configuration validation
  static bool validateConfiguration() {
    // Ensure ratios are valid
    if (controversyRatioMin >= controversyRatioMax) return false;
    if (controversyRatioMin < 0 || controversyRatioMax > 100) return false;
    
    // Ensure positive values
    if (minVotesForPromotion <= 0) return false;
    if (maxConcurrentSessions <= 0) return false;
    if (sessionDurationHours <= 0) return false;
    
    // Ensure weights sum properly for promotion algorithm
    final totalWeight = voteCountWeight + controversyWeight + recencyWeight;
    if ((totalWeight - 1.0).abs() > 0.01) return false; // Allow small floating point errors
    
    return true;
  }

  // Debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isTestingMode': isTestingMode,
      'systemMaintenanceMode': systemMaintenanceMode,
      'currentMaxSessions': getMaxConcurrentSessions(),
      'currentSessionDuration': getSessionDuration().toString(),
      'currentMinVotes': isTestingMode ? testMinVotesForPromotion : minVotesForPromotion,
      'currentControversyRange': '${isTestingMode ? testControversyRatioMin : controversyRatioMin}% - ${isTestingMode ? testControversyRatioMax : controversyRatioMax}%',
      'configurationValid': validateConfiguration(),
    };
  }
}

// Configuration change notifier for real-time updates
class CourtConfigNotifier {
  static final List<VoidCallback> _listeners = [];
  
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }
  
  static void notifyConfigChanged() {
    for (final listener in _listeners) {
      listener();
    }
  }
}

// Type alias for void callback
typedef VoidCallback = void Function();