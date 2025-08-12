import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/court_chat_message.dart';

// Widget to display individual court chat messages
class CourtChatMessageWidget extends StatelessWidget {
  final CourtChatMessage message;
  final VoidCallback? onDelete;

  const CourtChatMessageWidget({
    super.key,
    required this.message,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUser = currentUser?.uid == message.senderId;
    final messageColor = Color(message.messageType.colorValue);
    
    // Align based on message type: guilty = left, not guilty = right
    final isGuiltyMessage = message.messageType == ChatMessageType.guilty;

    return Align(
      alignment: isGuiltyMessage ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 16 * widthRatio,
          vertical: 4 * widthRatio,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isGuiltyMessage 
              ? CrossAxisAlignment.start 
              : CrossAxisAlignment.end,
          children: [
            // Message type indicator and sender name
            Padding(
              padding: EdgeInsets.only(
                left: isGuiltyMessage ? 8 * widthRatio : 0,
                right: isGuiltyMessage ? 0 : 8 * widthRatio,
                bottom: 4 * widthRatio,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Message type badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * widthRatio,
                      vertical: 2 * widthRatio,
                    ),
                    decoration: BoxDecoration(
                      color: messageColor,
                      borderRadius: BorderRadius.circular(8 * widthRatio),
                    ),
                    child: Text(
                      message.messageType.shortName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10 * widthRatio,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 6 * widthRatio),
                  
                  // Sender name
                  Text(
                    isCurrentUser ? 'You' : message.senderName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12 * widthRatio,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  
                  // Delete button for own messages
                  if (isCurrentUser && onDelete != null) ...[
                    SizedBox(width: 8 * widthRatio),
                    GestureDetector(
                      onTap: onDelete,
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16 * widthRatio,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Message bubble
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * widthRatio,
                vertical: 12 * widthRatio,
              ),
              decoration: BoxDecoration(
                color: isGuiltyMessage 
                    ? messageColor.withValues(alpha: 0.8)
                    : messageColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18 * widthRatio),
                border: Border.all(
                  color: messageColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                      height: 1.4,
                    ),
                  ),
                  
                  SizedBox(height: 6 * widthRatio),
                  
                  // Timestamp
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11 * widthRatio,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}