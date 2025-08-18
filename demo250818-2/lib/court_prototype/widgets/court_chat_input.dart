import 'package:flutter/material.dart';
import '../models/court_chat_message.dart';

// popup court info 
import '../models/case_model.dart'; // Add this import for CaseModel


// Chat input widget with guilty/not guilty toggle
class CourtChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String message, ChatMessageType messageType) onSend;
  final bool isEnabled;
  final CaseModel caseModel; // Add CaseModel here

  const CourtChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
    required this.caseModel, // Make it a required parameter
  });

  @override
  State<CourtChatInput> createState() => _CourtChatInputState();
}

class _CourtChatInputState extends State<CourtChatInput> with WidgetsBindingObserver {
  ChatMessageType _selectedMessageType = ChatMessageType.notGuilty;
  bool _isKeyboardVisible = false;
  late FocusNode _textFieldFocusNode;
  double _lastKnownKeyboardHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _textFieldFocusNode = FocusNode();
    _textFieldFocusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addObserver(this);
    
    // Post frame callback to get initial keyboard state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
    });
  }

  @override
  void dispose() {
    _textFieldFocusNode.removeListener(_onFocusChange);
    _textFieldFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onFocusChange() {
    // When focus changes, schedule a check for keyboard visibility
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateKeyboardVisibility();
        
        // If focus is lost, ensure keyboard dismissed state is handled
        if (!_textFieldFocusNode.hasFocus && _isKeyboardVisible) {
          // Schedule another check after focus animation completes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _updateKeyboardVisibility();
            }
          });
        }
      });
    }
  }

  void _updateKeyboardVisibility() {
    if (!mounted) return;
    
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool keyboardIsVisible = bottomInset > 0.0;
    
    // Only update if there's a significant change (> 1 pixel to avoid floating point issues)
    if ((_isKeyboardVisible != keyboardIsVisible) || 
        (bottomInset - _lastKnownKeyboardHeight).abs() > 1.0) {
      
      // Check if keyboard is being dismissed
      final bool keyboardDismissed = _isKeyboardVisible && !keyboardIsVisible;
      
      setState(() {
        _isKeyboardVisible = keyboardIsVisible;
        _lastKnownKeyboardHeight = bottomInset;
      });
      
      // Handle keyboard dismissal - reset icon state
      if (keyboardDismissed) {
        _handleKeyboardDismissed();
      }
    }
  }

  void _handleKeyboardDismissed() {
    // Reset focus when keyboard is dismissed
    if (_textFieldFocusNode.hasFocus) {
      _textFieldFocusNode.unfocus();
    }
    
    // Schedule a rebuild after the keyboard animation is complete
    // This ensures the icon switches back to document_scanner properly
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // This setState ensures the icon updates after keyboard dismissal
        });
      }
    });
  }

  @override
  void didChangeMetrics() {
    // Use post frame callback to ensure MediaQuery has updated values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateKeyboardVisibility();
    });
  }

  void _handleSend() {
    final message = widget.controller.text.trim();
    if (message.isNotEmpty && widget.isEnabled) {
      widget.onSend(message, _selectedMessageType);
      widget.controller.clear();
    }
  }

  void _handleIconTap() {
    if (!widget.isEnabled) return;
    
    if (_isKeyboardVisible || _textFieldFocusNode.hasFocus) {
      // If keyboard is visible or text field is focused, send message
      _handleSend();
    } else {
      // If keyboard is not visible, show case dialog
      _showCaseCardDialog();
    }
  }

  void _dismissKeyboard() {
    if (_textFieldFocusNode.hasFocus) {
      _textFieldFocusNode.unfocus();
      // Force a rebuild after keyboard dismiss
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  // New method to show the case card dialog
void _showCaseCardDialog() {
  // [#MODIFIED] Use a custom Dialog with the document UI
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (BuildContext context) {
      final screenSize = MediaQuery.of(context).size;
      final modalWidth = screenSize.width * 0.9;
      final modalHeight = screenSize.height * 0.65;

      // Use a custom dialog with a close button and the new document UI
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            SizedBox(
              width: modalWidth,
              height: modalHeight,
              child: _buildDocumentUi(
                width: modalWidth,
                height: modalHeight,
                title: widget.caseModel.title,
                content: Text(
                  widget.caseModel.description.isNotEmpty
                      ? widget.caseModel.description
                      : "이 사건에 대한 상세 내용이 없습니다.",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                pageInfo: '1/1',
              ),
            ),
            // Add a close button
            Positioned(
              top: -8,
              right: -8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildChatTypeSwitcher(double switcherIconSize) {
    // 선택된 타입에 따라 아이콘과 색상을 결정합니다.
    final IconData iconData = Icons.sync;  
    final Color iconColor = _selectedMessageType == ChatMessageType.notGuilty
        ? const Color(0xFF5F37CF)
        : const Color(0xFFE93D40);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            // 상태를 변경하여 아이콘을 전환합니다.
            _selectedMessageType = _selectedMessageType == ChatMessageType.notGuilty
                ? ChatMessageType.guilty
                : ChatMessageType.notGuilty;
          });
        },
        borderRadius: BorderRadius.circular(switcherIconSize / 2),
        child: Container(
          width: switcherIconSize + 12,
          height: switcherIconSize + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: switcherIconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String pageInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Spacer for centering title
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF5E4E2C), 
                fontSize: 20, 
                fontFamily: 'Pretendard', 
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              pageInfo, 
              textAlign: TextAlign.right, 
              style: const TextStyle(
                color: Color(0xFFA68A54), 
                fontSize: 14, 
                fontFamily: 'Pretendard', 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

   // Create court info card 
   Widget _buildDocumentUi({
  required double width,
  required double height,
  required String title,
  required Widget content,
  String pageInfo = '1/1',
}) {
    const double borderWidth = 12.0;
    const double foldSize = 50.0;

    Widget buildBorder(Widget child) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF79673F)),
          CustomPaint(
            painter: _PixelPatternPainter(
              dotColor: Colors.black.withValues(alpha: 0.1),
              step: 3.0,
            ),
            child: Container(),
          ),
          child,
        ],
      );
    }

    return Stack(
      children: [
        Container(color: const Color(0xFFF2E3BC)),
        CustomPaint(
          size: Size(width, height),
          painter: _PixelPatternPainter(
            dotColor: Colors.black.withValues(alpha: 0.05),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          width: foldSize,
          height: foldSize,
          child: ClipPath(
            clipper: _FoldedCornerClipper(),
            child: Container(color: const Color(0xFFD4C0A1)),
          ),
        ),
        Positioned(
          left: 0, top: 0, bottom: 0,
          child: SizedBox(width: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          right: 0, top: 0, bottom: 0,
          child: SizedBox(width: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          left: 0, top: 0, right: 0,
          child: SizedBox(height: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Positioned(
          left:  0, bottom: 0, right: 0,
          child: SizedBox(height: borderWidth, child: buildBorder(const SizedBox())),
        ),
        Padding(
          padding: const EdgeInsets.all(borderWidth + 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(title, pageInfo),
              const SizedBox(height: 15),
              Container(width: double.infinity, height: 1, color: const Color(0xFFE0C898)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    // Improved responsive design calculations
    const double baseWidth = 393.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double widthRatio = screenWidth / baseWidth;
    
    // Clamp width ratio for better sizing control
    final double clampedWidthRatio = widthRatio.clamp(0.8, 1.4);
    
    // Define consistent button sizes
    const double buttonSize = 44.0; // Standard touch target size
    const double iconSize = 20.0;
    const double switcherIconSize = 28.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Dismiss keyboard when tapping outside text field
        if (_isKeyboardVisible || _textFieldFocusNode.hasFocus) {
          _dismissKeyboard();
        }
      },
      child: Container(
        // 고정된 높이를 제거하여 내용에 맞게 자동 조절되도록 합니다.
        // height: 100 * widthRatio,
        padding: EdgeInsets.symmetric(
          horizontal: (8 * clampedWidthRatio).clamp(6.0, 12.0),
          vertical: (8 * clampedWidthRatio).clamp(6.0, 10.0),
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9), // gradiation 부여 
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 이 속성을 추가합니다.
            children: [
              Column(
                children: [
                  _buildChatTypeSwitcher(switcherIconSize),
                  SizedBox(
                    height: 16, // Fixed spacing instead of scaled
                  ),
                ],
              ), // 전환 case1 - sliding button
              
               
              Expanded( // color 흰색으로, 
                child: TextField(
                  controller: widget.controller,
                  focusNode: _textFieldFocusNode,
                  enabled: widget.isEnabled,
                  maxLines: 1,
                  maxLength: 200,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: (16 * clampedWidthRatio).clamp(14.0, 18.0),
                    fontFamily: 'Pretendard',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your ${_selectedMessageType.displayName.toLowerCase()} argument...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: (16 * clampedWidthRatio).clamp(14.0, 18.0),
                      fontFamily: 'Pretendard',
                    ),
                    filled: true,
                    fillColor: Colors.black54.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    counterStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: (12 * clampedWidthRatio).clamp(10.0, 14.0),
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 12),

              // Switch between send and docs icon based on keyboard visibility
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isEnabled ? _handleIconTap : null,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: buttonSize,
                    height: buttonSize,
                    decoration: BoxDecoration(
                      color: (_isKeyboardVisible || _textFieldFocusNode.hasFocus)
                          ? (widget.isEnabled 
                              ? Color(_selectedMessageType.colorValue) 
                              : Colors.grey)
                          : const Color(0xFF5F37CF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        (_isKeyboardVisible || _textFieldFocusNode.hasFocus) ? Icons.send : Icons.document_scanner,
                        key: ValueKey(_isKeyboardVisible || _textFieldFocusNode.hasFocus),
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      child: AnimatedContainer( // layout 현재 유지 
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

class _PixelPatternPainter extends CustomPainter {
  final Color dotColor;
  final double step;
  _PixelPatternPainter({required this.dotColor, this.step = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FoldedCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}