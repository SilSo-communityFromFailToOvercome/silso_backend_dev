import 'package:flutter/material.dart';

/// 투명 오버레이 디자인 위젯
/// appbar와 bottom input을 투명하게 만들면서 배경이 전체 화면을 덮도록 설계
class TransparentOverlayDesign extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomInput;
  final Color? overlayColor;
  final bool enableAppBarTransparency;
  final bool enableBottomTransparency;

  const TransparentOverlayDesign({
    super.key,
    required this.child,
    this.appBar,
    this.bottomInput,
    this.overlayColor,
    this.enableAppBarTransparency = true,
    this.enableBottomTransparency = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold 자체는 투명하게 만들어 배경이 전체를 덮도록 함
      backgroundColor: Colors.transparent,
      // AppBar도 투명하게 설정
      appBar: enableAppBarTransparency && appBar != null
          ? TransparentAppBarWrapper(originalAppBar: appBar!)
          : appBar,
      // extendBodyBehindAppBar로 배경이 appbar 뒤로 확장되도록 함
      extendBodyBehindAppBar: true,
      // extendBody로 배경이 bottom area 뒤로도 확장되도록 함
      extendBody: true,
      body: Stack(
        children: [
          // 메인 콘텐츠 (배경 포함)
          child,
          // 하단 투명 입력창 오버레이
          if (enableBottomTransparency && bottomInput != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TransparentBottomWrapper(
                child: bottomInput!,
              ),
            ),
        ],
      ),
    );
  }
}

/// 투명 AppBar 래퍼
class TransparentAppBarWrapper extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget originalAppBar;
  final double opacity;

  const TransparentAppBarWrapper({
    super.key,
    required this.originalAppBar,
    this.opacity = 0.0,
  });

  @override
  Size get preferredSize => originalAppBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent, // 완전 투명
      ),
      child: Opacity(
        opacity: opacity,
        child: originalAppBar,
      ),
    );
  }
}

/// 투명 하단 입력창 래퍼
class TransparentBottomWrapper extends StatelessWidget {
  final Widget child;
  final double opacity;

  const TransparentBottomWrapper({
    super.key,
    required this.child,
    this.opacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: child,
    );
  }
}

/// 전체 화면 배경 확장을 위한 설계 유틸리티
class FullScreenBackgroundDesign {
  /// 전체 화면을 덮는 배경 설정을 위한 Scaffold 설정
  static Widget createFullScreenBackground({
    required Widget backgroundWidget,
    required Widget content,
    PreferredSizeWidget? transparentAppBar,
    Widget? transparentBottomInput,
  }) {
    return Stack(
      children: [
        // 배경이 전체 화면을 덮도록 Positioned.fill 사용
        Positioned.fill(
          child: backgroundWidget,
        ),
        // 투명 오버레이와 콘텐츠
        TransparentOverlayDesign(
          appBar: transparentAppBar,
          bottomInput: transparentBottomInput,
          child: content,
        ),
      ],
    );
  }

  /// MediaQuery를 사용한 전체 화면 크기 계산
  static Size getFullScreenSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Size(
      mediaQuery.size.width,
      mediaQuery.size.height + mediaQuery.padding.top + mediaQuery.padding.bottom,
    );
  }

  /// Status bar와 navigation bar를 포함한 실제 화면 크기
  static EdgeInsets getScreenInsets(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
    );
  }
}

/// 투명도 조절 가능한 UI 요소들
class TransparencyController {
  /// AppBar 투명도 설정 (0.0 = 완전 투명, 1.0 = 완전 불투명)
  static const double appBarOpacity = 0.0;
  
  /// Bottom Input 투명도 설정 (0.0 = 완전 투명, 1.0 = 완전 불투명)
  static const double bottomInputOpacity = 0.0;
  
  /// 배경 오버레이 투명도 (배경 이미지 위의 어두운 오버레이)
  static const double backgroundOverlayOpacity = 0.3;

  /// 개발/테스트용 투명도 설정 (디버깅 시 사용)
  static const double debugOpacity = 0.3; // 개발 시 가시성을 위해 사용
}

/// 사용자 경험을 위한 투명 요소 설계 가이드라인
class TransparentUXGuidelines {
  /// 투명 요소에서도 터치 가능한 영역을 명확히 하기 위한 가이드라인
  static const EdgeInsets minTouchTargetPadding = EdgeInsets.all(8.0);
  
  /// 투명 상태에서 중요한 액션 버튼의 최소 크기
  static const Size minActionButtonSize = Size(44, 44);
  
  /// 투명 요소의 접근성을 위한 최소 contrast ratio
  static const double minContrastRatio = 3.0;

  /// 투명 상태에서 사용자가 인터랙션할 수 있는 영역을 표시하는 힌트
  static Widget createInteractionHint({
    required Widget child,
    bool showHint = false,
  }) {
    if (!showHint) return child;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}