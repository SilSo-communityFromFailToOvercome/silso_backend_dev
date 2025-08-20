import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/court_chat_message.dart';

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
    
    // Special handling for system messages (like silence messages)
    if (message.isSystemMessage) {
      return Container(
        margin: EdgeInsets.symmetric(vertical: 8 * widthRatio),
        child: Center(
          child: Text(
            message.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12 * widthRatio,
              fontWeight: FontWeight.w400,
              fontFamily: 'Pretendard',
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
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
                  // // Message type badge
                  // Container(
                  //   padding: EdgeInsets.symmetric(
                  //     horizontal: 6 * widthRatio,
                  //     vertical: 2 * widthRatio,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: messageColor,
                  //     borderRadius: BorderRadius.circular(8 * widthRatio),
                  //   ),
                  //   child: Text(
                  //     message.messageType.shortName,
                  //     style: TextStyle(
                  //       color: Colors.white,
                  //       fontSize: 10 * widthRatio,
                  //       fontWeight: FontWeight.w600,
                  //       fontFamily: 'Pretendard',
                  //     ),
                  //   ),
                  // ),
                  
                  // SizedBox(width: 6 * widthRatio),
                  
                  // Sender name
                  // 새로운 텍스트 박스 UI를 적용한 부분
                  Container(
                    height: 21,
                    // width는 텍스트 길이에 맞춰 자동으로 조절되도록 제거합니다.
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      // messageColor를 사용하여 배경색을 동적으로 설정합니다.
                      color: messageColor, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      child: Text(
                        isCurrentUser ? '사용자' : message.senderName,
                        style: TextStyle(
                          color: const Color(0xFFFAFAFA),
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          height: 1.43,
                        ),
                      ),
                    ),
                  )
                  // // Delete button for own messages
                  // if (isCurrentUser && onDelete != null) ...[
                  //   SizedBox(width: 8 * widthRatio),
                  //   GestureDetector(
                  //     onTap: onDelete,
                  //     child: Icon(
                  //       Icons.delete_outline,
                  //       color: Colors.white.withValues(alpha: 0.5),
                  //       size: 16 * widthRatio,
                  //     ),
                  //   ),
                  // ],
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
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16 * widthRatio),
                border: Border.all(
                  color: messageColor,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.message,
                    style: TextStyle(
                      color:const Color(0xFF121212),
                      fontSize: 16 * widthRatio,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                      height: 1.4,
                    ),
                  ),
                  
                  SizedBox(height: 6 * widthRatio),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}