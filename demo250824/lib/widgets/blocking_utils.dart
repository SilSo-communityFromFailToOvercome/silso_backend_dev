import 'package:flutter/material.dart';
import '../services/blocking_integration_service.dart';
import '../services/user_service.dart';

/// Utility class for adding blocking functionality to existing widgets
class BlockingUtils {
  static final BlockingIntegrationService _blockingService = BlockingIntegrationService();
  static final UserService _userService = UserService();

  /// Show block user confirmation dialog
  static Future<void> showBlockUserDialog({
    required BuildContext context,
    required String userIdToBlock,
    required String username,
    VoidCallback? onBlocked,
  }) async {
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text(
              '사용자 차단',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$username님을 차단하시겠습니까?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF121212),
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '차단하면 다음과 같은 효과가 있습니다:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 이 사용자의 게시물이 더 이상 표시되지 않습니다\n'
              '• 이 사용자의 댓글이 숨겨집니다\n'
              '• 설정에서 차단을 해제할 수 있습니다',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E8E8E),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              '차단',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldBlock == true && context.mounted) {
      await _performBlockUser(context, userIdToBlock, username, onBlocked);
    }
  }

  /// Perform the actual blocking operation
  static Future<void> _performBlockUser(
    BuildContext context,
    String userIdToBlock,
    String username,
    VoidCallback? onBlocked,
  ) async {
    try {
      await _blockingService.blockUserWithFeedback(userIdToBlock, username);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username님을 차단했습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '실행취소',
              textColor: Colors.white,
              onPressed: () async {
                await _undoBlockUser(context, userIdToBlock, username, onBlocked);
              },
            ),
          ),
        );
        onBlocked?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Undo block operation
  static Future<void> _undoBlockUser(
    BuildContext context,
    String userId,
    String username,
    VoidCallback? onUnblocked,
  ) async {
    try {
      await _blockingService.unblockUserWithFeedback(userId, username);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username님의 차단을 해제했습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onUnblocked?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('차단 해제에 실패했습니다: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Create a block menu option for PopupMenuButton
  static PopupMenuItem<String> createBlockMenuItem() {
    return const PopupMenuItem<String>(
      value: 'block',
      child: Row(
        children: [
          Icon(Icons.block, color: Colors.red, size: 18),
          SizedBox(width: 8),
          Text(
            '사용자 차단',
            style: TextStyle(
              color: Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  /// Handle menu selection for block action
  static Future<void> handleMenuSelection({
    required BuildContext context,
    required String selectedValue,
    required String userId,
    required String username,
    VoidCallback? onBlocked,
  }) async {
    if (selectedValue == 'block') {
      await showBlockUserDialog(
        context: context,
        userIdToBlock: userId,
        username: username,
        onBlocked: onBlocked,
      );
    }
  }

  /// Check if user should be shown (not blocked)
  static Future<bool> shouldShowUser(String userId) async {
    return await _blockingService.shouldShowUser(userId);
  }

  /// Quick block action without confirmation (for existing block buttons)
  static Future<void> quickBlockUser({
    required BuildContext context,
    required String userIdToBlock,
    required String username,
    VoidCallback? onBlocked,
  }) async {
    await _performBlockUser(context, userIdToBlock, username, onBlocked);
  }

  /// Add block button to existing app bars or action areas
  static Widget buildBlockButton({
    required String userId,
    required String username,
    required VoidCallback onBlocked,
    IconData icon = Icons.block,
    Color color = Colors.red,
  }) {
    return Builder(
      builder: (context) => IconButton(
        icon: Icon(icon, color: color),
        tooltip: '사용자 차단',
        onPressed: () async {
          await showBlockUserDialog(
            context: context,
            userIdToBlock: userId,
            username: username,
            onBlocked: onBlocked,
          );
        },
      ),
    );
  }

  /// Filter a list of items by checking if their users are blocked
  static Future<List<T>> filterBlockedUsers<T>(
    List<T> items,
    String Function(T) getUserId,
  ) async {
    final blockedUserIds = await _userService.getAllBlockingRelationships();
    
    return items.where((item) {
      final userId = getUserId(item);
      return !blockedUserIds.contains(userId);
    }).toList();
  }

  /// Create a wrapper that hides content from blocked users
  static Widget blockedUserWrapper({
    required String userId,
    required Widget child,
    Widget? placeholder,
  }) {
    return FutureBuilder<bool>(
      future: shouldShowUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? const SizedBox.shrink();
        }
        
        if (snapshot.data == true) {
          return child;
        }
        
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }

  /// Show blocking statistics (for debugging or admin)
  static Future<void> showBlockingStats(BuildContext context) async {
    try {
      final stats = await _blockingService.getBlockingStats();
      
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('차단 통계'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('총 차단된 사용자: ${stats['totalBlockedUsers']}'),
                Text('캐시된 사용자: ${stats['cachedBlockedUsers']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('통계를 불러올 수 없습니다: $e')),
        );
      }
    }
  }
}