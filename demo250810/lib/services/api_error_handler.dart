import 'dart:async';
import 'request_manager.dart';

/// API Error Handler for managing blocked requests and user feedback
class ApiErrorHandler {
  static final ApiErrorHandler _instance = ApiErrorHandler._internal();
  factory ApiErrorHandler() => _instance;
  ApiErrorHandler._internal();

  final RequestManager _requestManager = RequestManager();

  /// Handle blocked device errors specifically
  static bool isBlockedDeviceError(dynamic error) {
    if (error == null) return false;
    
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('blocked') ||
           errorMessage.contains('unusual activity') ||
           errorMessage.contains('too many requests') ||
           errorMessage.contains('rate limit') ||
           errorMessage.contains('temporary blocked') ||
           errorMessage.contains('quota exceeded');
  }

  /// Get user-friendly error message for blocked requests
  static String getBlockedDeviceMessage(String? endpoint) {
    final requestManager = RequestManager();
    final cooldown = requestManager.getCooldownRemaining(endpoint ?? 'default');
    
    if (cooldown.inSeconds > 0) {
      final minutes = cooldown.inMinutes;
      final seconds = cooldown.inSeconds % 60;
      
      String timeString;
      if (minutes > 0) {
        timeString = '${minutes}분 ${seconds}초';
      } else {
        timeString = '${seconds}초';
      }
      
      return '요청이 일시적으로 제한되었습니다.\n'
             '잠시 후 다시 시도해주세요. (약 $timeString 후)';
    }
    
    return '일시적으로 너무 많은 요청이 발생했습니다.\n'
           '잠시 후 다시 시도해주세요.';
  }

  /// Clear all blocks and rate limits (emergency reset)
  void emergencyReset() {
    _requestManager.clearCache();
    // Note: We can't clear all rate limits without endpoint names
    // But cache clearing will help with some scenarios
    print('Emergency reset performed - cache cleared');
  }

  /// Get detailed status for debugging
  Map<String, dynamic> getDetailedStatus() {
    // This would need to be implemented in RequestManager
    // For now, return basic info
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'cacheCleared': true,
      'message': 'Rate limiting active - check individual endpoints'
    };
  }

  /// Check if we should show alternative actions to user
  static bool shouldShowAlternativeActions(dynamic error) {
    return isBlockedDeviceError(error);
  }

  /// Get alternative action suggestions
  static List<String> getAlternativeActions() {
    return [
      '잠시 기다린 후 다시 시도',
      '네트워크 연결 확인',
      '앱 재시작',
      '나중에 다시 시도',
    ];
  }

  /// Handle error and provide appropriate response
  static ErrorResponse handleError(dynamic error, {String? endpoint}) {
    if (isBlockedDeviceError(error)) {
      return ErrorResponse(
        isBlocked: true,
        userMessage: getBlockedDeviceMessage(endpoint),
        alternatives: getAlternativeActions(),
        canRetry: true,
        retryAfter: RequestManager().getCooldownRemaining(endpoint ?? 'default'),
      );
    }

    // Handle other common errors
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return ErrorResponse(
        isBlocked: false,
        userMessage: '네트워크 연결을 확인하고 다시 시도해주세요.',
        canRetry: true,
        retryAfter: const Duration(seconds: 5),
      );
    }

    if (errorStr.contains('timeout')) {
      return ErrorResponse(
        isBlocked: false,
        userMessage: '요청 시간이 초과되었습니다. 다시 시도해주세요.',
        canRetry: true,
        retryAfter: const Duration(seconds: 3),
      );
    }

    // Default error handling
    return ErrorResponse(
      isBlocked: false,
      userMessage: '일시적인 오류가 발생했습니다. 다시 시도해주세요.',
      canRetry: true,
      retryAfter: const Duration(seconds: 1),
    );
  }
}

/// Structured error response
class ErrorResponse {
  final bool isBlocked;
  final String userMessage;
  final List<String> alternatives;
  final bool canRetry;
  final Duration retryAfter;
  final String? technicalDetails;

  ErrorResponse({
    required this.isBlocked,
    required this.userMessage,
    this.alternatives = const [],
    this.canRetry = true,
    this.retryAfter = const Duration(seconds: 1),
    this.technicalDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'isBlocked': isBlocked,
      'userMessage': userMessage,
      'alternatives': alternatives,
      'canRetry': canRetry,
      'retryAfterSeconds': retryAfter.inSeconds,
      'technicalDetails': technicalDetails,
    };
  }
}

/// Extension for easy error handling in UI
extension ErrorHandling on Exception {
  ErrorResponse toErrorResponse({String? endpoint}) {
    return ApiErrorHandler.handleError(this, endpoint: endpoint);
  }
}