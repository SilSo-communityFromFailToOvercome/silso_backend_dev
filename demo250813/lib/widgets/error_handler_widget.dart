import 'package:flutter/material.dart';
import '../services/api_error_handler.dart';
import '../services/request_manager.dart';

/// Widget that handles API errors gracefully with user-friendly messages
class ErrorHandlerWidget extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final ErrorResponse? errorResponse;

  const ErrorHandlerWidget({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.errorResponse,
  });

  /// Show error dialog with appropriate handling
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required dynamic error,
    String? endpoint,
    VoidCallback? onRetry,
  }) async {
    final errorResponse = ApiErrorHandler.handleError(error, endpoint: endpoint);
    
    await showDialog(
      context: context,
      barrierDismissible: !errorResponse.isBlocked,
      builder: (context) => ErrorHandlerWidget(
        title: title,
        message: errorResponse.userMessage,
        errorResponse: errorResponse,
        onRetry: onRetry,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<ErrorHandlerWidget> createState() => _ErrorHandlerWidgetState();
}

class _ErrorHandlerWidgetState extends State<ErrorHandlerWidget>
    with TickerProviderStateMixin {
  late AnimationController _countdownController;
  late Animation<double> _countdownAnimation;
  int _remainingSeconds = 0;
  bool _canRetry = false;

  @override
  void initState() {
    super.initState();
    
    _countdownController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _countdownAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.linear,
    ));

    _initializeCountdown();
  }

  void _initializeCountdown() {
    if (widget.errorResponse?.isBlocked == true) {
      _remainingSeconds = widget.errorResponse!.retryAfter.inSeconds;
      _startCountdown();
    } else {
      _canRetry = true;
    }
  }

  void _startCountdown() {
    if (_remainingSeconds > 0) {
      _countdownController.reset();
      _countdownController.forward().then((_) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _canRetry = true;
            } else {
              _startCountdown();
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double baseWidth = 393.0;
    final double widthRatio = screenWidth / baseWidth;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16 * widthRatio),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Icon(
            widget.errorResponse?.isBlocked == true 
                ? Icons.block 
                : Icons.error_outline,
            color: widget.errorResponse?.isBlocked == true 
                ? Colors.orange 
                : Colors.red,
            size: 24 * widthRatio,
          ),
          SizedBox(width: 12 * widthRatio),
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 18 * widthRatio,
                color: const Color(0xFF121212),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16 * widthRatio,
              color: const Color(0xFF121212),
              height: 1.4,
            ),
          ),
          
          if (widget.errorResponse?.isBlocked == true && _remainingSeconds > 0) ...[
            SizedBox(height: 16 * widthRatio),
            Container(
              padding: EdgeInsets.all(12 * widthRatio),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8 * widthRatio),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20 * widthRatio,
                    height: 20 * widthRatio,
                    child: AnimatedBuilder(
                      animation: _countdownAnimation,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _countdownAnimation.value,
                          strokeWidth: 2,
                          color: Colors.orange,
                          backgroundColor: Colors.orange.withOpacity(0.3),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12 * widthRatio),
                  Text(
                    '${_remainingSeconds}초 후 다시 시도 가능',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 14 * widthRatio,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.errorResponse?.alternatives.isNotEmpty == true) ...[
            SizedBox(height: 16 * widthRatio),
            Text(
              '다른 해결 방법:',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14 * widthRatio,
                color: const Color(0xFF121212),
              ),
            ),
            SizedBox(height: 8 * widthRatio),
            ...widget.errorResponse!.alternatives.map((alternative) =>
              Padding(
                padding: EdgeInsets.only(bottom: 4 * widthRatio),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14 * widthRatio,
                        color: const Color(0xFFC7C7C7),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        alternative,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 14 * widthRatio,
                          color: const Color(0xFFC7C7C7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.onDismiss != null)
          TextButton(
            onPressed: widget.onDismiss,
            child: Text(
              '닫기',
              style: TextStyle(
                color: const Color(0xFFC7C7C7),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16 * widthRatio,
              ),
            ),
          ),
        
        if (widget.onRetry != null)
          ElevatedButton(
            onPressed: _canRetry ? widget.onRetry : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _canRetry 
                  ? const Color(0xFF5F37CF) 
                  : const Color(0xFFBDBDBD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * widthRatio),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16 * widthRatio,
                vertical: 8 * widthRatio,
              ),
            ),
            child: Text(
              _canRetry ? '다시 시도' : '잠시 후 시도',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16 * widthRatio,
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin to add error handling capabilities to widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  
  /// Handle error with user-friendly dialog
  Future<void> handleError(
    dynamic error, {
    String title = '오류',
    String? endpoint,
    VoidCallback? onRetry,
  }) async {
    if (!mounted) return;
    
    await ErrorHandlerWidget.showErrorDialog(
      context,
      title: title,
      error: error,
      endpoint: endpoint,
      onRetry: onRetry,
    );
  }

  /// Handle specific blocked device error
  Future<void> handleBlockedDevice({
    String title = '요청 제한',
    String? endpoint,
    VoidCallback? onRetry,
  }) async {
    if (!mounted) return;
    
    final error = RequestLimitException(
      'Too many requests from this device. Try again later.'
    );
    
    await handleError(
      error,
      title: title,
      endpoint: endpoint,
      onRetry: onRetry,
    );
  }

  /// Show success message
  void showSuccess(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}