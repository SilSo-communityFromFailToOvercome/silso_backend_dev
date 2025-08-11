import 'package:flutter/material.dart';

// 키보드 인식 Scaffold - 입력창이 키보드에 가려지지 않도록 보장
class KeyboardAwareScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomSheet;
  final bool resizeToAvoidBottomInset;

  const KeyboardAwareScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomSheet,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      appBar: appBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        // 키보드가 올라왔을 때 body를 위로 이동
        transform: Matrix4.translationValues(
          0.0, 
          isKeyboardVisible ? -keyboardHeight * 0.1 : 0.0, // 키보드 높이의 10%만큼 위로
          0.0,
        ),
        child: body,
      ),
      bottomSheet: bottomSheet,
    );
  }
}

// 키보드 감지 위젯 - 입력창 위치 자동 조정
class KeyboardAwarePositioned extends StatelessWidget {
  final Widget child;
  final double? left;
  final double? right;
  final double bottom;
  final double? minKeyboardPadding;

  const KeyboardAwarePositioned({
    super.key,
    required this.child,
    this.left,
    this.right,
    required this.bottom,
    this.minKeyboardPadding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = Scaffold.of(context).appBarMaxHeight ?? 0;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    
    // 사용 가능한 화면 높이
    final availableHeight = screenHeight - appBarHeight - safeAreaTop;
    
    // 키보드가 있을 때 조정된 bottom 위치
    double adjustedBottom = bottom;
    
    if (keyboardHeight > 0) {
      // 키보드 높이 + 최소 패딩
      adjustedBottom = keyboardHeight + (minKeyboardPadding ?? 20.0);
      
      // 화면 상단 너무 가까이 가지 않도록 제한
      final maxBottom = availableHeight * 0.8; // 사용 가능 높이의 80% 이하
      adjustedBottom = adjustedBottom.clamp(bottom, maxBottom);
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: left,
      right: right,
      bottom: adjustedBottom,
      child: child,
    );
  }
}