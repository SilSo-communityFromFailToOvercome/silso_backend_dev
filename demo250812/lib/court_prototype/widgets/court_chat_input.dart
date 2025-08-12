import 'package:flutter/material.dart';
import '../../models/court_chat_message.dart';

// Chat input widget with guilty/not guilty toggle
class CourtChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String message, ChatMessageType messageType) onSend;
  final bool isEnabled;

  const CourtChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  State<CourtChatInput> createState() => _CourtChatInputState();
}

class _CourtChatInputState extends State<CourtChatInput> {
  ChatMessageType _selectedMessageType = ChatMessageType.notGuilty;

  void _handleSend() {
    final message = widget.controller.text.trim();
    if (message.isNotEmpty && widget.isEnabled) {
      widget.onSend(message, _selectedMessageType);
      widget.controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final double widthRatio = screenWidth / baseWidth;

    return Container(
      height: 100 * widthRatio,
      padding: EdgeInsets.symmetric(
        horizontal: 4 * widthRatio,
        vertical: 1 * widthRatio,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message type toggle buttons
          Row(
            children: [
                Expanded(
                  child: _buildMessageTypeButton(
                    type: ChatMessageType.notGuilty,
                    label: 'Not Guilty',
                    icon: Icons.thumb_up,
                    widthRatio: widthRatio,
                  ),
                ),
                SizedBox(width: 8 * widthRatio),
                Expanded(
                  child: _buildMessageTypeButton(
                    type: ChatMessageType.guilty,
                    label: 'Guilty',
                    icon: Icons.thumb_down,
                    widthRatio: widthRatio,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 0.5 * widthRatio),
            
          // Text input with send button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isEnabled,
                  maxLines: 1,
                  maxLength: 200,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * widthRatio,
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                      hintText: 'Share your ${_selectedMessageType.displayName.toLowerCase()} argument...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16 * widthRatio,
                        fontFamily: 'Pretendard',
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24 * widthRatio),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12 * widthRatio,
                        vertical: 2 * widthRatio,
                      ),
                      counterStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12 * widthRatio,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  onSubmitted: (_) => _handleSend(),
                ),
                ),
              
              SizedBox(width: 8 * widthRatio),
              
              // Send button
              GestureDetector(
                onTap: widget.isEnabled ? _handleSend : null,
                child: Container(
                  width: 30 * widthRatio,
                  height: 30 * widthRatio,
                  decoration: BoxDecoration(
                    color: widget.isEnabled 
                        ? Color(_selectedMessageType.colorValue)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 16 * widthRatio,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build message type toggle button
  Widget _buildMessageTypeButton({
    required ChatMessageType type,
    required String label,
    required IconData icon,
    required double widthRatio,
  }) {
    final isSelected = _selectedMessageType == type;
    final color = Color(type.colorValue);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessageType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: 4 * widthRatio,
          vertical: 1 * widthRatio,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? color 
              : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20 * widthRatio),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18 * widthRatio,
            ),
            SizedBox(width: 6 * widthRatio),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 14 * widthRatio,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}